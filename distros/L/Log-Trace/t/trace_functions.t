#!/usr/local/bin/perl -w
# $Id: trace_functions.t,v 1.4 2004/12/15 15:47:35 johna Exp $
use strict;
use Test::More tests => 9;

# Find local libs unless running under Test::Harness
BEGIN { unshift @INC, -d 't' ? 'lib' : '../lib' unless grep /\bblib\b/, @INC }
require_ok('Log::Trace');

my $output;
my $trace = sub {
    $output = shift() . "\n";
};

my $file = __FILE__;
sub test_here { TRACE_HERE() }

import Log::Trace custom => $trace;
my ($count, $item) = (11, 'green bottles');
TRACEF("%d %s sitting on the wall", --$count, $item);
is ($output, "$count $item sitting on the wall\n", 'simple TRACEF ok');

$output = '';
TRACE_HERE();
like ($output, qr/In Log::Trace::TRACE_HERE\(\) - line \d+ of \Q$file\E\n/,
      'simple TRACE_HERE, not in a subroutine');

$output = '';
test_here();
like ($output, qr/In main::test_here\(\) - line \d+ of \Q$file\E\n/,
      'simple TRACE_HERE, in a subroutine');

$output = '';
test_here(--$count, $item);
like ($output, qr/In main::test_here\((?:$count,$item)?\) - line \d+ of \Q$file\E\n/,
      'TRACE_HERE, in a subroutine with args');


# basic test of functions with a level
import Log::Trace custom => $trace, {Level => 1};
$output = '';
TRACEF({Level => 1}, "%d %s sitting on the wall", --$count, $item);
is ($output, "$count $item sitting on the wall\n", 'simple TRACEF at level 1 ok');

$output = '';
TRACE_HERE({Level => 1});
like ($output, qr/In Log::Trace::TRACE_HERE\(\) - line \d+ of \Q$file\E\n/,
      'simple TRACE_HERE at level 1, not in a subroutine');

# Test that the functions don't output at too high a level
$output = '';
TRACEF({Level => 99}, "%d %s sitting on the wall", --$count, $item);
is ($output, "", 'simple TRACEF at level 99, not output');

$output = '';
TRACE_HERE({Level => 99});
is ($output, '', 'simple TRACE_HERE at level 99, not output');


sub TRACE {}
