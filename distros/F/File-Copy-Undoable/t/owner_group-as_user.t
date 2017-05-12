#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';
use lib $Bin, "$Bin/t";
#use Log::Any '$log';

use File::chdir;
use File::Copy::Undoable;
use File::Path qw(remove_tree);
use File::Slurper qw(read_text write_text);
use File::Temp qw(tempdir);
use Test::More 0.98;
use Test::Perinci::Tx::Manager qw(test_tx_action);

plan skip_all => "this test requires running as normal user" if !$>;

my $tmpdir = tempdir(CLEANUP=>1);
$CWD = $tmpdir;

my $uid = $> == 65535 ? $>-1 : $>+1;
my $gid = $) == 65535 ? $)-1 : $)+1;

test_tx_action(
    name          => "copy",
    tmpdir        => $tmpdir,
    f             => "File::Copy::Undoable::cp",
    args          => {source=>"s", target=>"t",
                      target_owner=>$uid, target_group=>$gid},
    reset_state   => sub {
        remove_tree "s", "t";
        mkdir "s"; write_text("s/f1", "foo");
    },
    after_do     => sub {
        ok( (-d "t"), "t exists");
        is(scalar(read_text "t/f1"), "foo", "t/f1 exists");
        my @st_dir = stat ".";
        my @st = stat "t";
        is($st[4], $>, "owner still user");
        subtest "group still user's group" => sub {
            # [RT#95194] "New files and directories inherit their groups from
            # their parent directory at creation time." /tmp and /var/tmp belong
            # to the group "wheel", so any directory and file created here will
            # also belong to the group "wheel".
            if ($^O eq 'freebsd') {
                is($st[5], $st_dir[5]);
            } else {
                is($st[5], $)+0);
            }
        };
    },
    after_undo   => sub {
        ok(!(-e "t"), "t doesn't exist");
    },
);

DONE_TESTING:
done_testing();
if (Test::More->builder->is_passing) {
    #diag "all tests successful, deleting test data dir";
    $CWD = "/";
} else {
    diag "there are failing tests, not deleting test data dir $tmpdir";
}
