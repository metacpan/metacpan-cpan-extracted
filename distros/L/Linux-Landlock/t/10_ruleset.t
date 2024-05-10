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

my $base        = dirname(__FILE__) . '/data';
my $ruleset     = Linux::Landlock->new();
my $abi_version = $ruleset->get_abi_version();
ok($ruleset->allow_perl_inc_access(),                              "allow_perl_inc_access");
ok($ruleset->add_path_beneath_rule($base, qw(read_file)),          "allow read_file in $base");
ok($ruleset->add_path_beneath_rule('/usr', qw(execute read_file)), "allow read_file + execute in /usr");
ok($ruleset->allow_std_dev_access(),                               "allow_std_dev_access");
if ($abi_version >= 4) {
    ok($ruleset->add_net_port_rule(33333, 'bind_tcp'), "allow port 33333");
} else {
    throws_ok(sub { $ruleset->add_net_port_rule(33333, 'bind_tcp') }, qr/desired/, "no network support");
}
ok($ruleset->apply(),              "apply ruleset");
ok(eval { require Data::Dumper; }, "require Data::Dumper");
if ($abi_version >= 4) {
    ok(
        defined IO::Socket::INET->new(
            LocalPort => 33333,
            Proto     => 'tcp',
        ),
        "socket created"
    );
    ok(
        !defined IO::Socket::INET->new(
            LocalPort => 33334,
            Proto     => 'tcp',
        ),
        "socket not created: $!"
    );
}
for (@INC) {
    next unless -d $_;
    ok(IO::Dir->new($_), "opendir $_");
}
for (qw(/ /var)) {
    ok(-r $_,                     "technically readable: $_");
    ok(!defined IO::Dir->new($_), "opendir $_ failed");
}
ok(defined IO::File->new("$base/a", 'r'), "readable: $base/a");
ok(defined IO::File->new("$base/b", 'r'), "readable: $base/b");
is(system("/usr/bin/cat $base/a"),             0, "cat $base/a is allowed...");
is(system("/usr/bin/cat $base/a > /dev/null"), 0, "... as is writing to /dev/null");
my $ruleset2 = Linux::Landlock->new();
ok($ruleset2->allow_perl_inc_access(),                         "allow_perl_inc_access");
ok($ruleset2->add_path_beneath_rule("$base/a", qw(read_file)), "allow read_file on $base/a");
ok($ruleset2->apply(),                                         "apply ruleset");
ok(-r "$base/b",                                               "technically readable: $base/b");
# this fails if . was added to @INC
if (!grep { '.' } @INC) {
    ok(!defined IO::File->new("$base/b", 'r'), "no longer readable: $base/b");
}
ok(defined IO::File->new("$base/a", 'r'), "still readable: $base/a...");
is(system("/usr/bin/cat $base/a"), -1, "...but no permission to run cat");
for (@INC) {
    next unless -d $_;
    ok(IO::Dir->new($_), "opendir $_");
}
done_testing();

