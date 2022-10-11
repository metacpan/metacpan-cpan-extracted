use strict;
use warnings;

use Test2::V0;

use English;

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
    skip_all($msg);
}

eval { use Test::Pod 1.00; };

if ( $EVAL_ERROR ) {
   my $msg = 'Test::Pod v1.0 required to check POD syntax';
   skip_all($msg);
}

all_pod_files_ok();
