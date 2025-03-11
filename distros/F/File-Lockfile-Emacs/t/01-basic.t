#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Cwd qw(abs_path);
use File::chdir;
use File::Lockfile::Emacs qw(
                                emacs_lockfile_get
                                emacs_lockfile_lock
                                emacs_lockfile_locked
                                emacs_lockfile_unlock
                        );
use File::Slurper qw(write_text);
use File::Temp qw(tempdir);

# XXX check for platforms that don't have symlink()
# XXX test with creating/reading regular (non-symlink) lockfile

my $dir = abs_path(tempdir(CLEANUP=>1));
$CWD = $dir;

subtest "emacs_lockfile_lock" => sub {
    my $res;

    subtest "won't create lockfile when target file doesn't exist" => sub {
        $res = emacs_lockfile_lock(target_file => "f1");
        is($res->[0], 412);
    };

    subtest "create lockfile when target file exists" => sub {
        write_text("f1", "");
        $res = emacs_lockfile_lock(target_file => "f1");
        is($res->[0], 200);
        ok((-l ".#f1"), "lockfile created");
    };

    subtest "force=>1 for creating lockfile even when target file doesn't exist" => sub {
        unlink(".#f1");
        unlink("f1");
        $res = emacs_lockfile_lock(force=>1, target_file => "f1");
        is($res->[0], 200);
        ok((-l ".#f1"), "lockfile created");
    };

    subtest "won't create lockfile when lockfile is created by other process" => sub {
        unlink(".#f1");
        write_text("f1", "");
        symlink "user\@host.1:1234", ".#f1";
        $res = emacs_lockfile_lock(target_file => "f1");
        is($res->[0], 412);
    };
    subtest "force=>1 to force replacing lockfile created by other process with ours" => sub {
        $res = emacs_lockfile_lock(force=>1, target_file => "f1");
        is($res->[0], 200);
        ok((-l ".#f1"), "lockfile created");
    };

};

# TODO: test emacs_lockfile_get
# TODO: test emacs_lockfile_locked
# TODO: test emacs_lockfile_unlock

DONE_TESTING:
done_testing();
if (Test::More->builder->is_passing) {
    diag "all tests successful, deleting test data dir $dir";
    $CWD = "/";
} else {
    # don't delete test data dir if there are errors
    diag "there are failing tests, not deleting test data dir $dir";
}
