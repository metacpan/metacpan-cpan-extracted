use warnings;
use strict;

use Carp;
use Data::Dumper;
use IPC::Shareable;
IPC::Shareable->testing_set('IPC::Shareable');
use IPC::Shareable::SharedMem;
use Test::More;

use FindBin;
use lib $FindBin::Bin;
use IPCShareableTest qw(
    assert_clean_process barrier_new barrier_release barrier_wait unique_glue
);
use Test::SharedFork;


sub shm_cleaned {
    # shmread fails with EINVAL when the segment has been removed
    my $id = shift;
    my $data = '';
    shmread($id, $data, 0, 6);
    return $!{EINVAL} ? 1 : 0;
}

# create not sent in
{
    my $ret = eval { my $s = tie(my $sv, 'IPC::Shareable', unique_glue('child_sv'), { destroy => 0 , serializer => 'storable' }); 1; };
    is $ret, undef, "We croak if a key is specified, create is not called and no segment exists";
    like $@, qr/ERROR: Could not acquire/, "...and error message is sane";
}

# remove() (default IPC_PRIVATE)
{
    my $s = tie my $sv, 'IPC::Shareable', { destroy => 0 , serializer => 'storable' };
    $sv = 'foobar';
    is $sv, 'foobar', "Default (IPC_PRIVATE) SV set and value is 'foobar'";

    my $id = $s->seg->id;

    my $global = $s->global_register;
    my $process = $s->process_register;

    is keys %$global, 1, "Global register has one entry ok";
    is keys %$process, 1, "Process register has one entry ok";

    is exists $global->{$id}, 1, "ID $id exists in global register";
    is exists $global->{$id}, 1, "ID $id exists in process register";

    $s->remove;

    is shm_cleaned($id), 1, "Default (IPC_PRIVATE) seg id $id removed after remove() ok";

    is keys %$global, 0, "Global register cleaned after remove()";
    is keys %$process, 0, "Process register cleaned after remove()";
}

# remove()
{
    my $s = tie my $sv, 'IPC::Shareable', unique_glue('test'), { create => 1, destroy => 0 , serializer => 'storable' };
    $sv = 'foobar';
    is $sv, 'foobar', "SV set and value is 'foobar'";

    my $id = $s->seg->id;

    my $global = $s->global_register;
    my $process = $s->process_register;

    is keys %$global, 1, "Global register has one entry ok";
    is keys %$process, 1, "Process register has one entry ok";

    is exists $global->{$id}, 1, "ID $id exists in global register";
    is exists $global->{$id}, 1, "ID $id exists in process register";

    $s->remove;

    is shm_cleaned($id), 1, "seg id $id removed after remove() ok";

    is keys %$global, 0, "Global register cleaned after remove()";
    is keys %$process, 0, "Process register cleaned after remove()";
}

# clean_up()
{
    my $s = tie my $sv, 'IPC::Shareable', unique_glue('test'), { create => 1, destroy => 0 , serializer => 'storable' };
    $sv = 'foobar';
    is $sv, 'foobar', "SV set and value is 'foobar'";

    my $id = $s->seg->id;

    my $global = $s->global_register;
    my $process = $s->process_register;

    is keys %$global, 1, "Global register has one entry ok";
    is keys %$process, 1, "Process register has one entry ok";

    is exists $global->{$id}, 1, "ID $id exists in global register";
    is exists $global->{$id}, 1, "ID $id exists in process register";

    $s->clean_up;

    is shm_cleaned($id), 1, "seg id $id removed after clean_up() ok";

    is keys %$global, 0, "Global register cleaned after clean_up()";
    is keys %$process, 0, "Process register cleaned after clean_up()";
}

# clean_up_all()
{
    my $s = tie my $sv, 'IPC::Shareable', unique_glue('test'), { create => 1, destroy => 0 , serializer => 'storable' };
    $sv = 'foobar';
    is $sv, 'foobar', "SV set and value is 'foobar'";

    my $id = $s->seg->id;

    my $global = $s->global_register;
    my $process = $s->process_register;

    is keys %$global, 1, "Global register has one entry ok";
    is keys %$process, 1, "Process register has one entry ok";

    is exists $global->{$id}, 1, "ID $id exists in global register";
    is exists $global->{$id}, 1, "ID $id exists in process register";

    $s->clean_up_all;

    is shm_cleaned($id), 1, "seg id $id removed after clean_up_all() ok";

    is keys %$global, 0, "Global register cleaned after clean_up_all()";
    is keys %$process, 0, "Process register cleaned after clean_up_all()";
}

my ($z, $y, $x, $w);

# parent/child
{
    my $ready = barrier_new();   # parent -> child: segment created

    my $pid = fork;
    defined $pid or die "Cannot fork : $!";

    if ($pid == 0) {
        # child

        barrier_wait($ready);

        my $s = tie(my $sv, 'IPC::Shareable', unique_glue('kids'), { destroy => 0 , serializer => 'storable' });
        $sv = 'baz';

        is $sv, 'baz', "SV initialized and set to 'baz' ok";

        IPC::Shareable->clean_up;

        my $data = '';
        my $id = $s->seg->id;

        shmread($id, $data, 0, length('IPC::Shareable'));
        is $data, 'IPC::Shareable', "Shared memory alive ok in child";

        $s->clean_up;

        is shm_cleaned($id), 0, "after clean_up(), all is well ok in child, we don't clean up what isn't ours";

        shmread($id, $data, 0, length('IPC::Shareable'));
        is $data, 'IPC::Shareable', "SV doesn't get wiped if in a different proc w/clean_up()";

        exit;
    }
    else {
        # parent

        my $s = tie(my $sv, 'IPC::Shareable', unique_glue('kids'), { create => 1, destroy => 0 , serializer => 'storable' });

        barrier_release($ready);
        my $id = $s->seg->id;
        waitpid($pid, 0);

        is shm_cleaned($id), 0, "ID $id was not cleaned up in the child";

        is keys %{ $s->global_register }, 1, "Global register set before clean_up_all()";
        is keys %{ $s->process_register }, 1, "Process register set before clean_up_all()";

        IPC::Shareable->clean_up_all;

        is keys %{ $s->global_register }, 0, "Global register cleaned with clean_up_all()";
        is keys %{ $s->process_register }, 0, "Process register cleaned with clean_up_all()";
    }
}

IPC::Shareable::_end;

assert_clean_process();

# remove($key) warns when shmget fails for a non-existent key
{
    my $warnings = [];
    local $SIG{__WARN__} = sub { push @$warnings, @_ };

    IPC::Shareable->remove('0x1B0BFFFE');  # key never created

    is scalar(@$warnings), 1,
        "remove(non-existent key): emits exactly one warning";
    like $warnings->[0], qr/shmget failed/,
        "remove(non-existent key): warning mentions shmget failed";
}

# remove() (object form) warns when sem->remove fails
{
    # destroy => 0: the shm segment is already gone after $k->remove, so no
    # double-remove on scope exit.  Save the semaphore before mocking so we can
    # clean it up manually after the block (mock prevents normal cleanup).
    my $k = tie my %h, 'IPC::Shareable', { key => unique_glue('TE'), create => 1, destroy => 0 , serializer => 'storable' };
    $h{a} = 1;

    my $orphan_sem = $k->sem;

    my @seen_warnings;
    local $SIG{__WARN__} = sub { push @seen_warnings, @_ };

    {
        # Override IPC::Semaphore::remove via local typeglob, not Mock::Sub:
        # Mock::Sub 1.08 (on some CPAN testers) returns the call args for
        # return_value => undef, so sem->remove looked like it succeeded and the
        # warn path never fired. Bare `return` = failure in any context; no
        # warnings 'redefine' is block-scoped so real redefines warn.
        no warnings 'redefine';
        local *IPC::Semaphore::remove = sub { return };
        $k->remove;
    }

    # Mock is now out of scope; remove the orphaned semaphore that the mock left behind.
    $orphan_sem->remove;

    # undef return from sem->remove also triggers two 'uninitialized value'
    # warnings (from != and ne comparisons), so filter to the one we care about.
    my @sem_warns = grep { /Couldn't remove semaphore set/ } @seen_warnings;
    is scalar(@sem_warns), 1,
        "remove() object form: emits a 'Couldn't remove semaphore set' warning when sem->remove fails";
    like $sem_warns[0], qr/Couldn't remove semaphore set/,
        "remove() object form: warning message is correct";
}

done_testing();
