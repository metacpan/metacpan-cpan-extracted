=head1 NAME

Encode::JP::Emoji::Property - Emoji named character properties

=head1 SYNOPSIS

    use utf8;
    use Encode::JP::Emoji::Property;

    /\p{InEmojiDoCoMo}/;
    /\p{InEmojiKDDIapp}/;
    /\p{InEmojiKDDIweb}/;
    /\p{InEmojiSoftBank}/;
    /\p{InEmojiUnicode}/;
    /\p{InEmojiGoogle}/;
    /\p{InEmojiMixed}/;
    /\p{InEmojiAny}/;

=head1 DESCRIPTION

This exports the following named character properties:

=head2 \p{InEmojiDoCoMo}

This matches DoCoMo's private emoji code points: C<U+E63E> ... C<U+E757>.

=head2 \p{InEmojiKDDIapp}

This matches KDDI's private emoji code points: C<U+E468> ... C<U+EB8E>.

=head2 \p{InEmojiKDDIweb}

This matches B<undocumented version> of KDDI's private emoji code points: C<U+EC40> ... C<U+F0FC>.

=head2 \p{InEmojiSoftBank}

This matches SoftBank's private emoji code points: C<U+E001> ... C<U+E53E>.

=head2 \p{InEmojiMixed}

This matches emoji code points of all three carriers above.

=head2 \p{InEmojiGoogle}

This matches Google's private emoji code points: C<U+FE000> ... C<U+FEEA0>.

=head2 \p{InEmojiUnicode}

This matches emoji code points which will be defined in the Unicode Standard.

=head2 \p{InEmojiAny}

This matches any emoji code points above.

=head1 AUTHOR

Yusuke Kawasaki, L<http://www.kawa.net/>

=head1 SEE ALSO

L<Encode::JP::Emoji> and L<perlunicode>

=head1 COPYRIGHT

Copyright 2009-2010 Yusuke Kawasaki, all rights reserved.

=cut

package Encode::JP::Emoji::Property;
use strict;
use warnings;
use Encode::JP::Emoji::Mapping;
use base 'Exporter';

our $VERSION = '0.60';

our @EXPORT = qw(
    InEmojiDoCoMo
    InEmojiKDDIapp
    InEmojiKDDIweb
    InEmojiSoftBank
    InEmojiUnicode
    InEmojiGoogle
    InEmojiMixed
    InEmojiAny
);

*InEmojiDoCoMo   = \&Encode::JP::Emoji::Mapping::InEmojiDocomoUnicode;
*InEmojiKDDIapp  = \&Encode::JP::Emoji::Mapping::InEmojiKddiUnicode; # CAUTION!
*InEmojiKDDIweb  = \&Encode::JP::Emoji::Mapping::InEmojiKddiwebUnicode;
*InEmojiSoftBank = \&Encode::JP::Emoji::Mapping::InEmojiSoftbankUnicode;
*InEmojiUnicode  = \&Encode::JP::Emoji::Mapping::InEmojiUnicodeUnicode;
*InEmojiGoogle   = \&Encode::JP::Emoji::Mapping::InEmojiGoogleUnicode;
*InEmojiMixed    = \&Encode::JP::Emoji::Mapping::InEmojiMixedUnicode;

sub InEmojiAny { return <<"EOT"; }
+Encode::JP::Emoji::Property::InEmojiDoCoMo
+Encode::JP::Emoji::Property::InEmojiKDDIapp
+Encode::JP::Emoji::Property::InEmojiKDDIweb
+Encode::JP::Emoji::Property::InEmojiSoftBank
+Encode::JP::Emoji::Property::InEmojiUnicode
+Encode::JP::Emoji::Property::InEmojiGoogle
EOT

1;
