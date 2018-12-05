#!/usr/bin/perl -w

package # split, so as not to confuse stuff
    File::Find::Rule::Permissions::Tests;

use strict;
use lib '.';
use File::Find::Rule::Permissions;

use vars qw($userid $groupid);

eval 'require "t/_mock.pl"'; # must come after 'use FFRP'
eval 'require "t/_createtestfiles.pl"';
if($@) { eval qq{
    use Test::More;
    plan skip_all => "$@";
    exit(0);
}} else { eval q{
    use Test::More;
    END { done_testing };
}}
makefiles();

$userid  = 1;
$groupid = 0;
File::Find::Rule::Permissions::_getusergroupdetails(
    users => { root => 0 },
    groups => { wheel => 0 },
    UIDinGID => { 0 => [0] }
);
do 't/_filetests.pl'; # run root tests, define subs

# all files are owned by user1, group wheel
# user1's perms come from the U bits
# user2's perms come from the O bits
# user3's perms come from the G bits
$userid  = 1;
$groupid = 2;
File::Find::Rule::Permissions::_getusergroupdetails(
    users => { root => 0, user1 => 1, user2 => 2, user3 => 3 },
    groups => { wheel => 0, group1 => 1, group2 => 2 },
    UIDinGID => { 0 => [0], 1 => [1, 2], 2 => [3] }
    # user1 and user2 are in group1, user3 is in group2
);

user('user1');
group('user3');
other('user2');

edge_cases();
