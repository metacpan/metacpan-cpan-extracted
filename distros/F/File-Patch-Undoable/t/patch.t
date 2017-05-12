#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';
#use lib $Bin, "$Bin/t";
#use Log::Any '$log';

use File::chdir;
use File::Copy;
use File::Path qw(remove_tree);
use File::Slurper qw(read_text);
use File::Temp qw(tempdir);
use File::Patch::Undoable;
use Test::More 0.98;
use Test::Perinci::Tx::Manager qw(test_tx_action);

unless (File::Patch::Undoable::_check_patch_has_dry_run_option()) {
    plan skip_all => "patch doesn't support --dry-run on this system";
    goto DONE_TESTING;
}

my $tmpdir = tempdir(CLEANUP=>1);
$CWD = $tmpdir;

test_tx_action(
    name          => "file doesn't exist -> error",
    tmpdir        => $tmpdir,
    f             => "File::Patch::Undoable::patch",
    args          => {file=>"f", patch=>"p"},
    reset_state   => sub {
        remove_tree "f", "p";
        copy "$Bin/data/file.u.patch", "p";
    },
    status        => 412,
);
test_tx_action(
    name          => "patch doesn't exist -> error",
    tmpdir        => $tmpdir,
    f             => "File::Patch::Undoable::patch",
    args          => {file=>"f", patch=>"p"},
    reset_state   => sub {
        remove_tree "f", "p";
        copy "$Bin/data/file.old", "f";
    },
    status        => 412,
);
test_tx_action(
    name          => "file is a dir -> error",
    tmpdir        => $tmpdir,
    f             => "File::Patch::Undoable::patch",
    args          => {file=>"f", patch=>"p"},
    reset_state   => sub {
        remove_tree "f", "p";
        mkdir "f";
        copy "$Bin/data/file.u.patch", "p";
    },
    status        => 412,
);
test_tx_action(
    name          => "file is a symlink -> error",
    tmpdir        => $tmpdir,
    f             => "File::Patch::Undoable::patch",
    args          => {file=>"f", patch=>"p"},
    reset_state   => sub {
        remove_tree "f", "p";
        symlink "q", "p";
        copy "$Bin/data/file.u.patch", "p";
    },
    status        => 412,
) if eval { symlink("", ""); 1 };
test_tx_action(
    name          => "patch is a dir -> error",
    tmpdir        => $tmpdir,
    f             => "File::Patch::Undoable::patch",
    args          => {file=>"f", patch=>"p"},
    reset_state   => sub {
        remove_tree "f", "p";
        copy "$Bin/data/file.old", "f";
        mkdir "p";
    },
    status        => 412,
);

test_tx_action(
    name          => "file already patched -> noop",
    tmpdir        => $tmpdir,
    f             => "File::Patch::Undoable::patch",
    args          => {file=>"f", patch=>"p"},
    reset_state   => sub {
        remove_tree "f", "p";
        copy "$Bin/data/file.new", "f";
        copy "$Bin/data/file.u.patch", "p";
    },
    status        => 304,
);
test_tx_action(
    name          => "file already patched -> noop (reverse)",
    tmpdir        => $tmpdir,
    f             => "File::Patch::Undoable::patch",
    args          => {file=>"f", patch=>"p", reverse=>1},
    reset_state   => sub {
        remove_tree "f", "p";
        copy "$Bin/data/file.old", "f";
        copy "$Bin/data/file.u.patch", "p";
    },
    status        => 304,
);

test_tx_action(
    name          => "patch (format=unified)",
    tmpdir        => $tmpdir,
    f             => "File::Patch::Undoable::patch",
    args          => {file=>"f", patch=>"p"},
    reset_state   => sub {
        remove_tree "f", "p";
        copy "$Bin/data/file.old", "f";
        copy "$Bin/data/file.u.patch", "p";
    },
    after_do      => sub {
        is(scalar(read_text("f")), scalar(read_text("$Bin/data/file.new")), "f patched");
    },
    after_undo    => sub {
        is(scalar(read_text("f")), scalar(read_text("$Bin/data/file.old")), "f restored");
    },
);

test_tx_action(
    name          => "patch (format=context, reverse=1)",
    tmpdir        => $tmpdir,
    f             => "File::Patch::Undoable::patch",
    args          => {file=>"f", patch=>"p", reverse=>1},
    reset_state   => sub {
        remove_tree "f", "p";
        copy "$Bin/data/file.new", "f";
        copy "$Bin/data/file.c.patch", "p";
    },
    after_do      => sub {
        is(scalar(read_text("f")), scalar(read_text("$Bin/data/file.old")), "f patched");
    },
    after_undo    => sub {
        is(scalar(read_text("f")), scalar(read_text("$Bin/data/file.new")), "f restored");
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
