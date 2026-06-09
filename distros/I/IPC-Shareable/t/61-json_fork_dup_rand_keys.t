use warnings;
use strict;

# Test the fix to a bug where a random SHM key wasn't being created inside
# of a fork()

# It also regression tests a fix in global_register() where writing to the same
# hash from two procs didn't update the global_register properly

use IPC::Shareable qw(:lock);
IPC::Shareable->testing_set('IPC::Shareable');
use Test::More;
use Test::SharedFork;

use FindBin;
use lib $FindBin::Bin;
use IPCShareableTest qw(assert_clean_process unique_glue);

BEGIN {
    if (! $ENV{ASYNC_TESTING}) {
        plan skip_all => "Developer only test... needs Async::Event::Interval";
    }
}

use Async::Event::Interval;

{
    tie my %shared_data, 'IPC::Shareable', {
        key     => unique_glue('fork rand dup keys'),
        create  => 1,
        serializer => 'json',
        destroy => 1
    };

    my $event_one = Async::Event::Interval->new(0, sub {
        tied(%shared_data)->lock;
        $shared_data{$$}{called}++;
        tied(%shared_data)->unlock;
    });
    my $event_two = Async::Event::Interval->new(0, sub {
        tied(%shared_data)->lock;
        $shared_data{$$}{called}++;
        tied(%shared_data)->unlock;
    });

    $event_one->start;
    $event_two->start;

    sleep 1;

    $event_one->stop;
    $event_two->stop;

    my $one_pid = $event_one->pid;
    my $two_pid = $event_two->pid;

    is exists $shared_data{$one_pid}{called}, 1, "json: Event one got a rand shm key ok";
    is exists $shared_data{$two_pid}{called}, 1, "json: Adding srand() ensures _shm_key_rand() gives out rand key in fork()";

    IPC::Shareable::clean_up_all;
}

Async::Event::Interval::_end;
IPC::Shareable::_end;

assert_clean_process();

done_testing();
