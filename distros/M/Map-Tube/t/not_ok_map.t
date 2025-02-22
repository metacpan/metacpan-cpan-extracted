package BadSample;

use 5.006;
use Moo;
use namespace::clean;

has xml => (is => 'ro', default => sub { return File::Spec->catfile('t', 'bad-sample.xml') });
with 'Map::Tube';

package main;

use 5.006;
use strict; use warnings;
use Test::Map::Tube tests => 1;

# local $SIG{__WARN__} = sub {};
not_ok_map_data(BadSample->new);
