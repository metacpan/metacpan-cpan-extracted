#!/usr/local/bin/perl -w
# $Id: trace_deep.t,v 1.6 2004/12/03 11:43:53 simonf Exp $
use strict;
use Test::More tests => 5;

# Find local libs unless running under Test::Harness
BEGIN { unshift @INC, -d 't' ? 'lib' : '../lib' unless grep /\bblib\b/, @INC }
require_ok('Log::Trace');

use File::Basename;
use File::Spec::Functions 'catdir';
BEGIN { unshift @INC, catdir(dirname(__FILE__), 'lib') }

my $output;
my $trace = sub {
    $output = shift() . "\n";
};

my $message;
require Test_DeepImport;
import Log::Trace custom => $trace, {Deep => 1, AutoImport => 1};
my $o = Test_DeepImport->new();
is($output, "Creating object\n", 'Deep import');

ok(!$INC{'Test_DelayedImport.pm'}, "delayed module isn't loaded yet");
# eval because the require() in this doc is already compiled to use
# CORE::require
eval "require Test_DelayedImport";

ok($INC{'Test_DelayedImport.pm'}, "delayed module now loaded");
Test_DelayedImport::TRACE('This module is automatically set up for tracing');
is($output, "This module is automatically set up for tracing\n",
   'delayed module has tracing enabled automatically');

sub TRACE {}
