#!/usr/bin/perl

use lib "t/lib";

use strict;
use warnings;

use Test::More;
use Test::Exception;
use URI;

eval "use Test::M3::ServerView::TestServer";
plan skip_all => "Can't test HTTP stuff since server won't load" if $@;

plan tests => 10;

use_ok("M3::ServerView");

my $s = Test::M3::ServerView::TestServer->new();
my $uri = $s->started_ok("Test::M3::ServerView::TestServer up and running on port " . $s->port);
my $home = M3::ServerView->connect_to($uri)->root;
isa_ok($home, "M3::ServerView::RootView");

my $connection = $home->connection;
isa_ok($connection, "M3::ServerView");
is($connection->base_uri, $uri . "/");

$home = M3::ServerView->connect_to("${uri}/")->root;
isa_ok($home, "M3::ServerView::RootView");

$home = M3::ServerView->connect_to(URI->new($uri))->root;
isa_ok($home, "M3::ServerView::RootView");

throws_ok {
    M3::ServerView->connect_to(bless {}, "Foo");
} qr/URL is not an URI-instance/;

throws_ok {
    M3::ServerView->connect_to("${uri}/foo");
} qr/Invalid URL/;

throws_ok {
    M3::ServerView->_load_view("foobaz")
} qr/Can't determinte view class for 'foobaz'/;

