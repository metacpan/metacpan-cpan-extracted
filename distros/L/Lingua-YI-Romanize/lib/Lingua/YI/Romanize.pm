package Lingua::YI::Romanize;
use utf8;

use strict;
use warnings;

our $VERSION = '0.01';

use Unicode::Normalize;

our $normalize_combinings;
our $yivo2latn;
our $vowels;
our $consonants;
our $consonants_2;


sub new {
  my $class = shift;
  # uncoverable condition false
  bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
}

sub _gen_charclass {
   my $chartable = shift;
   my $string;
   for my $cons (@{$chartable}) {
       $string .= $cons->[0];
   }
   return join('|',split('',$string));
}

sub _normalize {
    my $string = shift;
    for my $rule (@$normalize_combinings) {
        $string =~ s/$rule->[0]/$rule->[1]/g;
    }
    return $string;
}

sub yivo2latn {
    my ($self, $text) = @_;
    my $string = _normalize(NFC($text));

	my $cons_2 = _gen_charclass($consonants_2);;
	my $cons   = _gen_charclass($consonants);
	my $vowels = _gen_charclass($vowels);

# "\x{05D9}" HEBREW LETTER YOD|י|y, i
# 1.1. y before or after a vowel;
# i between consonants;
# y after ‫ ט‬t, ‫ ד‬d, ‫ ס‬s, ‫ ז‬z, ‫ ל‬l, ‫ נ‬n; and before a vowel
#     indicates the palatals in words of Slavic origin.

    $string =~ s/\x{05D9}($vowels)/y$1/g;
    $string =~ s/($vowels)\x{05D9}/${1}y/g;
    $string =~ s/($cons_2)\x{05D9}/${1}y/g;
    $string =~ s/($cons)\x{05D9}($cons)/${1}i${2}/g;
    $string =~ s/\x{05D9}/i/g;

    for my $rule (@$yivo2latn) {
        $string =~ s/$rule->[0]/$rule->[1]/g;
    }
    return $string;
}

sub yivo2ipa {
    my ($self, $text) = @_;
    my $string = _normalize(NFC($text));

	my $cons_2 = _gen_charclass($consonants_2);;
	my $cons   = _gen_charclass($consonants);
	my $vowels = _gen_charclass($vowels);

# "\x{05D9}" HEBREW LETTER YOD|י|y, i
# 1.1. y before or after a vowel;
# i between consonants;
# y after ‫ ט‬t, ‫ ד‬d, ‫ ס‬s, ‫ ז‬z, ‫ ל‬l, ‫ נ‬n; and before a vowel
#     indicates the palatals in words of Slavic origin.

    $string =~ s/\x{05D9}($vowels)/j$1/g;
    $string =~ s/($vowels)\x{05D9}/${1}j/g;
    $string =~ s/($cons)\x{05D9}($cons)/${1}i${2}/g;
    $string =~ s/($cons_2)\x{05D9}/${1}j/g;


    for my $rule (@$yivo2latn) {
        $string =~ s/$rule->[0]/$rule->[2]/g;
    }
    return $string;
}

BEGIN {
$normalize_combinings = [
["\x{05D0}\x{05B7}","\x{FB2E}"], # HEBREW LETTER ALEF WITH PATAH
["\x{05D0}\x{05B8}","\x{FB2F}"], # HEBREW LETTER ALEF WITH QAMATS
["\x{05D1}\x{05BC}","\x{FB31}"], # HEBREW LETTER BET WITH DAGESH
["\x{05D1}\x{05BF}","\x{FB4C}"], # HEBREW LETTER BET WITH RAFE
["\x{05D5}\x{05BC}","\x{FB35}"], # HEBREW LETTER VAV WITH DAGESH
["\x{05D5}\x{05D5}","\x{05F0}"], # HEBREW LIGATURE YIDDISH DOUBLE VAV
["\x{05D5}\x{05D9}","\x{05F1}"], # HEBREW LIGATURE YIDDISH VAV YOD
["\x{05D9}\x{05B4}","\x{FB1D}"], # HEBREW LETTER YOD WITH HIRIQ
["\x{05D9}\x{05D9}","\x{05F2}"], # HEBREW LIGATURE YIDDISH DOUBLE YOD
["\x{05F2}\x{05B7}","\x{FB1F}"], # HEBREW LIGATURE YIDDISH YOD YOD PATAH
["\x{05DB}\x{05BC}","\x{FB3B}"], # HEBREW LETTER KAF WITH DAGESH
["\x{05E4}\x{05BC}","\x{FB44}"], # HEBREW LETTER PE WITH DAGESH
["\x{05E4}\x{05BF}","\x{FB4E}"], # HEBREW LETTER PE WITH RAFE
["\x{05E9}\x{05C2}","\x{FB2B}"], # HEBREW LETTER SHIN WITH SIN DOT
["\x{05EA}\x{05BC}","\x{FB4A}"], # HEBREW LETTER TAV WITH DAGESH
["\x{FB20}","\x{05E2}"], # HEBREW LETTER ALTERNATIVE AYIN
["\x{05E4}","\x{05BF}"], # HEBREW LETTER PE
];


$yivo2latn = [
["\x{05D3}\x{05D6}\x{05E9}",'dzh','d͡ʒ'],
["\x{05D6}\x{05E9}",'zh','ʒ'],
["\x{05D8}\x{05E9}",'tsh','t͡ʃ'],
["\x{05D0}",'',''],
["\x{FB2E}",'a','a'],
["\x{FB2F}",'o','ɔ'],
["\x{05D1}",'b','b'],
["\x{FB31}",'','b'],
["\x{FB4C}",'v','v'],
["\x{05D2}",'g','ɡ'],
["\x{05D3}",'d','d'],
["\x{05D4}",'h','h'],
["\x{05D5}",'u','ʊ'],
["\x{FB35}",'u','ʊ'],
# "\x{05D5}" HEBREW LETTER VAV,"\x{05B9}" HEBREW POINT HOLAM|וֹ|(none)|(none)|ɔ, ɔj|(o,oj)|khoylem|Non-YIVO alternative to אָ and וי.
["\x{05F0}",'v','v'],
["\x{05F1}",'oy','ɔj'],
["\x{05D6}",'z','z'],
["\x{05D7}",'kh','x'],
["\x{05D8}",'t','t'],
# TODO "\x{05D9}" HEBREW LETTER YOD|י|y, i|y, i|j, i|j, i|yud|Consonantal [j] when the first character in a syllable. Vocalic [i] otherwise.
["\x{FB1D}",'i','i'],
["\x{05F2}",'ey','ɛj'],
["\x{FB1F}",'ay','aj'],
["\x{FB3B}",'k','k'],
["\x{05DB}",'kh','x'],
["\x{05DA}",'kh','x'],
["\x{05DC}",'l','l'], # TODO: ʎ
["\x{05DE}",'m','m'],
["\x{05DD}",'m','m'],
["\x{05E0}",'n','n'],
["\x{05DF}",'n','n'], # TODO: ŋ, m
["\x{05E1}",'s','s'],
["\x{05E2}",'e','ɛ'], # TODO: ə
["\x{FB44}",'p','p'],
["\x{FB4E}",'f','f'],
["\x{05E3}",'f','f'],
["\x{05BF}",'f','f'],
["\x{05E6}",'ts','ts'],
["\x{05E5}",'ts','ts'],
["\x{05E7}",'k','k'],
["\x{05E8}",'r','ʀ'],
["\x{05E9}",'sh','ʃ'],
["\x{FB2B}",'s','s'],
["\x{FB4A}",'t','t'],
["\x{05EA}",'s','s'],
];

$vowels = [
["\x{FB2E}",'a'],
["\x{FB2F}",'o'],
["\x{05D5}",'u'],
["\x{FB35}",'u'],
["\x{05F1}",'oy'],
# TODO "\x{05D9}" HEBREW LETTER YOD|י|y, i|y, i|j, i|j, i|yud|Consonantal [j] when the first character in a syllable. Vocalic [i] otherwise.
["\x{FB1D}",'i'],
["\x{05F2}",'ey'],
["\x{FB1F}",'ay'],
["\x{05E2}",'e'],
];

$consonants = [
["\x{05D1}",'b'],
["\x{FB4C}",'v'],
["\x{05D2}",'g'],
["\x{05D3}",'d'],
["\x{05D4}",'h'],
["\x{05F0}",'v'],
["\x{05D6}",'z'],
["\x{05D7}",'kh'],
["\x{05D8}",'t'],
["\x{FB3B}",'k'],
["\x{05DB}",'kh'],
["\x{05DA}",'kh'],
["\x{05DC}",'l'],
["\x{05DE}",'m'],
["\x{05DD}",'m'],
["\x{05E0}",'n'],
["\x{05DF}",'n'],
["\x{05E1}",'s'],
["\x{FB44}",'p'],
["\x{FB4E}",'f'],
["\x{05E3}",'f'],
["\x{05BF}",'f'],
["\x{05E6}",'ts'],
["\x{05E5}",'ts'],
["\x{05E7}",'k'],
["\x{05E8}",'r'],
["\x{05E9}",'sh'],
["\x{FB2B}",'s'],
["\x{FB4A}",'t'],
["\x{05EA}",'s'],
];

$consonants_2 = [

["\x{05D3}",'d'],
["\x{05D6}",'z'],
["\x{05D8}",'t'],
["\x{05DC}",'l'],
["\x{05E0}",'n'],
["\x{05E1}",'s'],
#["\x{FB4A}",'t'],
];
}

1;

__END__

=encoding utf-8

=head1 NAME

Lingua::YI::Romanize - Transliterate Yiddish from Hebrew to Latin script

=begin html

<a href="https://travis-ci.org/wollmers/Lingua-YI-Romanize"><img src="https://travis-ci.org/wollmers/Lingua-YI-Romanize.png" alt="Lingua-YI-Romanize"></a>
<a href='https://coveralls.io/r/wollmers/Lingua-YI-Romanize?branch=master'><img src='https://coveralls.io/repos/wollmers/Lingua-YI-Romanize/badge.png?branch=master' alt='Coverage Status' /></a>
<a href='http://cpants.cpanauthors.org/dist/Lingua-YI-Romanize'><img src='http://cpants.cpanauthors.org/dist/Lingua-YI-Romanize.png' alt='Kwalitee Score' /></a>
<a href="http://badge.fury.io/pl/Lingua-YI-Romanize"><img src="https://badge.fury.io/pl/Lingua-YI-Romanize.svg" alt="CPAN version" height="18"></a>

=end html

=head1 SYNOPSIS

  use Lingua::YI::Romanize;
  my $romanized_text = Lingua::YI::Romanize->yivo2latn($text);

  my $phonetic_text = Lingua::YI::Romanize->yivo2ipa($text);


=head1 DESCRIPTION

Lingua::YI::Romanize transliterates Yiddish text written in Hebrew script
to the Latin script or to IPA (International Phonetic Alphabet).

=head2 CONSTRUCTOR

=over 4

=item new()

Creates a new object which maintains internal storage areas
for the Lingua::YI::Romanize computation.

=back

=head2 METHODS

=over 4


=item yivo2latn($text)

Returns a string transliterated to Latin characters. Transliteration follows YIVO.

$text must be in character mode. $text is first normalized to
NFC (Unicode Normalization Form Composed), then normalized to Yiddish precomposed characters.

=item yivo2ipa($text)

Returns a string transliterated to IPA. Transliteration follows WWS (The Worlds Writing Systems).

$text must be in character mode. $text is first normalized to
NFC (Unicode Normalization Form Composed), then normalized to Yiddish precomposed characters.

=back

=head2 EXPORT

None by design.

=head1 STABILITY

Until release of version 1.00 the included methods, names of methods and their
interfaces are subject to change.

Beginning with version 1.00 the specification will be stable, i.e. not changed between
major versions.


=head1 SOURCE REPOSITORY

L<http://github.com/wollmers/Lingua-YI-Romanize>

=head1 AUTHOR

Helmut Wollmersdorfer E<lt>helmut.wollmersdorfer@gmail.comE<gt>

=begin html

<a href='http://cpants.cpanauthors.org/author/wollmers'><img src='http://cpants.cpanauthors.org/author/wollmers.png' alt='Kwalitee Score' /></a>

=end html

=head1 COPYRIGHT

Copyright 2016 Helmut Wollmersdorfer

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO


=cut

