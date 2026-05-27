use warnings;
use strict;

use Carp;
use IPC::Shareable;
IPC::Shareable->testing_set('IPC::Shareable');
use Test::More;
use Test::SharedFork;

my $segs_before = IPC::Shareable::seg_count();
my $sems_before = IPC::Shareable::sem_count();
warn "Segs Before: $segs_before\n" if $ENV{PRINT_SEGS};

# serializer: storable
{
    my $awake = 0;
    local $SIG{ALRM} = sub { $awake = 1 };

    my $pid = fork;
    defined $pid or die "Cannot fork: $!";

    if ($pid == 0) {
        # child

        sleep unless $awake;

        tie my %h, 'IPC::Shareable', { key => 'testing25', destroy => 0 , serializer => 'storable' };
        $h{a} = 'foo';
        exit;
    } else {
        # parent

        tie my %h, 'IPC::Shareable', {
            key     => 'testing25',
            create  => 1,
            destroy => 1,
                    serializer => 'storable',
        };

        $h{a} = 'bar';
        is $h{a}, 'bar', "storable: in parent: parent set HV to 'bar' ok";

        kill ALRM => $pid;
        waitpid($pid, 0);

        is $h{a}, 'foo', "storable: in parent: child set HV to 'foo' ok";

        IPC::Shareable->clean_up_all;
    }
}

# serializer: json
{
    my $awake = 0;
    local $SIG{ALRM} = sub { $awake = 1 };

    my $pid = fork;
    defined $pid or die "Cannot fork: $!";

    if ($pid == 0) {
        # child

        sleep unless $awake;

        tie my %h, 'IPC::Shareable', { key => 'testing25j', destroy => 0, serializer => 'json' };
        $h{a} = 'foo';
        exit;
    } else {
        # parent

        tie my %h, 'IPC::Shareable', {
            key        => 'testing25j',
            create     => 1,
            destroy    => 1,
            serializer => 'json',
        };

        $h{a} = 'bar';
        is $h{a}, 'bar', "json: in parent: parent set HV to 'bar' ok";

        kill ALRM => $pid;
        waitpid($pid, 0);

        is $h{a}, 'foo', "json: in parent: child set HV to 'foo' ok";

        IPC::Shareable->clean_up_all;
    }
}

IPC::Shareable::_end;

my $segs_after = IPC::Shareable::seg_count();
warn "Segs After: $segs_after\n" if $ENV{PRINT_SEGS};
is $segs_after, $segs_before, "All segs cleaned up ok";
my $sems_after = IPC::Shareable::sem_count();
is $sems_after, $sems_before, "All semaphore sets cleaned up ok";

done_testing();
