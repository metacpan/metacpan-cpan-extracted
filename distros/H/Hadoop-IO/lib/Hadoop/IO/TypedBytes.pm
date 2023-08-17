package Hadoop::IO::TypedBytes;
$Hadoop::IO::TypedBytes::VERSION = '0.003';
use 5.010;
use strict;
use warnings;
use parent qw( Exporter );

our @VERSION = 0.01;

our @EXPORT_OK = qw(
    decode
    decode_hive
    encode
    encode_hive
    make_reader
);


sub _primitive {
    my ($name, $code, $size, $format) = @_;

    return {
        name => $name,
        code => $code,
        enc => sub { pack $format, shift },
        dec => sub {
            my $read = shift;
            return unpack $format, $read->($size) // die "EOF while decoding $name";
        },
    }
}

sub _prefixed {
    my ($name, $code) = @_;

    return {
        name => $name,
        code => $code,
        enc => sub { my $d = shift; pack("L>", length $d) . $d },
        dec => sub {
            my $read = shift;
            my $len = unpack "L>", $read->(4) // die "EOF while decoding $name";
            return $read->($len);
        }
    }
}

sub _array {
    my ($name, $code) = @_;

    return {
        name => $name,
        code => $code,
        enc => sub {
            my $vec = shift;
            my $buf = pack("L>", scalar @$vec);
            $buf .= encode($_) foreach (@$vec);
            return $buf;
        },

        dec => sub {
            my $read = shift;
            my $len = unpack "L>", $read->(4) // die "EOF while decoding $name";
            my @vec;
            while ($len-- > 0) {
                push @vec, _decode($read, $name);
            }
            return \@vec;
        },
    }
}

sub _struct {
    my ($name, $code) = @_;

    return {
        name => $name,
        code => $code,
        enc => sub {
            my $map = shift;
            my $buf = pack("L>", scalar keys %$map);
            $buf .= encode([ $_, $map->{$_} ]) foreach keys %$map;
            return $buf;
        },

        dec => sub {
            my $read = shift;
            my $len = unpack "L>", $read->(4) // die "EOF while decoding $name";
            my %map;
            while ($len-- > 0) {
                my ($k, $v) = @{_decode($read, $name)};
                $map{$k} = $v;
            }
            return \%map;
        },
    }
}

sub _list {
    my ($name, $code) = @_;
    return {
        name => $name,
        code => $code,
        enc => sub {
            my $lst = shift;
            my $buf = "";
            $buf .= encode($_) foreach @$lst;
            return $buf . "\xff";
        },
        dec => sub {
            my $read = shift;
            my (@lst, @val);
            push @lst, @val while @val = _decode($read, $name);
            return \@lst;
        }
    }
}

sub _empty {
    my ($name, $code) = @_;
    return {
        name => $name,
        code => $code,
        enc => sub { "" },
        dec => sub { () },
    };
}

my @TYPES = (
    _prefixed(bytes => 0),
    _primitive(byte => 1, 1, "c"),
    _primitive(bool => 2, 1, "c"),
    _primitive(int => 3,  4, "l>"),
    _primitive(long => 4, 8, "q>"),
    _primitive(float => 5, 4, "f>"),
    _primitive(double => 6, 8, "d>"),
    _prefixed(string => 7),
    _array(array => 8),
    _list(list => 9),
    _struct(struct => 10),
    _empty(end_of_record => 177), # hive specific
    _empty(empty => 255),
);

my %type_by_name = map { $_->{name}, $_ } @TYPES;
my %type_by_code = map { $_->{code}, $_ } @TYPES;


sub encode {
    my ($val) = @_;
    if (ref $val eq "ARRAY") {
        return _encode_as($val, "array");
    }
    elsif (ref $val eq "HASH") {
        return _encode_as($val, "struct");
    }
    elsif (ref $val) {
        die "unsupported value reference $val";
    }
    else {
        return _encode_as($val, "string");
    }
}

sub _encode_as {
    my ($val, $type) = @_;

    my $codec = $type_by_name{$type}
        or die "unsupported type name '$type'";

    my $code = pack "c", $codec->{code};
    return $code . $codec->{enc}->($val);
}


sub decode {
    my $read = shift;
    return _decode($read);
}

sub _decode {
    my ($read, $inner) = @_;

    my $mark = $read->(1);
    unless (defined $mark) {
        if ($inner) {
            die "EOF while decoding $inner";
        } else {
            return ();
        }
    }

    my $code = unpack "C", $mark;
    my $codec = $type_by_code{$code}
        or die "unsupported type code '$code'";

    return $codec->{dec}->($read);
}


sub encode_hive {
    my $buf;
    $buf .= encode($_) foreach (@_);
    $buf .= _encode_as(undef, "end_of_record");
    return $buf;
}


sub decode_hive {
    my $read = shift;
    my $codec = $type_by_name{list}
        or die "missing 'list' type codec";

    my $inner;
    my (@lst, @val);

    # If decode returns empty list at first read, this means either EOF at row
    # boundary or empty row (row starting with row terminator). The latter is
    # impossible because Hive requires at least one input expr in the transform
    # clause, so it must be EOF.

    my $first = 1;
    push @lst, @val while @val = _decode($read, $first ? $first = undef : "hive record");

    return @lst ? \@lst : undef;
}


sub make_reader {
    my $fh = shift;

    sub {
        my $len = shift;
        return "" if $len <= 0;

        my $num = $fh->read(my $buf, $len) // die $!;

        return undef if $num == 0;

        die "EOF in the middle of value (want $len bytes, got $num)" if $num < $len;

        return $buf;
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Hadoop::IO::TypedBytes

=head1 VERSION

version 0.003

=head1 SYNOPSIS

=head2 query.hql

    add jar /usr/lib/hive/lib/hive-contrib.jar;
    set hive.script.recordwriter=org.apache.hadoop.hive.contrib.util.typedbytes.TypedBytesRecordWriter;
    set hivevar:serde=org.apache.hadoop.hive.contrib.serde2.TypedBytesSerDe;

    select transform (foo, bar, baz) row format serde '${serde}' using 'script.pl' as ...

=head2 script.pl

    use Hadoop::IO::TypedBytes qw/make_reader decode_hive/;

    my $reader = make_reader(\*STDIN);
    while (defined (my $row = decode_hive($reader))) {
        my ($foo, $bar, $baz) = @$row;
        ...
    }

NB: these examples only use TypedBytes to pass data from Hive to the transform
script. To use TypedBytes for output as well, please refer to Hive
documentation.

=head1 DESCRIPTION

This package is useful if you want to pass multiline strings or binary data to
a transform script in a Hive query.

Encoding routines L</encode> and L</encode_hive> take Perl values and return
strings with their TypedBytes representations.

Decoding routines L</decode> and L</decode_hive> take a reader callback (see
L</READING>) instead of binary strings, because TypedBytes streams as
implemented by Hadoop and Hive are unframed, in other words it is impossible to
say in advance how long the object will be and read it in one go before passing
it to the decoder. For this reason decoder consumes the binary stream directly.

=head1 NAME

Hadoop::IO::TypedBytes - Hadoop/Hive compatible TypedBytes
serializer/deserializer.

=head1 FUNCTIONS

Nothing is exported by default.

=over

=item encode

    encode($val) -> $binary_string

Encode a scalar, array or hash reference as TypedBytes binary representation.

If you are interfacing with Hive, use L</encode_hive> instead.

Containers are encoded recursively. Blessed references are not supported and
will cause function to die.

Scalars are always encoded as TypedBytes strings, array references are encoded
as TypedBytes arrays and hash references are encoded as TypedBytes structs.
Note that as of time of writing Hive TypedBytes decoder does not support arrays
and structs. Hive documentation suggests to use JSON in that case.

=item decode

    decode($reader) -> $obj

Decode a binary TypedBytes stream into corresponding perl object.

See L</READING> for description of the C<$reader> parameter.

If you interfacing with Hive, use L</decode_hive> instead.

TypedBytes lists and arrays are decoded as array references.

TypedBytes structs are decoded as hash references.

TypedBytes standard empty marker and special marker are docoded as empty lists,
but you shouldn't encounter these under normla circumstances.

=item encode_hive

    encode_hive(@row) -> $binary_string

Encode a row of values in a format expected by Hive: concatenation of values
encoded terminated by a Hive specific "end-of-row" marker.

See notes for L</encode> for description of encoding process.

=item decode_hive

    decode_hive($reader) -> $row

Decode a binary TypedBytes stream into an array repsresenting a single row
received from Hive.

See L</READING> for description of the C<$reader> parameter.

See notes for L</decode> for a general description of decoding process.

=item make_reader

    make_reader($fh) -> $callback

Construct reader callback from a filehandle.

=back

=head1 READING

Both Hadoop and Hive streams that use TypedBytes provide no way to know size of
the following record without decoding the object. For this reason L</decode> and
L</decode_hive> take a callback instead of a string. Reader callback is passed a
single parameter, number of bytes to read and should return a string of exactly
that length or undef to indicate end-of-file. It should die and NOT return
C<undef> if number of bytes in the stream was less than requested.

Use L</make_reader> to make a compatible reader callback from a file-handle.

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
