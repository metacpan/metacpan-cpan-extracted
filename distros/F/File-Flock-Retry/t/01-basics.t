#!perl

use 5.010;
use strict;
use warnings;

use Cwd qw(abs_path);
use File::chdir;
use File::Slurper qw(write_text);
use File::Spec;
use Test::More 0.98;

use File::Temp qw(tempdir);
use File::Flock::Retry;

plan skip_all => 'Not tested on Windows yet' if $^O =~ /win32/i;

my $dir = abs_path(tempdir(CLEANUP=>1));
$CWD = $dir;

subtest "create (unlocked)" => sub {
    ok(!(-f "f1"), "f1 doesn't exist before lock");
    my $lock = File::Flock::Retry->lock("f1");
    ok((-f "f1"), "f1 exists after lock");
    $lock->unlock;
    ok(!(-f "f1"), "f1 doesn't exist after unlock");
};

subtest "create (destroyed)" => sub {
    ok(!(-f "f1"), "f1 doesn't exist before lock");
    my $lock = File::Flock::Retry->lock("f1");
    ok((-f "f1"), "f1 exists after lock");
    undef $lock;
    ok(!(-f "f1"), "f1 doesn't exist after DESTROY");
};

subtest "already exists" => sub {
    write_text("f1", "");
    ok((-f "f1"), "f1 exists before lock");
    my $lock = File::Flock::Retry->lock("f1");
    ok((-f "f1"), "f1 exists after lock");
    undef $lock;
    ok((-f "f1"), "f1 still exists after DESTROY");
    unlink "f1";
};

subtest "was created, but not empty" => sub {
    ok(!(-f "f1"), "f1 doesn't exist before lock");
    my $lock = File::Flock::Retry->lock("f1");
    ok((-f "f1"), "f1 exists after lock");
    { open my $f1, ">>", "f1"; print $f1 "a"; close $f1 }
    undef $lock;
    ok((-f "f1"), "f1 still exists after DESTROY");
};

# XXX test shared lock

DONE_TESTING:
done_testing();
if (Test::More->builder->is_passing) {
    diag "all tests successful, deleting test data dir";
    $CWD = "/";
} else {
    # don't delete test data dir if there are errors
    diag "there are failing tests, not deleting test data dir $dir";
}
