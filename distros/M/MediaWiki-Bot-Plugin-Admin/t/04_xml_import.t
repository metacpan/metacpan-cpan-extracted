use strict;
use warnings;
use Test::More;
use MediaWiki::Bot;

my $username = $ENV{PWPAdminUsername};
my $password = $ENV{PWPAdminPassword};
my $host     = $ENV{PWPAdminHost};
my $path     = $ENV{PWPAdminPath};
plan $username && $password && $host
    ? (tests => 1)
    : (skip_all => 'test wiki and admin login required');

my $t = __FILE__;
my $summary = "MediaWiki::Bot::Plugin::Admin tests ($t)";

my $bot = MediaWiki::Bot->new({
    agent   => $summary,
    host    => $host || 'test.wikipedia.org',
    ($path ? (path => $path) : ()),
    login_data => { username => $username, password => $password },
});

my $res = $bot->xml_import('t/testfile.xml');
SKIP: {
    skip 'Need importupload permission', 1 if ($bot->{error}->{details} =~ m/^cantimport-upload/);
    ok $res, 'XML upload import OK' or diag explain $res;
}
