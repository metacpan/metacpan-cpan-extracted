#!/usr/bin/perl -w

use strict;

use vars qw(
    %UIDsByUsername %UsernamesByUID %GIDsByGroupname
    %GroupnamesByGID %UIDinGID
);

package # split to avoid confusing stupid software
    File::Find::Rule::Permissions;

no warnings qw(redefine);
sub stat {
    my $filename = shift;
    my @stat = CORE::stat($filename);
    my $mode = oct($filename);
    # print "$filename: mode=$mode, user=$File::Find::Rule::Permissions::Tests::userid, group=$File::Find::Rule::Permissions::Tests::groupid\n";
    return (
        @stat[0, 1], $mode, $stat[3],
        $File::Find::Rule::Permissions::Tests::userid,
        $File::Find::Rule::Permissions::Tests::groupid,
        @stat[6..12]
    );
}

sub getusergroupdetails {
    my %params = @_;
    my $users = $params{users};         # { user1 => 1, user2 => 2 }
    my $groups = $params{groups};       # { group1 => 1, group2 => 2 }
    my $UIDinGID = $params{UIDinGID};   # { $gid1 => [$uid1, $uid2] }

    %UIDsByUsername = %{$users};
    %UsernamesByUID = reverse(%UIDsByUsername);
    %GIDsByGroupname = %{$groups};
    %GroupnamesByGID = reverse(%GIDsByGroupname);
    %UIDinGID = ();

    foreach my $gid (keys %{$UIDinGID}) {
        $UIDinGID{$gid}{$_} = 1 foreach(@{$UIDinGID->{$gid}});
    }
}
