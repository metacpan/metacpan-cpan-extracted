#! perl
use strict;
use warnings;
use Test::More;

diag "Dir::Flock test on $^O $]";
use_ok( 'Dir::Flock' );
diag "";
diag "Time::HiRes VERSION is ",Time::HiRes->VERSION;
diag "d_hires_stat is ", &Time::HiRes::d_hires_stat;
if ($INC{"Dir/Flock/Mock.pm"}) {
    diag "Dir::Flock::Mock  loaded\n";
}

done_testing();

__END__

Inadequately tested:

    Respecting advisory lock from another process
    Stealing lock from stale remote process
    Stealing lock from process owned by different user
    Stress testing

