#! perl
use strict;
use warnings;
use Test::More;

diag "Dir::Flock test on $^O $]";
use_ok( 'Dir::Flock' );
diag "";
diag "Time::HiRes VERSION is ",Time::HiRes->VERSION;

done_testing();

__END__

Inadequately tested:

    Synchronization over processes owned by different users
    Synchronization over multiple hosts
    Stress testing

