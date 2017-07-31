#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 27;

BEGIN {
    use_ok('Map::Tube::Exception')                          || print "Bail out!\n";
    use_ok('Map::Tube::Exception::MissingStationName')      || print "Bail out!\n";
    use_ok('Map::Tube::Exception::InvalidStationName')      || print "Bail out!\n";
    use_ok('Map::Tube::Exception::MissingStationId')        || print "Bail out!\n";
    use_ok('Map::Tube::Exception::InvalidStationId')        || print "Bail out!\n";
    use_ok('Map::Tube::Exception::MissingLineName')         || print "Bail out!\n";
    use_ok('Map::Tube::Exception::InvalidLineName')         || print "Bail out!\n";
    use_ok('Map::Tube::Exception::MissingNodeObject')       || print "Bail out!\n";
    use_ok('Map::Tube::Exception::InvalidNodeObject')       || print "Bail out!\n";
    use_ok('Map::Tube::Exception::MissingPluginGraph')      || print "Bail out!\n";
    use_ok('Map::Tube::Exception::DuplicateStationName')    || print "Bail out!\n";
    use_ok('Map::Tube::Exception::DuplicateStationId')      || print "Bail out!\n";
    use_ok('Map::Tube::Exception::FoundSelfLinkedStation')  || print "Bail out!\n";
    use_ok('Map::Tube::Exception::FoundMultiLinkedStation') || print "Bail out!\n";
    use_ok('Map::Tube::Exception::FoundMultiLinedStation')  || print "Bail out!\n";
    use_ok('Map::Tube::Exception::FoundUnsupportedMap')     || print "Bail out!\n";
    use_ok('Map::Tube::Exception::MissingSupportedMap')     || print "Bail out!\n";
    use_ok('Map::Tube::Exception::FoundUnsupportedObject')  || print "Bail out!\n";
    use_ok('Map::Tube::Exception::MissingSupportedObject')  || print "Bail out!\n";
    use_ok('Map::Tube::Exception::InvalidSupportedObject')  || print "Bail out!\n";
    use_ok('Map::Tube::Exception::InvalidLineId')           || print "Bail out!\n";
    use_ok('Map::Tube::Exception::MissingLineId')           || print "Bail out!\n";
    use_ok('Map::Tube::Exception::MissingPluginFuzzyFind')  || print "Bail out!\n";
    use_ok('Map::Tube::Exception::MissingPluginFormatter')  || print "Bail out!\n";
    use_ok('Map::Tube::Exception::InvalidLineColor')        || print "Bail out!\n";
    use_ok('Map::Tube::Exception::MissingMapData')          || print "Bail out!\n";
    use_ok('Map::Tube::Exception::MalformedMapData')        || print "Bail out!\n";
}

diag( "Testing Map::Tube::Exception $Map::Tube::Exception::VERSION, Perl $], $^X" );
