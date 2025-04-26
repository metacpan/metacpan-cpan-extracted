package InvalidMap;

use Moo;
use namespace::autoclean;

with 'Map::Tube';

package main;

use v5.14;
use strict;
use warnings;
use Test::More tests => 1;
use Test::Exception;

throws_ok { InvalidMap->new } qr/ERROR/;
