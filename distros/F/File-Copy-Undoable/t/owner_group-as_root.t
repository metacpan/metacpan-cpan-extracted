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

plan skip_all => "this test requires running as root" if $>;

my $tmpdir = tempdir(CLEANUP=>1);
$CWD = $tmpdir;

test_tx_action(
    name          => "copy",
    tmpdir        => $tmpdir,
    f             => "File::Copy::Undoable::cp",
    args          => {source=>"s", target=>"t",
                      target_owner=>1000, target_group=>2000},
    reset_state   => sub {
        remove_tree "s", "t";
        mkdir "s"; write_text("s/f1", "foo");
    },
    after_do     => sub {
        ok( (-d "t"), "t exists");
        is(scalar(read_text "t/f1"), "foo", "t/f1 exists");
        my @st = stat "t";
        is($st[4], 1000, "owner set");
        is($st[5], 2000, "group set");

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
