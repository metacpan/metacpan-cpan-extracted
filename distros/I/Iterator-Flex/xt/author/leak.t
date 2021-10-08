#! perl

use Test::More;
use Test::LeakTrace;

use Iterator::Flex::Common qw[ igrep iarray ];

no_leaks_ok {

    my $iter = igrep { $_ > 0 } iarray( [ -20 .. 20 ] );

    1 while <$iter>;

};

done_testing;
