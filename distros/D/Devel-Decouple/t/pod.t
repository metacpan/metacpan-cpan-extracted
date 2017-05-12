use strict;
use warnings;
use Test::More;

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::Pod; };

if ( $@ ) {
    my $msg = 'Test::Pod required to test POD syntax.';
    plan( skip_all => $msg );
}

Test::Pod::all_pod_files_ok();

