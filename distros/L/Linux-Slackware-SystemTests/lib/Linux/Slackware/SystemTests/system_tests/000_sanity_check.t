#!/usr/bin/perl

use strict;
use warnings;
use Test::Most;

use lib "./lib";
use Linux::Slackware::SystemTests;

my $st = Linux::Slackware::SystemTests->new();

ok -d '/tmp',     'got /tmp';
ok -d '/var/tmp', 'got /var/tmp';

# Trivially test some things in /bin, see if they execute at all:
foreach my $x (qw(arch base64 cat cksum date df dnsdomainname domainname expand fmt fold free groups head hostid hostname id ls lsblk lsmod more mount nisdomainname nproc paste pinky pr printenv ps ptx pwd shuf sort sum sync tail true tsort uname uniq users vdir wc who whoami ypdomainname)) {
    is system("echo '' | /bin/$x > /dev/null"), 0, "trivial exec /bin/$x";
}

# Trivially test false, see if it executes at all:
is system("echo '' | /bin/false > /dev/null"), 256, "trivial exec /bin/false";

# Trivially test some things in /sbin, see if they execute at all:
foreach my $x (qw(arp ifconfig iwconfig iwpriv iwspy lsmod lspci lspcmcia mount nstat route runlevel)) {
    is system("echo '' | /sbin/$x > /dev/null 2>\&1"), 0, "trivial exec /sbin/$x";
}

done_testing();
exit 0;
