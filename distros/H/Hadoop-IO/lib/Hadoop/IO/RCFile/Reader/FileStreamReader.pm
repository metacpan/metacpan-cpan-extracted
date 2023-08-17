package Hadoop::IO::RCFile::Reader::FileStreamReader;
$Hadoop::IO::RCFile::Reader::FileStreamReader::VERSION = '0.003';
use 5.010;
use strict;
use warnings;

use Data::Dumper;
use File::Spec;
use Log::Log4perl;
use Moo;
use Types::Standard qw(
    Dict
    HashRef
    InstanceOf
    Str
);

use constant {
    STRING_CHUNK_SIZE => 10 * 1024**2,
    ARRAY_CHUNK_SIZE  =>  1 * 1024**2,
};

has webhdfs_client => (
    is       => 'ro',
    isa      => InstanceOf['Net::Hadoop::WebHDFS::LWP'],
    required => 1,
);

has file => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has _file_meta => (
    is  => 'rw',
    isa => HashRef, # Dict?
);

has _reader_info => (
    is  => 'rw',
    isa => HashRef, # Dict?
);

has _web_reader_info => (
    is  => 'rw',
    isa => HashRef, # Dict?
);

has log => (
    is  => 'rw',
    isa => InstanceOf['Log::Log4perl::Logger'],
);

sub BUILD {
    my ($self, $args) = @_;

    $self->log(Log::Log4perl->get_logger("Hadoop::IO::RCFile::Reader::FileStreamReader"));

    my $file = $self->file;
    $self->log->debug("Retrieving file information for $file");

    my $hdfs_client = $self->webhdfs_client;
    my $file_meta   = $hdfs_client->exists($file ) || die "$file does not exist!";

    $self->log->debug("Got file meta for $file\n" . Dumper($file_meta));

    if ($file_meta->{type} ne 'FILE') {
        die "$file is not a file";
    }

    $self->_file_meta($file_meta);

    $self->_reader_info({ file_len    => $file_meta->{length},
                          file_offset => 0,
                          buffer_pos  => 0,
                          buffer_len  => 0,
                          raw_buffer  => [],
                          eof         => 0,
                        }
    );
    $self->_web_reader_info({ file_len    => $file_meta->{length},
                              file_offset => 0,
                              buffer_pos  => 0,
                              buffer_len  => 0,
                              raw_buffer  => undef,
                              eof         => 0,
                            }
    );
}

sub read_byte {
    my ($self) = @_;
    my ($nread, $data) = $self->read(1);
    return $data->[0] if ($data && (ref($data) eq 'ARRAY'));
    return undef;
}

sub read {
    my ($self, $len) = @_;
    if ($len <= 0) {
        return 0, [];
    }

    my $n = 0;
    my @content;
    while (1) {
        my $nread = $self->_read($len - $n, \@content);
        if ($nread <= 0) {
            if ($n == 0) {
                return $nread, undef;
            }
            $n = $n + $nread;
            return $n, \@content;
        }
        $n = $n + $nread;
        if ($n >= $len) {
            return $n, \@content;
        }
    }
}

sub _read {
    my ($self, $len, $container) = @_;
    my $reader_info = $self->_reader_info;

    if ($reader_info->{eof}) {
        return -1, undef;
    }
    my $buffer_len = $reader_info->{buffer_len};
    my $buffer_pos = $reader_info->{buffer_pos};
    my $avail      = $buffer_len - $buffer_pos;

    if ($avail <= 0) {
        my $n = $self->_fill();
        if ($n == -1) {
            return -1, undef;
        }
        return $self->_read($len, $container);
    }
    my $buffer = $reader_info->{raw_buffer};
    if ($avail >= $len) {
        push @$container, @{$buffer}[ $buffer_pos .. ($buffer_pos + $len - 1) ];
        $buffer_pos = $buffer_pos + $len;
        $reader_info->{buffer_pos} = $buffer_pos;
        return $len;
    } else {
        push @$container, @{$buffer}[ $buffer_pos .. ($buffer_pos + $avail - 1) ];
        $buffer_pos = $buffer_pos + $avail;
        $reader_info->{buffer_pos} = $buffer_pos;
        return $avail;
    }

}

sub _fill {
    my ($self) = @_;

    my $hdfs_client        = $self->webhdfs_client;
    my $file               = $self->file;
    my $reader_info        = $self->_reader_info;
    my $offset             = $reader_info->{file_offset};
    my $file_len           = $reader_info->{file_len};
    my $file_remaining_len = $file_len - $offset;

    if ($file_remaining_len <= 0) {
        $self->log->debug("We have reached end of file");
        $reader_info->{eof} = 1;
        return -1;
    }
    my $read_len    = ($file_remaining_len >= ARRAY_CHUNK_SIZE) ? ARRAY_CHUNK_SIZE : $file_remaining_len;
    my $content     = $self->_read_from_string_buffer($read_len);
    my @content_b   = unpack("c*", $content);
    my $content_len = scalar @content_b;
    delete $reader_info->{raw_buffer};
    $offset                     = $offset + $content_len;
    $reader_info->{file_offset} = $offset;
    $reader_info->{raw_buffer}  = \@content_b;
    $reader_info->{buffer_pos}  = 0;
    $reader_info->{buffer_len}  = $content_len;
    return $content_len;
}

sub _read_from_string_buffer {
    my ($self, $len) = @_;
    my $reader_info = $self->_web_reader_info;

    if ($reader_info->{eof}) {
        return -1, undef;
    }
    my $buffer_len = $reader_info->{buffer_len};
    my $buffer_pos = $reader_info->{buffer_pos};
    my $avail      = $buffer_len - $buffer_pos;

    if ($avail <= 0) {
        $self->log->debug("No data available in buffer, going to read from hdfs");
        my $n = $self->_read_data_from_hdfs();
        if ($n == -1) {
            return -1, undef;
        }
        return $self->_read_from_string_buffer($len);
    }
    my $buffer = $reader_info->{raw_buffer};
    if ($avail >= $len) {
        my $content = substr $buffer, $buffer_pos, $len;
        $buffer_pos = $buffer_pos + $len;
        $reader_info->{buffer_pos} = $buffer_pos;
        return $len, $content;
    } else {
        $self->log->debug("Less data available in buffer then needed in _read2");
        my $content = substr $buffer, $buffer_pos;
        $buffer_pos = $buffer_pos + $avail;
        $reader_info->{buffer_pos} = $buffer_pos;
        return $avail;
    }

}

sub _read_data_from_hdfs {
    my ($self) = @_;

    my $hdfs_client        = $self->webhdfs_client;
    my $file               = $self->file;
    my $reader_info        = $self->_web_reader_info;
    my $offset             = $reader_info->{file_offset};
    my $file_len           = $reader_info->{file_len};
    my $file_remaining_len = $file_len - $offset;

    if ($file_remaining_len <= 0) {
        $self->log->debug("We have reached end of file");
        $reader_info->{eof} = 1;
        return -1;
    }
    my $read_len = ($file_remaining_len >= STRING_CHUNK_SIZE) ? STRING_CHUNK_SIZE : $file_remaining_len;
    $self->log->debug("Going to read $read_len byte from file");
    my $content = $hdfs_client->read($file,
                                     offset => $offset,
                                     length => $read_len,
    );
    delete $reader_info->{raw_buffer};
    my $content_len = length $content;
    $offset                     = $offset + $content_len;
    $reader_info->{file_offset} = $offset;
    $reader_info->{raw_buffer}  = $content;
    $reader_info->{buffer_pos}  = 0;
    $reader_info->{buffer_len}  = $content_len;
    return $content_len;
}

sub has_more {
    my ($self) = @_;

    my $hdfs_client = $self->webhdfs_client;
    my $file        = $self->file;
    my $reader_info = $self->_reader_info;
    my $buffer_len  = $reader_info->{buffer_len};
    my $buffer_pos  = $reader_info->{buffer_pos};
    my $avail       = $buffer_len - $buffer_pos;
    return 1 if ($avail > 0);
    my $offset             = $reader_info->{file_offset};
    my $file_len           = $reader_info->{file_len};
    my $file_remaining_len = $file_len - $offset;
    return 1 if ($file_remaining_len > 0);
    $reader_info->{eof} = 1;
    return 0;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Hadoop::IO::RCFile::Reader::FileStreamReader

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    my $reader = Hadoop::IO::RCFile::Reader::FileStreamReader->new({
                            file => "/user/hive/warehouse/db_name.db/table_name/000000_0",
                            webhdfs_client => $webhdfs_client
                        });
    my ($len_read, $content) = $reader->read($len) if $reader->has_more();

=head1 DESCRIPTION

This module creates an abstract interface to access the raw file in hdfs.

=head1 NAME

Hadoop::IO::RCFile::Reader::FileStreamReader - Read the HDFS file through the WebHDFS API

=head1 METHODS

=head2 new

The constructor. Accepts parameters in key => value format.

=head3 file

=head3 webhdfs_client

=head2 read

Try to read next $len byte from the file, accept $len as parameter. Return 2 paramter, first one is
number of bytes able to read from the file, second is the content as string.Return (-1,undef) if end
of file reached already.

=head2 read_byte

=head2 has_more

Return true if more bytes can be read, else return false.

=for Pod::Coverage BUILD

=head1 AUTHORS

=over 4

=item *

Philippe Bruhat

=item *

Sabbir Ahmed

=item *

Somesh Malviya

=item *

Vikentiy Fesunov

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Booking.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
