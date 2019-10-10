#! perl
use strict;
use warnings;
use Test::More;

diag "Dir::Flock test on $^O $]";
use_ok( 'Dir::Flock' );
diag "Time::HiRes VERSION is ",Time::HiRes->VERSION;
diag "d_hires_stat is ", &Time::HiRes::d_hires_stat;

done_testing();

__END__

Inadequately tested:

    Stealing lock from stale remote process
    Stealing lock from process owned by different user
    Stress testing

