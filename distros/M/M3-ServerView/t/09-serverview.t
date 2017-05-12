#!/usr/bin/perl

use lib "t/lib";

use strict;
use warnings;

use Test::More;

plan tests => 1;

use M3::ServerView;

my $home = M3::ServerView::ServerView->new("M3::ServerView", "file:t/data/server.html");

# Page should contains 28 items
my $rs = $home->search();
is($rs->count, 28);
