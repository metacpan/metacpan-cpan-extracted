#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Data::Kanji::Kanjidic ':all';
use Lingua::KO::Munja ':all';
binmode STDOUT, ":utf8";
my $k = parse_kanjidic ('/home/ben/data/edrdg/kanjidic');
my @o = kanjidic_order ($k);
my $max = 10;
for my $kanji (@o[0..$max]) {
    my $entry = $k->{$kanji};
    my $korean = $entry->{W};
    if (! $korean) {
	next;
    }
    my @hangul = map {roman2hangul ($_)} @$korean;
    print "$kanji: @hangul\n";
}
