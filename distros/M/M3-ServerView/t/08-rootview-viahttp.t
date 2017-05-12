#!/usr/bin/perl

use lib "t/lib";

use strict;
use warnings;

use Test::More;
use Test::Exception;
use URI;

eval "use Test::M3::ServerView::TestServer";
plan skip_all => "Can't test HTTP stuff since server won't load" if $@;

plan tests => 7;

use_ok("M3::ServerView");

my $s = Test::M3::ServerView::TestServer->new();
my $uri = $s->started_ok("Test::M3::ServerView::TestServer up and running on port " . $s->port);
my $home = M3::ServerView->connect_to($uri)->root;
isa_ok($home, "M3::ServerView::RootView");

my $entry = $home->search({ type => "Server:DBIMAS" })->first;
ok(defined $entry);

my $server = $entry->details();
ok(defined $server);
isa_ok($server, "M3::ServerView::ServerView");
is($server->search({})->count, 28);