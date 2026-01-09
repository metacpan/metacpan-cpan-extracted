#!/usr/bin/perl
use strict;
use warnings;

use MIME::Lite;
use Test::More;

# Make a tester... here are 3 different alternatives:
$MIME::Lite::VANILLA  = 1;
$MIME::Lite::PARANOID = 1;

my $msg;

$msg  = MIME::Lite->new(From=>"me", To=>"you", Data=>"original text");
$msg->attach(Data => "attachment 1");
$msg->attach(Data => "attachment 2");
my $part = $msg->attach(Data => "attachment 3");
$part->attach(Data => "attachment 4");
$part->attach(Data => "attachment 5");

is($msg->parts, 4, "->parts count is correct");

is($msg->parts_DFS, 7, "->parts_DFS count is correct");

done_testing;
