#!/usr/bin/perl -w

package # split, so as not to confuse stuff
    File::Find::Rule::Permissions::Tests;

use strict;
use File::Find::Rule::Permissions;
use Data::Dumper;

eval 'require "t/_createtestfiles.pl"';
if($@) { eval qq{
    use Test::More;
    plan skip_all => "$@";
    exit(0);
}} elsif($> != 0) { eval { # not running as root
    use Test::More;
    plan skip_all => "Must be running as root to run these tests";
    exit(0);
}}


# figure out some users/groups
my %UsernamesByUID  = %File::Find::Rule::Permissions::UsernamesByUID;
my %GroupnamesByGID = %File::Find::Rule::Permissions::GroupnamesByGID;
my %UIDinGID        = %File::Find::Rule::Permissions::UIDinGID;

my $owner; my $group; my $useringroup; my $random;
FINDOWNER: foreach (grep { $_ } keys %UsernamesByUID) {
    $owner = $_; $group = undef; $useringroup = undef; $random = undef;
    # print "# trying with owner $owner ($UsernamesByUID{$owner})\n";
    my @groups = grep { $UIDinGID{$_}->{$owner} } keys %GroupnamesByGID;
    # print "# in groups [".join(', ', @groups)."]\n";
    my @notgroups = grep {
	my $group = $_;
        $group && !(grep { $_ == $group } @groups)
    } keys %GroupnamesByGID;
    # print "# not in groups [".join(', ', @notgroups)."]\n";
    FINDGROUP: foreach (@notgroups) {
        $group = $_;
	# print "#   looking for people *not* in group $group ($GroupnamesByGID{$group}) and not owner\n";
	FINDRANDOM: foreach (grep { $_ && $_ != $owner } keys %UsernamesByUID) {
	    $random = $_;
	    # print "#     trying $random ($UsernamesByUID{$random})\n";
	    last FINDRANDOM if(!$UIDinGID{$group}->{$random});
            undef $random;
	}
	# print "#   looking for people *in* group $group ($GroupnamesByGID{$group}) and not owner\n";
	FINDUSERINGROUP: foreach (grep { $_ && $_ != $owner } keys %UsernamesByUID) {
	    $useringroup = $_;
	    # print "#     trying $useringroup ($UsernamesByUID{$useringroup})\n";
	    last FINDUSERINGROUP if($UIDinGID{$group}->{$useringroup});
            undef $useringroup;
	}
	last FINDGROUP if($group && $useringroup);
        undef $group;
    }
    last FINDOWNER if($owner && $group && $useringroup && $random);
    undef $owner;
}

# really need to sanity-check all that nasty evil juju
undef($owner)       if($UIDinGID{$group}->{$owner});       # owner not in group
undef($useringroup) if(!$UIDinGID{$group}->{$useringroup});# user      in group
undef($random)      if($UIDinGID{$group}->{$random});      # random    in group
undef($owner) if( # must have three different users
    defined($owner) && defined($useringroup) && defined($random) && (
        $owner == $useringroup ||
        $owner == $random ||
        $random == $useringroup
    )
);

if($owner && $group && $useringroup && $random) { eval q{
    use Test::More tests => 26;
}} else { eval {
    use Test::More;
    plan skip_all => "Couldn't figure out a user who is in a group, and two users not in that group";
    exit(0);
}}

print "# using owner  = $owner ($UsernamesByUID{$owner})\n";
print "# using group  = $group ($GroupnamesByGID{$group})\n";
print "# group user   = $useringroup ($UsernamesByUID{$useringroup})\n";
print "# using random = $random ($UsernamesByUID{$random})\n";

makefiles($owner, $group);

do 't/_filetests.pl'; # run root tests, define subs

user($owner);
group($useringroup);
other($random);
