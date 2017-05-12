package Lingua::ES::Syllabify;

use 5.008008;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Lingua::ES::Syllabify ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'test' => [ qw(
    getSyllables
    processHiatus
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'test'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.9';

use String::Multibyte;
use TeX::Hyphen;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__


=head1 NAME

Lingua::ES::Syllabify - Perl extension for getting the syllables of a Spanish
word.

=head1 SYNOPSIS

  use Lingua::ES::Syllabify;

  @syllables = Lingua::ES::Syllabify::getSyllables($spanishWord);

=head1 DESCRIPTION

This module is used to get the syllables of a Spanish word. It uses TeX::Hyphen
for initial segmentatation. You need to edit the file to specify the hyphenation
definitions file, although it may work directly as the default path is quite
standard.

=head2 EXPORT

None by default.



=head1 SEE ALSO

TeX::Hyphen

=head1 AUTHOR

alberto, E<lt>alberto@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by alberto

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

my $hyp = new TeX::Hyphen (
        file => "/usr/share/texmf-texlive/tex/generic/hyphen/eshyph.tex",
        leftmin => 1,
        rightmin => 1);



sub getSyllables($) {
    my $word = shift;

    my $getHyphenationItems = sub {
        my $word = shift;
    
        my $hyphenatedWord = $hyp->visualize(" $word\n");
        $hyphenatedWord =~ s/\s+//g;
        $hyphenatedWord =~ s/ñ/-ñ/g;
        $hyphenatedWord =~ s/^-//;
        $hyphenatedWord =~ s/-$//;
        $hyphenatedWord =~ s/-([bcdfghjklmnpqrstvwxyz])$/$1/;
    
        return (split("-", $hyphenatedWord));
    };

    my @initialSyllables = map {
        $getHyphenationItems->($_); # A bit tricky, but needed to overcome
                                  #  TeX::Hyphen odd behaviour
    } ($getHyphenationItems->($word));

    my @syllables = map {processHiatus($_)} @initialSyllables;

    return @syllables;
}

=item processHiatus

    Given a syllabe-like text, find hiatus and return the appropiated syllables
=cut
sub processHiatus($) {
    my $text = shift;

    my $strongVowels_re = "a|á|e|é|o|ó";
    my $softVowels_re = "i|í|u|ú|ü";
    my $stressedSoftVowels_re = "í|ú";

    if ($text =~ /(($strongVowels_re)h?($strongVowels_re))/ ||
        $text =~ /(($softVowels_re)h?($softVowels_re))/ ||
        $text =~ /(($stressedSoftVowels_re)h?($strongVowels_re))/ ||
        $text =~ /(($strongVowels_re)h?($stressedSoftVowels_re))/) {
        my $hiatus = $1;
        my $utf8 = new String::Multibyte('UTF8');
        my @hiatusLetters = $utf8->strsplit('', $hiatus);
        my @splittedText = $utf8->strsplit("$hiatus", "=$text=");
        my @syllables = map {s/=//g; $_} @splittedText;
        $syllables[0] .= shift @hiatusLetters;
        $syllables[1] = join("", @hiatusLetters).$syllables[1];
        return @syllables;
    } else {
        return ($text);
    }
}
