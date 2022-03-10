use warnings;
use strict;

use IPC::Shareable;
use Test::More;

BEGIN {
    if (! $ENV{CI_TESTING}) {
        plan skip_all => "Not on a legit CI platform...";
    }
}

warn "Segs Before: " . IPC::Shareable::ipcs() . "\n" if $ENV{PRINT_SEGS};

my $k = tie my $sv, 'IPC::Shareable', {
    create => 1,
    destroy => 1,
    size => 1,
};

my $ok = eval {
    $sv = "more than one byte";
    1;
};

is $ok, undef, "Overwriting the byte boundary size of an shm barfs ok";
like $@, qr/exceeds shared segment size/, "...and the error is sane";

(tied $sv)->clean_up_all;

IPC::Shareable::_end;
warn "Segs After: " . IPC::Shareable::ipcs() . "\n" if $ENV{PRINT_SEGS};

done_testing();
