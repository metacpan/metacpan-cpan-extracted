#!/usr/bin/perl

use Test::More;

BEGIN {

    plan skip_all => 'Must set FB_TEST_USERID & _PASSWD for live tests.'
        unless exists $ENV{FB_TEST_USERID} && exists $ENV{FB_TEST_PASSWD};

    plan tests => 11;
}

#use URI;

use Fedora::Bugzilla;

# auto-login disabled
my $bz = Fedora::Bugzilla->new(
    userid => $ENV{FB_TEST_USERID},
    passwd => $ENV{FB_TEST_PASSWD},

    auto_login => 0,
);

is !$bz->logged_in, 1, 'Auto-login disabled correctly';
is  $bz->login > 0, 1, 'Login worked';

# auto-login enabled
$bz = Fedora::Bugzilla->new(
    userid => $ENV{FB_TEST_USERID},
    passwd => $ENV{FB_TEST_PASSWD},
);

is  $bz->logged_in > 0, 1, 'Auto-logged in correctly';
is  $bz->logout > 1,    1, 'Logged out ok';
is !$bz->logged_in,     1, 'shows logged out';

# auto_login set to a non-false value
$bz = Fedora::Bugzilla->new(
    userid => $ENV{FB_TEST_USERID},
    passwd => $ENV{FB_TEST_PASSWD},

    auto_login => 1,
);

is  $bz->logged_in > 0, 1, 'Auto-logged in correctly';
is  $bz->logout > 1,    1, 'Logged out ok';
is !$bz->logged_in,     1, 'shows logged out';

