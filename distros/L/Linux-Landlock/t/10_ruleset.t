#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Linux::Landlock;
use IO::File;
use IO::Dir;
use IO::Socket::INET;
use File::Basename;
use Linux::Landlock::Direct qw(:constants);
use Math::BigInt;

my $ppid = getppid;
my $base        = dirname(__FILE__) . '/data';
my $abi_version = Linux::Landlock->get_abi_version();
if ($abi_version < 0) {
    throws_ok(sub { Linux::Landlock->new() }, qr/not available/, "Landlock not available");
} else {
    my $ruleset = Linux::Landlock->new(restricted_ipc => [], die_on_unsupported => 1);
    ok($ruleset->allow_perl_inc_access(), "allow_perl_inc_access");
    is(
        $ruleset->add_path_beneath_rule($base, qw(read_file)),
        $LANDLOCK_ACCESS_FS{READ_FILE},
        "allow read_file in $base"
    );
    is(
        $ruleset->add_path_beneath_rule('/usr', qw(execute read_file)),
        $LANDLOCK_ACCESS_FS{READ_FILE} | $LANDLOCK_ACCESS_FS{EXECUTE},
        "allow read_file + execute in /usr"
    );
    ok($ruleset->allow_std_dev_access(), "allow_std_dev_access");
    if ($abi_version >= 4) {
        is($ruleset->add_net_port_rule(33333, 'bind_tcp'), $LANDLOCK_ACCESS_NET{BIND_TCP}, "allow port 33333");
    } else {
        throws_ok(sub { $ruleset->add_net_port_rule(33333, 'bind_tcp') }, qr/invalid/i, "no network support");
    }
    ok(defined IO::Dir->new("/"),  "can opendir /");
    ok($ruleset->apply(),          "apply ruleset");
    ok(kill(0, $ppid),                "can signal parent ($ppid)");
    ok(!defined IO::Dir->new("/"), "can no longer opendir /");
    ok($!{EACCES},                 "correct error: $!");
    $! = 0;
    ok(eval { require Data::Dumper; }, "require Data::Dumper");

    SKIP: {
        skip "no network support", if $abi_version < 4;
        ok(defined IO::Socket::INET->new(LocalPort  => 33333, Proto => 'tcp',), "socket created");
        ok(!defined IO::Socket::INET->new(LocalPort => 33334, Proto => 'tcp',), "socket not created: $!");
    }
    for (@INC) {
        next unless -d $_;
        next if $_ eq '.';
        ok(IO::Dir->new($_), "opendir $_");
    }
    for (qw(/ /var)) {
        ok(-r $_,                     "technically readable: $_");
        ok(!defined IO::Dir->new($_), "opendir $_ failed");
    }
    ok(defined IO::File->new("$base/a", 'r'), "readable: $base/a");
    ok(defined IO::File->new("$base/b", 'r'), "readable: $base/b");
    # may not exist in some environments
    SKIP: {
        skip "no /usr/bin/cat", unless -x '/usr/bin/cat';
        is(system("/usr/bin/cat $base/a"), 0, "cat $base/a is allowed...");
        is(system("/usr/bin/cat $base/a > /dev/null"), 0, "... as is writing to /dev/null");
    }

    my $ruleset2 = Linux::Landlock->new();
    ok($ruleset2->allow_perl_inc_access(), "allow_perl_inc_access");
    is(
        $ruleset2->add_path_beneath_rule("$base/a", qw(read_file)),
        $LANDLOCK_ACCESS_FS{READ_FILE},
        "allow read_file on $base/a"
    );
    ok($ruleset2->apply(), "apply ruleset");
    SKIP: {
        skip "No signal restrictions possible", if $abi_version < 6;
        ok(!kill(0, $ppid),               "cannot signal parent ($ppid)");
    }
    ok(-r "$base/b",       "technically readable: $base/b");
    $! = 0;
    ok(!defined IO::File->new("$base/b", 'r'), "no longer readable: $base/b");
    ok($!{EACCES},                             "correct error: $!");
    ok(defined IO::File->new("$base/a", 'r'), "still readable: $base/a...");
    SKIP: {
        skip "no /usr/bin/cat", unless -x '/usr/bin/cat';
        is(system("/usr/bin/cat $base/a"), -1, "no permission to run cat");
    }
    for (@INC) {
        next unless -d $_;
        next if $_ eq '.';
        ok(IO::Dir->new($_), "opendir $_");
    }
    my $ruleset_strict = Linux::Landlock->new(die_on_unsupported => 1);
    ok(defined $ruleset_strict, "ruleset created");
    $LANDLOCK_ACCESS_FS{BOGUS} = Math::BigInt->bone->blsft(60);
    throws_ok(sub { $ruleset_strict->add_path_beneath_rule("$base/a", qw(read_file bogus)) },
        qr/Unsupported/, "unsupported rule caught");
    my $ruleset_relaxed = Linux::Landlock->new();
    ok($ruleset_relaxed->add_path_beneath_rule("$base/a", qw(read_file bogus)), "unsupported rule ignored");
    my $ruleset_noop = Linux::Landlock->new(handled_fs_actions => [qw(write_file)], die_on_unsupported => 1);
    throws_ok(sub { $ruleset_noop->add_path_beneath_rule("$base/a", qw(execute)) },
        qr/Invalid/, "added rule is not covered by ruleset");
}
done_testing();

