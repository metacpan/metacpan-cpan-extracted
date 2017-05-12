#!/usr/bin/env perl
#
# Test reporting warnings and errors
#

use strict;
use warnings;

use Mail::Reporter;
use Mail::Message::Test;

use Test::More tests => 51;

my $rep = Mail::Reporter->new;
ok(defined $rep);

my $catch;
{  local $SIG{__WARN__} = sub { $catch = shift };
   $rep->log(ERROR => 'a test');   # \n will be added
}

is($catch, "ERROR: a test\n",           'Stored one error text');
cmp_ok($rep->report('ERRORS'), '==', 1, 'Counts one error');
is(($rep->report('ERRORS'))[0], "a test", 'Correctly stored text');

undef $catch;
{  local $SIG{__WARN__} = sub { $catch = shift };
   $rep->log(WARNING => "filter");
}

ok(defined $catch,                        'No visible warnings');
cmp_ok($rep->report('WARNING'), '==', 1,  'Count logged warnings');
cmp_ok($rep->report('ERROR'), '==', 1,    'Count logged errors');
cmp_ok($rep->report, '==', 2,             'Count all logged messages');
is(($rep->report('WARNINGS'))[0], "filter", 'No \n added');

my @reps = $rep->report;
is($reps[0][0], 'WARNING',                'Checking report()');
is($reps[0][1], "filter");
is($reps[1][0], 'ERROR');
is($reps[1][1], "a test");

@reps = $rep->reportAll;
is($reps[0][0], $rep,                     'Checking reportAll()');
is($reps[0][1], 'WARNING');
is($reps[0][2], "filter");
is($reps[1][0], $rep);
is($reps[1][1], 'ERROR');
is($reps[1][2], "a test");

cmp_ok($rep->errors, '==', 1,             'Check errors() short-cut');
cmp_ok($rep->warnings, '==', 1,           'Check warnings() short-cut');

#
# Check merging reports
#

my $r2 = Mail::Reporter->new(trace => 'NONE', log => 'DEBUG');
ok(defined $r2,                           'Another traceable object');
isa_ok($r2, 'Mail::Reporter');
ok($r2->log(WARNING => 'I warn you!'));
ok($r2->log(ERROR => 'You are in error'));
ok($r2->log(ERROR => 'I am sure!!'));
ok($r2->log(NOTICE => 'Don\'t notice me'));
$rep->addReport($r2);

@reps = $rep->reportAll;
cmp_ok(@{$reps[0]}, '==', 3);
is($reps[0][0], $rep,                     'Checking reportAll()');
is($reps[0][1], 'NOTICE');
is($reps[0][2], "Don't notice me");
cmp_ok(@{$reps[1]}, '==', 3);
is($reps[1][0], $rep);
is($reps[1][1], 'WARNING');
is($reps[1][2], "filter");
cmp_ok(@{$reps[2]}, '==', 3);
is($reps[2][0], $rep);
is($reps[2][1], 'WARNING');
is($reps[2][2], "I warn you!");
cmp_ok(@{$reps[3]}, '==', 3);
is($reps[3][0], $rep);
is($reps[3][1], 'ERROR');
is($reps[3][2], "a test");
cmp_ok(@{$reps[4]}, '==', 3);
is($reps[4][0], $rep);
is($reps[4][1], 'ERROR');
is($reps[4][2], "You are in error");
cmp_ok(@{$reps[5]}, '==', 3);
is($reps[5][0], $rep);
is($reps[5][1], 'ERROR');
is($reps[5][2], "I am sure!!");

