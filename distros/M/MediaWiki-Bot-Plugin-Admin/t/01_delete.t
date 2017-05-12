#!perl
use strict;
use warnings;
use Test::More;
use MediaWiki::Bot;

my $username = $ENV{PWPAdminUsername};
my $password = $ENV{PWPAdminPassword};
my $host     = $ENV{PWPAdminHost};
my $path     = $ENV{PWPAdminPath};
plan $username && $password && $host
    ? (tests => 7)
    : (skip_all => 'test wiki and admin login required');

my $t = __FILE__;
my $summary = "MediaWiki::Bot::Plugin::Admin tests ($t)";

my $bot = MediaWiki::Bot->new({
    agent   => $summary,
    host    => $host,
    ($path ? (path => $path) : ()),
    login_data => { username => $username, password => $password },
});

$bot->delete("User:$username/01_delete.t");
my $text = $bot->get_text("User:$username/01_delete.t");
is($text, undef, 'Page does not exist yet');

my $rand = rand();
$bot->edit({
    page    => "User:$username/01_delete.t",
    text    => $rand,
    summary => $summary,
});
$text = $bot->get_text("User:$username/01_delete.t");
is($text, $rand, 'Page created successfully');

$bot->delete("User:$username/01_delete.t", $summary);
$text = $bot->get_text("User:$username/01_delete.t");
isnt($text, $rand, 'Page does not contain $rand');
is($text,   undef, 'Page was deleted');

$bot->undelete("User:$username/01_delete.t", $summary);
$text = $bot->get_text("User:$username/01_delete.t");
is($text, $rand, 'Page does contain $rand');

$bot->delete("User:$username/01_delete.t", $summary);
$text = $bot->get_text("User:$username/01_delete.t");
isnt($text, $rand, 'Page does not contain $rand');
is($text,   undef, 'Page was deleted');
