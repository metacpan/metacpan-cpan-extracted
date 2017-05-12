#!/usr/bin/perl -w
use strict;

use Test::More tests => 6;

BEGIN {
    use_ok('Labyrinth::Plugin::Survey');
    use_ok('Labyrinth::Plugin::Survey::Act::API');
    use_ok('Labyrinth::Plugin::Survey::Announce');
    use_ok('Labyrinth::Plugin::Survey::Course');
    use_ok('Labyrinth::Plugin::Survey::Talk');
    use_ok('Labyrinth::Plugin::Survey::YAPC');
}
