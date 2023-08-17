package Hadoop::IO::SequenceFile;
$Hadoop::IO::SequenceFile::VERSION = '0.003';
use 5.010;
use strict;
use warnings;

use Digest::MD5 qw/md5/;


sub new {
    my ($class, %args) = @_;

    my $writer = delete $args{writer}
        or die "$class: missing required argument 'writer'";
    my $key_class = delete $args{key_class}
        // "Hadoop::IO::SequenceFile::BytesWriteable";
    my $val_class = delete $args{val_class}
        // "Hadoop::IO::SequenceFile::Text";

    my $writer_cb;
    if (ref $writer eq "CODE") {
        $writer_cb = $writer;
    } elsif (eval { $writer->can("write") }) {
        $writer_cb = sub { $writer->write(@_) };
    } else {
        die "$class: bad 'writer' value: should be either coderef or instance of a writer.";
    }


    die "$class: bad options " . join(", ", map "'$_'", keys %args) if %args;

    return bless {
        writer_cb => $writer_cb,
        key_class => $key_class,
        val_class => $val_class,
        sync => md5(time),
    }, $class;
}

sub _write {
    my ($self, $value, $flush) = @_;
    $self->{writer_cb}->($value, $flush);
}

sub _write_int {
    my ($self, $value) = @_;
    $self->_write(pack "L>", $value);
}

sub _write_boolean {
    my ($self, $value) = @_;
    $self->_write($value ? "\x01" : "\x00");
}

sub _write_string {
    my ($self, $value) = @_;
    $self->_write(Hadoop::IO::SequenceFile::Text->encode($value));
}


sub write_header {
    my ($self) = @_;

    my $key_class = $self->{key_class}->class_name;
    my $val_class = $self->{val_class}->class_name;

    my $rec_compression = 0; # "org.apache.hadoop.io.compress.GzipCodec";
    my $blk_compression = 0;

    $self->_write("SEQ\x06");
    $self->_write_string($key_class);
    $self->_write_string($val_class);
    $self->_write_boolean($rec_compression);
    $self->_write_boolean($blk_compression);
    if ($rec_compression) {
        $self->_write_string($rec_compression);
    }
    $self->_write_metadata();
    $self->_write($self->{sync});
}

sub _write_metadata {
    my ($self) = @_;

    my $nkeys = 0;

    $self->_write_int($nkeys);
}

sub _write_sync {
    my ($self) = @_;
    $self->_write_int(-1);
    $self->_write($self->{sync});
}


sub write_record {
    my ($self, $key, $val) = @_;

    my $buf = $self->{key_class}->encode($key);
    my $key_len = length $buf;
    $buf .= $self->{val_class}->encode($val);

    $self->_write(pack "L>", length $buf);
    $self->_write(pack "L>", $key_len);
    $self->_write($buf);

    $self->_write_sync();
}


sub write_row {
    my ($self, @fields) = @_;
    my $val = join "\x01", @fields;
    $self->write_record("", $val);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Hadoop::IO::SequenceFile

=head1 VERSION

version 0.003

=head1 DESCRIPTION

This class handles serialization of records in Hadoop SequenceFile format.

=head1 NAME

Hadoop::IO::SequenceFile - Hadoop / Hive compatible SequenceFile serializer.

=head1 METHODS

=head2 $class->new(%args) -> $inst

Create and return new instance of SequenceFile serializer.

Supported arguments are:

=head3 writer

Either instance of L<Hadoop::IO::SequenceFile::HDFSWriter> or a coderef.
Coderef will be called with a single argument: data to be written to the file.
It will be called multiple times.

=head3 key_class

Name of the perl package responsible for encoding keys in this file. Default is
L<Hadoop::IO::SequenceFile::BytesWriteable>, which is equivalent to what
Hive uses by default.

=head3 val_class

Name of the perl package responsible for encoding values in this file. Default is
L<Hadoop::IO::SequenceFile::Text>, which is equivalent to what
Hive uses by default.

=head2 $self->write_header()

This should be called soon after creating new file and before first
L<write_record> or L<write_row>. Do not call this if you just want to append to
a pre-existing file.

=head2 $self->write_record($key, $val)

Writes next new record to the file. $key and $val will be encoded using C<key_class> and C<val_class> passed to the constructor.

=head2 $self->write_row(@values)

Writes a sequence of fields in a format compatible with LazySimpleSerDe which Hive uses by default.

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
