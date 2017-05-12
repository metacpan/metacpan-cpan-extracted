#!/usr/bin/perl -w
use strict;

use Test::More tests => 3;

BEGIN {
	use_ok('Labyrinth::PSGI');
	use_ok('Labyrinth::Query::PSGI');
	use_ok('Labyrinth::Writer::Render::PSGI');
}
