#!/usr/bin/perl;

use strict;
use warnings;
use FindBin;
use Test::More;
use File::Temp;
use File::Slurp;

BEGIN { unshift(@INC, "$FindBin::Bin/../lib") unless $ENV{HARNESS_ACTIVE}; }
	
my $finished = 0;
my $skip = 0;

END { ok($finished, 'finished') unless $skip }

use File::Slurp::Remote;

my $rhost = `$File::Slurp::Remote::SmartOpen::ssh localhost -n hostname`;
my $lhost = `hostname`;

unless ($lhost eq $rhost) {
	$skip = 1;
	plan skip_all => 'Cannot ssh to localhost';
	exit;
}

import Test::More qw(no_plan);

my $dir = tempdir(CLEANUP => 1);

srand($$);

#
# Fake things out so that sometimes we use the remote code and 
# sometimes we use the local code.
#
$File::Slurp::Remote::BrokenDNS::myfqdn = 'local';
$File::Slurp::Remote::BrokenDNS::cache{local} = 'local';
$File::Slurp::Remote::BrokenDNS::cache{localhost} = 'localhost';

write_remote_file('local', "$dir/A", "A1\nA2\n");
my ($a, $b) = read_remote_file('localhost', "$dir/A");

is($a, "A1\n");
is($b, "A2\n");

my $c = read_remote_file('localhost', "$dir/A");

is($c, "A1\nA2\n");

write_remote_file('localhost', "$dir/B", "B1\nB2\n");

my ($d, $e) = read_remote_file('local', "$dir/B");

is($d, "B1\n");
is($e, "B2\n");

my $f = read_remote_file('local', "$dir/B");

is($f, "B1\nB2\n");

write_remote_file('local', "$dir/C.gz", "C1\nC2\n");
my ($g, $h) = read_remote_file('localhost', "$dir/C.gz");

is($g, "C1\n");
is($h, "C2\n");

my $i = read_remote_file('localhost', "$dir/C.gz");

is($i, "C1\nC2\n");

my $j = read_file("$dir/C.gz");

isnt($i, $j);

write_remote_file('localhost', "$dir/D.gz", "D1\nD2\n");

my ($k, $l) = read_remote_file('local', "$dir/D.gz");

is($k, "D1\n");
is($l, "D2\n");

my $m = read_remote_file('local', "$dir/D.gz");

is($m, "D1\nD2\n");

my $n = read_file("$dir/D.gz");

isnt($m, $n);

$finished = 1;

