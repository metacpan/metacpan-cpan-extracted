package Lingua::EN::Pseudolocalize;
use strict; use warnings; use 5.008;
use Sub::Exporter::Simple qw/convert deconvert/;
use charnames ':full';

# ABSTRACT: Test Unicode support by pretending to speak a different language.

my $lookup = {
   'th' => "\N{LATIN SMALL LETTER TH WITH STRIKETHROUGH}",
   'ts' => "\N{LATIN SMALL LETTER TS DIGRAPH}",
   'st' => "\N{LATIN SMALL LIGATURE ST}",
   'a' =>  "\N{LATIN SMALL LETTER A WITH HOOK ABOVE}",
   'b' =>  "\N{LATIN SMALL LETTER B WITH MIDDLE TILDE}",
   'd' =>  "\N{LATIN SMALL LETTER D WITH CURL}",
   'e' =>  "\N{LATIN SMALL LETTER E WITH INVERTED BREVE}",
   'i' =>  "\N{LATIN SMALL LETTER I WITH DIAERESIS AND ACUTE}",
   'o' =>  "\N{LATIN SMALL LETTER O WITH DOT ABOVE}",
   'u' =>  "\N{LATIN SMALL LETTER U WITH HORN AND HOOK ABOVE}",
   'A' =>  "\N{LATIN CAPITAL LETTER A WITH RING BELOW}",
   'E' =>  "\N{LATIN CAPITAL LETTER E WITH TILDE BELOW}",
   'I' =>  "\N{LATIN CAPITAL LETTER I WITH INVERTED BREVE}",
   'O' =>  "\N{LATIN CAPITAL LETTER O WITH STROKE AND ACUTE}",
   'U' =>  "\N{LATIN CAPITAL LETTER U WITH DIAERESIS BELOW}",
   'T' =>  "\N{LATIN CAPITAL LETTER T WITH HOOK}",
   'N' =>  "\N{LATIN CAPITAL LETTER N WITH ACUTE}",
   'S' =>  "\N{LATIN CAPITAL LETTER S WITH COMMA BELOW}",
   'H' =>  "\N{LATIN CAPITAL LETTER H WITH DIAERESIS}",
   'R' =>  "\N{LATIN CAPITAL LETTER R WITH DOT BELOW AND MACRON}",
   'D' =>  "\N{LATIN CAPITAL LETTER D WITH STROKE}",
   'L' =>  "\N{LATIN CAPITAL LETTER L WITH MIDDLE DOT}",
};

sub convert {
   my $str = shift;
   $str =~ s/$_/$lookup->{$_}/g for keys %$lookup;
   return $str
}

sub deconvert {
   my $str = shift;
   $str =~ s/$lookup->{$_}/$_/g for keys %$lookup;
   return $str
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::EN::Pseudolocalize - Test Unicode support by pretending to speak a different language.

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use Lingua::EN::Pseudolocalize qw( convert deconvert );

    my $text = 'Widdly scuds?';

    my $pl_text = convert($text);

=head1 DESCRIPTION

This package contains utilities for pseudolocalizing English or similar languages expressable in the ASCII character set.

Applications created or maintained by English-speaking developers may suffer from overlooked Unicode support due to the ASCII, latin1, Windows CP1252,  and utf8 encodings being equivalent for the code points used in English. You may think that your application is Unicode-friendly, but it's easy to forget to test for extended character support. It goes overlooked until a customer pastes in some decorative quotes from MS Word and you end up with mojibake in your app.

This module will convert your basic Latin characters to similar-looking characters that are much higher on the code plane. This process is called pseudolocalization, and it will very quickly expose a few common errors in encoding support.

DO NOT USE THIS MODULE IN PRODUCTION. Use it in read-only mode, or on a test data set. It should make round-trip conversions just fine, but if you have data in your application that is in the conversion table, no effort is made to preserve your data. It might end up stripping out all the diacritics from your data, and that would ruin your comprehensive database of melodic Finnish folk-metal bands.

=head1 FUNCTIONS

=over 4

=item convert($text)

Converts $text into pseudolocalized text using a simple mapping table. A few pairs are combined into single characters with ligatures, while the rest are simple one-to-one mappings.

Returns: the converted string

=item deconvert($text)

Reverses the process of convert() using the same mapping table.

Returns: the converted string

=back

=head1 AUTHOR

Wes Malone <wesm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Wes Malone <wesm@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
