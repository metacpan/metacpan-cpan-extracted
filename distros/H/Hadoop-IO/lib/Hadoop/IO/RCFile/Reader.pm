package Hadoop::IO::RCFile::Reader;
$Hadoop::IO::RCFile::Reader::VERSION = '0.003';
use 5.010;
use strict;
use warnings;
use integer;

use constant {
    CURRENT_VERSION =>  1,
    SYNC_ESCAPE     => -1,
    SYNC_HASH_SIZE  => 16,
};

use Encode ();
use Hadoop::IO::RCFile::Reader::FileStreamReader;
use Log::Log4perl;
use Moo;
use Types::Standard qw(
    ArrayRef
    Bool
    Dict
    HashRef
    InstanceOf
    Int
    Str
);

has webhdfs_client => (
    is       => 'ro',
    isa      => InstanceOf['Net::Hadoop::WebHDFS::LWP'],
    required => 1,
);

has directory => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has decode_utf8 => (
    is  => 'rw',
    isa => Bool,
);

has _files => (
    is  => 'rw',
    isa => ArrayRef[ Str ],
);

has _file_meta => (
    is  => 'rw',
    isa => HashRef,
);

has _current_file_info => (
    is  => 'rw',
    isa => HashRef, # Dict?
);

has _total_file_count => (
    is  => 'rw',
    isa => Int,
);

has _stream_reader => (
    is  => 'rw',
    isa => InstanceOf['Hadoop::IO::RCFile::Reader::FileStreamReader'],
);

has log => (
    is  => 'rw',
    isa => InstanceOf['Log::Log4perl::Logger'],
);

sub BUILD {
    my ($self, $args) = @_;

    $self->log(Log::Log4perl->get_logger("Hadoop::IO::RCFile::Reader"));

    my $directory = $self->directory;

    $self->log->info("Retrieving file list for $directory");

    my $hdfs_client    = $self->webhdfs_client;
    my $directory_info = $hdfs_client->exists($directory);
    if (!$directory_info) {
        die "$directory does not exist!";
    }

    my (@files, %file_meta);

    if ($directory_info->{type} eq 'DIRECTORY') {
        $hdfs_client->find(
            $directory,
            sub {
                my ($cwd, $e) = @_;
                my $file = File::Spec->catfile($cwd, $e->{pathSuffix});
                push @files, $file;
                $file_meta{$file} = $e;
            },
            {  re_ignore => qr{
                            \A       # Filter some filenames out even before reaching the callback
                                [_.] # logs and meta data, java junk, _SUCCESS files, etc.
                        }xms,
            },
        );
    } else {
        push @files, $directory;
        $file_meta{$directory} = $directory_info;
    }

    $self->log->info("Found " . scalar(@files) . " files to read in directory $directory");
    $self->log->info("decode_utf8 is true, will decode string to utf string using decode_utf8 method") if $self->decode_utf8;

    $self->_files(\@files);
    $self->_file_meta(\%file_meta);
    $self->_current_file_info({ file_pos  => 0,
                                init      => 0,
                                row_group => { row_count       => 0,
                                               next_row_idx    => 0,
                                               current_row_idx => -1,
                                }
                              }
    );
    $self->_total_file_count(scalar @files);
}

sub current_row {
    my $self            = shift;
    my $current_row_idx = $self->{_current_file_info}{row_group}{current_row_idx};
    if ($current_row_idx != -1) {
        my $rows = $self->{_current_file_info}{row_group}{rows};
        return $rows->[$current_row_idx];
    }
    return;
}

sub next {
    my $self = shift;
    if ($self->_has_record_in_buffer()) {
        my $rowgroup_info = $self->{_current_file_info}{row_group};
        $rowgroup_info->{current_row_idx} = $rowgroup_info->{next_row_idx};
        $rowgroup_info->{next_row_idx}++;
        return 1;
    }
    my $current_file_info = $self->{_current_file_info};

    #check all file readed
    if ($current_file_info->{file_pos} >= $self->{_total_file_count}) {
        return 0;
    }

    #check current file initiated or not
    my $current_file_pos = $current_file_info->{file_pos};
    my $total_file_count = $self->{_total_file_count};
    for (; $current_file_pos < $total_file_count ; $current_file_pos++, $current_file_info->{file_pos}++) {
        if (!$current_file_info->{init}) {
            my $current_file = $self->{_files}[$current_file_pos];
            my $file_meta    = $self->{_file_meta}{$current_file};
            if ($file_meta->{length} == 0) {

                #The file has length, 0 ignore it for now
                $self->log->debug("$current_file has length 0, ignoring it");
                next;
            }
            eval {
                $self->_init($current_file);
                1;
              }
              or do {
                my $eval_err = $@;
                die "$current_file initializatoin failed: $eval_err";
              };
        }

        #check if we are end of file
        unless ($self->{_stream_reader}->has_more()) {
            $current_file_info->{init} = 0;
            $current_file_info->{row_group} = { row_count       => 0,
                                                next_row_idx    => 0,
                                                current_row_idx => -1,
            };
            $self->log->debug("Current file finished, Going to read from next file");
            next;
        }

        my $ret = $self->_read_next_row_group();
        return ($ret > 0) && $self->next();
    }
    return 0;
}

sub _init {
    my ($self, $file_name) = @_;
    my $stream_reader = Hadoop::IO::RCFile::Reader::FileStreamReader->new(
                            webhdfs_client => $self->{webhdfs_client},
                            file           => $file_name,
                        );
    $self->_stream_reader($stream_reader);

    #Only RCF file starts with 'RCF' are supported
    my @MAGIC = unpack("c3", "RCF");
    my (undef, $magic) = $stream_reader->read(3);
    if (!_array_equal(\@MAGIC, $magic)) {
        die "Not a valid RCF file or format not supported";
    }

    my $version = $stream_reader->read_byte();
    if ($version > CURRENT_VERSION) {
        die "RCF file version $version not supported";
    }

    my $decompress = $stream_reader->read_byte();
    if ($decompress) {
        my $codec_class = $self->_read_text();
        $self->{_current_file_info}{decompress}  = 1;
        $self->{_current_file_info}{codec_class} = $codec_class;
        die "RCF file with Compression not supported";
    } else {
        $self->{_current_file_info}{decompress} = 0;
    }
    $self->_read_meta_data();
    $self->{_current_file_info}{meta_data}{column_count} = $self->{_current_file_info}{meta_data}{'hive.io.rcfile.column.number'};

    my (undef, $sync) = $stream_reader->read(SYNC_HASH_SIZE);
    $self->{_current_file_info}{sync_bytes} = $sync;
    $self->{_current_file_info}{init}       = 1;
    $self->log->info("RC reader initialization done");
}

sub _has_record_in_buffer {
    my $self          = shift;
    my $rowgroup_info = $self->{_current_file_info}{row_group};
    return $rowgroup_info->{next_row_idx} < $rowgroup_info->{row_count};
}

sub _read_next_row_group {
    my $self = shift;

    delete $self->{_current_file_info}{row_group}{rows};
    $self->_read_key_buffer();
    $self->_read_value_buffer();

    delete $self->{_current_file_info}{row_group}{column_info};
    $self->log->info("Successfilly read a row group of " . $self->{_current_file_info}{row_group}{row_count} . " rows");
    return 1;
}

sub _read_value_buffer {
    my ($self) = @_;
    my $stream_reader = $self->{_stream_reader};

    my @rows;
    my $row_count    = $self->{_current_file_info}{row_group}{row_count};
    my $column_count = $self->{_current_file_info}{meta_data}{column_count} + 0;
    my $column_info  = $self->{_current_file_info}{row_group}{column_info};
    for (my $i = 0 ; $i < $row_count ; $i++) {
        push @rows, [];
    }
    for my $i (0 .. $column_count - 1) {
        my $per_row_len_arr = $column_info->[$i]{column_per_value_len};
        my $column_buff_len = $column_info->[$i]{column_buffer_len};
        my ($n, $bytes) = $stream_reader->read($column_buff_len);
        my $total_string = pack 'c*', @$bytes;
        my $off = 0;
        for my $j (0 .. $row_count - 1) {
            my $current_row = $rows[$j];
            my $len         = $per_row_len_arr->[$j];
            my $str         = substr $total_string, $off, $len;
            if ( $self->decode_utf8 ) {
                $str = Encode::decode_utf8($str);
            } else {
                Encode::_utf8_on($str);
            }
            $off += $len;
            if ($str ne '\\N') {
                push @$current_row, $str;
            } else {
                push @$current_row, undef;
            }

        }
    }
    $self->{_current_file_info}{row_group}{rows} = \@rows;
}

sub _read_key_buffer {
    my ($self) = @_;
    my $stream_reader = $self->{_stream_reader};

    my $current_record_length = $self->_read_record_length();
    return -1 if $current_record_length == -1;
    my $current_key_length    = $self->_read_int();
    my $compressed_key_length = $self->_read_int();
    if ($self->{_current_file_info}{decompress}) {

        #TODO for compression, key is compressed

    } else {

        #key is not compressed, read normally
        my ($row_count, $column_info) = $self->_read_key_fields();
        $self->{_current_file_info}{row_group}{column_info}     = $column_info;
        $self->{_current_file_info}{row_group}{row_count}       = $row_count;
        $self->{_current_file_info}{row_group}{next_row_idx}    = 0;
        $self->{_current_file_info}{row_group}{current_row_idx} = -1;
    }
}

sub _read_key_fields {
    my ($self) = @_;
    my $stream_reader = $self->{_stream_reader};

    my $number_of_column = $self->{_current_file_info}{meta_data}{column_count} + 0;
    my $number_of_rows   = $self->_read_v_int();                                       #number of rows in this record
    my $column_info      = [];
    for (my $i = 0 ; $i < $number_of_column ; $i++) {
        my $column_buffer_len              = $self->_read_v_int();
        my $column_buffer_uncompressed_len = $self->_read_v_int();
        my $key_buff_len                   = $self->_read_v_int();
        my (undef, $all_key_buffer) = $stream_reader->read($key_buff_len);
        my $column_per_value_length = [];
        $column_per_value_length->[ $number_of_rows - 1 ] = undef;
        my $pos       = 0;
        my $length    = 0;
        my $prev      = -1;
        my $row_count = 0;

        while ($pos < $key_buff_len) {
            {

              #This block will read a variable length integer number to calculate $length
              #For -112 <= i <= 127, only one byte is used with the actual value.
              #For other values of i, the first byte value indicates whether the
              #long is positive or negative, and the number of bytes that follow.
              #If the first byte value v is between -113 and -120, the following long
              #is positive, with number of bytes that follow are -(v+112).
              #If the first byte value v is between -121 and -128, the following long
              #is negative, with number of bytes that follow are -(v+120). Bytes are
              #stored in the high-non-zero-byte-first order.
              #Code from here
              #https://github.com/apache/hadoop/blob/branch-2.8.2/hadoop-common-project/hadoop-common/src/main/java/org/apache/hadoop/io/WritableUtils.java#L307
                my $first_byte = $all_key_buffer->[ $pos++ ];
                my $len = ($first_byte >= -112) ? 1 : (($first_byte < -120) ? (-119 - $first_byte) : (-111 - $first_byte));
                if ($len == 1) {
                    $length = $first_byte;
                } else {
                    my $n = 0;
                    for (my $i = 0 ; $i < $len - 1 ; $i++, $pos++) {
                        my $byte = $all_key_buffer->[$pos];
                        $n <<= 8;
                        $n |= ($byte & 255);
                    }

                    if (_is_negative_v_long($first_byte)) {
                        $n = ~$n;
                    }
                    $length = $n;
                }
            }

            if ($length < 0) {
                $length = ~$length;
                for (my $j = 0 ; $j < $length ; $j++) {
                    $column_per_value_length->[ $row_count++ ] = $prev;
                }
            } else {
                $column_per_value_length->[ $row_count++ ] = $length;
                $prev = $length;
            }
        }
        push @$column_info, { column_per_value_len           => $column_per_value_length,
                              column_buffer_len              => $column_buffer_len,                 # I think this is the total length of values for this column
                              column_buffer_uncompressed_len => $column_buffer_uncompressed_len,    # same as up but uncompressed
        };
    }
    return $number_of_rows, $column_info;
}

sub _read_record_length {
    my ($self) = @_;
    my $stream_reader = $self->{_stream_reader};

    my $length = $self->_read_int();
    if ($self->{_current_file_info}{sync_bytes} && $length == SYNC_ESCAPE) {

        # a sync entry
        $self->log->debug("New Sync entry");
        my ($n, $sync_check) = $stream_reader->read(SYNC_HASH_SIZE);
        if (!_array_equal($sync_check, $self->{_current_file_info}{sync_bytes})) {
            $self->log->error("Sync bytes does not match");
            die "File is corrupted";
        }
        $length = $self->_read_int();
    }
    return $length;
}

sub _read_meta_data {
    my ($self) = @_;
    my $stream_reader = $self->{_stream_reader};

    my $size = $self->_read_int();
    if ($size < 0) {
        die "Invalid size $size for file metadata";
    }
    my $meta_data = {};
    for (my $i = 0 ; $i < $size ; $i++) {
        my $key   = $self->_read_text();
        my $value = $self->_read_text();
        $meta_data->{$key} = $value;
    }
    $self->{_current_file_info}{meta_data} = $meta_data;
}

sub _read_text {
    my ($self) = @_;
    my $stream_reader = $self->{_stream_reader};

    my $size = $self->_read_v_int();
    my (undef, $bytes) = $stream_reader->read($size);
    my $str = pack 'c*', @$bytes;
    if ( $self->decode_utf8 ) {
        $str = Encode::decode_utf8($str);
    } else {
        Encode::_utf8_on($str);
    }
    return $str;
}

sub _read_v_long {

    #For -112 <= i <= 127, only one byte is used with the actual value.
    #For other values of i, the first byte value indicates whether the
    #long is positive or negative, and the number of bytes that follow.
    #If the first byte value v is between -113 and -120, the following long
    #is positive, with number of bytes that follow are -(v+112).
    #If the first byte value v is between -121 and -128, the following long
    #is negative, with number of bytes that follow are -(v+120). Bytes are
    #stored in the high-non-zero-byte-first order.
    #https://github.com/apache/hadoop/blob/branch-2.8.2/hadoop-common-project/hadoop-common/src/main/java/org/apache/hadoop/io/WritableUtils.java#L307
    my ($self) = @_;
    my $stream_reader = $self->{_stream_reader};

    my $first_byte = $stream_reader->read_byte();
    my $len        = _decode_v_long_size($first_byte);
    if ($len == 1) {
        return $first_byte;
    } else {
        my $n = 0;

        for (my $i = 0 ; $i < $len - 1 ; $i++) {
            my $byte = $stream_reader->read_byte();
            $n <<= 8;
            $n |= ($byte & 255);
        }

        if (_is_negative_v_long($first_byte)) {
            $n = ~$n;
        }
        return $n;
    }
}

sub _is_negative_v_long {

    #Given the first byte of a vint/vlong, determine the sign
    #https://github.com/apache/hadoop/blob/branch-2.8.2/hadoop-common-project/hadoop-common/src/main/java/org/apache/hadoop/io/WritableUtils.java#L369
    my ($value) = @_;
    return ($value < -120) || (($value >= -112) && ($value <= 0));
}

sub _decode_v_long_size {

    #Parse the first byte of a vint/vlong to determine the number of bytes
    #https://github.com/apache/hadoop/blob/branch-2.8.2/hadoop-common-project/hadoop-common/src/main/java/org/apache/hadoop/io/WritableUtils.java#L378
    my ($value) = @_;
    return ($value >= -112) ? 1 : (($value < -120) ? (-119 - $value) : (-111 - $value));
}

sub _read_v_int {
    my ($self) = @_;

    my $n = $self->_read_v_long();
    if ($n <= 2147483647 && $n >= -2147483648) {
        return $n;
    } else {
        die "value too long to fit in integer";
    }
}

sub _read_int {
    my ($self) = @_;
    my $stream_reader = $self->{_stream_reader};
    my (undef, $bytes) = $stream_reader->read(4);

    my $number = 0;
    for (my $i = 0 ; $i < 4 ; $i++) {
        $number <<= 8;
        $number |= ($bytes->[$i] & 255);
    }
    if ($number > 2147483647) {
        $number = $number - 4294967296;
    }
    return $number;
}

sub _array_equal {
    my ($arr_one, $arr_two) = @_;
    my $len_one = scalar @$arr_one;
    my $len_two = scalar @$arr_two;

    return 0 if ($len_one != $len_two);

    for (my $i = 0 ; $i < $len_one ; $i++) {
        return 0 if ($arr_one->[$i] != $arr_two->[$i]);
    }
    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Hadoop::IO::RCFile::Reader

=head1 VERSION

version 0.003

=head1 SYNOPSIS

   use Hadoop::IO::RCFile::Reader;

   my $table_reader = Hadoop::IO::RCFile::Reader->new(directory => '/user/hive/warehouse/sabbir.db/', webhdfs_client => $webhdfs_client);
   while($table_reader->next()) {
        my $current_row = $table_reader->current_row();
   }

=head1 DESCRIPTION

This module decodes a RCFILE based hive table and reads rows from the table. It reads directly from HDFS file,
so no partition information available, only the data of the file will be read. User need to take care
of partition informations.

The documentation about the file format can be found here: https://hive.apache.org/javadocs/r2.1.1/api/org/apache/hadoop/hive/ql/io/RCFile.html

=head1 NAME

Hadoop::IO::RCFile::Reader - Read the RCFILE based hive table from HDFS through the WebHDFS API

=head1 METHODS

=head2 new

The constructor. Accepts parameters in key => value format.

=head3 directory

Name of the directory/file;

=head3 webhdfs_client

A Net::Hadoop::WebHDFS client.

=head2 next

Move the current row pointer to next row, must be called before reading any row. First call will make the first row as current row.
Returns true if it can move the pointer to next row, false if no more rows available to read.

=head2 current_row

Returns the current row as a reference of list of columns from left to right.

=for Pod::Coverage BUILD CURRENT_VERSION SYNC_ESCAPE SYNC_HASH_SIZE

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
