# -*- perl -*-

# t/02-path.t - check path create/use

use strict;
use warnings;
use Test::Simple tests=>3;

BEGIN {
	(-d 'tmp') || mkdir('tmp') || die;
}

use IPC::Lite Path=>'tmp/test.db', qw($obj $t);

my %x;
$obj = \%x;		# this ties %x, so x now contains what is in the db

$x{one} = 1;		# $obj->{one} is stored, since %x is now tied 
$x{time} = $t = time();	# $obj->{time} is stored, since %x is now tied 

my $r;

$r = join(',',values(%{$obj}));
ok("1,$t" eq $r, "v: $r");

$r = join(',',keys(%{$obj}));
ok('one,time' eq $r, "k: $r");

ok(exists($x{one}), "exists: x{one}");
