use warnings;
use strict;

use IPC::Shareable;
use Test::More;
use Test::SharedFork;

my $segs_before = IPC::Shareable::seg_count();
my $sems_before = IPC::Shareable::sem_count();
warn "Segs Before: $segs_before\n" if $ENV{PRINT_SEGS};

my $protect_lock = 441;

# Test: re-attaching to a protected segment in the same process auto-populates
# the protected attribute from the semaphore.
{
    tie my %p, 'IPC::Shareable', {
        key       => 'pp66a',
        create    => 1,
        exclusive => 1,
        destroy   => 0,
        protected => $protect_lock,
        serializer => 'storable',
    };
    $p{val} = 'same_proc';

    # Attach again (no protected specified)
    tie my %p2, 'IPC::Shareable', {
        key    => 'pp66a',
        create => 0,
        serializer => 'storable',
    };

    is tied(%p2)->attributes('protected'), $protect_lock,
        "Same-process re-attach: protected auto-populated from semaphore ok";

    is $p2{val}, 'same_proc',
        "Same-process re-attach: can read segment data ok";

    IPC::Shareable->clean_up_protected($protect_lock);
}

# Test: attaching from a forked child process auto-populates protected even
# when the caller omits the protected option. child's clean_up_all then
# correctly skips the segment.
{
    my $awake = 0;
    local $SIG{ALRM} = sub { $awake = 1 };

    my $pid = fork;
    die "Cannot fork: $!" unless defined $pid;

    if ($pid == 0) {
        # child: wait for parent to create segment then attach
        sleep unless $awake;

        tie my %child_p, 'IPC::Shareable', {
            key    => 'pp66b',
            create => 0,
            serializer => 'storable',
        };

        is tied(%child_p)->attributes('protected'), $protect_lock,
            "Child: protected auto-populated from semaphore when attaching with create=>0 ok";

        is $child_p{val}, 'cross_proc',
            "Child: can read protected segment data ok";

        # clean_up_all should skip this segment because protected was
        # restored from the semaphore.
        IPC::Shareable->clean_up_all;

        exit(0);
    }
    else {
        # parent: create the protected segment, wake child, then verify
        tie my %p, 'IPC::Shareable', {
            key       => 'pp66b',
            create    => 1,
            exclusive => 1,
            destroy   => 0,
            protected => $protect_lock,
            serializer => 'storable',
        };
        $p{val} = 'cross_proc';

        kill ALRM => $pid;
        waitpid($pid, 0);

        # Segment must have survived child's clean_up_all
        is $p{val}, 'cross_proc',
            "Parent: protected segment data intact after child's clean_up_all ok";

        is tied(%p)->attributes('protected'), $protect_lock,
            "Parent: protected attribute unchanged after child's clean_up_all ok";

        IPC::Shareable->clean_up_protected($protect_lock);
    }
}

IPC::Shareable::_end;

my $segs_after = IPC::Shareable::seg_count();
warn "Segs After: $segs_after\n" if $ENV{PRINT_SEGS};
is $segs_after, $segs_before, "All segs cleaned up ok";
my $sems_after = IPC::Shareable::sem_count();
is $sems_after, $sems_before, "All semaphore sets cleaned up ok";

done_testing();
