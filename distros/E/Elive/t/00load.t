#!perl
use strict;
use warnings;
use Test::More;

use_ok('Elive'); # to get version

diag( "Testing Elive $Elive::VERSION, Perl $], $^X" );

my $MODULE = 'Test::Strict';
eval "use $MODULE";
if ($@) {
    diag "$MODULE not available for strict tests";
    done_testing();
}
else {
    all_perl_files_ok( 'lib', 'script' );
};

BAIL_OUT("unable to compile - aborting further tests")
    unless Test::More->builder->is_passing;
