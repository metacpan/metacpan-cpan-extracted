#!/usr/bin/perl

use lib "t/lib";

use strict;
use warnings;

use Test::More;

plan tests => 14;

use M3::ServerView;

my $home = M3::ServerView::RootView->new("M3::ServerView", "file:t/data/home.html");

like($home->response_time, qr/^ \d+ (?:\.\d+) $/x);
like($home->request_time, qr/^ \d{4}-\d{2}-\d{2} \s+ \d{2}:\d{2}:\d{2} $/x);
like($home->request_time("timestamp"), qr/^\d+$/);

# Page should contains 21 items
my $rs = $home->search();
is($rs->count, 21);

$rs = $home->search({ type => "Supervisor" });
is($rs->count, 1);

my $entry = $rs->first;
is($entry->no, "1");
is($entry->type, "Supervisor");
is($entry->pid, 6443);
ok($entry->started);
ok(!defined $entry->jobs);
is($entry->threads, 26);
is($entry->cpu, "2/191");
is($entry->heap, 72928);
is($entry->status, "Up");

