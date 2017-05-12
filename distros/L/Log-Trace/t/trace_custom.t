#!/usr/local/bin/perl -w
# $Id: trace_custom.t,v 1.3 2004/11/23 14:07:31 simonf Exp $
use strict;
use Test::More tests => 4;

# Find local libs unless running under Test::Harness
BEGIN { unshift @INC, -d 't' ? 'lib' : '../lib' unless grep /\bblib\b/, @INC }
require_ok('Log::Trace');

my $output;
my $trace = sub {
    $output = shift() . "\n";
};

my $message;
import Log::Trace custom => $trace;
$message = 'sending trace message to custom subroutine';
TRACE($message);
is ($output, "$message\n", 'message handled by custom tracing routine');

$output = '';
import Log::Trace custom => $trace, {Level => 1};
$message = $0;
TRACE({Level => 1}, $message);
is ($output, "$message\n", 'level 1 appended sent to custom handler');

$output = '';
TRACE({Level => 99}, $message);
is ($output, '', 'level 99 message not traced ok');

sub TRACE {}
