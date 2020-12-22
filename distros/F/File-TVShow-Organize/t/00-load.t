#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    if ($^O eq 'MSWin32') {
      BAIL_OUT("OS unsupported");
    };
    use_ok( 'File::TVShow::Organize' ) || print "Bail out!\n";
}

diag( "Testing File::TVShow::Organize $File::TVShow::Info::VERSION, Perl $], $^X" );
