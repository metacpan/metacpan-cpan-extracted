package Labyrinth::Plugin::Groups;

use warnings;
use strict;

our $VERSION = '5.19';

=head1 NAME

Labyrinth::Plugin::Groups - handler for Labyrinth groups

=head1 DESCRIPTION

Contains all the group handling functionality for the Labyrinth
framework.

=cut

#   type 1 - userid link to groupid
#   type 2 - groupid link to groupid

# -------------------------------------
# Library Modules

use base qw(Labyrinth::Plugin::Base);

use Labyrinth::Audit;
use Labyrinth::DBUtils;
use Labyrinth::Groups;
use Labyrinth::MLUtils;
use Labyrinth::Support;
use Labyrinth::Users;
use Labyrinth::Variables;

# -------------------------------------
# Variables

# html: 0 = none, 1 = text, 2 = textarea

my %fields = (
    groupid     => { type => 0, html => 0 },
    groupname   => { type => 1, html => 1 },
);

my (@mandatory, @allfields);
for(keys %fields) {
    push @mandatory, $_     if($fields{$_}->{type});
    push @allfields, $_;
}

# -------------------------------------
# The Subs

=head1 PUBLIC INTERFACE METHODS

=over 4

=item GetUserGroup()

For the current user login, set main group.

=back

=cut

sub GetUserGroup {
    my @rows = $dbi->GetQuery('hash','UserGroups',$tvars{loginid});
    $tvars{user}{groupid} = $rows[0]->{groupid}    if(@rows);
}

=head1 ADMIN INTERFACE METHODS

All action methods are only accessible by users with admin permission.

=over 4

=item Admin

Provides List and Delete functionality for Group Admin.

=item Add

Creates a new group.

=item AddLinkUser

Links a given user to the given group.

=item AddLinkGroup

Links a given group to another, the latter becoming the parent of the former.

=item Edit

Provides group admin functionality for a given group.

=item Save

Saves the current settings for the given group.

=item User

Provides group admin functionality for a given user.

=item UserSave

Saves the current group settings for the given user.

=item Delete

Deletes a group. Called from within the Admin method above.

=item DeleteLinkUser

Removes the given user from the given group.

=item DeleteLinkGroup

Removes the given group from a nominated parent.

=back

=cut

sub Admin {
    return  unless AccessUser(ADMIN);
    if($cgiparams{doaction}) {
        Delete()    if($cgiparams{doaction} eq 'Delete');
    }
    my @where = ($tvars{useraccess} == MASTER ? () : ('groupid!=9'));
    push @where, "groupname LIKE '%$cgiparams{'searchname'}%'"  if($cgiparams{'searchname'});
    my $where = @where ? 'WHERE '.join(' AND ',@where) : '';
    my @rows = $dbi->GetQuery('hash','AllGroups',{where=>$where});
    for(@rows) {
        my @cnt = $dbi->GetQuery('hash','GroupCount',$_->{groupid});
        $_->{count} = @cnt ? $cnt[0]->{count} : 0;
    }
    $tvars{data} = \@rows   if(@rows);
}

sub Add {
    return  unless AccessUser(ADMIN);
    $tvars{newgroup} = 1;
}

sub AddLinkUser {
    return  unless AccessUser(ADMIN);
    return  unless $cgiparams{'groupid'};
    return  unless $cgiparams{'id'};
    $dbi->DoQuery('AddLinkIndex',0,$cgiparams{'id'},$cgiparams{'groupid'});
}

sub AddLinkGroup {
    return  unless AccessUser(ADMIN);
    return  unless $cgiparams{'groupid'};
    return  unless $cgiparams{'id'};
    $dbi->DoQuery('AddLinkIndex',1,$cgiparams{'id'},$cgiparams{'groupid'});
}

sub User {
    return  unless AccessUser(ADMIN);
    return  unless $cgiparams{'userid'};
    my @rows = $dbi->GetQuery('hash','GetUserByID',$cgiparams{'userid'});
    $tvars{data} = $rows[0];
    my @urows = $dbi->GetQuery('hash','UserGroups',$cgiparams{'userid'});
    $tvars{primary} = \@urows   if(@urows);
    my %groups;
    my @arows = $dbi->GetQuery('hash','AllGroups');
    my @irows = $dbi->GetQuery('hash','AllGroupIndex');
    foreach (@irows) { push @{$groups{$_->{groupid}}}, $_->{linkid}; }
    my @list;
    my %grps = map {$_->{groupid} => 1} @urows;
    my @grps = keys %grps;
    while(@grps) {
        my $g = shift @grps;
        push @list, $g  unless($grps{$g});      # not primary group
        next            unless($groups{$g});    # not already seen
        push @grps, @{$groups{$g}};
        delete $groups{$g};
    }
    my %list = map {$_->{groupid} => $_->{groupname}} @arows;
    my @deps = sort map {$list{$_}} @list;
    $tvars{secondary} = \@deps  if(@deps);
    $tvars{ddgroups} = GroupSelect();
}

sub Edit {
    return  unless AccessUser(ADMIN);
    return  unless $cgiparams{'groupid'};
    my @rows = $dbi->GetQuery('hash','GetGroup',$cgiparams{'groupid'});
    return  unless(@rows);
    $tvars{data} = $rows[0];
    my @urows = $dbi->GetQuery('hash','LinkUsers',$cgiparams{'groupid'});
    my @grows = $dbi->GetQuery('hash','LinkGroups',$cgiparams{'groupid'});
    $tvars{groupusers} = \@urows    if(@urows);
    $tvars{primary}    = \@grows    if(@grows);
    my %groups;
    my @arows = $dbi->GetQuery('hash','AllGroups');
    my @irows = $dbi->GetQuery('hash','AllGroupIndex');
    foreach (@irows) { push @{$groups{$_->{groupid}}}, $_->{linkid}; }
    my @list;
    my %grps = map {$_->{linkid} => 1} @grows;
    my @grps = keys %grps;
    while(@grps) {
        my $g = shift @grps;
        push @list, $g  unless($grps{$g});      # not primary group
        next            unless($groups{$g});    # not already seen
        push @grps, @{$groups{$g}};
        delete $groups{$g};
    }
    my %list = map {$_->{groupid} => $_->{groupname}} @arows;
    my @deps = sort map {$list{$_}} @list;
    $tvars{secondary}   = \@deps    if(@deps);
    $tvars{ddusers}  = UserSelect(undef,5);
    $tvars{ddgroups} = GroupSelectMulti($cgiparams{'groupid'});
}

sub Save {
    return  unless AccessUser(ADMIN);
    for(keys %fields) {
           if($fields{$_}->{html} == 1) { $cgiparams{$_} = CleanHTML($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 2) { $cgiparams{$_} = CleanTags($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 3) { $cgiparams{$_} = CleanLink($cgiparams{$_}) }
    }
    return  if FieldCheck(\@allfields,\@mandatory);
    # cannot change names of core groups
    my @rows = $dbi->GetQuery('hash','GetGroup',$cgiparams{'groupid'});
    unless($rows[0]->{master}) {
        if($cgiparams{'groupid'})
                {   $dbi->DoQuery('SaveGroup',$cgiparams{'groupname'},$cgiparams{'groupid'}); }
        else    {   $cgiparams{'groupid'} = $dbi->IDQuery('AddGroup',$cgiparams{'groupname'}); }
    }
    if($cgiparams{'users'}) {
        push my @ids, CGIArray('users');
        $dbi->DoQuery('AddLinkIndex',1,$_,$cgiparams{'groupid'})    for @ids;
    }
    if($cgiparams{'groups'}) {
        push my @ids, CGIArray('groups');
        $dbi->DoQuery('AddLinkIndex',2,$_,$cgiparams{'groupid'})    for @ids;
    }
}

sub UserSave {
    return  unless AccessUser(ADMIN);
    return  unless($cgiparams{'userid'});
    if($cgiparams{'groups'}) {
        push my @ids, CGIArray('groups');
        $dbi->DoQuery('AddLinkIndex',1,$cgiparams{'userid'},$_) for @ids;
    }
}

sub Delete {
    return  unless AccessUser(ADMIN);
    my @ids = CGIArray('LISTED');
    return  unless @ids;
    for my $id (@ids) {
        my @rows = $dbi->GetQuery('hash','GetGroup',$id);
        next    if($rows[0]->{master}); # cannot delete core groups
        $dbi->DoQuery('DeleteGroupIndex',$id);
        $dbi->DoQuery('DeleteGroup',$id);
    }
}

sub DeleteLinkUser {
    return  unless AccessUser(ADMIN);
    return  unless $cgiparams{'groupid'};
    return  unless $cgiparams{'userid'};
    $dbi->DoQuery('DeleteLinkIndex',1,$cgiparams{'userid'},$cgiparams{'groupid'});
}

sub DeleteLinkGroup {
    return  unless AccessUser(ADMIN);
    return  unless $cgiparams{'groupid'};
    return  unless $cgiparams{'id'};
    $dbi->DoQuery('DeleteLinkIndex',2,$cgiparams{'id'},$cgiparams{'groupid'});
}

1;

__END__

=head1 SEE ALSO

L<Labyrinth>

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
