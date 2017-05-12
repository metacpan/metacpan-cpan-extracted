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
    ? (tests => 3)
    : (skip_all => 'test wiki and admin login required');

my $t = __FILE__;
my $summary = "MediaWiki::Bot::Plugin::Admin tests ($t)";

my $bot = MediaWiki::Bot->new({
    agent   => $summary,
    host    => $host,
    ($path ? (path => $path) : ()),
    login_data => { username => $username, password => $password },
});
my $target = 'Perlwikibot testing';
$bot->unblock($target, $summary);
my $is_blocked = $bot->is_blocked($target);
is($is_blocked, 0, "[[User:$target]] is unblocked");

subtest 'block' => sub {
    plan tests => 6;
    my $duration = '1 minute';
    $bot->block({
        user        => $target,
        length      => $duration,
        summary     => $summary,
        autoblock   => 0,
    });

    my $block = $bot->get_log({ type => 'block', user => $username, title => "User:$target" });
    is $block->[0]->{comment},    $summary,         'Block summary is correct';
    is $block->[0]->{user},       $username,        'Block made by right user';
    is $block->[0]->{action},     'block',          'Block is registered as a block';
    like $block->[0]->{title},    qr/\Q$target\E/,  'Block was set on the right user';
    is $block->[0]->{type},       'block',          'Block is registered as a block';
    is $block->[0]->{block}->{duration}, $duration, 'Block was set for the right duration';
};

subtest 'unblock' => sub {
    plan tests => 2;
    $bot->unblock($target, "Finished $summary");
    $is_blocked = $bot->is_blocked($target);
    is $is_blocked, 0, "[[User:$target]] is unblocked";
    my $unblock = $bot->get_log({ type => 'block', user => $username, title => "User:$target" });
    is $unblock->[0]->{comment}, "Finished $summary", 'Unblock summary is used'
        or diag explain $unblock->[0];
};
