use warnings;
use strict;

use Data::Dumper;
use Test::More tests => 4;

BEGIN { use_ok('IPC::Shareable') };

warn "Segs Before: " . IPC::Shareable::ipcs() . "\n" if $ENV{PRINT_SEGS};
my $segs = IPC::Shareable::ipcs();
print "Starting with $segs segments\n";

is $segs, $segs, "Initial test ok";

{
    my $a = tie my $x, 'IPC::Shareable';
    my $b = tie my $y, 'IPC::Shareable', { create => 1, destroy => 1 };

    is $a->{_key}, 0, "tie with no glue or options is IPC_PRIVATE ok";
    is $b->{_key}, 0, "tie with no glue but with options is IPC_PRIVATE ok";

    if (!$ENV{CI_TESTING}) {
        done_testing();
        exit;
    }

    $a->remove;

    # Store existing segments in a shared hash to test against
    # at conclusion of test suite run

    tie my %store, 'IPC::Shareable', { key => 'async_tests', create => 1 };

    $store{segs} = $segs;
}

IPC::Shareable::_end;
warn "Segs After: " . IPC::Shareable::ipcs() . "\n" if $ENV{PRINT_SEGS};
