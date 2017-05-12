package Lingua::JA::Sort::ReadableKey;

use 5.006;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw( kanji_to_kana japanese_pronunciation japanese_sort_order );
our $VERSION = '0.01';
use Encode;
use Encode::JP;

my $repeat = qr/[\x{3033}\x{309d}\x{30fd}]/;
my $voiced_repeat = qr/[\x{309e}\x{30fe}]/;

my %romanize;
my %rank;
while (<DATA>) {
    Encode::_utf8_on($_);
    /^(\w)\s+(\w+\d)/ or die "Bad line $_";
    $romanize{$1} = $2;
    $rank{$2} = $.;
}

sub japanese_sort_order {
    my $string = _key(shift);
    $string =~ s#([A-Za-z]+\d)#exists $rank{$1} ? chr(33+$rank{$1}) : $1#eg;
    return $string;
}

my %mutations = (qw(
    K    G
    T    D
    S    Z
    H    B
));
sub japanese_pronunciation {
    my $string = _key(shift);
    $string =~ s/\/.*?$//;
    # First deal with tenten
    $string =~ s/0//g;
    while (my ($k,$v) = each %mutations) {
        $string =~ s/$k(.)1/$v$1/g;
    }
    $string =~ s/H(.)2/p$1/g;
    $string =~ s/ZI/JI/g;
    # Now geminate consonants
    $string =~ s/tu(.)/$1$1/g;
    # Now smallchars
    $string =~ s/(.)(y?[aeiou])/$2/g;

    # Finally, Kunreishiki->Hepburn
    $string = lc $string;
    $string =~ s/si/shi/g;
    $string =~ s/sy/sh/g;
    $string =~ s/jy/j/g;
    $string =~ s/ti/chi/g;
    $string =~ s/tu/tsu/g;
    $string =~ s/n([bp])/m$1/g;
    return $string;
}

sub kanji_to_kana {
    my $string = shift;
    return $string unless /[\x{4e00}-\x{9fff}]/;
    require Text::ChaSen;
    my $string_euc = encode("euc-jp", $string);
    Text::ChaSen::getopt_argv('chasen-perl', '-F', '%a0');
    $string = decode("euc-jp", Text::ChaSen::sparse_tostr($string_euc)) 
              || return $string;
    chomp $string;
    $string =~ tr/\x{30fc}/\x{30a6}/; # Hack
    $string =~ tr/\x{30a1}-\x{30ff}/\x{3041}-\x{309f}/;
    $string;
}

sub _key {
    my $string = shift;
    my $type = "hiragana";
    my $last = "";
    my @code;
    $string = kanji_to_kana($string);
    $string =~ s/(.)$repeat/$1$1/g;
    $string =~ s/(.)$voiced_repeat/$1.chr(1+ord($1))/eg;
    $type ="katakana" if $string =~ tr/\x{30a1}-\x{30ff}/\x{3041}-\x{309f}/;
    $string =~ s/(.)/exists $romanize{$1} ? $romanize{$1} : $1 /eg;
    return $string."/$type";
}
1;

=head1 NAME

Lingua::JA::Sort::ReadableKey - Sorting and Romanizing Japanese

=head1 SYNOPSIS

  use Lingua::JA::Sort::ReadableKey;
  for ( map { $_->[0] }
       sort { $a->[1] cmp $b->[1] }
        map { [ $_, japanese_sortorder($_) ] } @utf8 ) {

=head1 DESCRIPTION

First, does L<Lingua::JA::Sort::JIS> do what you want? Look at that
first.

It may not do what you want if you want

=over 3

=item *

Kanji phrases sorted in their reading order, rather than as a separate block.

=item *

A machine-readable or storable key so that comparisons and sorting can
be done by a non-Japanese-aware system later.

=back

This module uses C<Text::ChaSen> to do kanji-kana conversion, and then
produces a comparable ASCII key for sorting.

All text should be in "real" UTF-8 - that is, strings in Perl's internal
format with the UTF-8 flag on.

=head2 EXPORT

The following methods are exported:

=head3 kanji_to_kana

Use ChaSen to convert a kanji sequence into hiragana. You obviously need
to install ChaSen, and its Perl interface C<Text::ChaSen> to make this
work. You can get ChaSen from http://chasen.aist-nara.ac.jp/ and
C<Text::ChaSen> is bundled with it. If you have Debian, install the
packages "chasen" and "libtext-chasen-perl". This code will work with
both ChaSen1 and ChaSen2.

=head3 japanese_pronunciation

This turns a Japanese string into an ASCII representation of its
reading. You can't sort on this, because Japanese don't sort according
to the Latin alphabet, but you can use to label Japanese things for
people who can't read Japanese. This will automatically call
C<kanji_to_kana> if necessary to get the reading of kanji strings.

=head3 japanese_sort_order

This returns an ASCII string which represents, in some bizarre magic
encoding, the sort order of the Japanese input string, such that
comparing the C<japanese_sort_order> of two UTF-8 strings will tell you
how they should be sorted in a Japanese dictionary.

By "bizarre" and "magic", I mean that for each character, we find its
order in the Japanese alphabet, and then replace that with
C<chr(32+$order)> so that it can be compared with C<cmp>.

This also calls C<kanji_to_kana> if there are any kanji strings.

=head1 SEE ALSO

L<Lingua::JA::Sort::JIS>, L<Text::ChaSen>.

http://chasen.aist-nara.ac.jp/

=head1 AUTHOR

Simon Cozens, E<lt>simon@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Simon Cozens

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut

__DATA__
あ A0
ぁ a0
い I0
ぃ i0
う U0
え E0
ぇ e0
お O0
ぉ o0
か KA0
が KA1
き KI1
ぎ KI1
く KU0
ぐ KU1
け KE0
げ KE1
こ KO0
ご KO1
さ SA0
ざ SA1
し SI0
じ SI1
す SU0
ず SU1
せ SE0
ぜ SE1
そ SO0
ぞ SO1
た TA0
だ TA1
ち TI0
ぢ TI1
つ TU0
づ TU1
っ tu0
て TE0
で TE1
と TO0
ど TO1
な NA0
に NI0
ぬ NU0
ね NE0
の NO0
は HA0
ば HA1
ぱ HA2
ひ HI0
び HI1 
ぴ HI2
ふ HU0
ぶ HU1
ぷ HU2
へ HE0
べ HE1
ぺ HE2
ほ HO0
ぼ HO1
ぽ HO2
ま MA0
み MI0
む MU0
め ME0
も MO0
ら RA0
り RI0
る RU0
れ RE0
ろ RO0
や YA0
ゃ ya0
ゆ YU0
ゅ yu0
よ YO0
ょ yo0
わ WA0
を WO0
ん N0
