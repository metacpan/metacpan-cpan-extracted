#!/usr/bin/perl -w
use strict;

use Test::More tests => 5;

BEGIN {
    use_ok('Labyrinth::Plugin::Event');
    use_ok('Labyrinth::Plugin::Event::Sponsors');
    use_ok('Labyrinth::Plugin::Event::Talks');
    use_ok('Labyrinth::Plugin::Event::Types');
    use_ok('Labyrinth::Plugin::Event::Venues');
}
