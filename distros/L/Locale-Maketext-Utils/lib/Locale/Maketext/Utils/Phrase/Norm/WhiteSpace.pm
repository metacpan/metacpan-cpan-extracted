package Locale::Maketext::Utils::Phrase::Norm::WhiteSpace;

use strict;
use warnings;

use Encode ();

my $space_and_no_break_space = qr/(?:\x20|\xc2\xa0)/;

# regex is made from the Unicode code points from: `unichars '\p{WhiteSpace}'` (sans SPACE and NO-BREAK SPACE)
my $disallowed_whitespace = qr/(?:\x09|\x0a|\x0b|\x0c|\x0d|\xc2\x85|\xe1\x9a\x80|\xe1\xa0\x8e|\xe2\x80\x80|\xe2\x80\x81|\xe2\x80\x82|\xe2\x80\x83|\xe2\x80\x84|\xe2\x80\x85|\xe2\x80\x86|\xe2\x80\x87|\xe2\x80\x88|\xe2\x80\x89|\xe2\x80\x8a|\xe2\x80\xa8|\xe2\x80\xa9|\xe2\x80\xaf|\xe2\x81\x9f|\xe3\x80\x80)/;

# regex is made from the Unicode code points from: `uninames invisible`
my $invisible = qr/(?:\xe2\x80\x8b|\xe2\x81\xa2|\xe2\x81\xa3|\xe2\x81\xa4)/;

# regex is made from the Unicode code points from: `unichars '\p{Control}'`
my $control =
  qr/(?:\x00|\x01|\x02|\x03|\x04|\x05|\x06|\x07|\x08|\x09|\x0a|\x0b|\x0c|\x0d|\x0e|\x0f|\x10|\x11|\x12|\x13|\x14|\x15|\x16|\x17|\x18|\x19|\x1a|\x1b|\x1c|\x1d|\x1e|\x1f|\x7f|\xc2\x80|\xc2\x81|\xc2\x82|\xc2\x83|\xc2\x84|\xc2\x85|\xc2\x86|\xc2\x87|\xc2\x88|\xc2\x89|\xc2\x8a|\xc2\x8b|\xc2\x8c|\xc2\x8d|\xc2\x8e|\xc2\x8f|\xc2\x90|\xc2\x91|\xc2\x92|\xc2\x93|\xc2\x94|\xc2\x95|\xc2\x96|\xc2\x97|\xc2\x98|\xc2\x99|\xc2\x9a|\xc2\x9b|\xc2\x9c|\xc2\x9d|\xc2\x9e|\xc2\x9f)/;

sub normalize_maketext_string {
    my ($filter) = @_;

    my $string_sr = $filter->get_string_sr();

    # detect any whitespace-ish characters that are not ' ' or "\xC2\xA0" (non-break-space)
    if ( ${$string_sr} =~ s/($disallowed_whitespace|$invisible|$control)/my $uh=sprintf('%04X', unpack('U',Encode::decode_utf8($1)));"[comment,invalid char Ux$uh]"/exmsg ) {
        $filter->add_violation('Invalid whitespace, control, or invisible characters');
    }

    # The only WS possible after that is $space_and_no_break_space

    # remove beginning and trailing white space
    if ( ${$string_sr} !~ m/\A \xE2\x80\xA6/ms && ${$string_sr} =~ s/\A($space_and_no_break_space+)//xms ) {
        my $startswith = $1;
        if ( substr( ${$string_sr}, 0, 3 ) eq "\xE2\x80\xA6" ) {
            if ( $startswith =~ m/\xc2\xa0/ ) {
                $filter->add_violation('Beginning ellipsis space should be a normal space');
            }
            ${$string_sr} = " ${$string_sr}";
        }

        $filter->add_violation('Beginning white space');

    }

    if ( ${$string_sr} =~ s/(?:$space_and_no_break_space)+\z//xms ) {
        $filter->add_violation('Trailing white space');
    }

    # collapse internal white space into a single space
    if ( ${$string_sr} =~ s/$space_and_no_break_space{2,}/ /xms ) {
        $filter->add_violation('Multiple internal white space');
    }

    return $filter->return_value;
}

1;

__END__

=encoding utf-8

=head1 Normalization

The only single white space characters allowed are normal space and non-break-space.

=head2 Rationale

=over 4

=item * A tiny change in white-space[-ish] characters will make a phrase lookup fail erroneously.

=item * The only other purpose of allowing characters like this would be formatting which should not be part of a phrase.

=over 4

=item * Such formatting is not applicable to all contexts (e.g. HTML)

=item * Since it is not a translatable entity translators are likley to miss it and break your format.

=item * Same text with different formatting becomes a new, redundant, phrase.

=back

Doing internal formatting via bracket notation’s output() methods address the first 2 completely and the third one most of the time (it can be “completely” if you give it a little thought first).

=item * It is easy for a developer to miss the subtle difference and get it wrong.

=item * Surrounding whitespace is likely a sign that partial phrases are in use.

=back

That being the case we simplify consistently by using single space and non-break-space characters inside the string
(and the beginning if it starts with an L<ellipsis|Locale::Maketext::Utils::Phrase::Norm::Ellipsis>).

=head2 possible violations

=over 4

=item Invalid whitespace-like characters

The string contains white space characters besides space and non-break-space, invisible characters, or control characters.

These will be turned into “[comment,invalid char UxNNNN]” (where NNNN is the Unicode code point) so you can find them visually.

=item Beginning white space

These are removed.

This accounts for strings beginning with an ellipsis which should be preceded by one space.

=item Beginning ellipsis space should be a normal space

If a string starts with an ellipsis it should be a normal space. A non-break-space implies formatting or concatenation of 2 partial phrases, ick!

=item Trailing white space

These are removed.

=item Multiple internal white space

These are collapsed into a single space.

=back

=head2 possible warnings

None
