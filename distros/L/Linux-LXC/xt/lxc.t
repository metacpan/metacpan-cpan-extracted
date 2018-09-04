#!/usr/bin/env perl

#use v5.20;
use strict;

use Log::Any::Adapter('File', 'log.txt');
use Test::Deep;
use Test::Exception;
use Test::More;
use Linux::LXC qw(ALLOW_UNDEF ADDITION_MODE ERASING_MODE);

my $container = Linux::LXC->new(utsname => 'lxc-test');
$container->set_template('alpine');
$container->destroy if $container->is_existing;
ok !$container->is_existing, 'is_Existing return false.';
is $container->get_lxc_path, '/var/lib/lxc/lxc-test', 'Lxcpath has the good default value.';
throws_ok {$container->get_config('lxc.network.ipv4')}
  qr/Container lxc-test doesn't exist/, 'Error throwed because container is not existing.';

$container->deploy;
ok $container->is_existing, 'is_existing returns true.';
ok grep{'lxc-test'} `lxc-ls -1`, 'Container is not created.';
ok grep{'lxc-test'} $container->get_existing_containers, 'Container is present in get_existing_containers.';
ok grep{'lxc-test'} $container->get_stopped_containers, 'Container is present in get_stopped_containers.';
ok grep{'lxc-test'} $container->get_running_containers == 0, 'Container is absent of get_running_containers.';
ok !$container->is_running, 'is_running returns false.';
ok $container->is_stopped, 'Container is considered as stopped.';
my @containerConfig = $container->get_config('lxc.utsname');
is $containerConfig[0], 'lxc-test', 'Can fetch a configuration value.';
is_deeply {$container->get_config('lxc.arch', qr/x(\d+)_(\d+)/)},
	{'86', '64'}, 'Check multi select configuration value.';
throws_ok {$container->get_config()}
	qr/Parameter to get is missing/, 'Check get_config without parameter.';

$container->set_config('lxc.aa_allow_incomplete', 1);
$container->start;
ok !$container->is_stopped, 'Container is not considered as stopped.';
ok grep{'lxc-test'} $container->get_stopped_containers == 0, 'Container is not present is get_stopped_containers.';
ok $container->is_running, 'Container is considered as running.';
ok grep{'lxc-test'} $container->get_running_containers, 'Container is present in get_running_containers.';

`echo testing > /tmp/lxc-test.txt`;
$container->set_config('lxc.id_map', 'u 0 4300000 100000', ADDITION_MODE);
$container->set_config('lxc.id_map', 'g 0 4300000 100000', ADDITION_MODE);
$container->put('/tmp/lxc-test.txt', '/etc/random/lxc-test.txt');
ok -f '/var/lib/lxc/lxc-test/rootfs/etc/random/lxc-test.txt', 'A file was correctly put into the container.';
my %paths = (
	'' => 0,
	'/etc' => 0,
	'/etc/random' => 4300000,
	'/etc/random/lxc-test.txt' => 4300000
);
for (keys %paths) {
	my @stats = stat '/var/lib/lxc/lxc-test/rootfs' . $_;
	ok $stats[4] eq $paths{$_}, 'Correct ownership';
}
$container->del_config('lxc.id_map');
my $cmd = $container->exec('cat /someting/that/doesnt/exist');
ok !$cmd, 'Scalar retured by exec is correct.';
my ($status, $stdout, $stderr) = $container->exec('cat /etc/random/lxc-test.txt');
ok $status, 'Execution return status of exec is correct.';
ok (chomp $stdout) eq 'testing', 'Stdout return of exec is correct.';
ok $stderr eq '', 'Stderr of exec is correct.';

$container->stop;
ok $container->is_stopped, 'Container is stopped';

$container->set_config('newnode', '42');
my @configValues = $container->get_config('newnode');
is $configValues[0], '42', 'Creation of a new configuration attribute.';
$container->set_config('lxc.network.ipv4', '42.42.42.42');
throws_ok {$container->set_config('lxc.network.ipv4', '12.12.12.12', ERASING_MODE | ADDITION_MODE)}
  qr/set_config can not be in erasing and addition mode/, 'Test set_config erasing and addition modes exclusion.';
@configValues = $container->get_config('lxc.network.ipv4');
is $configValues[0], '42.42.42.42', 'Update of a configuration attribute.';
throws_ok {$container->get_config('lxc.non-existing')}
  qr/'lxc.non-existing' attribute was not found in lxc configuration file with filter (?^u:(.*))/;
is $container->get_config('lxc.non-existing', undef, ALLOW_UNDEF), 0, 'get_config with ALLOW_UNDEF';
$container->set_config('lxc.network.ipv4', '12.13.14.15', ADDITION_MODE);
my @ipExpected = ('42.42.42.42', '12.13.14.15');
my @ipFetched = $container->get_config('lxc.network.ipv4');
cmp_bag(\@ipExpected, \@ipFetched, 'set_config addition mode is working.');

$container->set_config('lxc.network.ipv4', '12.13.14.16', ADDITION_MODE);
$container->set_config('lxc.network.ipv4', '12.50.14.16', ADDITION_MODE);
$container->set_config('lxc.network.ipv4', '12.50.14.17', ADDITION_MODE);
my $lines_deleted = $container->del_config('lxc.network.ipv4', qr/^12.13/);
ok $lines_deleted == 2, 'del_config result seems correct.';
@ipExpected = ('42.42.42.42', '12.50.14.16', '12.50.14.17');
@ipFetched = $container->get_config('lxc.network.ipv4');
cmp_bag(\@ipExpected, \@ipFetched, 'del_config with filter seems to work.');
$lines_deleted = $container->del_config('lxc.network.ipv4');
ok $lines_deleted == 3;
@ipFetched = $container->get_config('lxc.network.ipv4', undef, ALLOW_UNDEF);
ok @ipFetched == 0, 'del_config without filter seems to work.';

$container->destroy;
ok grep{'lxc-test'} $container->get_existing_containers == 0, 'Container is absent of get_existing_containers.';
ok grep{'lxc-test'} `lxc-ls -1` == 0, 'Container doesn\'t exist anymore.';

done_testing;
