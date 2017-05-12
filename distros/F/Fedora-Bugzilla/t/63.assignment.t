#!/usr/bin/perl

# test changing various bug attributes

use Test::More; 

BEGIN {

    plan skip_all => 'Must set FB_TEST_USERID & _PASSWD for live tests.'
        unless exists $ENV{FB_TEST_USERID} && exists $ENV{FB_TEST_PASSWD};

    plan tests => 5;
}

use Fedora::Bugzilla;

my $bz = Fedora::Bugzilla->new(
    userid => $ENV{FB_TEST_USERID},
    passwd => $ENV{FB_TEST_PASSWD},
);

is  $bz->login > 0,  1, 'Login worked';


# scratch bug
my $BUG = '465913';

my $bug = $bz->bug($BUG);

isa_ok $bug, 'Fedora::Bugzilla::Bug';

my $orig = $bug->assigned_to;

diag "originally assigned to $orig";

# reassign
$bug->assigned_to('cweyl@alumni.drew.edu');
$bug->update;

is $bug->assigned_to => 'cweyl@alumni.drew.edu', 'reassigned correctly';

$bug->assigned_to('nobody@fedoraproject.org');
$bug->update;

is $bug->assigned_to => 'nobody@fedoraproject.org', 'back to nobody@fp.org';

is  $bz->logout > 1, 1, 'Logged out ok';
