#!perl -w

use warnings;
use strict;
use Test::More;

use File::Spec;

my @tests = qw(
    gelem-good.pl
    if-then-good.pl
    in-out-branch-bad.pl
    in-out-branch-good.pl
    int-then-string-bad.pl
    simple.pl
    transitive-bad.pl
    transitive-good.pl
    unify-glob-bad.pl
    unify-glob-good.pl
);

plan tests => scalar @tests;

for my $test ( sort @tests ) {
    my $filename = File::Spec->catdir( "t", "samples", $test );

    my $command = "$^X -Mblib -MO=TypeCheck,-main $filename";
    if ( $ENV{TEST_VERBOSE} ) {
        diag $command;
    }
    else {
        $command .= " > /dev/null 2&>1";
    }

    my $exitval = system($command);
    if ($test =~ /-bad\.pl$/) {
        isnt( $exitval, 0, "$test should fail" );
    } else {
        is( $exitval, 0, "$test should pass" );
    }
}
