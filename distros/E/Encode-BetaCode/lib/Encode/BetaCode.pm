package Encode::BetaCode;

use 5.006;
use strict;
use warnings;

require Exporter;

use base qw(Exporter);
use Unicode::Normalize;

our %EXPORT_TAGS = (
    'all' => [
        qw(
          beta_decode
          beta_encode
          )
    ],
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

=head1 NAME

Encode::BetaCode - Perl module for converting to and from Beta Code

=head1 VERSION

Version 0.09

=encoding utf8

=cut

our $VERSION = '0.09';

=head1 SYNOPSIS

    use Encode::BetaCode qw(beta_decode beta_encode);

    my $unicode_text = beta_decode($language, $text);
    
    my $betacode_text = beta_encode($language, $style, $text);

=head1 DESCRIPTION

B<Encode::BetaCode> provides functions that convert Beta Code strings
to Unicode and reverse. No functions are exported by default.

"use Encode::BetaCode qw(:all)" exports all of them.

=head1 FUNCTIONS

=over

=item B<beta_decode> LANGUAGE, STRING

Converts strings from Beta Code to Unicode.

=over

=item Supported languages (so far):

-> C<'greek'>

-> C<'greek_punct'> (with punctuation conversions)

=back

=back

=cut

sub beta_decode
{
    my ( $language, $input ) = @_;

    if ( $language eq 'greek' || $language eq 'greek_punct' )
    {

        #Uppercase accents and diacritics.#
        $input =~ s/[*]a&/Ᾱ/gi;
        $input =~ s/[*]a'/Ᾰ/gi;
        $input =~ s/[*][)]\/a[|]/ᾌ/gi;
        $input =~ s/[*][(]\/a[|]/ᾍ/gi;
        $input =~ s/[*][)]=a[|]/ᾎ/gi;
        $input =~ s/[*][(]=a[|]/ᾏ/gi;
        $input =~ s/[*][(]\\a/Ἃ/gi;
        $input =~ s/[*][)]\/a/Ἄ/gi;
        $input =~ s/[*][(]\/a/Ἅ/gi;
        $input =~ s/[*][)]=a/Ἆ/gi;
        $input =~ s/[*][(]=a/Ἇ/gi;
        $input =~ s/[*][)]a[|]/ᾈ/gi;
        $input =~ s/[*][(]a[|]/ᾉ/gi;
        $input =~ s/[*][)]a/Ἁ/gi;
        $input =~ s/[*][(]a/Ἁ/gi;
        $input =~ s/[*]\\a/Ὰ/gi;
        $input =~ s/[*]\/a/Ά/gi;
        $input =~ s/[*]a[|]/ᾼ/gi;
        $input =~ s/[*][)]\\a/Ἂ/g;
        $input =~ s/[*][)]\\e/Ἒ/gi;
        $input =~ s/[*][(]\\e/Ἓ/gi;
        $input =~ s/[*][)]\/e/Ἔ/gi;
        $input =~ s/[*][(]\/e/Ἕ/gi;
        $input =~ s/[*][)]e/Ἐ/gi;
        $input =~ s/[*][(]e/Ἑ/gi;
        $input =~ s/[*]\\e/Ὲ/gi;
        $input =~ s/[*]\/e/Έ/gi;
        $input =~ s/[*][)]\/h[|]/ᾜ/gi;
        $input =~ s/[*][(]\/h[|]/ᾝ/gi;
        $input =~ s/[*][)]=h[|]/ᾞ/gi;
        $input =~ s/[*][(]=h[|]/ᾟ/gi;
        $input =~ s/[*][)]\\h/Ἢ/gi;
        $input =~ s/[*][(]\\h/Ἣ/gi;
        $input =~ s/[*][)]\/h/Ἤ/gi;
        $input =~ s/[*][(]\/h/Ἥ/gi;
        $input =~ s/[*][)]=h/Ἦ/gi;
        $input =~ s/[*][(]=h/Ἧ/gi;
        $input =~ s/[*][)]h[|]/ᾘ/gi;
        $input =~ s/[*][(]h[|]/ᾙ/gi;
        $input =~ s/[*][)]h/Ἠ/gi;
        $input =~ s/[*][(]h/Ἡ/gi;
        $input =~ s/[*]\\h/Ὴ/gi;
        $input =~ s/[*]\/h/Ή/gi;
        $input =~ s/[*]h[|]/ῌ/gi;
        $input =~ s/[*]i&/Ῑ/gi;
        $input =~ s/[*]i'/Ῐ/gi;
        $input =~ s/[*][+]i/Ϊ/gi;
        $input =~ s/[*][)]\\i/Ἲ/gi;
        $input =~ s/[*][(]\\i/Ἳ/gi;
        $input =~ s/[*][)]\/i/Ἴ/gi;
        $input =~ s/[*][(]\/i/Ἵ/gi;
        $input =~ s/[*][)]=i/Ἶ/gi;
        $input =~ s/[*][(]=i/Ἷ/gi;
        $input =~ s/[*][)]i/Ἰ/gi;
        $input =~ s/[*][(]i/Ἱ/gi;
        $input =~ s/[*]\\i/Ὶ/gi;
        $input =~ s/[*]\/i/Ί/gi;
        $input =~ s/[*][)]\\o/Ὂ/gi;
        $input =~ s/[*][(]\\o/Ὃ/gi;
        $input =~ s/[*][)]\/o/Ὄ/gi;
        $input =~ s/[*][(]\/o/Ὅ/gi;
        $input =~ s/[*][)]=o/Ὄ/gi;
        $input =~ s/[*][(]=o/Ὅ/gi;
        $input =~ s/[*][)]o/Ὀ/gi;
        $input =~ s/[*][(]o/Ὁ/gi;
        $input =~ s/[*]\\o/Ὸ/gi;
        $input =~ s/[*]\/o/Ό/gi;
        $input =~ s/[*][)]r/Ρ/gi;
        $input =~ s/[*][(]r/Ῥ/gi;
        $input =~ s/[*]u&/Ῡ/gi;
        $input =~ s/[*]u'/Ῠ/gi;
        $input =~ s/[*][+]u/Ϋ/gi;
        $input =~ s/[*][(]\\u/Ὓ/gi;
        $input =~ s/[*][(]\/u/Ὕ/gi;
        $input =~ s/[*][(]=u/Ὗ/gi;
        $input =~ s/[*][(]u/Ὑ/gi;
        $input =~ s/[*]\\u/Ὺ/gi;
        $input =~ s/[*]\/u/Ύ/gi;
        $input =~ s/[*][)]\/w[|]/ᾬ/gi;
        $input =~ s/[*][(]\/w[|]/ᾭ/gi;
        $input =~ s/[*][)]=w[|]/ᾮ/gi;
        $input =~ s/[*][(]=w[|]/ᾯ/gi;
        $input =~ s/[*][)]\\w/Ὢ/gi;
        $input =~ s/[*][(]\\w/Ὣ/gi;
        $input =~ s/[*][)]\/w/Ὤ/gi;
        $input =~ s/[*][(]\/w/Ὥ/gi;
        $input =~ s/[*][)]=w/Ὦ/gi;
        $input =~ s/[*][(]=w/Ὧ/gi;
        $input =~ s/[*][)]w[|]/ᾨ/gi;
        $input =~ s/[*][(]w[|]/ᾩ/gi;
        $input =~ s/[*][)]w/Ὠ/gi;
        $input =~ s/[*][(]w/Ὡ/gi;
        $input =~ s/[*]\\w/Ὼ/gi;
        $input =~ s/[*]\/w/Ώ/gi;
        $input =~ s/[*]w[|]/ῼ/gi;

        #Lowercase accents and diacritics.#
        $input =~ s/a&/ᾱ/gi;
        $input =~ s/a'/ᾰ/gi;
        $input =~ s/a[)]\/[|]/ᾄ/gi;
        $input =~ s/a[(]\/[|]/ᾅ/gi;
        $input =~ s/a[)]=[|]/ᾆ/gi;
        $input =~ s/a[(]=[|]/ᾇ/gi;
        $input =~ s/a[)][|]/ᾀ/gi;
        $input =~ s/a[(][|]/ᾁ/gi;
        $input =~ s/a\/[|]/ᾴ/gi;
        $input =~ s/a=[|]/ᾷ/gi;
        $input =~ s/a[)]\\/ἂ/gi;
        $input =~ s/a[(]\\/ἃ/gi;
        $input =~ s/a[)]\//ἄ/gi;
        $input =~ s/a[(]\//ἅ/gi;
        $input =~ s/a[)]=/ἆ/gi;
        $input =~ s/a[(]=/ἇ/gi;
        $input =~ s/a[)]/ἀ/gi;
        $input =~ s/a[(]/ἁ/gi;
        $input =~ s/a\\/ὰ/gi;
        $input =~ s/a\//ά/gi;
        $input =~ s/a=/ᾶ/gi;
        $input =~ s/a[|]/ᾳ/gi;
        $input =~ s/e[)]\\/ἒ/gi;
        $input =~ s/e[(]\\/ἓ/gi;
        $input =~ s/e[)]\//ἔ/gi;
        $input =~ s/e[(]\//ἕ/gi;
        $input =~ s/e[)]/ἐ/gi;
        $input =~ s/e[(]/ἑ/gi;
        $input =~ s/e\\/ὲ/gi;
        $input =~ s/e\//έ/gi;
        $input =~ s/h[)]\/[|]/ᾔ/gi;
        $input =~ s/h[(]\/[|]/ᾕ/gi;
        $input =~ s/h[)]=[|]/ᾖ/gi;
        $input =~ s/h[(]=[|]/ᾗ/gi;
        $input =~ s/h[)][|]/ᾐ/gi;
        $input =~ s/h[(][|]/ᾑ/gi;
        $input =~ s/h\/[|]/ῄ/gi;
        $input =~ s/h=[|]/ῇ/gi;
        $input =~ s/h[)]\\/ἢ/gi;
        $input =~ s/h[(]\\/ἣ/gi;
        $input =~ s/h[)]\//ἤ/gi;
        $input =~ s/h[(]\//ἥ/gi;
        $input =~ s/h[)]=/ἦ/gi;
        $input =~ s/h[(]=/ἧ/gi;
        $input =~ s/h[)]/ἠ/gi;
        $input =~ s/h[(]/ἡ/gi;
        $input =~ s/h\\/ὴ/gi;
        $input =~ s/h\//ή/gi;
        $input =~ s/h=/ῆ/gi;
        $input =~ s/h[|]/ῃ/gi;
        $input =~ s/i&/ῑ/gi;
        $input =~ s/i'/ῐ/gi;
        $input =~ s/i[+]\\/ῒ/gi;
        $input =~ s/i\\[+]/ῒ/gi;
        $input =~ s/i[+]\//ΐ/gi;
        $input =~ s/i\/[+]/ΐ/gi;
        $input =~ s/i[+]=/ῗ/gi;
        $input =~ s/i=[+]/ῗ/gi;
        $input =~ s/i[+]/ϊ/gi;
        $input =~ s/i[)]\\/ἲ/gi;
        $input =~ s/i[(]\\/ἳ/gi;
        $input =~ s/i[)]\//ἴ/gi;
        $input =~ s/i[(]\//ἵ/gi;
        $input =~ s/i[)]=/ἶ/gi;
        $input =~ s/i[(]=/ἷ/gi;
        $input =~ s/i[)]/ἰ/gi;
        $input =~ s/i[(]/ἱ/gi;
        $input =~ s/i\\/ὶ/gi;
        $input =~ s/i\//ί/gi;
        $input =~ s/i=/ῖ/gi;
        $input =~ s/o[)]\\/ὂ/gi;
        $input =~ s/o[(]\\/ὃ/gi;
        $input =~ s/o[)]\//ὄ/gi;
        $input =~ s/o[(]\//ὅ/gi;
        $input =~ s/o[)]/ὀ/gi;
        $input =~ s/o[(]/ὁ/gi;
        $input =~ s/o\\/ὸ/gi;
        $input =~ s/o\//ό/gi;
        $input =~ s/r[)]/ῤ/gi;
        $input =~ s/r[(]/ῤ/gi;
        $input =~ s/u&/ῡ/gi;
        $input =~ s/u'/ῠ/gi;
        $input =~ s/u[+]\\/ῢ/gi;
        $input =~ s/u\\[+]/ῢ/gi;
        $input =~ s/u[+]\//ΰ/gi;
        $input =~ s/u\/[+]/ΰ/gi;
        $input =~ s/u[+]=/ῧ/gi;
        $input =~ s/u=[+]/ῧ/gi;
        $input =~ s/u[+]/ϋ/gi;
        $input =~ s/u[)]\\/ὒ/gi;
        $input =~ s/u[(]\\/ὓ/gi;
        $input =~ s/u[)]\//ὔ/gi;
        $input =~ s/u[(]\//ὕ/gi;
        $input =~ s/u[)]=/ὖ/gi;
        $input =~ s/u[(]=/ὗ/gi;
        $input =~ s/u[)]/ὐ/gi;
        $input =~ s/u[(]/ὑ/gi;
        $input =~ s/u\\/ὺ/gi;
        $input =~ s/u\//ύ/gi;
        $input =~ s/u=/ῦ/gi;
        $input =~ s/w[)]\/[|]/ᾤ/gi;
        $input =~ s/w[(]\/[|]/ᾥ/gi;
        $input =~ s/w[)]=[|]/ᾦ/gi;
        $input =~ s/w[(]=[|]/ᾧ/gi;
        $input =~ s/w[)][|]/ᾠ/gi;
        $input =~ s/w[(][|]/ᾡ/gi;
        $input =~ s/w\/[|]/ῴ/gi;
        $input =~ s/w=[|]/ῷ/gi;
        $input =~ s/w[)]\\/ὢ/gi;
        $input =~ s/w[(]\\/ὣ/gi;
        $input =~ s/w[)]\//ὤ/gi;
        $input =~ s/w[(]\//ὥ/gi;
        $input =~ s/w[)]=/ὦ/gi;
        $input =~ s/w[(]=/ὧ/gi;
        $input =~ s/w[)]/ὠ/gi;
        $input =~ s/w[(]/ὡ/gi;
        $input =~ s/w\\/ὼ/gi;
        $input =~ s/w\//ώ/gi;
        $input =~ s/w=/ῶ/gi;
        $input =~ s/w[|]/ῳ/gi;

        #Plain uppercase letters.#
        $input =~ s/[*]a/Α/gi;
        $input =~ s/[*]b/Β/gi;
        $input =~ s/[*]g/Γ/gi;
        $input =~ s/[*]d/Δ/gi;
        $input =~ s/[*]e/Ε/gi;
        $input =~ s/[*]z/Ζ/gi;
        $input =~ s/[*]h/Η/gi;
        $input =~ s/[*]q/Θ/gi;
        $input =~ s/[*]i/Ι/gi;
        $input =~ s/[*]k/Κ/gi;
        $input =~ s/[*]l/Λ/gi;
        $input =~ s/[*]m/Μ/gi;
        $input =~ s/[*]n/Ν/gi;
        $input =~ s/[*]c/Ξ/gi;
        $input =~ s/[*]o/Ο/gi;
        $input =~ s/[*]p/Π/gi;
        $input =~ s/[*]r/Ρ/gi;
        $input =~ s/[*]s3/Ϲ/gi;
        $input =~ s/[*]s/Σ/gi;
        $input =~ s/[*]t/Τ/gi;
        $input =~ s/[*]u/Υ/gi;
        $input =~ s/[*]f/Φ/gi;
        $input =~ s/[*]x/Χ/gi;
        $input =~ s/[*]y/Ψ/gi;
        $input =~ s/[*]w/Ω/gi;
        $input =~ s/[*]v/Ϝ/gi;

        #Plain lowercase letters.#
        $input =~ s/a/α/gi;
        $input =~ s/b/β/gi;
        $input =~ s/g/γ/gi;
        $input =~ s/d/δ/gi;
        $input =~ s/e/ε/gi;
        $input =~ s/z/ζ/gi;
        $input =~ s/h/η/gi;
        $input =~ s/q/θ/gi;
        $input =~ s/i/ι/gi;
        $input =~ s/k/κ/gi;
        $input =~ s/l/λ/gi;
        $input =~ s/m/μ/gi;
        $input =~ s/n/ν/gi;
        $input =~ s/c/ξ/gi;
        $input =~ s/o/ο/gi;
        $input =~ s/p/π/gi;
        $input =~ s/r/ρ/gi;
        $input =~ s/s1/σ/gi;
        $input =~ s/s2/ς/gi;
        $input =~ s/s3/ϲ/gi;
        $input =~ s/s([,.;:])/ς$1/gi;
        $input =~ s/s(\s)/ς$1/gi;
        $input =~ s/s$/ς/gi;
        $input =~ s/s([a-zA-Z\/\\=[+]\-'])/σ$1/gi;
        $input =~ s/s([^a-zA-Z\/\\=[+]\-'])/ς$1/gi;
        $input =~ s/s/σ/gi;
        $input =~ s/t/τ/gi;
        $input =~ s/u/υ/gi;
        $input =~ s/f/φ/gi;
        $input =~ s/x/χ/gi;
        $input =~ s/y/ψ/gi;
        $input =~ s/w/ω/gi;
        $input =~ s/v/ϝ/gi;
    }
    else
    {
        warn 'Only "greek/greek_punct" is available for now.';
    }

    if ( $language eq 'greek_punct' )
    {

        #Punctuation.#
        $input =~ s/:/·/g;
        $input =~ s/_/—/g;
        $input =~ s/#/ʹ/g;

        # If ' has not been used for breve (˘), then
        # it is an apostrophe.
        $input =~ s/'/’/g;
    }

    return $input;
}

=over

=item  B<beta_encode> LANGUAGE, STYLE, STRING

Converts strings from Unicode to Beta Code. It can also handle text with
 combined characters.

=over

=item Supported languages (so far):

-> C<'greek'>

-> C<'greek_punct'> (with punctuation conversions)

=item Supported styles (so far):

-> C<'TLG'>

-> C<'Perseus'>

=back

=back

=cut

sub beta_encode
{
    my ( $language, $style, $input ) = @_;

    # Decompose combined characters (if any).
    use utf8;
    unless ( utf8::is_utf8($input) )
    {
        utf8::decode($input);
        $input = NFC($input);
    }
    else
    {
        no utf8;
    }

    if ( $language eq 'greek_punct' )
    {

        #Punctuation.#
        $input =~ s/·/:/g;
        $input =~ s/—/_/g;
        $input =~ s/’/'/g;

        # The true Unicode equivalent of the numeral (#) is ʹ.
        # However, the NFC() function call above will turn ʹ
        # into ʹ. Therefore, the conversion below will be
        # from ʹ into #, and not from ʹ into #.
        $input =~ s/ʹ/#/g;
    }
    if ( $language eq 'greek' || $language eq 'greek_punct' )
    {

        #Uppercase accents and diacritics.#
        $input =~ s/Ᾱ/*a&/g;
        $input =~ s/Ᾰ/*a'/g;
        $input =~ s/ᾌ/*)\/a|/g;
        $input =~ s/ᾍ/*(\/a|/g;
        $input =~ s/ᾎ/*)=a|/g;
        $input =~ s/ᾏ/*(=a|/g;
        $input =~ s/Ἃ/*(\\a/g;
        $input =~ s/Ἄ/*)\/a/g;
        $input =~ s/Ἅ/*(\/a/g;
        $input =~ s/Ἆ/*)=a/g;
        $input =~ s/Ἇ/*(=a/g;
        $input =~ s/ᾈ/*)a|/g;
        $input =~ s/ᾉ/*(a|/g;
        $input =~ s/Ἀ/*)a/g;
        $input =~ s/Ἁ/*(a/g;
        $input =~ s/Ὰ/*\a/g;
        $input =~ s/Ά/*\/a/g;
        $input =~ s/ᾼ/*a|/g;
        $input =~ s/Ἂ/*)\\a/g;
        $input =~ s/Ἃ/*(\\a/g;
        $input =~ s/Ἒ/*)\\e/g;
        $input =~ s/Ἓ/*(\\e/g;
        $input =~ s/Ἔ/*)\/e/g;
        $input =~ s/Ἕ/*(\/e/g;
        $input =~ s/Ἐ/*)e/g;
        $input =~ s/Ἑ/*(e/g;
        $input =~ s/Ὲ/*\e/g;
        $input =~ s/Έ/*\/e/g;
        $input =~ s/Ὲ/*\\e/g;
        $input =~ s/ᾜ/*)\/h|/g;
        $input =~ s/ᾝ/*(\/h|/g;
        $input =~ s/ᾞ/*)=h|/g;
        $input =~ s/ᾟ/*(=h|/g;
        $input =~ s/Ἢ/*)\\h/g;
        $input =~ s/Ἣ/*(\\h/g;
        $input =~ s/Ἤ/*)\/h/g;
        $input =~ s/Ἥ/*(\/h/g;
        $input =~ s/Ἦ/*)=h/g;
        $input =~ s/Ἧ/*(=h/g;
        $input =~ s/ᾘ/*)h|/g;
        $input =~ s/ᾙ/*(h|/g;
        $input =~ s/Ἠ/*)h/g;
        $input =~ s/Ἡ/*(h/g;
        $input =~ s/Ὴ/*\\h/g;
        $input =~ s/Ή/*\/h/g;
        $input =~ s/ῌ/*h|/g;
        $input =~ s/Ῑ/*i&/g;
        $input =~ s/Ῐ/*i'/g;
        $input =~ s/Ϊ/*+i/g;
        $input =~ s/Ἲ/*)\\i/g;
        $input =~ s/Ἳ/*(\\i/g;
        $input =~ s/Ἴ/*)\/i/g;
        $input =~ s/Ἵ/*(\/i/g;
        $input =~ s/Ἶ/*)=i/g;
        $input =~ s/Ἷ/*(=i/g;
        $input =~ s/Ἰ/*)i/g;
        $input =~ s/Ἱ/*(i/g;
        $input =~ s/Ὶ/*\\i/g;
        $input =~ s/Ί/*\/i/g;
        $input =~ s/Ὂ/*)\\o/g;
        $input =~ s/Ὃ/*(\\o/g;
        $input =~ s/Ὄ/*)\/o/g;
        $input =~ s/Ὅ/*(\/o/g;
        $input =~ s/Ὄ/*)=o/g;
        $input =~ s/Ὅ/*(=o/g;
        $input =~ s/Ὀ/*)o/g;
        $input =~ s/Ὁ/*(o/g;
        $input =~ s/Ὸ/*\\o/g;
        $input =~ s/Ό/*\/o/g;
        $input =~ s/Ρ/*)r/g;
        $input =~ s/Ῥ/*(r/g;
        $input =~ s/Ῡ/*u&/g;
        $input =~ s/Ῠ/*u'/g;
        $input =~ s/Ϋ/*+u/g;
        $input =~ s/Ὓ/*(\\u/g;
        $input =~ s/Ὕ/*(\/u/g;
        $input =~ s/Ὗ/*(=u/g;
        $input =~ s/Ὑ/*(u/g;
        $input =~ s/Ὺ/*\u/g;
        $input =~ s/Ύ/*\/u/g;
        $input =~ s/ᾬ/*)\/w|/g;
        $input =~ s/ᾭ/*(\/w|/g;
        $input =~ s/ᾮ/*)=w|/g;
        $input =~ s/ᾯ/*(=w|/g;
        $input =~ s/Ὢ/*)\\w/g;
        $input =~ s/Ὣ/*(\\w/g;
        $input =~ s/Ὤ/*)\/w/g;
        $input =~ s/Ὥ/*(\/w/g;
        $input =~ s/Ὦ/*)=w/g;
        $input =~ s/Ὧ/*(=w/g;
        $input =~ s/ᾨ/*)w|/g;
        $input =~ s/ᾩ/*(w|/g;
        $input =~ s/Ὠ/*)w/g;
        $input =~ s/Ὡ/*(w/g;
        $input =~ s/Ὼ/*\\w/g;
        $input =~ s/Ώ/*\/w/g;
        $input =~ s/ῼ/*w|/g;

        #Lowercase accents and diacritics.#
        $input =~ s/ᾱ/a&/g;
        $input =~ s/ᾰ/a'/g;
        $input =~ s/ᾄ/a)\/|/g;
        $input =~ s/ᾅ/a(\/|/g;
        $input =~ s/ᾆ/a)=|/g;
        $input =~ s/ᾇ/a(=|/g;
        $input =~ s/ᾀ/a)|/g;
        $input =~ s/ᾁ/a(|/g;
        $input =~ s/ᾴ/a\/|/g;
        $input =~ s/ᾷ/a=|/g;
        $input =~ s/ἂ/a)\\/g;
        $input =~ s/ἃ/a(\\/g;
        $input =~ s/ἄ/a)\//g;
        $input =~ s/ἅ/a(\//g;
        $input =~ s/ἆ/a)=/g;
        $input =~ s/ἇ/a(=/g;
        $input =~ s/ἀ/a)/g;
        $input =~ s/ἁ/a(/g;
        $input =~ s/ὰ/a\\/g;
        $input =~ s/ά/a\//g;
        $input =~ s/ᾶ/a=/g;
        $input =~ s/ᾳ/a|/g;
        $input =~ s/ἒ/e)\\/g;
        $input =~ s/ἓ/e(\\/g;
        $input =~ s/ἔ/e)\//g;
        $input =~ s/ἕ/e(\//g;
        $input =~ s/ἐ/e)/g;
        $input =~ s/ἑ/e(/g;
        $input =~ s/ὲ/e\\/g;
        $input =~ s/έ/e\//g;
        $input =~ s/ᾔ/h)\/|/g;
        $input =~ s/ᾕ/h(\/|/g;
        $input =~ s/ᾖ/h)=|/g;
        $input =~ s/ᾗ/h(=|/g;
        $input =~ s/ᾐ/h)|/g;
        $input =~ s/ᾑ/h(|/g;
        $input =~ s/ῄ/h\/|/g;
        $input =~ s/ῇ/h=|/g;
        $input =~ s/ἢ/h)\\/g;
        $input =~ s/ἣ/h(\\/g;
        $input =~ s/ἤ/h)\//g;
        $input =~ s/ἥ/h(\//g;
        $input =~ s/ἦ/h)=/g;
        $input =~ s/ἧ/h(=/g;
        $input =~ s/ἠ/h)/g;
        $input =~ s/ἡ/h(/g;
        $input =~ s/ὴ/h\\/g;
        $input =~ s/ή/h\//g;
        $input =~ s/ῆ/h=/g;
        $input =~ s/ῃ/h|/g;
        $input =~ s/ῑ/i&/g;
        $input =~ s/ῐ/i'/g;
        $input =~ s/ῒ/i+\\/g;
        $input =~ s/ΐ/i+\//g;
        $input =~ s/ῗ/i+=/g;
        $input =~ s/ϊ/i+/g;
        $input =~ s/ἲ/i)\\/g;
        $input =~ s/ἳ/i(\\/g;
        $input =~ s/ἴ/i)\//g;
        $input =~ s/ἵ/i(\//g;
        $input =~ s/ἶ/i)=/g;
        $input =~ s/ἷ/i(=/g;
        $input =~ s/ἰ/i)/g;
        $input =~ s/ἱ/i(/g;
        $input =~ s/ὶ/i\\/g;
        $input =~ s/ί/i\//g;
        $input =~ s/ῖ/i=/g;
        $input =~ s/ὂ/o)\\/g;
        $input =~ s/ὃ/o(\\/g;
        $input =~ s/ὄ/o)\//g;
        $input =~ s/ὅ/o(\//g;
        $input =~ s/ὀ/o)/g;
        $input =~ s/ὁ/o(/g;
        $input =~ s/ὸ/o\\/g;
        $input =~ s/ό/o\//g;
        $input =~ s/ῤ/r)/g;
        $input =~ s/ῤ/r(/g;
        $input =~ s/ῡ/u&/g;
        $input =~ s/ῠ/u'/g;
        $input =~ s/ῢ/u+\\/g;
        $input =~ s/ΰ/u+\//g;
        $input =~ s/ῧ/u+=/g;
        $input =~ s/ϋ/u+/g;
        $input =~ s/ὒ/u)\\/g;
        $input =~ s/ὓ/u(\\/g;
        $input =~ s/ὔ/u)\//g;
        $input =~ s/ὕ/u(\//g;
        $input =~ s/ὖ/u)=/g;
        $input =~ s/ὗ/u(=/g;
        $input =~ s/ὐ/u)/g;
        $input =~ s/ὑ/u(/g;
        $input =~ s/ὺ/u\\/g;
        $input =~ s/ύ/u\//g;
        $input =~ s/ῦ/u=/g;
        $input =~ s/ᾤ/w)\/|/g;
        $input =~ s/ᾥ/w(\/|/g;
        $input =~ s/ᾦ/w)=|/g;
        $input =~ s/ᾧ/w(=|/g;
        $input =~ s/ᾠ/w)|/g;
        $input =~ s/ᾡ/w(|/g;
        $input =~ s/ῴ/w\/|/g;
        $input =~ s/ῷ/w=|/g;
        $input =~ s/ὢ/w)\\/g;
        $input =~ s/ὣ/w(\\/g;
        $input =~ s/ὤ/w)\//g;
        $input =~ s/ὥ/w(\//g;
        $input =~ s/ὦ/w)=/g;
        $input =~ s/ὧ/w(=/g;
        $input =~ s/ὠ/w)/g;
        $input =~ s/ὡ/w(/g;
        $input =~ s/ὼ/w\\/g;
        $input =~ s/ώ/w\//g;
        $input =~ s/ῶ/w=/g;
        $input =~ s/ῳ/w|/g;

        #Plain uppercase letters.#
        $input =~ s/Α/*a/g;
        $input =~ s/Β/*b/g;
        $input =~ s/Γ/*g/g;
        $input =~ s/Δ/*d/g;
        $input =~ s/Ε/*e/g;
        $input =~ s/Ζ/*z/g;
        $input =~ s/Η/*h/g;
        $input =~ s/Θ/*q/g;
        $input =~ s/Ι/*i/g;
        $input =~ s/Κ/*k/g;
        $input =~ s/Λ/*l/g;
        $input =~ s/Μ/*m/g;
        $input =~ s/Ν/*n/g;
        $input =~ s/Ξ/*c/g;
        $input =~ s/Ο/*o/g;
        $input =~ s/Π/*p/g;
        $input =~ s/Ρ/*r/g;
        $input =~ s/Ϲ/*s/g;
        $input =~ s/Σ/*s/g;
        $input =~ s/Τ/*t/g;
        $input =~ s/Υ/*u/g;
        $input =~ s/Φ/*f/g;
        $input =~ s/Χ/*x/g;
        $input =~ s/Ψ/*y/g;
        $input =~ s/Ω/*w/g;
        $input =~ s/Ϝ/*v/g;

        #Plain lowercase letters.#
        $input =~ s/α/a/g;
        $input =~ s/β/b/g;
        $input =~ s/γ/g/g;
        $input =~ s/δ/d/g;
        $input =~ s/ε/e/g;
        $input =~ s/ζ/z/g;
        $input =~ s/η/h/g;
        $input =~ s/θ/q/g;
        $input =~ s/ι/i/g;
        $input =~ s/κ/k/g;
        $input =~ s/λ/l/g;
        $input =~ s/μ/m/g;
        $input =~ s/ν/n/g;
        $input =~ s/ξ/c/g;
        $input =~ s/ο/o/g;
        $input =~ s/π/p/g;
        $input =~ s/ρ/r/g;
        $input =~ s/σ/s/g;
        $input =~ s/ς/s/g;
        $input =~ s/ϲ/s/g;
        $input =~ s/τ/t/g;
        $input =~ s/υ/u/g;
        $input =~ s/φ/f/g;
        $input =~ s/χ/x/g;
        $input =~ s/ψ/y/g;
        $input =~ s/ω/w/g;
        $input =~ s/ϝ/v/g;
    }
    else
    {
        warn 'Only "greek/greek_punct" is available for now.';
    }

    if ( $style eq 'TLG' )
    {
        $input = uc $input;
    }
    elsif ( $style eq 'Perseus' )
    {
        $input = lc $input;
    }
    else
    {
        warn 'Only the TLG and Perseus styles are available for now.';
    }
    return $input;
}

=head1 BUGS

Please report any bugs or feature requests to C<bug-encode-betacode at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Encode-BetaCode>.

I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

Also, the source code is available at GitHub: L<https://github.com/dgkontopoulos/Encode-BetaCode>

=head1 AUTHOR

Dimitrios - Georgios Kontopoulos, C<< <dgkontopoulos at member.fsf.org> >>

=head1 ACKNOWLEDGEMENTS

The inspiration to write this module is thanks to B<Jennie Petoumenou>, a 
member of the Ubuntu-gr community (L<http://ubuntu-gr.org/>).
Her contribution to defining and testing the conversion rules was more than significant.

Valuable contributions in form of bug reports have been also provided by 
B<Philipp Steinkrüger>, and B<Juan Miguel Corral Cano>.

=head1 SEE ALSO

L<http://www.tlg.uci.edu/encoding/>

L<http://www.perseus.tufts.edu/hopper/>

L<http://en.wikipedia.org/wiki/Beta_code>

=head1 COPYRIGHT

Copyright 2012-16 Dimitrios - Georgios Kontopoulos.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Encode::BetaCode
