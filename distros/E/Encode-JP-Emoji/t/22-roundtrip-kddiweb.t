use strict;
use warnings;
use lib 't';
require 'test-util.pl';
use Test::More;
use Encode;
use Encode::JP::Emoji;

my $encode1 = 'x-sjis-emoji-kddiweb-pp';
my $encode2 = 'x-sjis-e4u-kddiweb-pp';
my $encode3 = 'x-utf8-e4u-kddiweb-pp';
my $table = read_tsv('t/kddi-table.tsv');
my @keys = sort {$a cmp $b} keys %$table;

plan tests => 4 * scalar @keys;

foreach my $sjisH (@keys) {
#   my $utf8H = $table->{$sjisH};                       # KDDI(A)
    my $utf8H = sprintf('%04X', hex($sjisH) - 1792);    # KDDI(B)
    my $strS  = chr hex $utf8H;
    my $octS  = pack 'H*' => $sjisH;
    my $strA  = decode($encode1, $octS);
    is(shex($strA), shex($strS), "1. $encode1 utf-8 string $sjisH $utf8H");
}

foreach my $sjisH (@keys) {
#   my $utf8H = $table->{$sjisH};                       # KDDI(A)
    my $utf8H = sprintf('%04X', hex($sjisH) - 1792);    # KDDI(B)
    my $strS  = chr hex $utf8H;
    my $octA  = encode($encode1, $strS);
    my $strB  = decode($encode1, $octA);
    is(ohex($strB), ohex($strS), "2. $encode1 roundtrip $utf8H");
}

foreach my $sjisH (@keys) {
    my $octS  = pack 'H*' => $sjisH;
    my $strA  = decode($encode2, $octS);
    my $octB  = encode($encode2, $strA);
    is(shex($octB), shex($octS), "3. $encode2 roundtrip $sjisH");
}

foreach my $sjisH (@keys) {
#   my $utf8H = $table->{$sjisH};                       # KDDI(A)
    my $utf8H = sprintf('%04X', hex($sjisH) - 1792);    # KDDI(B)
    my $octS  = encode utf8 => chr hex $utf8H;
    my $strA  = decode($encode3, $octS);
    my $octB  = encode($encode3, $strA);
    is(ohex($octB), ohex($octS), "4. $encode3 roundtrip $utf8H");
}
