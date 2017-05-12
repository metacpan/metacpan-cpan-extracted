#!perl
use warnings;
use strict;

use Test::More tests => 4;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $des = Devel::Examine::Subs->new(
                            file => 't/sample.data',
                          );


my $run = $des->_run_end();
is ($run, undef, "_run_end() is undef when called out of context");

$run = $des->_run_end(1);
is ($run, 1, "_run_end() sets itself to true properly");

$run = $des->_run_end(0);
is ($run, 0, "_run_end() sets itself to false properly");

