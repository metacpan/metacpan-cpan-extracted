#!/usr/bin/env perl
#
# Test processing of message bodies which have their content stored
# in an array.  This does not test the reading of the bodies
# from file.
#

use strict;
use warnings;

use Mail::Message::Test;
use Mail::Message::Body::Lines;

use Test::More tests => 30;
use IO::Scalar;

# Test to read a Lines from file.
# Let's fake the file, for simplicity.

my $filedata = <<'SIMULATED_FILE';
This is a file
with five lines, and it
is used to test whether
the reading into a lines body
would work (or not)
SIMULATED_FILE

my $f = IO::Scalar->new(\$filedata);

my $body = Mail::Message::Body::Lines->new(file => $f);
ok($body,                                        "body from file is true");

is($body->string, $filedata,                     "body strings to data");
cmp_ok($body->nrLines, "==", 5,                  "body reports 5 lines");
cmp_ok($body->size, "==", length $filedata,      "body size as data");

my $fakeout;
my $g = IO::Scalar->new(\$fakeout);
$body->print($g);
is($fakeout, $filedata,                          "body prints right data");

my @lines = $body->lines;
cmp_ok(@lines, "==", 5,                          "body produces five lines");

my @filedata = split /^/, $filedata;
cmp_ok(@filedata, "==", 5,                       "data 5 lines");

foreach (0..4) { is($lines[$_], $filedata[$_],   "expected line $_") }

# Reading data from lines.

$body = Mail::Message::Body::Lines->new(data => [@filedata]);
ok($body,                                        "body from array is true");

is($body->string, $filedata,                     "body string is data");
cmp_ok($body->nrLines, "==", 5,                  "body reports 5 lines");
cmp_ok($body->size, "==", length $filedata,      "body reports correct size");

$fakeout = '';
$body->print($g);
is($fakeout, $filedata,                          "body prints to data");

@lines = $body->lines;
cmp_ok(@lines, "==", 5,                          "body produces 5 lines");
foreach (0..4) { is($lines[$_], $filedata[$_],   "body line $_") }

# Test overloading

is("$body", $filedata,                           "stringification");
@lines = @$body;
cmp_ok(@lines, "==", 5,                          "overload array-deref");
foreach (0..4) { is($lines[$_], $filedata[$_],   "overload array $_") }
