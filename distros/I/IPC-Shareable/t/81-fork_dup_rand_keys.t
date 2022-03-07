use warnings;
use strict;

use Data::Dumper;
use IPC::Shareable;
use Test::More;

BEGIN {
    if (! $ENV{CI_TESTING}) {
        plan skip_all => "Not on a legit CI platform...";
    }

    my $async_loaded = eval {
        require Async::Event::Interval;
        1;
    };

    if (! $async_loaded) {
        plan skip_all => "Async::Event::Interval not loaded...";
    }
}

tie my %shared_data, 'IPC::Shareable', {
    key     => '123456789',
    create  => 1,
    destroy => 1
};

$shared_data{$$}{called}++;

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

(tied %shared_data)->remove;

done_testing();
