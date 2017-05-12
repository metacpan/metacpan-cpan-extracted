use strict;
use warnings;
use Test::More tests => 19;
use Log::Handler;

my %msg;

sub counter {
    if (shift->{message} =~ /(INFO|WARN).+(unknown\d|forward\d)/) {
        $msg{$2}{$1}++;
    }
}

my $log = Log::Handler->new();

$log->config(
    config => {
        forward => [
            {
                alias    => "forward1",
                maxlevel => "info",
                minlevel => "emerg",
                priority => 2,
                forward_to     => \&counter,
                message_layout => "%L - forward1 %m",
            },
            {
                alias    => "forward2",
                maxlevel => "info",
                minlevel => "emerg",
                priority => 1,
                forward_to     => \&counter,
                message_layout => "%L - forward2 %m",
            },
            {
                alias    => "forward3",
                maxlevel => "info",
                minlevel => "emerg",
                priority => 3,
                forward_to     => \&counter,
                message_layout => "%L - forward3 %m",
            },
            {
                maxlevel => "info",
                minlevel => "emerg",
                priority => 3,
                forward_to     => \&counter,
                message_layout => "%L - unknown1 %m",
            },
        ],
    },
);

$log->warning(1);
$log->info(1);

$log->reload(
    config => {
        forward => [
            {
                alias    => "forward1",
                maxlevel => "warning",
                minlevel => "emerg",
                priority => 2,
                forward_to     => \&counter,
                message_layout => "%T [%L] forward1 %m",
            },
            {
                alias    => "forward3",
                maxlevel => "warning",
                minlevel => "emerg",
                priority => 1,
                forward_to     => \&counter,
                message_layout => "%T [%L] forward3 %m",
            },
            {
                alias    => "forward4",
                maxlevel => "warning",
                minlevel => "emerg",
                priority => 1,
                forward_to     => \&counter,
                message_layout => "%T [%L] forward4 %m",
            },
            {
                alias    => "forward5",
                maxlevel => "warning",
                minlevel => "emerg",
                priority => 1,
                forward_to     => \&counter,
                message_layout => "%T [%L] forward5 %m",
            },
            {
                maxlevel => "warning",
                minlevel => "emerg",
                priority => 3,
                forward_to     => \&counter,
                message_layout => "%L - unknown2 %m",
            },
        ],
    }
) or die $log->errstr;

ok(1, "reload");

$log->warning(1);
$log->info(1);

my $f1 = scalar keys %{$msg{forward1}};
my $f2 = scalar keys %{$msg{forward2}};
my $f3 = scalar keys %{$msg{forward3}};
my $f4 = scalar keys %{$msg{forward4}};
my $f5 = scalar keys %{$msg{forward5}};

ok($f1 == 2, "checking forward1 keys ($f1)");
ok($f2 == 2, "checking forward2 keys ($f2)");
ok($f3 == 2, "checking forward3 keys ($f3)");
ok($f4 == 1, "checking forward4 keys ($f4)");
ok($f5 == 1, "checking forward5 keys ($f5)");

ok($msg{forward1}{INFO} == 1, "checking forward1 INFO ($msg{forward1}{INFO})");
ok($msg{forward1}{WARN} == 2, "checking forward1 WARN ($msg{forward1}{WARN})");
ok($msg{forward2}{INFO} == 1, "checking forward2 INFO ($msg{forward2}{INFO})");
ok($msg{forward2}{WARN} == 1, "checking forward2 WARN ($msg{forward2}{WARN})");
ok($msg{forward3}{INFO} == 1, "checking forward3 INFO ($msg{forward3}{INFO})");
ok($msg{forward3}{WARN} == 2, "checking forward3 WARN ($msg{forward3}{WARN})");
ok($msg{forward4}{WARN} == 1, "checking forward3 WARN ($msg{forward4}{WARN})");
ok($msg{forward5}{WARN} == 1, "checking forward3 WARN ($msg{forward5}{WARN})");
ok($msg{forward5}{WARN} == 1, "checking forward3 WARN ($msg{forward5}{WARN})");

ok($msg{unknown1}{INFO} == 1, "checking unknown1 INFO ($msg{unknown1}{INFO})");
ok($msg{unknown1}{WARN} == 1, "checking unknown1 INFO ($msg{unknown1}{WARN})");
ok($msg{unknown2}{WARN} == 1, "checking unknown2 INFO ($msg{unknown1}{WARN})");
ok(!exists $msg{unknown2}{INFO}, "checking unknown2 INFO");
