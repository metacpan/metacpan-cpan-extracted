#!/usr/bin/perl
#
# Copyright (C) 2011 by Mark Hindess

use strict;
use constant DEBUG => $ENV{DEVICE_CURRENT_COST_TEST_DEBUG};
use Test::More tests => 34;

$|=1;
use_ok('Device::CurrentCost');
use_ok('Device::CurrentCost::Message');
BEGIN { use_ok('Device::CurrentCost::Constants'); }

my @history = ();
sub hist_cb { push @history, [ @_ ] };
open my $fh, 't/log/cc128.incomplete.history.xml';
my $dev =
  Device::CurrentCost->new(filehandle => $fh, history_callback => \&hist_cb);
is($dev->type, CURRENT_COST_ENVY, 'envy device');
my $msg = $dev->read;
ok($msg, 'read message 1');
ok($msg->has_history, '... has history');
is($msg->summary, q{Device: CC128 v0.11
  History
    Sensor 0
      -6 months: 698.75
      -7 months: 695.25
      -8 months: 787.75
      -9 months: 788.5
    Sensor 1
      -6 months: 0
      -7 months: 0
      -8 months: 0
      -9 months: 0
    Sensor 2
      -6 months: 0
      -7 months: 0
      -8 months: 0
      -9 months: 0
    Sensor 3
      -6 months: 0
      -7 months: 0
      -8 months: 0
      -9 months: 0
    Sensor 4
      -6 months: 0
      -7 months: 0
      -8 months: 0
      -9 months: 0
    Sensor 5
      -6 months: 0
      -7 months: 0
      -8 months: 0
      -9 months: 0
    Sensor 6
      -6 months: 0
      -7 months: 0
      -8 months: 0
      -9 months: 0
    Sensor 7
      -6 months: 0
      -7 months: 0
      -8 months: 0
      -9 months: 0
    Sensor 8
      -6 months: 0
      -7 months: 0
      -8 months: 0
      -9 months: 0
    Sensor 9
      -6 months: 0
      -7 months: 0
      -8 months: 0
      -9 months: 0
}, '... summary');

$msg = $dev->read;
ok($msg, 'read message 2');
ok($msg->has_history, '... has history');
is($msg->summary, q{Device: CC128 v0.11
  History
    Sensor 0
      -2 months: 1443.5
      -3 months: 1705.75
      -4 months: 1084
      -5 months: 780
    Sensor 1
      -2 months: 0
      -3 months: 0
      -4 months: 0
      -5 months: 0
    Sensor 2
      -2 months: 0
      -3 months: 0
      -4 months: 0
      -5 months: 0
    Sensor 3
      -2 months: 0
      -3 months: 0
      -4 months: 0
      -5 months: 0
    Sensor 4
      -2 months: 0
      -3 months: 0
      -4 months: 0
      -5 months: 0
    Sensor 5
      -2 months: 0
      -3 months: 0
      -4 months: 0
      -5 months: 0
    Sensor 6
      -2 months: 0
      -3 months: 0
      -4 months: 0
      -5 months: 0
    Sensor 7
      -2 months: 0
      -3 months: 0
      -4 months: 0
      -5 months: 0
    Sensor 8
      -2 months: 0
      -3 months: 0
      -4 months: 0
      -5 months: 0
    Sensor 9
      -2 months: 0
      -3 months: 0
      -4 months: 0
      -5 months: 0
}, '... summary');

$msg = $dev->read;
ok($msg, 'read message 3');
ok($msg->has_history, '... has history');
is($msg->summary, q{Device: CC128 v0.11
  History
    Sensor 0
      -1 months: 1248.25
    Sensor 1
      -1 months: 0
    Sensor 2
      -1 months: 0
    Sensor 3
      -1 months: 0
    Sensor 4
      -1 months: 0
    Sensor 5
      -1 months: 0
    Sensor 6
      -1 months: 0
    Sensor 7
      -1 months: 0
    Sensor 8
      -1 months: 0
    Sensor 9
      -1 months: 0
}, '... summary');
is_deeply(\@history, [], 'incomplete so callback not called');

open $fh, 't/log/cc128.complete.history.xml';
$dev =
  Device::CurrentCost->new(filehandle => $fh, history_callback => \&hist_cb);
is($dev->type, CURRENT_COST_ENVY, 'envy device');
$msg = $dev->read;
ok($msg, 'read message 1');
ok($msg->has_history, '... has history');
is($msg->summary, q{Device: CC128 v0.11
  History
    Sensor 0
      -18 months: 930
      -19 months: 903.25
      -20 months: 879.75
      -21 months: 995
    Sensor 1
      -18 months: 0
      -19 months: 0
      -20 months: 0
      -21 months: 0
    Sensor 2
      -18 months: 0
      -19 months: 0
      -20 months: 0
      -21 months: 0
    Sensor 3
      -18 months: 0
      -19 months: 0
      -20 months: 0
      -21 months: 0
    Sensor 4
      -18 months: 0
      -19 months: 0
      -20 months: 0
      -21 months: 0
    Sensor 5
      -18 months: 0
      -19 months: 0
      -20 months: 0
      -21 months: 0
    Sensor 6
      -18 months: 0
      -19 months: 0
      -20 months: 0
      -21 months: 0
    Sensor 7
      -18 months: 0
      -19 months: 0
      -20 months: 0
      -21 months: 0
    Sensor 8
      -18 months: 0
      -19 months: 0
      -20 months: 0
      -21 months: 0
    Sensor 9
      -18 months: 2.75
      -19 months: 2.75
      -20 months: 2.75
      -21 months: 2.25
}, '... summary');

$msg = $dev->read;
ok($msg, 'read message 2');
ok($msg->has_history, '... has history');
is($msg->summary, q{Device: CC128 v0.11
  History
    Sensor 0
      -14 months: -2024.3
      -15 months: 1906
      -16 months: 1152.25
      -17 months: 982.5
    Sensor 1
      -14 months: 0
      -15 months: 0
      -16 months: 0
      -17 months: 0
    Sensor 2
      -14 months: 0
      -15 months: 0
      -16 months: 0
      -17 months: 0
    Sensor 3
      -14 months: 0
      -15 months: 0
      -16 months: 0
      -17 months: 0
    Sensor 4
      -14 months: 0
      -15 months: 0
      -16 months: 0
      -17 months: 0
    Sensor 5
      -14 months: 0
      -15 months: 0
      -16 months: 0
      -17 months: 0
    Sensor 6
      -14 months: 0
      -15 months: 0
      -16 months: 0
      -17 months: 0
    Sensor 7
      -14 months: 0
      -15 months: 0
      -16 months: 0
      -17 months: 0
    Sensor 8
      -14 months: 0
      -15 months: 0
      -16 months: 0
      -17 months: 0
    Sensor 9
      -14 months: 0.5
      -15 months: 1.25
      -16 months: 2.25
      -17 months: 2.75
}, '... summary');

$msg = $dev->read;
ok($msg, 'read message 3');
ok($msg->has_history, '... has history');
is($msg->summary, q{Device: CC128 v0.11
  History
    Sensor 0
      -10 months: 792.75
      -11 months: 917.25
      -12 months: 1449.25
      -13 months: 2031.5
    Sensor 1
      -10 months: 0
      -11 months: 0
      -12 months: 0
      -13 months: 0
    Sensor 2
      -10 months: 0
      -11 months: 0
      -12 months: 0
      -13 months: 0
    Sensor 3
      -10 months: 0
      -11 months: 0
      -12 months: 0
      -13 months: 0
    Sensor 4
      -10 months: 0
      -11 months: 0
      -12 months: 0
      -13 months: 0
    Sensor 5
      -10 months: 0
      -11 months: 0
      -12 months: 0
      -13 months: 0
    Sensor 6
      -10 months: 0
      -11 months: 0
      -12 months: 0
      -13 months: 0
    Sensor 7
      -10 months: 0
      -11 months: 0
      -12 months: 0
      -13 months: 0
    Sensor 8
      -10 months: 0
      -11 months: 0
      -12 months: 0
      -13 months: 0
    Sensor 9
      -10 months: 0
      -11 months: 0
      -12 months: 0.5
      -13 months: 0.25
}, '... summary');

$msg = $dev->read;
ok($msg, 'read message 4');
ok($msg->has_history, '... has history');
is($msg->summary, q{Device: CC128 v0.11
  History
    Sensor 0
      -6 months: 698.75
      -7 months: 695.25
      -8 months: 787.75
      -9 months: 788.5
    Sensor 1
      -6 months: 0
      -7 months: 0
      -8 months: 0
      -9 months: 0
    Sensor 2
      -6 months: 0
      -7 months: 0
      -8 months: 0
      -9 months: 0
    Sensor 3
      -6 months: 0
      -7 months: 0
      -8 months: 0
      -9 months: 0
    Sensor 4
      -6 months: 0
      -7 months: 0
      -8 months: 0
      -9 months: 0
    Sensor 5
      -6 months: 0
      -7 months: 0
      -8 months: 0
      -9 months: 0
    Sensor 6
      -6 months: 0
      -7 months: 0
      -8 months: 0
      -9 months: 0
    Sensor 7
      -6 months: 0
      -7 months: 0
      -8 months: 0
      -9 months: 0
    Sensor 8
      -6 months: 0
      -7 months: 0
      -8 months: 0
      -9 months: 0
    Sensor 9
      -6 months: 0
      -7 months: 0
      -8 months: 0
      -9 months: 0
}, '... summary');

$msg = $dev->read;
ok($msg, 'read message 5');
ok($msg->has_history, '... has history');
is($msg->summary, q{Device: CC128 v0.11
  History
    Sensor 0
      -2 months: 1443.5
      -3 months: 1705.75
      -4 months: 1084
      -5 months: 780
    Sensor 1
      -2 months: 0
      -3 months: 0
      -4 months: 0
      -5 months: 0
    Sensor 2
      -2 months: 0
      -3 months: 0
      -4 months: 0
      -5 months: 0
    Sensor 3
      -2 months: 0
      -3 months: 0
      -4 months: 0
      -5 months: 0
    Sensor 4
      -2 months: 0
      -3 months: 0
      -4 months: 0
      -5 months: 0
    Sensor 5
      -2 months: 0
      -3 months: 0
      -4 months: 0
      -5 months: 0
    Sensor 6
      -2 months: 0
      -3 months: 0
      -4 months: 0
      -5 months: 0
    Sensor 7
      -2 months: 0
      -3 months: 0
      -4 months: 0
      -5 months: 0
    Sensor 8
      -2 months: 0
      -3 months: 0
      -4 months: 0
      -5 months: 0
    Sensor 9
      -2 months: 0
      -3 months: 0
      -4 months: 0
      -5 months: 0
}, '... summary');

$msg = $dev->read;
ok($msg, 'read message 6');
ok($msg->has_history, '... has history');
is($msg->summary, q{Device: CC128 v0.11
  History
    Sensor 0
      -1 months: 1248.25
    Sensor 1
      -1 months: 0
    Sensor 2
      -1 months: 0
    Sensor 3
      -1 months: 0
    Sensor 4
      -1 months: 0
    Sensor 5
      -1 months: 0
    Sensor 6
      -1 months: 0
    Sensor 7
      -1 months: 0
    Sensor 8
      -1 months: 0
    Sensor 9
      -1 months: 0
}, '... summary');
is_deeply(\@history,
  [
   [
    '0' => 'months',
    {
     '1' => '1248.25', '2' => '1443.5', '3' => '1705.75', '4' => 1084,
     '5' => 780, '6' => '698.75', '7' => '695.25', '8' => '787.75',
     '9' => '788.5', '10' => '792.75', '11' => '917.25', '12' => '1449.25',
     '13' => '2031.5', '14' => '-2024.3', '15' => 1906, '16' => '1152.25',
     '17' => '982.5', '18' => 930, '19' => '903.25', '20' => '879.75',
     '21' => 995,
    }
   ],
   [
    '1' => 'months',
    {
     '1' => 0, '2' => 0, '3' => 0, '4' => 0, '5' => 0, '6' => 0,
     '7' => 0, '8' => 0, '9' => 0, '10' => 0, '11' => 0, '12' => 0,
     '13' => 0, '14' => 0, '15' => 0, '16' => 0, '17' => 0, '18' => 0,
     '19' => 0, '20' => 0, '21' => 0,
    }
   ],
   [
    '2' => 'months',
    {
     '1' => 0, '2' => 0, '3' => 0, '4' => 0, '5' => 0, '6' => 0,
     '7' => 0, '8' => 0, '9' => 0, '10' => 0, '11' => 0, '12' => 0,
     '13' => 0, '14' => 0, '15' => 0, '16' => 0, '17' => 0, '18' => 0,
     '19' => 0, '20' => 0, '21' => 0,
    }
   ],
   [
    '3' => 'months',
    {
     '1' => 0, '2' => 0, '3' => 0, '4' => 0, '5' => 0, '6' => 0,
     '7' => 0, '8' => 0, '9' => 0, '10' => 0, '11' => 0, '12' => 0,
     '13' => 0, '14' => 0, '15' => 0, '16' => 0, '17' => 0, '18' => 0,
     '19' => 0, '20' => 0, '21' => 0,
    }
   ],
   [
    '4' => 'months',
    {
     '1' => 0, '2' => 0, '3' => 0, '4' => 0, '5' => 0, '6' => 0,
     '7' => 0, '8' => 0, '9' => 0, '10' => 0, '11' => 0, '12' => 0,
     '13' => 0, '14' => 0, '15' => 0, '16' => 0, '17' => 0, '18' => 0,
     '19' => 0, '20' => 0, '21' => 0,
    }
   ],
   [
    '5' => 'months',
    {
     '1' => 0, '2' => 0, '3' => 0, '4' => 0, '5' => 0, '6' => 0,
     '7' => 0, '8' => 0, '9' => 0, '10' => 0, '11' => 0, '12' => 0,
     '13' => 0, '14' => 0, '15' => 0, '16' => 0, '17' => 0, '18' => 0,
     '19' => 0, '20' => 0, '21' => 0,
    }
   ],
   [
    '6' => 'months',
    {
     '1' => 0, '2' => 0, '3' => 0, '4' => 0, '5' => 0, '6' => 0,
     '7' => 0, '8' => 0, '9' => 0, '10' => 0, '11' => 0, '12' => 0,
     '13' => 0, '14' => 0, '15' => 0, '16' => 0, '17' => 0, '18' => 0,
     '19' => 0, '20' => 0, '21' => 0,
    }
   ],
   [
    '7' => 'months',
    {
     '1' => 0, '2' => 0, '3' => 0, '4' => 0, '5' => 0, '6' => 0,
     '7' => 0, '8' => 0, '9' => 0, '10' => 0, '11' => 0, '12' => 0,
     '13' => 0, '14' => 0, '15' => 0, '16' => 0, '17' => 0, '18' => 0,
     '19' => 0, '20' => 0, '21' => 0,
    }
   ],
   [
    '8' => 'months',
    {
     '1' => 0, '2' => 0, '3' => 0, '4' => 0, '5' => 0, '6' => 0,
     '7' => 0, '8' => 0, '9' => 0, '10' => 0, '11' => 0, '12' => 0,
     '13' => 0, '14' => 0, '15' => 0, '16' => 0, '17' => 0, '18' => 0,
     '19' => 0, '20' => 0, '21' => 0,
    }
   ],
   [
    '9' => 'months',
    {
     '1' => 0, '2' => 0, '3' => 0, '4' => 0, '5' => 0, '6' => 0,
     '7' => 0, '8' => 0, '9' => 0, '10' => 0, '11' => 0,
     '12' => '0.5', '13' => '0.25', '14' => '0.5', '15' => '1.25',
     '16' => '2.25', '17' => '2.75', '18' => '2.75', '19' => '2.75',
     '20' => '2.75', '21' => '2.25',
    }
   ],
  ], 'complete so callback called');
