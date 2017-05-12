#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';
use lib $Bin, "$Bin/t";
#use Log::Any '$log';

use File::chdir;
use File::Move::Undoable;
use File::Path qw(remove_tree);
use File::Slurper qw(read_text write_text);
use File::Temp qw(tempdir);
use File::Which;
use Sys::Filesystem::MountPoint qw(:all);
use Test::More 0.98;
use Test::Perinci::Tx::Manager qw(test_tx_action);

plan skip_all => "HOME environment not set" unless $ENV{HOME};
plan skip_all => "rsync not available in PATH" unless which('rsync');

my $tmpdir   = tempdir(CLEANUP=>1);
my $mphome   = path_to_mount_point($ENV{HOME});
my $mptmp    = path_to_mount_point($tmpdir);
my $htmpdir = tempdir(CLEANUP=>1, DIR=>$ENV{HOME}) if $mphome ne $mptmp;

$CWD = $tmpdir;

for my $tdir ($tmpdir, $htmpdir) {
    unless ($tdir) {
        diag "Skipping test moving to another filesystem ".
            "because $ENV{HOME} and $tmpdir are on the same filesystem";
        next;
    }
    my $same_fs = $tdir eq $htmpdir ? 0 : 1;

    test_tx_action(
        name          => "source & target don't exist -> error",
        tmpdir        => $tmpdir,
        f             => "File::Move::Undoable::mv",
        args          => {source=>"s", target=>"$tdir/t"},
        reset_state   => sub {
            remove_tree "s", "$tdir/t";
        },
        status        => 412,
    );

    test_tx_action(
        name          => "source doesn't exist & target exists -> noop",
        tmpdir        => $tmpdir,
        f             => "File::Move::Undoable::mv",
        args          => {source=>"s", target=>"$tdir/t"},
        reset_state   => sub {
            remove_tree "s", "$tdir/t";
            mkdir "$tdir/t";
        },
        status        => 304,
    );

    test_tx_action(
        name          => "move $tmpdir/s -> $tdir/t",
        tmpdir        => $tmpdir,
        f             => "File::Move::Undoable::mv",
        args          => {source=>"s", target=>"$tdir/t"},
        reset_state   => sub {
            remove_tree "s", "$tdir/t";
            mkdir "s"; write_text("s/f1", "foo");
        },
        after_do     => sub {
            ok( (-d "$tdir/t"), "t exists");
            is(scalar(read_text "$tdir/t/f1"), "foo", "t/f1 exists");
            ok(!(-d "s"), "t doesn't exist");
        },
        after_undo   => sub {
            ok(!(-d "$tdir/t"), "t doesn't exist");
            ok( (-d "s"), "s exists");
            is(scalar(read_text "s/f1"), "foo", "s/f1 exists");
        },
    );

    if (!$same_fs) {
        test_tx_action(
            name          => "failure in move -> rollback",
            tmpdir        => $tmpdir,
            f             => "File::Move::Undoable::mv",
            args          => {source=>"s", target=>"$tdir/t",
                              rsync_opts=>["--foo"], # bogus
                          },
            reset_state   => sub {
                remove_tree "s", "$tdir/t";
                mkdir "s"; write_text("s/f1", "foo");
            },
            status       => 532,
            after_do     => sub {
                ok(!(-e "$tdir/t"), "t doesn't exist");
                ok( (-e "s"), "s exists");
            },
        );
    }

    # XXX test both exists, ok when !same_fs
}

# XXX test crash during move
# XXX test crash during trash

DONE_TESTING:
done_testing();
if (Test::More->builder->is_passing) {
    #diag "all tests successful, deleting test data dir";
    $CWD = "/";
} else {
    diag "there are failing tests, not deleting test data dir $tmpdir";
}
