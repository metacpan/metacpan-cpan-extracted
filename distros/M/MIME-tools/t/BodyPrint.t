#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More tests => 7;

use MIME::Body;
use MIME::Tools;

my $body = MIME::Body::InCore->new("hi\n");
my $fh = $body->open("r");
my @ary = <$fh>;
$fh->close();
is(scalar(@ary), 1);
is($ary[0], "hi\n");

$body = MIME::Body::InCore->new(\"hi\n");
$fh = $body->open("r");
@ary = <$fh>;
$fh->close();
is(scalar(@ary), 1);
is($ary[0], "hi\n");

$body = MIME::Body::InCore->new(["line 1\n", "line 2\n"]);
$fh = $body->open("r");
@ary = <$fh>;
$fh->close();
is(scalar(@ary), 2);
is($ary[0], "line 1\n");
is($ary[1], "line 2\n");

