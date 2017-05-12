#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'MavenBuilds::Tasks::BuildWebappsWithMaven' ) || print "Bail out!\n";
}

diag( "Testing MavenBuilds::Tasks::BuildWebappsWithMaven $MavenBuilds::Tasks::BuildWebappsWithMaven::VERSION, Perl $], $^X" );
