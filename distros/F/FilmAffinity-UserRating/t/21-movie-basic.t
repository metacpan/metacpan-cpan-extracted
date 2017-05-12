use strict;
use warnings;

use Test::More tests => 2;

use_ok('FilmAffinity::Movie');

my $faMovie = FilmAffinity::Movie->new( id => 932476 );

is($faMovie->id(), 932476, 'same id');
