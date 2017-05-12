# load_chmod.t
#
# Since perl v5.14 (or thereabouts), a warning is issued when the autodie
# pragma is used and &File::chmod::chmod doesn't match the prototype of (@)
# that CORE::chmod has.  Adding a prototype to &File::chmod::chmod silences
# the warning.  This test ensures that the prototype doesn't get lost
# somewhere in the future.

use strict;
use warnings;
use autodie;
use utf8;
use Test::More;

my $test_passed;
BEGIN {
    $test_passed = 1;
    $SIG{__WARN__} = sub {
        my $msg = shift;
        if ( $msg =~ m/Prototype\s+mismatch:\s+sub\s+main::chmod/i ) {
            $test_passed = 0;
        }
    };
}

use File::chmod;
ok( $test_passed, "Load File::chmod without 'Missing prototype' warning" );

done_testing;
