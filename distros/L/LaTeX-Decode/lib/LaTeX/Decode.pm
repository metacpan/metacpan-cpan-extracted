package LaTeX::Decode;

use 5.008;
use warnings;
use strict;
use Carp;

=encoding utf-8

=head1 NAME

LaTeX::Decode - Decode from LaTeX to Unicode

=head1 VERSION

Version 0.04

=cut

use base qw(Exporter);
our $VERSION = '0.04';
our @EXPORT  = qw(latex_decode);
use LaTeX::Decode::Data;
use Unicode::Normalize;

=head1 SYNOPSIS

    use LaTeX::Decode;

    my $latex_string = 'Mu\\d{h}ammad ibn M\\=us\=a al-Khw\\=arizm\\={\\i}';
    my $new_string   = latex_decode($latex_string); # => 'Muḥammad ibn Mūsā al-Khwārizmī'

=head1 DESCRIPTION

=head1 EXPORT

=head1 FUNCTIONS

=head2 latex_decode($text, %options)

Decodes the given text from LaTeX to Unicode.

The function accepts a number of options:

    * normalize => $bool (default 0)
        whether the output string should be normalized with Unicode::Normalize

    * normalization => <normalization form> (default 'NFC')
        and if yes, the normalization form to use (see the Unicode::Normalize documentation)

    * strip_outer_braces => $bool (default 0)
        whether the outer curly braces around letters+combining marks should be
        stripped off. By default "fut{\\'e}" becomes fut{é}, to prevent something
        like '\\textuppercase{\\'e}' to become '\\textuppercaseé'. Setting this option to
        TRUE can be useful for instance when converting BibTeX files.

=head1 GLOBAL OPTIONS

The decoding scheme can be set with
  $LaTeX::Decode::DefaultScheme = '<name>';
Possible values are 'base', 'extra' and 'full'; default value is 'extra'.

TODO : explain these scheme!

base  => Most common macros and diacritics (sufficient for Western languages
         and common symbols)

extra => Also converts punctuation, larger range of diacritics and macros (e.g. for IPA, Latin Extended
         Additional, etc.)

full  => Also converts symbols, Greek letters, dingbats, negated symbols, and
         superscript characters and symbols ...

=cut

our $DefaultScheme = 'extra';

sub _get_diac {
    my $scheme = shift;
    if ( $scheme eq 'base' ) {
        return %DIACRITICS;
    }
    else {
        return ( %DIACRITICS, %DIACRITICSEXTRA );
    }
}

sub _get_mac {
    my $scheme = shift;
    if ( $scheme eq 'base' ) {
        return %WORDMACROS;
    }
    elsif ( $scheme eq 'full' ) {
        return ( %WORDMACROS, %WORDMACROSEXTRA, %PUNCTUATION, %SYMBOLS,
            %GREEK );
    }
    else {
        return ( %WORDMACROS, %WORDMACROSEXTRA, %PUNCTUATION );
    }
}

sub latex_decode {
    my $text      = shift;
    my %opts      = @_;
    my $norm      = exists $opts{normalize} ? $opts{normalize} : 1;
    my $norm_form = exists $opts{normalization} ? $opts{normalization} : 'NFC';
    my $scheme    = exists $opts{scheme} ? $opts{scheme} : $DefaultScheme;
    croak "invalid scheme name '$scheme'"
        unless ( $scheme eq 'full' or $scheme eq 'base' or $scheme eq 'extra' );
    my $strip_outer_braces =
      exists $opts{strip_outer_braces} ? $opts{strip_outer_braces} : 0;

    my %DIAC    = _get_diac($scheme);
    my %WORDMAC = _get_mac($scheme);

    # a regex with all possible word macros
    my $WORDMAC_RE =
      join( '|', sort { length $b <=> length $a } keys %WORDMAC );
    $WORDMAC_RE = qr{$WORDMAC_RE};

    my $DIAC_RE;
    if ( $scheme eq 'base' ) {
        $DIAC_RE = $DIAC_RE_BASE;
    }
    else {
        $DIAC_RE = $DIAC_RE_EXTRA;
    }

    if ( $scheme eq 'full' ) {
        $text =~ s/\\not\\($NEG_SYMB_RE)/$NEGATEDSYMBOLS{$1}/ge;
        $text =~ s/\\textsuperscript{($SUPER_RE)}/$SUPERSCRIPTS{$1}/ge;
        $text =~ s/\\textsuperscript{\\($SUPERCMD_RE)}/$CMDSUPERSCRIPTS{$1}/ge;
        $text =~ s/\\dings{([2-9AF][0-9A-F])}/$DINGS{$1}/ge;
    }

    $text =~ s/(\\[a-zA-Z]+)\\(\s+)/$1\{\}$2/g;    # \foo\ bar -> \foo{} bar
    $text =~ s/([^{]\\\w)([;,.:%])/$1\{\}$2/g;     #} Aaaa\o, -> Aaaa\o{},
    $text =~ s/(\\(?:$DIAC_RE_BASE|$ACCENTS_RE)){\\i}/$1\{i\}/g;
           # special cases such as '\={\i}' -> '\={i}' -> "i\x{304}"

    ## remove {} around macros that print one character
    ## by default we skip that, as it would break constructions like \foo{\i}
    if ($strip_outer_braces) {
        $text =~ s/ \{\\($WORDMAC_RE)\} / $WORDMAC{$1} /gxe;
    }
    $text =~ s/ \\($WORDMAC_RE)(?: \{\} | \s+ | \b) / $WORDMAC{$1} /gxe;

    $text =~ s/\\($ACCENTS_RE)\{(\p{L}\p{M}*)\}/$2 . $ACCENTS{$1}/ge;

    $text =~ s/\\($ACCENTS_RE)(\p{L}\p{M}*)/$2 . $ACCENTS{$1}/ge;

    $text =~ s/\\($DIAC_RE)\s*\{(\p{L}\p{M}*)\}/$2 . $DIAC{$1}/ge;

    $text =~ s/\\($DIAC_RE)\s+(\p{L}\p{M}*)/$2 . $DIAC{$1}/ge;

    $text =~ s/\\($ACCENTS_RE)\{(\p{L}\p{M}*)\}/$2 . $ACCENTS{$1}/ge;

    $text =~ s/\\($ACCENTS_RE)(\p{L}\p{M}*)/$2 . $ACCENTS{$1}/ge;

    $text =~ s/\\($DIAC_RE)\s*\{(\p{L}\p{M}*)\}/$2 . $DIAC{$1}/ge;

    $text =~ s/\\($DIAC_RE)\s+(\p{L}\p{M}*)/$2 . $DIAC{$1}/ge;

    ## remove {} around letter+combining mark(s)
    ## by default we skip that, as it would destroy constructions like \foo{\`e}
    if ($strip_outer_braces) {
        $text =~ s/{(\PM\pM+)}/$1/g;
    }

    if ($norm) {
        return Unicode::Normalize::normalize( $norm_form, $text );
    }
    else {
        return $text;
    }
}

=head1 AUTHOR

François Charette, C<< <firmicus@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-latex-decode at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LaTeX-Decode>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2009-2015 François Charette, all rights reserved.

This module is free software.  You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

1;

# vim: set tabstop=4 shiftwidth=4 expandtab:
