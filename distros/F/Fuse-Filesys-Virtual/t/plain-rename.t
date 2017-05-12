#
# Tests using Filesys::Virtual::Plain
#
# rename
#

use strict;

use Test::More tests => 13;

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

    # create a test tree
    mkpath(["$testroot/dir001/dir002"], 0, 0755);
    prepare_content("$testroot/dir001/a.txt", "abc");
    prepare_content("$testroot/dir001/dir002/b.txt", "xyz");

    # rename directory
    is($fs->rename("/dir001", "/dir999"), 0);
    ok(!-d "$testroot/dir001");
    is(content("$testroot/dir999/a.txt"), "abc");
    is(content("$testroot/dir999/dir002/b.txt"), "xyz");

    # rename file
    is($fs->rename("/dir999/a.txt", "/dir999/b.txt"), 0);
    ok(!-f "$testroot/dir999/a.txt");
    is(content("$testroot/dir999/b.txt"), "abc");

    # move file across directries
    is($fs->rename("/dir999/b.txt", "/dir999/dir002/c.txt"), 0);
    ok(!-f "$testroot/dir999/b.txt");
    is(content("$testroot/dir999/dir002/c.txt"), "abc");

    # move file across directries
    is($fs->rename("/dir999/dir002/c.txt", "/dir999"), 0);
    ok(!-f "$testroot/dir999/dir002/c.txt");
    is(content("$testroot/dir999/c.txt"), "abc");

    rmtree([$testroot]);
};
