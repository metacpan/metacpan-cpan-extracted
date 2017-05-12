# -*- perl -*-

# t/01-usevars.t - check use vars

use strict;
use warnings;

use Test::Simple tests => 5;

use IPC::Lite qw($x $obj %h);

$x = '' if !defined $x;

my $t = time();

$x = $t;

$h{1} = 'one';
$h{time} = $t;

my %x;
$obj = \%x;
$x{5} = $t;

ok(ref(tied(%x)) eq 'IPC::Lite', 'inherit tie');
ok($x eq $t, "\$x = $x");
ok($h{1} eq 'one', "\$h{1} = 'one'");
ok($h{time} eq $t, "\$h{time} = '$t'");
ok($obj->{5} eq $t, "\$obj->{5} = '$t'");
