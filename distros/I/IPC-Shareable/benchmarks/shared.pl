use warnings;
use strict;

use Async::Event::Interval;
use IPC::Shareable;

tie my %shared_data, 'IPC::Shareable', {
    key         => '123456789',
    create      => 1,
    destroy     => 1
};

$shared_data{called_count}{$$}++;

my $event_one = Async::Event::Interval->new(0.2, \&update);
my $event_two = Async::Event::Interval->new(1, \&update);

$event_one->start;
$event_two->start;

sleep 5;

$event_one->stop;
$event_two->stop;

for my $pid (keys %{ $shared_data{called_count} }) {
    printf(
        "Process ID %d executed %d times\n",
        $pid,
        $shared_data{called_count}->{$pid}
    );
}

for my $event ($event_one, $event_two) {
    printf(
        "Event ID %d with PID %d ran %d times, with %d errors and an interval" .
        " of %.2f seconds\n",
        $event->id,
        $event->pid,
        $event->runs,
        $event->errors,
        $event->interval
    );
}


sub update {
    # Because each event runs in its own process, $$ will be set to the
    # process ID of the calling event, even though they both call this
    # same function

    $shared_data{called_count}->{$$}++;
}

END {
    (tied %shared_data)->clean_up_all;
}