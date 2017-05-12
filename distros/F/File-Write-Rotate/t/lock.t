#!perl

use 5.010;
use strict;
use warnings;

use File::chdir;
use File::Temp qw(tempdir);
use File::Write::Rotate;

use Test::Exception;
use Test::More 0.98;
use Test::Warnings qw(:no_end_test warnings);

my $dir = tempdir(CLEANUP=>1);
$CWD = $dir;

test_locking(
    label => "none",
    prefix => "a",
    new_params => {
        lock_mode => "none",
    },
    locked_write => 0,
    locked_creation => 0,
);

test_locking(
    label => "write",
    prefix => "b",
    new_params => {
        lock_mode => "write",
    },
    locked_write => 1,
    locked_creation => 0,
);

test_locking(
    label => "exclusive",
    prefix => "c",
    new_params => {
        lock_mode => "exclusive",
    },
    locked_write => 1,
    locked_creation => 1,
);

sub check_lock {
    my ($lockfile, $label, $expected) = @_;
    ok((-e $lockfile), "lock file exists: $label") if $expected;
    ok((! -e $lockfile), "lock file doesn't exist: $label") if ! $expected;
}

sub test_locking {
    my (%args) = @_;
    my $label_base = $args{label};
    my $prefix = $args{prefix};
    my %new_params = %{$args{new_params}};
    my %seen;

    subtest "locking: $label_base" => sub {
        my $lockfile;
        {
            my $fwr = File::Write::Rotate->new(
                %new_params,
                dir => $dir,
                prefix => $prefix,
                size => 1,
                hook_after_create => sub {
                    $seen{hook_after_create} = 1;
                    check_lock($lockfile, "hook_after_create", $args{locked_write});
                },
                hook_before_write => sub {
                    $seen{hook_before_write} = 1;
                    check_lock($lockfile, "hook_before_write", $args{locked_write});
                },
                hook_before_rotate => sub {
                    $seen{hook_before_rotate} = 1;
                    check_lock($lockfile, "hook_before_rotate", $args{locked_write});
                },
                hook_after_rotate => sub {
                    $seen{hook_after_rotate} = 1;
                    check_lock($lockfile, "hook_after_rotate", $args{locked_write});
                },
            );
            $lockfile = $fwr->lock_file_path;
            check_lock($lockfile, "created", $args{locked_creation});
            $fwr->write("[1]\n");
            check_lock($lockfile, "after 1st write", $args{locked_creation});
            $fwr->write("[2]\n");
            check_lock($lockfile, "after 2nd write", $args{locked_creation});
            is(scalar keys %seen, 4, "Expected 4 hooks to run");
        }
        check_lock($lockfile, "out of scope", 0);
    };
}

DONE_TESTING:
done_testing;

if (Test::More->builder->is_passing) {
    $CWD = "/";
} else {
    diag "there are failing tests, not deleting test data dir $dir";
}
