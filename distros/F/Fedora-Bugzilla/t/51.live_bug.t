#!/usr/bin/perl

use Test::More;

BEGIN {

    plan skip_all => 'Must set FB_TEST_USERID & _PASSWD for live tests.'
        unless exists $ENV{FB_TEST_USERID} && exists $ENV{FB_TEST_PASSWD};

    plan tests => 11;
}

use Fedora::Bugzilla;

my $bz = Fedora::Bugzilla->new(
    userid => $ENV{FB_TEST_USERID},
    passwd => $ENV{FB_TEST_PASSWD},
);

is  $bz->login > 0,  1, 'Login worked';


my $BUG = '465913';

#use Smart::Comments;

# play with perl-Moose for testing
my $bug = $bz->bug(205321);
#my $bug = $bz->bug($BUG);

isa_ok $bug, 'Fedora::Bugzilla::Bug';

is $bug->alias,   'perl-Moose', 'alias is correct';
is $bug->summary, 
    'Review Request: perl-Moose - Complete modern object system for Perl 5',
    'summary is correct'
    ;

# note: look at creation time, as that's not going to change
my $dt = $bug->creation_time;

isa_ok $dt, 'DateTime';

is "$dt", '20060905T20:08:00', 'creation time is correct';


is  $bz->logout > 1, 1, 'Logged out ok';
