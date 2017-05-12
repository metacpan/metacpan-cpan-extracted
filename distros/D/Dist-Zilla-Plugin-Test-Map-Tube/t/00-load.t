#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Dist::Zilla::Plugin::Test::Map::Tube') || print "Bail out!\n"; }
diag( "Testing Dist::Zilla::Plugin::Test::Map::Tube $Dist::Zilla::Plugin::Test::Map::Tube::VERSION, Perl $], $^X" );
