use warnings;
use strict;

use Carp;
use Data::Dumper;
use IPC::Shareable;
use IPC::Shareable::SharedMem;
use Test::More;
use Test::SharedFork;

BEGIN {
    if (! $ENV{CI_TESTING}) {
        plan skip_all => "Not on a legit CI platform...";
    }
}

sub shm_cleaned {
    # --- shmread should barf if the segment has really been cleaned
    my $id = shift;
    my $data = '';

    eval { shmread($id, $data, 0, 6) or die "$!" };

    if ($@ && ($@ =~ /Invalid/ || $@ =~ /removed/)) {
        return 1;
    }

    return 0;
}

# create not sent in
{
    my $ret = eval { my $s = tie(my $sv, 'IPC::Shareable', 'child_sv', { destroy => 0 }); 1; };
    is $ret, undef, "We croak if a key is specified, create is not called and no segment exists";
    like $@, qr/ERROR: Could not acquire/, "...and error message is sane";
}

# remove() (default IPC_PRIVATE)
{
    my $s = tie my $sv, 'IPC::Shareable', { destroy => 0 };
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
    my $s = tie my $sv, 'IPC::Shareable', 'test', { create => 1, destroy => 0 };
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
    my $s = tie my $sv, 'IPC::Shareable', 'test', { create => 1, destroy => 0 };
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
    my $s = tie my $sv, 'IPC::Shareable', 'test', { create => 1, destroy => 0 };
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
    my $awake = 0;
    local $SIG{ALRM} = sub { $awake = 1 };

    my $pid = fork;
    defined $pid or die "Cannot fork : $!";

    if ($pid == 0) {
        # child

        sleep unless $awake;

        my $s = tie(my $sv, 'IPC::Shareable', 'kids', { destroy => 0 });
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

        my $s = tie(my $sv, 'IPC::Shareable', 'kids', { create => 1, destroy => 0 });

        kill ALRM => $pid;
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

done_testing();
