#!/usr/local/bin/perl -w
# $Id: trace_buffer.t,v 1.5 2004/12/15 15:47:35 johna Exp $
use strict;
use Test::More tests => 7;

# Find local libs unless running under Test::Harness
BEGIN { unshift @INC, -d 't' ? 'lib' : '../lib' unless grep /\bblib\b/, @INC }

require_ok('Log::Trace');
my $test_file = __FILE__;
my $timestamp = qr|\d{4}(?:-\d\d){2} \d\d(?::\d\d){2}(?:\.\d{6})?|;

my ($output, $message) = '';
import Log::Trace buffer => \$output;
$message = 'buffering trace output';
TRACE($message);
is ($output, "$message\n", 'message appended to buffer');

$output = '';
import Log::Trace buffer => \$output, {Level => 1};
$message = $0;
TRACE({Level => 1}, $message);
is ($output, "$message\n", 'level 1 appended to buffer');

$output = '';
TRACE({Level => 99}, $message);
is ($output, '', 'level 99 message not traced ok');

$output = '';
import Log::Trace buffer => \$output, {Verbose => 0};
TRACE(join '', reverse 0..9);
is ($output, "9876543210\n", 'verbose:0 is also not verbose');

$output = '';
import Log::Trace buffer => \$output, {Verbose => 1};
TRACE(join '', ('a'..'f'));
like ($output, qr/\Amain::__ANON__ \(\d+\) :: abcdef\n\Z/,
      'verbose:1 adds some caller information');

$output = '';
import Log::Trace buffer => \$output, {Verbose => 2};
TRACE(join '', ('a'..'f'));
like ($output, qr/\A\Q$test_file\E: main::__ANON__ \(\d+\) \[$timestamp\] abcdef\n\Z/,
      'verbose:2 adds timstamp and file info');

sub TRACE {}
