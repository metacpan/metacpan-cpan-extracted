#!/usr/bin/env perl
#
# Test installing a log callback
#

use strict;
use warnings;

use Mail::Message::Test;
use Mail::Reporter;

use Test::More tests => 13;

my ($thing, $level, @text);
sub callback($$@) { ($thing, $level, @text) = @_ }

my ($l, $t) = Mail::Reporter->defaultTrace(PROGRESS => \&callback);
ok(defined $l);
ok(defined $t);

is($l, 'NONE',                      'string log level');
cmp_ok($l, '==',  6,                'numeric log level');

is($t, 'PROGRESS',                  'string trace level');
cmp_ok($t, '==',  3,                'string trace level');

Mail::Reporter->log(ERROR => 'one', 'two');

is($thing, 'Mail::Reporter',        'class call');
is($level, 'ERROR',                 'string trace level');
cmp_ok(@text, '==', 1,              'text');
is($text[0], "onetwo");

($thing, $level, @text) = ();
Mail::Reporter->log(NOTICE => 'three');
ok(!defined $thing,                 'too low level, nothing');
ok(!defined $level,                 'no level');
cmp_ok(@text, '==', 0,              'no text');

