#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 8;

BEGIN {
    use_ok('Map::Tube::NYC'                          ) || print "Bail out!\n";
    use_ok('Map::Tube::NYC::Line::INDSixthAvenue'    ) || print "Bail out!\n";
    use_ok('Map::Tube::NYC::Line::INDEighthAvenue'   ) || print "Bail out!\n";
    use_ok('Map::Tube::NYC::Line::INDCrosstown'      ) || print "Bail out!\n";
    use_ok('Map::Tube::NYC::Line::IRTFlushing'       ) || print "Bail out!\n";
    use_ok('Map::Tube::NYC::Line::BMTCanarsie'       ) || print "Bail out!\n";
    use_ok('Map::Tube::NYC::Line::BMTNassauStreet'   ) || print "Bail out!\n";
    use_ok('Map::Tube::NYC::Line::IRTLexingtonAvenue') || print "Bail out!\n";
}

diag( "Testing Map::Tube::NYC $Map::Tube::NYC::VERSION, Perl $], $^X" );
