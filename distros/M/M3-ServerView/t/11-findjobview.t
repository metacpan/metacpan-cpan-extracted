#!/usr/bin/perl

use lib "t/lib";

use strict;
use warnings;

use Test::More;

plan tests => 8;

use M3::ServerView;

my $find = M3::ServerView::FindJobView->new("M3::ServerView", "file:t/data/findjob.html");

# Page should contains 20 items
my $rs = $find->search();
is($rs->count, 20);

my $entry = $rs->next;
is($entry->no, 1);
is($entry->type, "Job:I");
is($entry->name, "MMS001");
is($entry->id, 273);
is($entry->user, "User01");
is($entry->status, "MMS001 READ_DSP MMA001BC");
is($entry->change, 0);