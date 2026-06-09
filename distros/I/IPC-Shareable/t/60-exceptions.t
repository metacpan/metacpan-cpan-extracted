use warnings;
use strict;

use IPC::SysV qw(IPC_RMID);
use Mock::Sub;
use Test::More;

use FindBin;
use lib $FindBin::Bin;
use IPCShareableTest qw(assert_clean_process unique_glue);

#plan skip_all => "TEST FILE NOT READY";

use IPC::Shareable;
IPC::Shareable->testing_set('IPC::Shareable');


{
    # exclusive duplicate

    my $opts = {
        key       => unique_glue('k1234'),
        create    => 1,
        exclusive => 1,
        destroy   => 1,
        mode      => 0600,
        size      => 999,
        serializer => 'storable',
    };

    my $s = tie my %opt_test => 'IPC::Shareable', $opts;
    $opt_test{a} = 1;


    is
        eval {
            my $s = tie my %opt_test => 'IPC::Shareable', $opts;
            1;
        },
        undef,
        "trying to re-create an existing memory segment fails";

    like $@, qr/using exclusive/, "...and error message is sane";

}

IPC::Shareable::_end;

assert_clean_process();

# _decode_json: croaks when decode_json returns undef (mocked)
{
    tie my %h, 'IPC::Shareable', { create => 1, destroy => 1, serializer => 'json' };
    $h{a} = 1;  # write something so the segment has the IPC::Shareable tag

    # Use local typeglob override instead of Mock::Sub to avoid prototype mismatch
    # warnings (decode_json carries a ($) prototype). no warnings 'redefine' is
    # block-scoped so a genuine accidental redefine elsewhere still warns.
    no warnings 'redefine';
    local *IPC::Shareable::decode_json = sub { return undef };

    is eval { my $x = $h{a}; 1 }, undef,
        "_decode_json: croaks when decode_json returns undef";
    like $@, qr/Munged shared memory segment/,
        "_decode_json: error message mentions munged segment";
}

# _tie: limit check — croaks when size > SHMMAX_BYTES and limit => 1
{
    is
        eval { tie my %h, 'IPC::Shareable', { create => 1, destroy => 1, size => 2_000_000_000, limit => 1 , serializer => 'storable' }; 1 },
        undef,
        "_tie limit: croaks when size exceeds SHMMAX_BYTES";
    like $@, qr/larger than max size/,
        "_tie limit: error message mentions max size";
}

# _tie: fallthrough croak when SharedMem->new returns undef (create => 1, not exclusive)
{
    # Override SharedMem::new via local typeglob, not Mock::Sub: Mock::Sub 1.08
    # (on some CPAN testers) returns the call args for return_value => undef, so
    # the croak-on-undef path never fired. Bare `return` = failure in any
    # context; no warnings 'redefine' is block-scoped so real redefines warn.
    no warnings 'redefine';
    local *IPC::Shareable::SharedMem::new = sub { return };

    is
        eval { tie my %h, 'IPC::Shareable', { create => 1, destroy => 1 , serializer => 'storable' }; 1 },
        undef,
        "_tie: croaks when SharedMem->new returns undef";
    like $@, qr/Could not create shared memory segment/,
        "_tie: error message mentions shared memory segment";
}

# _tie: "Could not create semaphore set" when IPC::Semaphore->new returns undef
{
    my $key     = '0x1B0BFFF2';
    my $key_int = hex($key);

    {
        # Override IPC::Semaphore::new via local typeglob, not Mock::Sub:
        # Mock::Sub 1.08 (on some CPAN testers) returns the call args for
        # return_value => undef, so the croak-on-undef path never fired. Bare
        # `return` = failure in any context; no warnings 'redefine' is
        # block-scoped so real redefines warn.
        no warnings 'redefine';
        local *IPC::Semaphore::new = sub { return };

        is
            eval { tie my %h, 'IPC::Shareable', { key => $key, create => 1, destroy => 0 , serializer => 'storable' }; 1 },
            undef,
            "_tie: croaks when IPC::Semaphore->new returns undef";
        like $@, qr/Could not create semaphore set/,
            "_tie: error message mentions semaphore set";
    }

    # The segment was created before the semaphore set failed; _tie() now removes
    # it before croaking, so it is no longer orphaned.
    my $leaked_id = shmget($key_int, 0, 0);
    ok ! defined $leaked_id,
        "_tie: the just-created segment is removed, not orphaned, on sem-create failure";
    shmctl($leaked_id, IPC_RMID, 0) if defined $leaked_id;   # Safety net if it regresses
}

# _thaw: croaks when Storable::thaw returns undef (munged segment).
# Uses an aggregate (hash) tie: a scalar holding a plain value is now stored
# verbatim and never reaches _thaw, so the freeze/thaw path is exercised here.
{
    tie my %h, 'IPC::Shareable', { create => 1, destroy => 1 , serializer => 'storable' };
    %h = (k => 'hello');   # aggregate => Storable freeze (carries the tag)

    {
        # Override thaw via local typeglob, not Mock::Sub: Mock::Sub 1.08 (on
        # some CPAN testers) returns the call args for return_value => undef, so
        # the croak-on-undef path never fired. Bare `return` = failure in any
        # context; no warnings 'redefine' is block-scoped so real redefines warn.
        no warnings 'redefine';
        local *IPC::Shareable::thaw = sub { return };

        is eval { my $x = $h{k}; 1 }, undef,
            "_thaw: croaks when Storable::thaw returns undef";
        like $@, qr/Munged shared memory segment/,
            "_thaw: error message mentions munged segment";
    }
}

# _tie: croaks with OOM message when SharedMem->new fails with ENOMEM
{
    # no warnings 'redefine' is block-scoped so a genuine accidental redefine
    # elsewhere still warns.
    no warnings 'redefine';
    local *IPC::Shareable::SharedMem::new = sub {
        $! = 12;   # ENOMEM
        return undef;
    };

    is eval { tie my %h, 'IPC::Shareable', { create => 1, destroy => 1 , serializer => 'storable' }; 1 }, undef,
        "_tie: croaks when SharedMem->new fails with ENOMEM";
    like $@, qr/spawning too many segments/,
        "_tie: OOM error message references segment spawning";
}

# _tie: croaks when create+exclusive set but SharedMem->new returns undef
# (SharedMem::new normally croaks itself for File exists; this tests the _tie fallthrough)
{
    # no warnings 'redefine' is block-scoped so a genuine accidental redefine
    # elsewhere still warns.
    no warnings 'redefine';
    local *IPC::Shareable::SharedMem::new = sub {
        $! = 17;   # EEXIST
        return undef;
    };

    is eval { tie my %h, 'IPC::Shareable', { create => 1, exclusive => 1, destroy => 1 , serializer => 'storable' }; 1 }, undef,
        "_tie: croaks when create+exclusive set and SharedMem->new returns undef";
    like $@, qr/exclusive.*are set|Does the segment already exist/,
        "_tie: create+exclusive error message correct";
}

# _tie: croaks when sem->op fails for the initial LOCK_SH
{
    my $key     = '0x1B0BFFF5';
    my $key_int = hex($key);

    {
        my $mock    = Mock::Sub->new;
        my $op_mock = $mock->mock('IPC::Semaphore::op', return_value => 0);

        is eval { tie my %h, 'IPC::Shareable', { key => $key, create => 1, destroy => 0 , serializer => 'storable' }; 1 }, undef,
            "_tie: croaks when sem->op fails for initial LOCK_SH";
        like $@, qr/Could not obtain semaphore set lock/,
            "_tie: semaphore op failure error message correct";
    }

    # SharedMem and the semaphore set were created before op failed — clean up manually.
    my $leaked_id = shmget($key_int, 0, 0);
    shmctl($leaked_id, IPC_RMID, 0) if defined $leaked_id;
    my $leaked_sem = IPC::Semaphore->new($key_int, 0, 0);
    $leaked_sem->remove if defined $leaked_sem;
}

# _tie: croaks when sem->setval fails during initialization
{
    my $key     = '0x1B0BFFF6';
    my $key_int = hex($key);

    {
        my $mock        = Mock::Sub->new;
        my $setval_mock = $mock->mock('IPC::Semaphore::setval', return_value => 0);

        is eval { tie my %h, 'IPC::Shareable', { key => $key, create => 1, destroy => 0 , serializer => 'storable' }; 1 }, undef,
            "_tie: croaks when sem->setval fails during initialization";
        like $@, qr/Couldn't set semaphore during object creation/,
            "_tie: setval failure error message correct";
    }

    # Clean up the leaked shm segment and semaphore set.
    my $leaked_id = shmget($key_int, 0, 0);
    shmctl($leaked_id, IPC_RMID, 0) if defined $leaked_id;
    my $leaked_sem = IPC::Semaphore->new($key_int, 0, 0);
    $leaked_sem->remove if defined $leaked_sem;
}


# Type guards: array-only methods on a hash knot

{
    my $key = int(rand(99999));
    tie my %h, 'IPC::Shareable', { key => $key, create => 1, destroy => 1 };
    my $knot = tied(%h);

    is eval { $knot->PUSH('x'); 1 }, undef,
        "PUSH on hash knot croaks";
    like $@, qr/Cannot push to a non-array/,
        "PUSH on hash knot: error message correct";

    is eval { $knot->POP; 1 }, undef,
        "POP on hash knot croaks";
    like $@, qr/Cannot pop from a non-array/,
        "POP on hash knot: error message correct";

    is eval { $knot->SHIFT; 1 }, undef,
        "SHIFT on hash knot croaks";
    like $@, qr/Cannot shift from a non-array/,
        "SHIFT on hash knot: error message correct";

    is eval { $knot->UNSHIFT('x'); 1 }, undef,
        "UNSHIFT on hash knot croaks";
    like $@, qr/Cannot unshift a non-array/,
        "UNSHIFT on hash knot: error message correct";

    is eval { $knot->SPLICE(0, 0); 1 }, undef,
        "SPLICE on hash knot croaks";
    like $@, qr/Cannot splice a non-array/,
        "SPLICE on hash knot: error message correct";

    is eval { $knot->FETCHSIZE; 1 }, undef,
        "FETCHSIZE on hash knot croaks";
    like $@, qr/Cannot fetchsize on a non-array/,
        "FETCHSIZE on hash knot: error message correct";

    is eval { $knot->STORESIZE(5); 1 }, undef,
        "STORESIZE on hash knot croaks";
    like $@, qr/Cannot storesize on a non-array/,
        "STORESIZE on hash knot: error message correct";
}

# Type guard: DELETE on an array knot

{
    my $key = int(rand(99999));
    tie my @a, 'IPC::Shareable', { key => $key, create => 1, destroy => 1 };
    my $knot = tied(@a);

    is eval { $knot->DELETE('foo'); 1 }, undef,
        "DELETE on array knot croaks";
    like $@, qr/Cannot delete from a non-hash/,
        "DELETE on array knot: error message correct";
}

done_testing();
