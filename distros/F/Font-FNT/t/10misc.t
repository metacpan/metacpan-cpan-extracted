
use strict;
use warnings;
use Test::More tests => 7;
BEGIN { use_ok 'Font::FNT' }

my $name = '1252_13x8_OEM';

my $fnt = Font::FNT->load_yaml("t/$name.yml");
ok( $fnt,'load_yaml');

$fnt->save_pbm("t/$name.pbm");
ok( -e "t/$name.pbm",'-e');

$fnt->save("t/$name.fnt");
ok( -e "t/$name.fnt",'-e');

my $fnt2 = Font::FNT->load("t/$name.fnt");
ok( $fnt2,'load');

my @stat = stat "t/$name.fnt";
is( $stat[7], $fnt2->{Size},"Size: $fnt2->{Size}");

$fnt2->save_yaml('t/test.yml');
ok( -e 't/test.yml','-e');
