#!perl
use 5.14.0;
use strict;
use utf8;
use open ':std', ':encoding(UTF-8)';
use warnings FATAL => 'all';
use Test::More 0.82;
use Map::Tube::Beijing;

eval 'use Test::Map::Tube tests => 3';
plan skip_all => 'Test::Map::Tube required for this test' if $@;

my $map = new_ok( 'Map::Tube::Beijing' => [ nametype => 'alt' ]);

ok_map_functions($map);

my @routes = <DATA>;
ok_map_routes( $map, \@routes );

__DATA__
Route 1|雍和宫|动物园|雍和宫, 安定门, 鼓楼大街, 积水潭, 平安里, 新街口, 西直门, 动物园
Route 2|雍和宫|金台夕照|雍和宫, 东直门, 东四十条, 朝阳门, 东大桥, 呼家楼, 金台夕照
