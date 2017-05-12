use strict;
use warnings;
use lib 't';
require 'test-util.pl';
use Test::More;
use Encode;
use Encode::JP::Emoji;

my $table1 = read_tsv('t/docomo-table.tsv');
my $table2 = read_tsv('t/kddi-table.tsv');
my $table3 = read_tsv('t/softbank-table.tsv');
my $list1 = [map {chr hex $_} values %$table1];
my $list2 = [map {chr hex $_} values %$table2];
my $list3 = [map {chr hex $_} values %$table3];
my $list4 = google_list();
my $listjoin = [@$list1, @$list2, @$list3, @$list4];

plan tests => 4 * scalar @$listjoin;

my $sjis_none = 'x-sjis-e4u-none-pp';
foreach my $strS (@$listjoin) {
    my $hex  = sprintf '%04X' => ord $strS;
    my $octA = encode $sjis_none => $strS, Encode::FB_PERLQQ();
    is(lc $octA, lc shex($strS), "$sjis_none FB_PERLQQ $hex");
}

my $utf8_none = 'x-utf8-e4u-none-pp';
foreach my $strS (@$listjoin) {
    my $hex  = sprintf '%04X' => ord $strS;
    my $octA = encode $utf8_none => $strS, Encode::FB_PERLQQ();
    is(lc $octA, lc shex($strS), "$utf8_none FB_PERLQQ $hex");
}

foreach my $strS (@$listjoin) {
    my $hex  = sprintf '%04X' => ord $strS;
    my $sub  = sub { sprintf '[%04X]' => $_[0]; };
    my $octA = encode $sjis_none => $strS, $sub;
    is($octA, "[$hex]", "$sjis_none sub $hex");
}

foreach my $strS (@$listjoin) {
    my $hex  = sprintf '%04X' => ord $strS;
    my $sub  = sub { sprintf '[%04X]' => $_[0]; };
    my $octA = encode $utf8_none => $strS, $sub;
    is($octA, "[$hex]", "$utf8_none sub $hex");
}
