#!/usr/bin/perl
# -*- mode: cperl -*-

use strict;
use Kwiki::Test;
use Test::More;
use Kwiki::UserMessage;
use Kwiki::UserMessage::CDBI;

plan tests => 3;

my $kwiki = Kwiki::Test->new->init(['Kwiki::DB::ClassDBI','Kwiki::UserMessage']);

my $hub = $kwiki->hub;

ok(ref($hub->user_message) eq 'Kwiki::UserMessage');

my $um = $hub->user_message;
$um->init;
$um->dbinit;

ok($um->post("Alice","Bob","Test Msg","Testing Message"));

my $mlist = $um->message_list("Bob");
ok($mlist->[0]->{subject} eq "Test Msg");

$kwiki->cleanup;


