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

my $ok = eval {
    tie my $sv, 'IPC::Shareable', {key => 'test02', destroy => 1};
    1;
};

is $ok, undef, "We croak ok if create is not set and segment doesn't yet exist";
like $@, qr/Could not acquire/, "...and error is sane.";

IPC::Shareable::_end;

warn "Segs After: " . IPC::Shareable::ipcs() . "\n" if $ENV{PRINT_SEGS};

done_testing;

