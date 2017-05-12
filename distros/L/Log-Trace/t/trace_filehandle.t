#!/usr/local/bin/perl -w
# $Id: trace_filehandle.t,v 1.5 2004/12/15 15:47:35 johna Exp $
use strict;
use Test::More tests => 7;

# Find local libs unless running under Test::Harness
BEGIN { unshift @INC, -d 't' ? 'lib' : '../lib' unless grep /\bblib\b/, @INC }
require_ok('Log::Trace');

my $test_file = __FILE__;
my $timestamp = qr|\d{4}(?:-\d\d){2} \d\d(?::\d\d){2}(?:\.\d{6})?|;

my $message;
tie *TEST_HANDLE, 'CapturingFileHandle';

import Log::Trace print => \*TEST_HANDLE;
$message = 'Testing output to a filehandle';
TRACE($message);
is (<TEST_HANDLE>, "$message\n", 'message traced to supplied filehandle');

import Log::Trace print => \*TEST_HANDLE, {Level => 1};
$message = $0;
TRACE({Level => 1}, $message);
is (<TEST_HANDLE>, "$message\n", 'level 1 trace to filehandle ok');

TRACE({Level => 99}, $message);
is (<TEST_HANDLE>, undef, 'level 99 message not traced ok');

import Log::Trace print => \*TEST_HANDLE, {Verbose => 0};
TRACE(join '', reverse 0..9);
is (<TEST_HANDLE>, "9876543210\n", 'verbose:0 is also not verbose');

import Log::Trace print => \*TEST_HANDLE, {Verbose => 1};
TRACE(join '', ('a'..'f'));
like (<TEST_HANDLE>, qr/\Amain::__ANON__ \(\d+\) :: abcdef\n\Z/,
      'verbose:1 adds some caller information');

import Log::Trace print => \*TEST_HANDLE, {Verbose => 2};
TRACE(join '', ('a'..'f'));
like (<TEST_HANDLE>, qr/\A\Q$test_file\E: main::__ANON__ \(\d+\) \[$timestamp\] abcdef\n\Z/,
      'verbose:2 adds timstamp and file info');

sub TRACE {}


# A basic tied handle
package CapturingFileHandle;

sub TIEHANDLE {
   bless \do {my $string = ''}, shift;
}

sub PRINT {
    my $self = shift;
    $$self .= shift;
}

sub READLINE {
    my $self = shift;
    if (my $data = $$self) {
        $self->reset;
        return $data
    } else {
        return;
    }
}

sub reset {
    my $self = shift;
    $$self = '';
}

