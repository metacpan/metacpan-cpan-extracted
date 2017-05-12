#!/usr/bin/perl -w
use strict;

use Test::More tests => 3;

BEGIN {
    use_ok('Labyrinth::Plugin::Review');
    use_ok('Labyrinth::Plugin::Review::Retailers');
    use_ok('Labyrinth::Plugin::Review::Types');
}
