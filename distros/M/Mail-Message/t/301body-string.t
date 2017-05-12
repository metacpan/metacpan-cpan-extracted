#!/usr/bin/env perl
#
# Test processing of message bodies which have their content stored
# in a single string.  This does not test the reading of the bodies
# from file.
#

use strict;
use warnings;

use Mail::Message::Test;
use Mail::Message::Body::String;

use IO::Scalar;
use Test::More tests => 30;

# Test to read a scalar from file.
# Let's fake the file, for simplicity.

my $filedata = <<'SIMULATED_FILE';
This is a file
with five lines, and it
is used to test whether
the reading into a scalar body
would work (or not)
SIMULATED_FILE

my @filedata = split /^/, $filedata;
cmp_ok(@filedata, '==', 5);

my $f = IO::Scalar->new(\$filedata);
my $body = Mail::Message::Body::String->new(file => $f);
ok(defined $body);
is($body->string, $filedata);
cmp_ok($body->nrLines, '==', 5);
cmp_ok($body->size, '==', length $filedata);

my $fakeout;
my $g = IO::Scalar->new(\$fakeout);
$body->print($g);
is($fakeout, $filedata);

my @lines = $body->lines;
cmp_ok(@lines, '==', 5);
foreach (0..4) { is($lines[$_], $filedata[$_]) }

# Reading data from lines.

$body = Mail::Message::Body::String->new(data => [@filedata]);
ok($body);
is($body->string, $filedata);
cmp_ok($body->nrLines, '==', 5);
cmp_ok($body->size, '==', length $filedata);

$fakeout = '';
$body->print($g);
is($fakeout, $filedata);

@lines = $body->lines;
cmp_ok(@lines, '==', 5);
foreach (0..4) { is($lines[$_], $filedata[$_]) }

# Test overloading

is("$body", $filedata);
@lines = @$body;
cmp_ok(@lines, '==', 5);
foreach (0..4) { is($lines[$_], $filedata[$_]) }
