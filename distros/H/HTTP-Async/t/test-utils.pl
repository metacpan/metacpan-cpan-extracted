use strict;
use warnings;

use Time::HiRes qw(time);

{
    my $start_time = undef;

    sub reset_timer { return $start_time = time; }

    sub delay_lt_ok ($$) { return delay_ok( '<',  @_ ); }
    sub delay_le_ok ($$) { return delay_ok( '<=', @_ ); }
    sub delay_ge_ok ($$) { return delay_ok( '>=', @_ ); }
    sub delay_gt_ok ($$) { return delay_ok( '>',  @_ ); }

    sub delay_ok ($$$) {
        my ( $cmp, $delay, $message ) = @_;

        my $timer = time - $start_time;

        my $display_test = sprintf '%.2f %s %.2f', $timer, $cmp, $delay;
        return cmp_ok $timer, $cmp, $delay, "$message ($display_test)";
    }
}

1;
