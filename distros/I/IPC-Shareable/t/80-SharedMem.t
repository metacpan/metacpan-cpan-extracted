use warnings;
use strict;

use Config;
use Data::Dumper;
use IPC::Shareable;
use IPC::SysV qw(IPC_CREAT IPC_EXCL);
use Mock::Sub;
use Test::More;

my $segs_before = IPC::Shareable::seg_count();
my $sems_before = IPC::Shareable::sem_count();
warn "Segs Before: $segs_before\n" if $ENV{PRINT_SEGS};

my $mod = 'IPC::Shareable::SharedMem';

# new()
{
    # croak on no key param

    {
        my $seg;
        my $ok = eval { $seg = $mod->new; 1; };
        is $ok, undef, "new() equires a 'key' parameter with value";
        like $@, qr/new\(\) requires a 'key'/, "...and error is sane";
    }

    # croak on non-integer key

    {
        my $seg;
        my $ok = eval { $seg = $mod->new(key => 'aaaa'); 1; };
        is $ok, undef, "'key' param must be integer";
        like $@, qr/with an integer value/, "...and error is sane";
    }

    # Success: check defaults

    {
        my $seg;
        my $ok = eval { $seg = $mod->new(key => 5555, flags => IPC_CREAT); 1; };
        is $ok, 1, "segment object created ok";

        is ref $seg, 'IPC::Shareable::SharedMem', "object is of proper type ok";

        is $seg->key, 5555, "key attr set ok";
        is $seg->size, 1024, "size attr default ok";
        is $seg->flags, 950, "flags attr default ok";
        is $seg->mode, 0666, "mode attr default ok";
        is $seg->type, undef, "type defaults to undef ok";
        like $seg->id, qr/^\d+$/, "id is an integer ok";

        is $seg->remove, 1, "segment removed ok";
    }
}

# size()
{
    # Object already instantiated warning

    {

        my $warning;
        local $SIG{__WARN__} = sub { $warning = shift; };

        my $seg = $mod->new(key => 5555, flags => IPC_CREAT);
        $seg->size(2048);
        like $warning, qr/instantiated/, "size() warns that it can't be set after obj created";
        is $seg->size, 1024, "...and it hasn't been changed ok";

        is $seg->remove, 1, "seg cleaned up ok";
    }

    # Invalid type

    {
        my $seg;
        my $ok = eval { $seg = $mod->new(key => 5555, size => 'aaaa'); 1; };
        is $ok, undef, "size() requires an integer";
        like $@, qr/size\(\) requires an integer/, "...and error is sane";
    }
}

# flags()
{
    # Object already instantiated warning

    {
        my $warning;
        local $SIG{__WARN__} = sub { $warning = shift; };

        my $seg = $mod->new(key => 5555, flags => IPC_CREAT);
        $seg->flags(1024);
        like $warning, qr/instantiated/, "flags() warns that it can't be set after obj created";
        is $seg->flags, 950, "...and it hasn't been changed ok";

        is $seg->remove, 1, "seg cleaned up ok";
    }
}

# mode()
{
    # Object already instantiated warning

    {

        my $warning;
        local $SIG{__WARN__} = sub { $warning = shift; };

        my $seg = $mod->new(key => 5555, flags => IPC_CREAT);
        $seg->mode(0666);
        like $warning, qr/instantiated/, "mode() warns that it can't be set after obj created";
        is $seg->mode, 0666, "...and it hasn't been changed ok";

        is $seg->remove, 1, "seg cleaned up ok";
    }

    # Successful change

    {
        my $seg = $mod->new(key => 5555, flags => IPC_CREAT, mode => 0444);
        is $seg->mode, 0444, "mode() set ok in new";
        is $seg->remove, 1, "seg cleaned up ok";
    }
}

# type()
{
    # Object already instantiated warning

    {

        my $warning;
        local $SIG{__WARN__} = sub { $warning = shift; };

        my $seg = $mod->new(key => 5555, flags => IPC_CREAT, type => 'TESTING');
        $seg->type('HELLO');
        like $warning, qr/instantiated/, "type() warns that it can't be set after obj created";
        is $seg->type, 'TESTING', "...and it hasn't been changed ok";

        is $seg->remove, 1, "seg cleaned up ok";
    }
}

# id()
{
    # Object already instantiated warning

    {
        my $warning;
        local $SIG{__WARN__} = sub { $warning = shift; };

        my $seg = $mod->new(key => 5555, flags => IPC_CREAT);
        my $created_id = $seg->id;

        $seg->id(9998);

        like $warning, qr/instantiated/, "id() warns that it can't be set after obj created";
        is $seg->id, $created_id, "...and it hasn't been changed ok";

        is $seg->remove, 1, "seg cleaned up ok";
    }
}

# shmread() & shmwrite()
{
    my $seg = $mod->new(key => 5555, flags => IPC_CREAT);

    my $data = "blah";

    is $seg->shmwrite($data), 1, "shmwrite() returns 1 on success";

    is $seg->data, $data, "shmread() returns the proper data ok";

    is $seg->remove, 1, "seg removed ok";
}

# new() with a hex string key
{
    my $seg = $mod->new(key => '0x00001571', flags => IPC_CREAT);
    is ref($seg), 'IPC::Shareable::SharedMem', "new() with hex string key creates object ok";
    is $seg->key, hex('0x00001571'), "new() with hex key: integer key stored correctly";
    is $seg->remove, 1, "seg removed ok";
}

# key() croak when called as setter after object is established
{
    my $seg = $mod->new(key => 5555, flags => IPC_CREAT);
    my $ok = eval { $seg->key(9999); 1 };
    is $ok, undef, "key() croaks when set after object established";
    like $@, qr/after object is already established/, "...and error message is correct";
    is $seg->key, 5555, "...and key is unchanged";
    is $seg->remove, 1, "seg removed ok";
}

# stat() returns undef when the underlying segment has been removed
{
    my $seg = $mod->new(key => 5555, flags => IPC_CREAT);
    $seg->remove;
    my $stat = $seg->stat;
    is $stat, undef, "stat() returns undef when segment has been removed";
}

# remove() returns 0 on second call (segment already gone)
{
    my $seg = $mod->new(key => 5555, flags => IPC_CREAT);
    is $seg->remove, 1, "remove() returns 1 on first call";
    is $seg->remove, 0, "remove() returns 0 on second call (segment already removed)";
}

# stat
{
    my $seg = $mod->new(key => 5555, flags => IPC_CREAT, mode => 0644);

    my $data = "blah";
    is $seg->shmwrite($data), 1, "shmwrite() returns 1 on success";

    # printf("%d: %d\n", $seg->stat->uid, $seg->stat->ctime);

    is $seg->remove, 1, "seg removed ok";
}

SKIP: {
    skip 'OpenBSD 64-bit shmid_ds tests require 64-bit Perl', 14
        if $Config{ivsize} < 8;

    # OpenBSD 64-bit shmid_ds unpack template correctness
    # Construct a synthetic binary buffer with known values at the OpenBSD
    # 64-bit offsets (verified against offsetof() on OpenBSD 7.4 amd64).
    #
    # struct shmid_ds layout (104 bytes):
    #   ipc_perm (32): uid(4) gid(4) cuid(4) cgid(4) mode(4) + 12 pad
    #   segsz(4/int) lpid(4/pid_t) cpid(4/pid_t) nattch(2/shmatt_t) [pad 2]
    #   atime(8/time_t) __shm_atimensec(8)
    #   dtime(8/time_t) __shm_dtimensec(8)
    #   ctime(8/time_t) __shm_ctimensec(8) + shm_internal(8)
    {
        my ($uid, $gid, $cuid, $cgid) = (1001, 1002, 1003, 1004);
        my $mode    = 0644;
        my $segsz   = 65536;
        my $lpid    = 40001;
        my $cpid    = 40002;
        my $nattch  = 3;
        my ($atime, $dtime, $ctime) = (1748000000, 1748000001, 1748000002);

        my $synthetic = pack(
            'L L L L L x[12] L l l S x[2] q x[8] q x[8] q x[16]',
            $uid, $gid, $cuid, $cgid, $mode, $segsz,
            $lpid, $cpid, $nattch, $atime, $dtime, $ctime
        );

        my %vals;
        @vals{qw(uid gid cuid cgid mode segsz lpid cpid nattch atime dtime ctime)}
            = unpack('L L L L L x[12] L l l S x[2] q x[8] q x[8] q', $synthetic);

        is $vals{uid},    $uid,    'OpenBSD 64-bit stat: uid unpack correct';
        is $vals{gid},    $gid,    'OpenBSD 64-bit stat: gid unpack correct';
        is $vals{cuid},   $cuid,   'OpenBSD 64-bit stat: cuid unpack correct';
        is $vals{cgid},   $cgid,   'OpenBSD 64-bit stat: cgid unpack correct';
        is $vals{mode},   $mode,   'OpenBSD 64-bit stat: mode unpack correct';
        is $vals{segsz},  $segsz,  'OpenBSD 64-bit stat: segsz unpack correct';
        is $vals{lpid},   $lpid,   'OpenBSD 64-bit stat: lpid unpack correct';
        is $vals{cpid},   $cpid,   'OpenBSD 64-bit stat: cpid unpack correct';
        is $vals{nattch}, $nattch, 'OpenBSD 64-bit stat: nattch unpack correct';
        is $vals{atime},  $atime,  'OpenBSD 64-bit stat: atime unpack correct';
        is $vals{dtime},  $dtime,  'OpenBSD 64-bit stat: dtime unpack correct';
        is $vals{ctime},  $ctime,  'OpenBSD 64-bit stat: ctime unpack correct';

        my @seg_offsets = qw(uid gid cuid cgid mode segsz lpid cpid nattch atime dtime ctime);
        my $segsz_idx = 0;
        for (0..$#seg_offsets) { $segsz_idx = $_ if $seg_offsets[$_] eq 'segsz' }
        cmp_ok $vals{segsz}, '>=', 65536,
            "OpenBSD 64-bit stat: segsz (offset $segsz_idx in unpack) is >= 65536, not a garbage value";
    }

    # Verify the pack template produces exactly 104 bytes (the real sizeof(shmid_ds))
    {
        my $buf = pack('L L L L L x[12] L l l S x[2] q x[8] q x[8] q x[16]',
            1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12);
        is length($buf), 104, 'OpenBSD 64-bit: synthetic shmid_ds is 104 bytes';
    }
}

my $segs_after = IPC::Shareable::seg_count();
warn "Segs After: $segs_after\n" if $ENV{PRINT_SEGS};
is $segs_after, $segs_before, "All segs cleaned up ok";
my $sems_after = IPC::Shareable::sem_count();
is $sems_after, $sems_before, "All semaphore sets cleaned up ok";

done_testing();
