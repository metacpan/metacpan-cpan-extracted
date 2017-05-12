package Encode::First;

use strict;
our $VERSION = '0.01';

use Carp ();
use Encode ();

require Exporter;
*import = \&Exporter::import;
our @EXPORT = qw( encode_first );

sub encode_first {
    my($encodings, $str) = @_;

    $encodings = _encodings($encodings);

    for my $enc (@$encodings) {
        my $copy  = $str; # Encode::encode might break the original string
        my $bytes;
        eval {
            $bytes = Encode::encode($enc, $str, Encode::FB_CROAK);
        };
        unless ($@) {
            return wantarray ? ($enc, $bytes) : $enc;
        }
    }

    Carp::croak("No encoding can encode the given string.");
}

sub _encodings {
    my $encodings = shift;
    return if ref $encodings && ref $encodings eq 'ARRAY';

    Carp::croak "Unknown reference type ", ref $encodings
        if ref $encodings && ref $encodings ne 'ARRAY';

    return [ split /[:,]/, $encodings ];
}

1;
__END__

=for stopwords Juerd Waalboer encodable iso-2022-jp utf-8

=head1 NAME

Encode::First - Encode strings in a first possible encoding

=head1 SYNOPSIS

  use Encode::First;

  my($enc, $bytes) = encode_first("ascii,latin-1,iso-2022-jp,utf-8", $string);

=head1 DESCRIPTION

Encode::First provides a function to encode strings in the first
possible encoding out of multiple encodings supplied as a list.

It'd be useful to figure out what's the minimal encoding to encode the
email content, for instance, to be friendly with utf-8 incapable email
clients.

=head1 FUNCTIONS

=over 4

=item encode_first

  ($enc, $bytes) = encode_first($encodings, $string);

returns I<$enc> (encoding used) and I<$bytes>, the encoded
characters. I<$enc> is the first encoding that I<$string> is encodable
into. I<$encodings> can be either comma or colon separated scalar, or
an array reference.

If none of I<$encodings> can encode the I<$string> safely, the
function would throw an exception. To avoid that, you should always
add I<utf-8> in I<$encodings>.

  $enc = encode_first($encodings, $string);

In a scalar context it just returns the name of encoding.

This function is exported by default.

=back

=head1 BUGS

As of this writing, if you include I<iso-2022-jp> in the list of
encodings, this module will return I<iso-2022-jp> as the best encoding
for most of the Unicode strings, because of Encode::JP::JIS7 bug. The
bug is reported and awaits for the patch to be applied.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

Juerd Waalboer

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Encode::InCharset>, L<http://use.perl.org/~miyagawa/journal/32781>

=cut
