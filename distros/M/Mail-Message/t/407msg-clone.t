#!/usr/bin/env perl
#
# Test cloning messages
#

use strict;
use warnings;

use Mail::Message;
use Mail::Message::Test;
use Mail::Message::Construct;
use Mail::Message::Body::Lines;
use Mail::Message::Body::Multipart;
use Mail::Message::Body::Nested;

use Test::More tests => 10;
use IO::Scalar;
use Mail::Address;

my $p1 = Mail::Message::Body::Lines->new
 ( data      => [ "line of text in part 1" ]
 , mime_type => 'text/plain'
 );

my $p2 = Mail::Message::Body::Lines->new
 ( data      => [ "line of html in part 2" ]
 , mime_type => 'text/html'
 );

my $p3 = Mail::Message::Body::Lines->new
 ( data      => [ "I know this is not postscript" ]
 , mime_type => 'application/postscript'
 );

my $p4 = Mail::Message::Body::Nested->new
 ( nested => $p3
 );

my $mp = Mail::Message::Body::Multipart->new
 ( parts => [ $p1, $p2, $p4 ]
 );

my $msg = Mail::Message->buildFromBody
 ( $mp
 , To   => 'you@home.com'
 , From => 'me@perl.org'
 );

#$msg->printStructure(\*STDERR);
ok(!defined $msg->partNumber, 'part number');
my @parts = $msg->parts;
cmp_ok($parts[0]->partNumber, 'eq', 1);
cmp_ok($parts[1]->partNumber, 'eq', 2);
cmp_ok($parts[2]->partNumber, 'eq', 3);
cmp_ok($parts[2]->body->nested->partNumber, 'eq', 3);

my $msg2 = $msg->clone;
ok($msg2);
cmp_ok($msg2->parts , "==",  3);
ok($mp->part(-1)->body->isNested);

my $orig_text  = '';
my $orig       = IO::Scalar->new(\$orig_text);
$msg->print($orig);
$orig->close;

my $clone_text = '';
my $clone      = IO::Scalar->new(\$clone_text);
$msg2->print($clone);
$clone->close;

ok(length $orig_text);
is($orig_text, $clone_text);
