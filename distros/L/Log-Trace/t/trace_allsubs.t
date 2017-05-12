#!/usr/local/bin/perl -w
# $Id: trace_allsubs.t,v 1.1 2004/12/03 11:43:53 simonf Exp $
use strict;
use Test::More tests => 8;

# Find local libs unless running under Test::Harness
BEGIN { unshift @INC, -d 't' ? 'lib' : '../lib' unless grep /\bblib\b/, @INC }
require_ok('Log::Trace');

use File::Basename;
use File::Spec::Functions 'catdir';
BEGIN { unshift @INC, catdir(dirname(__FILE__), 'lib') }

my $output;
my $trace = sub {
    $output .= shift() . "\n";
};


require Test_DeepImport;
import Log::Trace custom => $trace, {Deep => 1, Match => qr/Test_DeepImport/, AllSubs => 1};
Test_DeepImport::hello();
like($output, qr/\ATest_DeepImport::hello\(\s+\)\n/, 'hello() trace contains auto-trace');
like($output, qr/Hello World!\n\Z/, 'hello() trace contains the TRACE()');

$output = '';
Test_DeepImport::first();
like($output, qr/\ATest_DeepImport::first\(\s+\)\n/, 'call to first() was traced');
like($output, qr/Test_DeepImport::next\(\s+\)\n/, 'call to next() was traced');
like($output, qr/IN NEXT\n\Z/, 'next() called TRACE()');

# test Everywhere option
$output = '';
Test_DeepImport_Without_TRACE::test();
is($output, '', 'tracing not enabled in matching package without TRACE fn.');

import Log::Trace custom => $trace, {Deep => 1, Match => qr/Test_DeepImport/, AllSubs => 1, Everywhere => 1};
Test_DeepImport_Without_TRACE::test();
like($output, qr/Test_DeepImport_Without_TRACE::test\(\s+\)\n/,
     'tracing enabled in package without TRACE(), with the Everywhere option');

sub TRACE {}
