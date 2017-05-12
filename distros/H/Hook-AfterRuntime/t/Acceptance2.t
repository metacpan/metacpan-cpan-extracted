#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use vars qw/$TRIGGERED/;

BEGIN {
    package Test::A;
    use strict;
    use warnings;
    use Hook::AfterRuntime;

    sub import {
        after_runtime { $main::TRIGGERED++ };
    }

    $INC{'Test/A.pm'} = __FILE__;

    1;
}

BEGIN {
    package Test::B;
    use strict;
    use warnings;

    use Test::More;
    use Test::A;

    ok( !$main::TRIGGERED, "Not triggered yet." );

    $INC{'Test/B.pm'} = __FILE__;

    1;
}

use Test::B;

ok( $main::TRIGGERED, "triggered" );

done_testing();
