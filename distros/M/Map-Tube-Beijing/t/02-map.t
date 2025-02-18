#!perl
use 5.12.0;
use strict;
use utf8;
use warnings FATAL => 'all';
use Test::More 0.82;
use Map::Tube::Beijing;

eval 'use Test::Map::Tube tests => 3';
plan skip_all => 'Test::Map::Tube required for this test' if $@;
my $map = new_ok( 'Map::Tube::Beijing' );

ok_map_functions($map);

my @routes = <DATA>;
ok_map_routes( $map, \@routes );

__DATA__
Route 1|Yonghegong Lama Temple|Beijing Zoo|Yonghegong Lama Temple, Andingmen, Gulou Dajie, Jishuitan, Ping'anli, Xinjiekou, Xizhimen, Beijing Zoo
Route 2|yonghegong lama temple|JINTAI XIZHAO|Yonghegong Lama Temple, Dongzhimen, Dongsi Shitiao, Chaoyangmen, Dongdaqiao, Hujialou, Jintai Xizhao
