use strict;
use warnings;
use Test::More tests => 20;
use IO::AIO qw(aio_mkdir);
use IO::AIO::Util qw(aio_mkpath);
use File::Spec::Functions qw(catdir);
use File::Temp qw(tempdir tempfile);
use POSIX ();

# Copied from IO::AIO tests
sub pcb {
    while (IO::AIO::nreqs) {
        vec (my $rfd="", IO::AIO::poll_fileno, 1) = 1;
        select $rfd, undef, undef, undef;
        IO::AIO::poll_cb;
    }
}

my $tmp = tempdir(CLEANUP => 1);
ok(-d $tmp, 'creation of temp directory');

# Test the original aio_mkdir.
{
    my $dir1 = catdir($tmp, qw(aio_mkdir1));
    my $dir2 = catdir($tmp, qw(aio_mkdir2 subdir1));

    aio_mkdir $dir1, 0777, sub {
        is($_[0], 0, 'new path w/ aio_mkdir: return status');
        ok(! $!, "new path w/ aio_mkdir: errno ($!)");
        is(-d $dir1, 1, "new path w/ aio_mkdir: -d $dir1");
    };

    pcb;

    aio_mkdir $dir2, 0777, sub {
        is($_[0], -1, 'new complex path w/ aio_mkdir: return status');
        ok($!, "new complex path w/ aio_mkdir: errno ($!)");
        is(-d $dir2, undef, "new complex path w/ aio_mkdir: -d $dir2");
    };

    pcb;
}

{
    my $dir = catdir($tmp, qw(dir1 dir2));

    aio_mkpath $dir, 0777, sub {
        is($_[0], 0, 'new path: return status');
        ok(! $!, "new path: errno ($!)");
        is(-d $dir, 1, "new path: -d $dir");
    };

    pcb;

    aio_mkpath $dir, 0777, sub {
        is($_[0], 0, 'existing path: return status');
        ok(! $!, "existing path: errno ($!)");
    };

    pcb;
}

{
    my (undef, $file) = tempfile(DIR => $tmp);

    aio_mkpath $file, 0777, sub {
        is($_[0], -1, 'existing file: return status');
        is(0 + $!, &POSIX::EEXIST, "existing file: errno ($!)");
    };

    my $subdir = catdir($file, 'dir1');

    aio_mkpath $subdir, 0777, sub {
        is($_[0], -1, 'subdir of existing file: return status');
        is(0 + $!, &POSIX::ENOTDIR, "subdir of existing file: errno ($!)");
    };

    pcb;
}

SKIP: {
    skip 'cannot test permissions errors as this user', 2
        unless $> > 0 and $) > 0;

    my $dir = catdir($tmp, qw(dir2 dir3));

    aio_mkpath $dir, 0755, sub { }; pcb;
    chmod 0000, $dir or die "$dir: $!\n";
    my $subdir = catdir($dir, 'dir4');

    aio_mkpath $subdir, 0777, sub {
        is($_[0], -1, 'permission denied: return status');
        is(0 + $!, &POSIX::EACCES, "permission denied: errno ($!)");
    };

    pcb;
}

SKIP: {
    skip "cannot test permissions errors as this user", 2
        unless $> > 0 and $) > 0;

    my $dir = catdir($tmp, qw(dir3 dir4));

    aio_mkpath $dir, 0111, sub {
        is($_[0], -1, 'bad permissions: return status');
        ok(&POSIX::EACCES == $!, "bad permissions: errno ($!)");
    };

    pcb;
}
