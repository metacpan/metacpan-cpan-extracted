#
# Tests using Filesys::Virtual::Plain
#

use strict;

use Test::More tests => 30;

use Cwd;
use File::Path;
use POSIX qw(:errno_h :fcntl_h);

use Fuse::Filesys::Virtual;

sub content {
    my $file = shift;
    open(my $fh, $file) or die "$file: $!";
    local $/;
    my $ret = <$fh>;
    close($fh);

    return $ret;
}

sub prepare_content {
    my $file = shift;
    my $content = shift;

    open(my $fh, ">$file") or die "$file: $!";
    print $fh $content;
    close($fh);
}

SKIP: {
    eval "use Filesys::Virtual::Plain";
    my $fvp_installed = $@ ? 0 : 1;
    skip "Filesys::Virtual::Plain is not unstalled", 1 unless ($fvp_installed);

    my $dir = getcwd;
    my $testroot = "$dir/t/testdir";

    rmtree([$testroot]);
    mkpath([$testroot], 0, 0755);

    my $plain = Filesys::Virtual::Plain->new({root_path => $testroot });
    # ugly...
    $plain->{uid} = $<;
    $plain->{gid} = $(;

    my $fs = Fuse::Filesys::Virtual->new($plain, {debug => 1});

    # create a file
    is($fs->mknod("/test.txt", 0644, 0), 0);
    ok(-f "$testroot/test.txt");
    is($fs->write("/test.txt", "xyz", 0), 3);
    is($fs->write("/test.txt", "abc", 4), 3);
    is($fs->flush("/test.txt"), 0);
    is($fs->fsync("/test.txt", 1), 0);
    is($fs->release("/test.txt"), 0);
    is($fs->chmod("/test.txt", 0644), 0);
    is(content("$testroot/test.txt"), "xyzabc");

    my @dir = $fs->getdir("/");
    ok(grep { /^\.$/ } @dir);
    ok(grep { /^\.\.$/ } @dir);
    ok(grep { /^test\.txt$/ } @dir);
    is($dir[$#dir], 0);

    my @stat = $fs->getattr("/test.txt");
    is_deeply(\@stat, [stat("$testroot/test.txt")]);

    # read it.
    is($fs->open("/test.txt", 0), 0);
    my $data = $fs->read("/test.txt", 3, 3);
    is($data, "abc");
    is($fs->release("/test.txt"), 0);

    # create a directory
    is($fs->mkdir("/dir001", 0644), 0);
    ok(-d "$testroot/dir001");

    # utime
    $fs->utime("/test.txt", 1, 2);
    @stat = stat("$testroot/test.txt");
    is($stat[8], 1);
    is($stat[9], 2);

    # truncate
    is($fs->open("/test.txt", 0), 0);
    is($fs->truncate("/test.txt"), 0);
    is($fs->release("/test.txt"), 0);
    is(content("$testroot/test.txt"), "");

    # remove
    is($fs->unlink("/test.txt"), 0);
    ok(!-f "$testroot/test.txt");

    # rmdir
    is($fs->rmdir("/dir001"), 0);
    ok(!-d "$testroot/dir001");

    # 
    is($fs->open("/never-found/a.txt", 0), -ENOENT());
};
