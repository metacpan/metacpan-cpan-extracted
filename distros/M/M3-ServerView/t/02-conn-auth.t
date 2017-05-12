#!/usr/bin/perl

use lib "t/lib";

use strict;
use warnings;

use Test::More;
use Test::Exception;
use URI;

eval "use Test::M3::ServerView::TestServer";
plan skip_all => "Can't test HTTP stuff since server won't load because $@" if $@;

plan tests => 4;

use M3::ServerView;

my $s = Test::M3::ServerView::TestServer->new("foo:bar");
my $uri = $s->started_ok("Test::M3::ServerView::TestServer up and running on port " . $s->port);

throws_ok {
    M3::ServerView->connect_to($uri, user => "wrong", password => "user")->root;
} qr/401 Unauthorized/;

throws_ok {
    M3::ServerView->connect_to($uri)->root;
} qr/401 Unauthorized/;

lives_ok {
    M3::ServerView->connect_to($uri, user => "foo", password => "bar")->root;    
};