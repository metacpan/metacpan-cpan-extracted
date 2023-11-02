#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use Getopt::Long;
use Test::More;
use Sys::Hostname;

use Doit;

sub get_hostname {
    return hostname;
}

sub stdout_test {
    print "This goes to STDOUT\n";
    4711;
}

sub stderr_test {
    print STDERR "This goes to STDERR\n";
    314;
}

return 1 if caller;

require FindBin;
{ no warnings 'once'; push @INC, "$FindBin::RealBin/../t"; }
require TestUtil;

my $doit = Doit->init;

plan skip_all => 'docker not in PATH'
    if !$doit->which('docker');

my $name = 'doit-docker-component-test';
eval {
    # just in case
    $doit->system('docker', 'stop', '-t=0', $name);
    $doit->system('docker', 'rm', $name);
};
eval {
    $doit->system('docker', 'run', '--detach', '-h', $name, "--name=$name", 'debian:bookworm', 'sleep', '3600');
    $doit->system('docker', 'exec', $name, 'sh', '-c', 'apt-get update && apt-get install -y perl-modules');
};
plan skip_all => "Cannot create docker container: $@"
    if $@;

plan 'no_plan';

$doit->add_component('docker');
ok $doit->can('docker_connect'), 'add_component was successful';

my $docker = $doit->docker_connect(container => $name);

my $res = $docker->call('get_hostname');
is $res, $name, 'hostname in container';

is $docker->call('stdout_test'), 4711;
is $docker->call('stderr_test'), 314;

{
    my $res = $docker->qx({quiet=>1}, 'perl', '-e', 'print "STDOUT without newline"');
    is $res, 'STDOUT without newline';
}

# not needed anymore, but try it anyway
$docker->exit;

$doit->system('docker', 'stop', '-t=0', $name);
$doit->system('docker', 'rm', $name);

__END__
