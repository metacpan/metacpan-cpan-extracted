package GoodMap;

use 5.006;
use Moo;
use namespace::clean;

has xml => (is => 'ro', default => sub { File::Spec->catfile('t', 'good-map.xml') });
with 'Map::Tube';

package BadMap;

use 5.006;
use Moo;
use namespace::clean;

has json => (is => 'ro', default => sub { File::Spec->catfile('t', 'bad-map.json') });
with 'Map::Tube';

package main;

use 5.006;
use strict; use warnings;
use Test::More;

my $min_ver = 0.22;
eval "use Test::Map::Tube $min_ver tests => 1";
plan skip_all => "Test::Map::Tube $min_ver required." if $@;

local $SIG{__WARN__} = sub { };
not_ok_map(BadMap->new);
