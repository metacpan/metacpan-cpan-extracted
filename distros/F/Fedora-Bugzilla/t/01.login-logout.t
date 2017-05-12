#!/usr/bin/perl

use Test::More;

plan skip_all => 'Must set FB_TEST_USERID & _PASSWD for live tests.'
    unless exists $ENV{FB_TEST_USERID} && exists $ENV{FB_TEST_PASSWD};

plan tests => 13;

use Fedora::Bugzilla;

my $bz = Fedora::Bugzilla->new(
    #site  => URI->new('https://bugzilla.redhat.com/xmlrpc.cgi'),
    site  => 'https://bugzilla.redhat.com/xmlrpc.cgi',
    userid => $ENV{FB_TEST_USERID},
    passwd => $ENV{FB_TEST_PASSWD},
);

isa_ok($bz, 'Fedora::Bugzilla');

# method testing
can_ok($bz, 'login');
can_ok($bz, 'logged_in');
can_ok($bz, 'logout');
can_ok($bz, 'version');
#...ok, that's probably enough

my $site = $bz->site;
isa_ok $site, 'URI';
is "$site" eq 'https://bugzilla.redhat.com/xmlrpc.cgi', 1, 'Site is correct';

is !$bz->logged_in, 1, "We haven't logged in yet";

is  $bz->login > 0,  1, 'Login worked';
is  $bz->logged_in,  1, "Yep, we're logged in";
is  $bz->logout > 1, 1, 'Logged out ok';
is !$bz->logged_in,  1, 'predicate reset successfully';
