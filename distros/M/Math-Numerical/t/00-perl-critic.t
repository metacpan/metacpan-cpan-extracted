use strict;
use warnings;

use Test2::V0;

use English;
use File::Spec;

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
    skip_all($msg);
}

eval { use Test2::Tools::PerlCritic; };

if ( $EVAL_ERROR ) {
   my $msg = 'Test2::Tools::PerlCritic required to criticise code';
   skip_all($msg);
}

perl_critic_ok(([qw(lib)]));

done_testing;
