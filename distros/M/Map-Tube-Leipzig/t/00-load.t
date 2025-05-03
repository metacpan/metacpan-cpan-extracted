#!/usr/bin/perl

use v5.14;
use strict;
use warnings;
use Test::More tests => 3;

BEGIN {
    use_ok('Map::Tube::Leipzig'          ) || print "Bail out!\n";
    use_ok('Map::Tube::Leipzig::Line::S3') || print "Bail out!\n";
    use_ok('Map::Tube::Leipzig::Line::S7') || print "Bail out!\n";
}

diag( "Testing Map::Tube::Leipzig $Map::Tube::Leipzig::VERSION, Perl $], $^X" );
