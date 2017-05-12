#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok( 'Dist::Zilla::PluginBundle::MANWAR') || print "Bail out!\n"; }
diag( "Testing Dist::Zilla::PluginBundle::MANWAR $Dist::Zilla::PluginBundle::MANWAR::VERSION, Perl $], $^X" );
