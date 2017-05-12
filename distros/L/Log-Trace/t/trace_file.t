#!/usr/local/bin/perl -w
# $Id: trace_file.t,v 1.6 2004/12/15 15:47:35 johna Exp $
use strict;
use Test::More;
use File::Basename;
use File::Spec;

# get suitable dir for output file, or skip this test
my $filename;
my $dir = File::Spec->tmpdir;
$dir  ||= -w dirname(__FILE__) ? dirname(__FILE__) : -w '.' ? '.' : '';
if ($dir) {
    plan tests => 7;
    $filename = File::Spec->catfile($dir, 'Log-Trace-test-filemode.out');
} else {
    plan skip_all => 'No writable temp directory found';
}
TRACE("trace output -> $filename");

# Cleanup
END { unlink $filename }

# Find local libs unless running under Test::Harness
BEGIN { unshift @INC, -d 't' ? 'lib' : '../lib' unless grep /\bblib\b/, @INC }
require_ok('Log::Trace');

my $test_file = __FILE__;
my $timestamp = qr|\d{4}(?:-\d\d){2} \d\d(?::\d\d){2}(?:\.\d{6})?|;


my $message;
import Log::Trace file => $filename;
$message = q[Just don't create a file called -rf. :-)
    --Larry Wall in <11393@jpl-devvax.JPL.NASA.GOV>];
TRACE($message);
my $test_output = "$message\n";
is (read_file(), $test_output, 'message traced to supplied file');

import Log::Trace file => $filename, {Level => 1};
$message = $0;
TRACE({Level => 1}, $message);
$test_output .= "$message\n";
is (read_file(), $test_output, 'level 1 trace to file ok');

TRACE({Level => 99}, $message);
# no change-> # $test_output .= "$message\n";
is (read_file(), $test_output, 'level 99 message not traced ok');

# Test verbose
import Log::Trace file => $filename, {Verbose => 0};
TRACE(join '', reverse 0..9);
$test_output .= "9876543210\n";
is (read_file(), $test_output, 'verbose:0 is also not verbose');


import Log::Trace file => $filename, {Verbose => 1};
TRACE(join '', ('a'..'f'));
like (read_file(), qr/\nmain::__ANON__ \(\d+\) :: abcdef\n\Z/,
      'verbose:1 adds some caller information');

import Log::Trace file => $filename, {Verbose => 2};
TRACE(join '', ('a'..'f'));
like (read_file(), qr/\n\Q$test_file\E: main::__ANON__ \(\d+\) \[$timestamp\] abcdef\n\Z/,
      'verbose:2 adds timstamp and file info');


sub read_file {
    local *FH;
    open FH, "< $filename" or die "open < '$filename' -- $!";
    my $contents = do {local $/; <FH>};
    close FH;
    return $contents;
}

sub TRACE {}
