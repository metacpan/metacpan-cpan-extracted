#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';
use lib $Bin, "$Bin/t";
#use Log::Any '$log';

use File::chdir;
use File::Path qw(remove_tree);
use File::Slurp::Tiny qw(read_file write_file);
use File::Temp qw(tempdir);
use File::Prepend::Undoable;
use Test::More 0.98;
use Test::Perinci::Tx::Manager qw(test_tx_action);

my $tmpdir = tempdir(CLEANUP=>1);
$CWD = $tmpdir;

test_tx_action(
    name          => "path doesn't exist -> error",
    tmpdir        => $tmpdir,
    f             => "File::Prepend::Undoable::prepend",
    args          => {path=>"p", string=>"foo"},
    reset_state   => sub {
        remove_tree "p";
    },
    status        => 412,
);
test_tx_action(
    name          => "path is a dir -> error",
    tmpdir        => $tmpdir,
    f             => "File::Prepend::Undoable::prepend",
    args          => {path=>"p", string=>"foo"},
    reset_state   => sub {
        remove_tree "p";
        mkdir "p";
    },
    status        => 412,
);
test_tx_action(
    name          => "path is a symlink -> error",
    tmpdir        => $tmpdir,
    f             => "File::Prepend::Undoable::prepend",
    args          => {path=>"p", string=>"foo"},
    reset_state   => sub {
        remove_tree "p";
        symlink "q", "p";
    },
    status        => 412,
) if eval { symlink "", ""; 1 };
test_tx_action(
    name          => "file already contains string -> noop",
    tmpdir        => $tmpdir,
    f             => "File::Prepend::Undoable::prepend",
    args          => {path=>"p", string=>"foo"},
    reset_state   => sub {
        remove_tree "p";
        write_file "p", "foo bar";
    },
    status        => 304,
);
test_tx_action(
    name          => "prepend",
    tmpdir        => $tmpdir,
    f             => "File::Prepend::Undoable::prepend",
    args          => {path=>"p", string=>"foo"},
    reset_state   => sub {
        remove_tree "p";
        write_file "p", "bar";
        chmod 0614, "p";
    },
    after_do      => sub {
        my @st = stat "p";
        ok( (-f _), "file exists");
        is($st[2] & 07777, 0614, "file mode");
        is(scalar(read_file "p"), "foobar", "string prepended");
    },
    after_undo    => sub {
        my @st = stat "p";
        ok( (-f _), "file exists");
        is($st[2] & 07777, 0614, "file mode");
        is(scalar(read_file "p"), "bar", "file content is restored");
    },
);

# XXX test ownership

DONE_TESTING:
done_testing();
if (Test::More->builder->is_passing) {
    #diag "all tests successful, deleting test data dir";
    $CWD = "/";
} else {
    diag "there are failing tests, not deleting test data dir $tmpdir";
}
