#!perl -Tw

# This test verifies that there is a t/*.t file for every possible Lint error.

use Test::More 'no_plan';

BEGIN {
    use_ok( 'HTML::Lint::Error' );
}

my @errors = do { no warnings; keys %HTML::Lint::Error::errors };

isnt( scalar @errors, 0, 'There are at least some errors to be found.' );

for my $error ( @errors ) {
    my $filename = "t/$error.t";
    ok( -e $filename, "$filename exists" );
}
