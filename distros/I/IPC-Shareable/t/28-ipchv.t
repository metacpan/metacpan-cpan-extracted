use warnings;
use strict;

use Carp;
use IPC::Shareable;
IPC::Shareable->testing_set('IPC::Shareable');
use Test::More;
use Test::SharedFork;

use FindBin;
use lib $FindBin::Bin;
use IPCShareableTest qw(
    assert_clean barrier_new barrier_release barrier_wait unique_glue
);

# A pipe-based barrier handshake (see IPCShareableTest::barrier_new) replaces
# the old SIGALRM/sleep handshake, which had a lost-wakeup race: a signal
# delivered between the "unless $awake" check and sleep() was dropped and the
# sleeper blocked forever (the FreeBSD smoker hang) or the two processes
# desynced (the long-double Linux undef reads). Each section walks the child
# and parent through three barriers: segment-ready (parent -> child),
# child-wrote (child -> parent), and parent-wrote (parent -> child). Waiting on
# child-wrote also replaces the old non-deterministic "sleep 1".

# --- serializer: storable -------------------------------------------------

my $seg_ready    = barrier_new();   # parent -> child: segment created
my $child_wrote  = barrier_new();   # child  -> parent: child's keys written
my $parent_wrote = barrier_new();   # parent -> child: parent's keys written

my $pid = fork;
defined $pid or die "Cannot fork: $!";

if ($pid == 0) {
    # child

    barrier_wait($seg_ready);

    my $ipch = tie my %hv, 'IPC::Shareable', unique_glue('test'), {
        create     => 'yes',
        exclusive  => 0,
        mode       => 0644,
        destroy    => 0,
        serializer => 'storable',
    };

    for (qw(fee fie foe fum)) {
        $ipch->shlock();
        $hv{$_} = $$;
        $ipch->shunlock();
    }

    barrier_release($child_wrote);
    barrier_wait($parent_wrote);

    my $parent = getppid;
    $parent == 1 and die "Parent process has unexpectedly gone away";
}
else {
    # parent

    my $ipch = tie my %hv, 'IPC::Shareable', unique_glue('test'), {
        create     => 1,
        exclusive  => 0,
        mode       => 0666,
        size       => 1024*512,
        destroy    => 'yes',
        serializer => 'storable',
    };

    %hv = ();

    barrier_release($seg_ready);
    barrier_wait($child_wrote);

    for (qw(eenie meenie minie moe)) {
        $ipch->shlock();
        $hv{$_} = $$;
        $ipch->shunlock();
    }

    barrier_release($parent_wrote);
    waitpid($pid, 0);

    for (qw(fee fie foe fum)) {
        is $hv{$_}, $pid, "storable: parent: HV $_ has val $pid";
    }

    for (qw(eenie meenie minie moe)) {
        is $hv{$_}, $$, "storable: parent: HV $_ has val $$";
    }
}

# --- serializer: json (parent only) ---------------------------------------

if ($pid != 0) {
    my $seg_ready2    = barrier_new();
    my $child_wrote2  = barrier_new();
    my $parent_wrote2 = barrier_new();

    my $pid2 = fork;
    defined $pid2 or die "Cannot fork: $!";

    if ($pid2 == 0) {
        # child

        barrier_wait($seg_ready2);

        my $ipch2 = tie my %hv, 'IPC::Shareable', unique_glue('testj'), {
            create     => 'yes',
            exclusive  => 0,
            mode       => 0644,
            destroy    => 0,
            serializer => 'json',
        };

        for (qw(fee fie foe fum)) {
            $ipch2->shlock();
            $hv{$_} = $$;
            $ipch2->shunlock();
        }

        barrier_release($child_wrote2);
        barrier_wait($parent_wrote2);

        my $parent = getppid;
        $parent == 1 and die "Parent process has unexpectedly gone away";

        exit;
    }
    else {
        # parent

        my $ipch2 = tie my %hv, 'IPC::Shareable', unique_glue('testj'), {
            create     => 1,
            exclusive  => 0,
            mode       => 0666,
            size       => 1024*512,
            destroy    => 'yes',
            serializer => 'json',
        };

        %hv = ();

        barrier_release($seg_ready2);
        barrier_wait($child_wrote2);

        for (qw(eenie meenie minie moe)) {
            $ipch2->shlock();
            $hv{$_} = $$;
            $ipch2->shunlock();
        }

        barrier_release($parent_wrote2);
        waitpid($pid2, 0);

        for (qw(fee fie foe fum)) {
            is $hv{$_}, $pid2, "json: parent: HV $_ has val $pid2";
        }

        for (qw(eenie meenie minie moe)) {
            is $hv{$_}, $$, "json: parent: HV $_ has val $$";
        }
    }
}

IPC::Shareable::_end;

if ($pid != 0) {
    assert_clean(unique_glue('test'), unique_glue('testj'));
    done_testing();
}
