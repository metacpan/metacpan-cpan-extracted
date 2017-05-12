#!/usr/local/bin/perl -w
# $Id: trace_warn.t,v 1.5 2004/12/15 16:50:14 johna Exp $
use strict;
use Test::More tests => 7;

# Find local libs unless running under Test::Harness
BEGIN { unshift @INC, -d 't' ? 'lib' : '../lib' unless grep /\bblib\b/, @INC }
require_ok('Log::Trace');

my $test_file = __FILE__;
my $timestamp = qr|\d{4}(?:-\d\d){2} \d\d(?::\d\d){2}(?:\.\d{6})?|;

my ($buffer, $message) = ('');
$SIG{__WARN__} = sub {$buffer .= shift};

import Log::Trace 'warn';
$buffer = '', $message = 'The quick brown fox jumped over the lazy dog';
TRACE($message);
is ($buffer, "$message\n", 'simple warn');

import Log::Trace warn => {Level => 1};
$buffer = '', $message = 'Jackdaws love my big sphinx of quartz';
TRACE({Level => 1}, $message);
is ($buffer, "$message\n", 'warn at level 1');

$buffer = '';
TRACE({Level => 99}, $message);
is ($buffer, '', 'warn at level 99 not traced');

$buffer = '';
import Log::Trace warn => {Verbose => 0};
TRACE(join '', reverse 0..9);
is ($buffer, "9876543210\n", 'verbose:0 is also not verbose');

$buffer = '';
import Log::Trace warn => {Verbose => 1};
TRACE(join '', ('a'..'f'));
like ($buffer, qr/\Amain::__ANON__ \(\d+\) :: abcdef\n\Z/,
      'verbose:1 adds some caller information');

$buffer = '';
import Log::Trace warn => {Verbose => 2};
TRACE(join '', ('a'..'f'));
like ($buffer, qr/\A\Q$test_file\E: main::__ANON__ \(\d+\) \[$timestamp\] abcdef\n\Z/,
      'verbose:2 adds timstamp and file info');

sub TRACE {}
