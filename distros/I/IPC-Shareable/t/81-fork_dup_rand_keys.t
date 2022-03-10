use warnings;
use strict;

use IPC::Shareable;
use Test::More;

my $segs_before;

BEGIN {
    if (! $ENV{CI_TESTING}) {
        plan skip_all => "Not on a legit CI platform...";
    }

    if (! $ENV{RELEASE_TESTING}) {
        plan skip_all => "Developer only test...";
    }

    warn "Segs Before: " . IPC::Shareable::ipcs() . "\n" if $ENV{PRINT_SEGS};
    $segs_before = IPC::Shareable::ipcs();
}

use Async::Event::Interval;

{
    tie my %shared_data, 'IPC::Shareable', {
        key     => 'fork rand dup keys',
        create  => 1,
        destroy => 1
    };

    my $event_one = Async::Event::Interval->new(0, sub {$shared_data{$$}{called}++});
    my $event_two = Async::Event::Interval->new(0, sub {$shared_data{$$}{called}++});

    $event_one->start;
    $event_two->start;

    sleep 1;

    $event_one->stop;
    $event_two->stop;

    my $one_pid = $event_one->pid;
    my $two_pid = $event_two->pid;

    is exists $shared_data{$one_pid}{called}, 1, "Event one got a rand shm key ok";
    is exists $shared_data{$two_pid}{called}, 1, "Adding srand() ensures _shm_key_rand() gives out rand key in fork()";

    IPC::Shareable::clean_up_all;
}

Async::Event::Interval::_end;
IPC::Shareable::_end;

warn "Segs After: " . IPC::Shareable::ipcs() . "\n" if $ENV{PRINT_SEGS};
my $segs_after = IPC::Shareable::ipcs();

is $segs_after, $segs_before, "All segs, even those created in separate procs, cleaned up ok";

done_testing();
