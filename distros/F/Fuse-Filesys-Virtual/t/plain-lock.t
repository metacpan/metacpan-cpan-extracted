#
# Tests using Filesys::Virtual::Plain
#
# file is busy while using
#

use strict;

use Test::More tests => 15;

use Cwd;
use File::Path;
use POSIX qw(:errno_h :fcntl_h);

use Fuse::Filesys::Virtual;

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

    # create a test tree
    mkpath(["$testroot/dir001"], 0, 0755);
    mkpath(["$testroot/dir00a"], 0, 0755);
    mkpath(["$testroot/dir00b"], 0, 0755);
    prepare_content("$testroot/dir001/a.txt", "abc");
    prepare_content("$testroot/dir001/b.txt", "xyz");
    prepare_content("$testroot/dir00a/1.txt", "xyz");
    prepare_content("$testroot/dir00b/1.txt", "xyz");

    # open for read
    my $data = $fs->read("/dir001/a.txt", 3, 0);
    is($fs->open("/dir001/a.txt", 0), 0);
    is($fs->rename("/dir001/a.txt", "/dir001/b.txt"), -EBUSY());
    is($fs->rename("/dir001/b.txt", "/dir001/a.txt"), -EBUSY());
    is($fs->rename("/dir001", "/dir002"), -EBUSY());
    is($fs->rename("/dir00a", "/dir001"), 0);
    is($fs->unlink("/dir001/a.txt"), -EBUSY());
    is($fs->rmdir("/dir001"), -EBUSY());
    $fs->release("/dir001/a.txt");

    # open for write
    is($fs->open("/dir001/a.txt", 0), 0);
    is($fs->write("/dir001/a.txt", "def", 4), 3);
    is($fs->rename("/dir001/a.txt", "/dir001/b.txt"), -EBUSY());
    is($fs->rename("/dir001/b.txt", "/dir001/a.txt"), -EBUSY());
    is($fs->rename("/dir001", "/dir002"), -EBUSY());
    is($fs->rename("/dir00b", "/dir001"), 0);
    is($fs->unlink("/dir001/a.txt"), -EBUSY());
    is($fs->rmdir("/dir001"), -EBUSY());
    $fs->release("/dir001/a.txt");

    rmtree([$testroot]);
};
