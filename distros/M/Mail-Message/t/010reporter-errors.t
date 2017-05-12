#!/usr/bin/env perl
#
# Test producing warnings, errors and family.
#

use strict;
use warnings;

use Mail::Reporter;
use Mail::Message::Test;

use Test::More tests => 41;

#
# Dualvar logPriority
#

my $a = Mail::Reporter->logPriority('WARNING');
ok(defined $a);
ok($a == 4);
is($a, 'WARNING');

my $b = Mail::Reporter->logPriority('WARNINGS');
ok(defined $b);
ok($b == 4);
is($b, 'WARNING');

my $c = Mail::Reporter->logPriority(4);
ok(defined $c);
ok($c == 4);
is($c, 'WARNING');

my $d = Mail::Reporter->logPriority('AAP');
ok(!defined $d);
my $e = Mail::Reporter->logPriority(8);
ok(!defined $e);

#
# Initial default trace
#

my ($l, $t) = Mail::Reporter->defaultTrace;
ok(defined $l);
ok(defined $t);

is($l, 'WARNING',                   'string log level');
cmp_ok($l, '==',  4,                'numeric log level');

is($t, 'WARNING',                   'string trace level');
cmp_ok($t, '==',  4,                'string trace level');



#
# Set default trace
#

($l, $t) = Mail::Reporter->defaultTrace('DEBUG', 'ERRORS');
ok(defined $l);
ok(defined $t);

is($l, 'DEBUG',                     'string log level');
cmp_ok($l, '==',  1,                'numeric log level');

is($t, 'ERROR',                     'string trace level');
cmp_ok($t, '==',  5,                'string trace level');

($l, $t) = Mail::Reporter->defaultTrace('PROGRESS');
is($l, 'PROGRESS',                  'string log level');
cmp_ok($l, '==',  3,                'numeric log level');

is($t, 'PROGRESS',                  'string trace level');
cmp_ok($t, '==',  3,                'string trace level');

($l, $t) = Mail::Reporter->defaultTrace('WARNING', 'WARNINGS');
is($l, 'WARNING',                   'string log level');
cmp_ok($l, '==',  4,                'numeric log level');

is($t, 'WARNING',                   'string trace level');
cmp_ok($t, '==',  4,                'string trace level');

#
# Reporting levels based on objects
#

my $rep = Mail::Reporter->new;
ok(defined $rep);
is($rep->log, 'WARNING',            'Default log-level');
cmp_ok($rep->log, '==', 4);
$l = $rep->log;
is($l, 'WARNING',                   'Default log-level');
cmp_ok($l, '==', 4);

is($rep->trace, 'WARNING',          'Default trace-level');
cmp_ok($rep->trace, '==', 4);
$t = $rep->trace;
is($t, 'WARNING',                   'Default trace-level');
cmp_ok($t, '==', 4);

cmp_ok($rep->trace('ERROR'), '==', 5,   'Check error level numbers');
