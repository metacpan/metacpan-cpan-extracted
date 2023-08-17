package Hadoop::IO::SequenceFile::Text;
$Hadoop::IO::SequenceFile::Text::VERSION = '0.003';
use 5.010;
use strict;
use warnings;

use constant {
    CLASS_NAME => "org.apache.hadoop.io.Text",
};

sub class_name { CLASS_NAME }

sub encode {
    my ($self, $data) = @_;
    my $len = _pack_varint(length $data);
    return $len . $data;
}

sub _pack_varint {
    my $value = shift;

    if ($value >= -112 && $value <= 127) {
        return pack "c", $value;
    }

    my $sign;

    if ($value < 0) {
        $sign = -1;
        $value = -$value;
    } else {
        $sign = 1;
    }

    my $pack = pack("Q>", $value) =~ s/^\x00+//r;
    my $mark = pack("c", ($sign > 0 ? -112 : -120) - length $pack);

    return $mark . $pack;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Hadoop::IO::SequenceFile::Text

=head1 VERSION

version 0.003

=head1 NAME

Hadoop::IO::SequenceFile::Text - Hadoop compatible Text serializer.

=head1 METHODS

=over 8

=item $class->class_name() -> $string

Get java class name for Text.

=item $class->encode($data) -> $encoded

Encode a perl string, containing (possibly) binary data into the format compatible with how Text is serialized by Hadoop.

=back

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
