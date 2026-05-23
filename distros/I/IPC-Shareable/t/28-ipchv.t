use warnings;
use strict;

use Carp;
use IPC::Shareable;
use Test::More;
use Test::SharedFork;

my $segs_before = IPC::Shareable::seg_count();
my $sems_before = IPC::Shareable::sem_count();
warn "Segs Before $segs_before\n" if $ENV{PRINT_SEGS};

#plan tests => 8;

my %shareOpts = (
		 create =>       'yes',
		 exclusive =>    0,
		 mode =>         0644,
		 destroy =>      'yes',
		 );

my $awake = 0;
local $SIG{ALRM} = sub { $awake = 1 };

my $pid = fork;
defined $pid or die "Cannot fork: $!";

if ($pid == 0) {
    # child

    sleep unless $awake;
    $awake = 0;

    my $ipch = tie my %hv, 'IPC::Shareable', "test", {
        create    => 'yes',
        exclusive => 0,
        mode      => 0644,
        destroy   => 0,
            serializer => 'storable',
    };

    for (qw(fee fie foe fum)) {
        $ipch->shlock();
        $hv{$_} = $$;
        $ipch->shunlock();
    }

    sleep unless $awake;

#    for (qw(fee fie foe fum)) {
#        is $hv{$_}, $$, "child: HV key $_ has val $$";
#    }

    my $parent = getppid;
    $parent == 1 and die "Parent process has unexpectedly gone away";

#    for (qw(eenie meenie minie moe)) {
#        is $hv{$_}, $parent, "child: HV key $_ has val $parent (parent PID)";
#    }
} else {
    # parent

    my $ipch = tie my %hv, 'IPC::Shareable', "test", {
        create    => 1,
        exclusive => 0,
        mode      => 0666,
        size      => 1024*512,
        destroy   => 'yes',
            serializer => 'storable',
    };

    %hv = ();

    kill ALRM => $pid;
    sleep 1;           # Allow time for child to process the signal before next ALRM comes in
    
    for (qw(eenie meenie minie moe)) {
        $ipch->shlock();
        $hv{$_} = $$;
        $ipch->shunlock();
    }

    kill ALRM => $pid;
    waitpid($pid, 0);

    for (qw(fee fie foe fum)) {
        is $hv{$_}, $pid, "storable: parent: HV $_ has val $pid";
    }

    for (qw(eenie meenie minie moe)) {
        is $hv{$_}, $$, "storable: parent: HV $_ has val $$";
    }
}

# serializer: json — only run from the parent (original child has no explicit exit)
if ($pid != 0) {
    my $awake2 = 0;
    local $SIG{ALRM} = sub { $awake2 = 1 };

    my $pid2 = fork;
    defined $pid2 or die "Cannot fork: $!";

    if ($pid2 == 0) {
        # child

        sleep unless $awake2;
        $awake2 = 0;

        my $ipch2 = tie my %hv, 'IPC::Shareable', "testj", {
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

        sleep unless $awake2;

        my $parent = getppid;
        $parent == 1 and die "Parent process has unexpectedly gone away";

        exit;
    } else {
        # parent

        my $ipch2 = tie my %hv, 'IPC::Shareable', "testj", {
            create     => 1,
            exclusive  => 0,
            mode       => 0666,
            size       => 1024*512,
            destroy    => 'yes',
            serializer => 'json',
        };

        %hv = ();

        kill ALRM => $pid2;
        sleep 1;

        for (qw(eenie meenie minie moe)) {
            $ipch2->shlock();
            $hv{$_} = $$;
            $ipch2->shunlock();
        }

        kill ALRM => $pid2;
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
    my $segs_after = IPC::Shareable::seg_count();
    warn "Segs After: $segs_after\n" if $ENV{PRINT_SEGS};
    is $segs_after, $segs_before, "All segs, even those created in separate procs, cleaned up ok";
    my $sems_after = IPC::Shareable::sem_count();
    is $sems_after, $sems_before, "All semaphore sets cleaned up ok";
    done_testing();
}

