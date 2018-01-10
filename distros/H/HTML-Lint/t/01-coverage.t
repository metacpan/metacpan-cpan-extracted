#!perl -Tw

# This test verifies that there is a t/*.t file for every possible Lint error.

use strict;
use warnings;

use Test::More 'no_plan';

use HTML::Lint::Error;

my @errors = keys %HTML::Lint::Error::errors;

isnt( scalar @errors, 0, 'There are at least some errors to be found.' );

for my $error ( @errors ) {
    my $filename = "t/$error.t";
    ok( -e $filename, "$filename exists" );
}
