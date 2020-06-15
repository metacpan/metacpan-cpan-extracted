#!perl

# UsRobotics module test
#
# $Id: usrobotics.t,v 1.2 2006-04-20 20:19:22 cosimo Exp $

use strict;
use Test::More;

plan tests => 6;

use_ok('Device::Modem::UsRobotics');

my $modem = Device::Modem::UsRobotics->new(
    port => '/dev/ttyS0',
    log => 'file,./usrobotics.log',
    loglevel=>'info'
);

ok($modem, 'UsRobotics object ok');

$modem->connect(baudrate=>19200) or die "Can't connect";

ok($modem, 'connected');

$modem->attention();

# Test MCC usr extension
my $ans = $modem->mcc_get();
diag('mcc: ', $ans, "\n");
ok(defined $ans && $ans ne '' && $ans =~ /[\d\,]+/, 'mcc command');

# Test msr extension
$ans = $modem->msg_status();
diag('msr: ', $ans, "\n");
ok($ans =~ /\d+,\d+,\d+,\d+/, 'message status ok');

ok($modem->disconnect(), 'disconnected');
