# -*- perl -*-

# t/03-saved.t - check to see if values were saved from previous test

use strict;
use warnings;
use Test::Simple tests=>2;

use IPC::Lite Path=>'tmp/test.db', qw($obj $t);

my $r;
$r = join(',',values(%{$obj}));
ok("1,$t" eq $r, "v: $r");

$r = join(',',keys(%{$obj}));
ok('one,time' eq $r, "k: $r");

