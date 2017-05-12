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

# TODO ... all of this.

my $BUG = '465913';

#use Smart::Comments;

#my $ret = $bz->add_comment($BUG, 'Hm.  Foo!.');

my $ret = $bz->add_attachment(
    $BUG, 
    filename => '/etc/fedora-release',
    description => 'the great fedora-release!',
    contenttype => 'text/plain',
);
### $ret

#$bz->add_comment('465913', 'Fedora::Bugzilla testing...');

# play with perl-Moose for testing
my $bug = $bz->bug(205321);

isa_ok $bug, 'Fedora::Bugzilla::Bug';

is $bug->alias, 'perl-Moose', 'alias is correct';

### $bug

is  $bz->logout > 1, 1, 'Logged out ok';
