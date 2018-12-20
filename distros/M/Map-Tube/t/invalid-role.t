package InvalidMap;

use 5.006;
use Moo;
use namespace::autoclean;

with 'Map::Tube';

package main;

use 5.006;
use strict; use warnings;
use Test::More tests => 1;
use Test::Exception;

throws_ok { InvalidMap->new } qr/ERROR/;
