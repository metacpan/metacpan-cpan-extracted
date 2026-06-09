use warnings;
use strict;

use Data::Dumper;
use File::Temp qw(tempdir);
use IPC::Shareable;
IPC::Shareable->testing_set('IPC::Shareable');
use Test::More;

use FindBin;
use lib $FindBin::Bin;
use IPCShareableTest qw(assert_clean_process);


# sysv_info() - class method
{
    my $info = IPC::Shareable->sysv_info;

    if ($^O eq 'darwin' || $^O eq 'linux' || $^O eq 'freebsd' || $^O eq 'openbsd') {
        isnt $info, undef, "sysv_info() returns a value on $^O";
        is ref $info, 'HASH', "...and it's a hash ref";

        # shmmax, shmmni, shmall are always present on all supported platforms
        for my $key (qw(shmmax shmmni shmall)) {
            ok exists $info->{$key}, "...key '$key' exists";
            like $info->{$key}, qr/^\d+$/, "...'$key' is an integer ($info->{$key})";
        }

        # semmni is the max number of semaphore identifier sets. Reported
        # on every platform that exposes it via sysctl/procfs.
        ok exists $info->{semmni}, "...key 'semmni' exists on $^O";
        like $info->{semmni}, qr/^\d+$/, "...'semmni' is an integer ($info->{semmni})";

        if ($^O eq 'darwin') {
            # shmmin and shmseg come from sysctl and are always present on macOS
            for my $key (qw(shmmin shmseg)) {
                ok exists $info->{$key}, "...key '$key' exists on macOS";
                like $info->{$key}, qr/^\d+$/, "...'$key' is an integer ($info->{$key})";
            }
        }
        elsif ($^O eq 'freebsd') {
            # FreeBSD exposes the same five keys as macOS via sysctl kern.ipc
            for my $key (qw(shmmin shmseg)) {
                ok exists $info->{$key}, "...key '$key' exists on FreeBSD";
                like $info->{$key}, qr/^\d+$/, "...'$key' is an integer ($info->{$key})";
            }
        }
        elsif ($^O eq 'linux') {
            # shmmin is a kernel compile-time constant; not always exposed via procfs
            if (exists $info->{shmmin}) {
                like $info->{shmmin}, qr/^\d+$/, "...'shmmin' is an integer if present ($info->{shmmin})";
            }
            else {
                pass "...'shmmin' not available via procfs on this kernel (ok)";
            }
        }
    }
    else {
        is $info, undef, "sysv_info() returns undef on unsupported platform ($^O)";
    }
}

# sysv_info() - object method
{
    my $knot = tie my %hv, 'IPC::Shareable', { create => 1, destroy => 1 , serializer => 'storable' };

    my $info = $knot->sysv_info;

    if ($^O eq 'darwin' || $^O eq 'linux' || $^O eq 'freebsd' || $^O eq 'openbsd') {
        isnt $info, undef, "sysv_info() called as object method returns a value";
        is ref $info, 'HASH', "...and it's a hash ref";

        for my $key (qw(shmmax shmmni shmall)) {
            ok exists $info->{$key}, "...key '$key' exists";
        }
    }
    else {
        is $info, undef, "sysv_info() returns undef on unsupported platform ($^O)";
    }

    # warn(Dumper $info);

    IPC::Shareable->clean_up_all;
}

# sysv_info() - class method and object method return identical data
{
    my $knot = tie my %hv, 'IPC::Shareable', { create => 1, destroy => 1 , serializer => 'storable' };

    if ($^O eq 'darwin' || $^O eq 'linux' || $^O eq 'freebsd' || $^O eq 'openbsd') {
        my $class_info  = IPC::Shareable->sysv_info;
        my $object_info = $knot->sysv_info;

        is_deeply $class_info, $object_info,
            "Class method and object method return identical data";
    }

    IPC::Shareable->clean_up_all;
}

assert_clean_process();

# -----------------------------------------------------------------------
# Linux branch - mocked via _proc_dir and local $^O
# -----------------------------------------------------------------------

{
    my $tmpdir = tempdir(CLEANUP => 1);

    for my $key (qw(shmmax shmmin shmmni shmall)) {
        open my $fh, '>', "$tmpdir/$key" or die "Cannot create $tmpdir/$key: $!";
        print $fh "65536\n";
        close $fh;
    }
    open my $sem_fh, '>', "$tmpdir/sem"
        or die "Cannot create $tmpdir/sem: $!";
    print $sem_fh "32000 1024000000 500 128\n";  # semmsl semmns semopm semmni
    close $sem_fh;

    my $info;
    {
        local $^O = 'linux';
        $info = IPC::Shareable->sysv_info(_proc_dir => $tmpdir);
    }

    isnt $info, undef,
        "linux branch (mocked): sysv_info() returns a defined value";
    is ref($info), 'HASH',
        "linux branch (mocked): return value is a hash ref";

    for my $key (qw(shmmax shmmin shmmni shmall)) {
        is $info->{$key}, '65536',
            "linux branch (mocked): '$key' reads value from fake proc file";
    }

    is $info->{semmsl}, '32000',
        "linux branch (mocked): semmsl from 1st field of /proc/sys/kernel/sem";
    is $info->{semmns}, '1024000000',
        "linux branch (mocked): semmns from 2nd field";
    is $info->{semopm}, '500',
        "linux branch (mocked): semopm from 3rd field";
    is $info->{semmni}, '128',
        "linux branch (mocked): semmni from 4th field";
}

# -----------------------------------------------------------------------
# FreeBSD branch - mocked via _sysctl_out and local $^O
# -----------------------------------------------------------------------

{
    my $fake_out = join("\n",
        'kern.ipc.shmmax: 65536',
        'kern.ipc.shmmin: 1',
        'kern.ipc.shmmni: 192',
        'kern.ipc.shmseg: 128',
        'kern.ipc.shmall: 131072',
        'kern.ipc.semmni: 50',
        'kern.ipc.semmns: 340',
        'kern.ipc.semmsl: 340',
        'kern.ipc.semopm: 100',
        'kern.ipc.somethingelse: ignored',
    );

    my $info;
    {
        local $^O = 'freebsd';
        $info = IPC::Shareable->sysv_info(_sysctl_out => $fake_out);
    }

    isnt $info, undef,
        "freebsd branch (mocked): sysv_info() returns a defined value";
    is ref($info), 'HASH',
        "freebsd branch (mocked): return value is a hash ref";

    for my $key (qw(shmmax shmmin shmmni shmseg shmall semmni semmns semmsl semopm)) {
        ok exists $info->{$key},
            "freebsd branch (mocked): '$key' key present";
        like $info->{$key}, qr/^\d+$/,
            "freebsd branch (mocked): '$key' is an integer";
    }

    ok !exists $info->{somethingelse},
        "freebsd branch (mocked): non-shm/sem kern.ipc keys are filtered out";
}

# -----------------------------------------------------------------------
# OpenBSD branch - mocked via _sysctl_out and local $^O
# -----------------------------------------------------------------------

{
    my $fake_out = join("\n",
        'kern.seminfo.semmni=10',
        'kern.seminfo.semmns=60',
        'kern.seminfo.semmsl=60',
        'kern.shminfo.shmmax=33554432',
        'kern.shminfo.shmmin=1',
        'kern.shminfo.shmmni=128',
        'kern.shminfo.shmall=8192',
    );

    my $info;
    {
        local $^O = 'openbsd';
        $info = IPC::Shareable->sysv_info(_sysctl_out => $fake_out);
    }

    isnt $info, undef,
        "openbsd branch (mocked): sysv_info() returns a defined value";
    is ref($info), 'HASH',
        "openbsd branch (mocked): return value is a hash ref";

    is $info->{semmni}, '10',
        "openbsd branch (mocked): semmni parsed";
    is $info->{shmmax}, '33554432',
        "openbsd branch (mocked): shmmax parsed";
}

# -----------------------------------------------------------------------
# Solaris branch - not implemented; sysv_info() returns undef
# -----------------------------------------------------------------------

{
    my $info;
    {
        local $^O = 'solaris';
        $info = IPC::Shareable->sysv_info;
    }

    is $info, undef,
        "solaris branch (mocked): sysv_info() returns undef (unsupported platform)";
}

done_testing();
