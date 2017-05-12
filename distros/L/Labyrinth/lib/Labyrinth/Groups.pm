package Labyrinth::Groups;

use warnings;
use strict;

use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT @EXPORT_OK);
$VERSION = '5.32';

=head1 NAME

Labyrinth::Groups - User Group Manager for Labyrinth

=head1 DESCRIPTION

This package provides group management for user access. Groups can be used to
set permissions for a set of users, without setting individual user
permissions.

=cut

# -------------------------------------
# Export Details

require Exporter;
@ISA = qw(Exporter);

%EXPORT_TAGS = (
    'all' => [ qw( GetGroupID UserInGroup UserGroups GroupSelect GroupSelectMulti ) ]
);

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
@EXPORT    = ( @{ $EXPORT_TAGS{'all'} } );

# -------------------------------------
# Library Modules

use Labyrinth::Audit;
use Labyrinth::Globals;
use Labyrinth::DBUtils;
use Labyrinth::MLUtils;
use Labyrinth::Session;
use Labyrinth::Support;
use Labyrinth::Variables;

# -------------------------------------
# Variables

my %InGroup;

# -------------------------------------
# The Subs

=head1 FUNCTIONS

=over 4

=item GetGroupID

Returns the ID of the specific group.

=item UserInGroup

Checks whether the specified user (or current user) is in the specified group
Returns 1 if true, otherwise 0 for false.

=item UserGroups()

For the current user login, return the list of groups they are associated with.

=item GroupSelect([$opt])

Provides the XHTML code for a single select dropdown box. Pass the id of a
group to pre-select that group.

=item GroupSelectMulti([$opt[,$rows]])

Provides the XHTML code for a multiple select dropdown box. Pass the group id 
or an arrayref to a list of group ids to pre-select those groups. By default
the number of rows displayed is 5, although this can be changed by passing the
number of rows you require.

=cut

sub GetGroupID {
    my $name = shift || return;
    my @rows = $dbi->GetQuery('array','GetGroupID',$name);
    return  unless(@rows);
    return $rows[0]->[0];
}

sub UserInGroup {
    my $groupid = shift || return;
    my $userid  = shift || $tvars{loginid};
    return 0    unless($groupid && $userid);

    $InGroup{$userid} ||= do { UserGroups($userid) };
    return 1    if($InGroup{$userid} =~ /\b$groupid\b/);
    return 0;
}

sub UserGroups {
    my $userid  = shift || $tvars{loginid};
    my (%groups,@grps);
    my @rows = $dbi->GetQuery('hash','AllGroupIndex');
    foreach (@rows) {
        # a user link, but not our user
        next    if($_->{type} == 1 && $_->{linkid} ne $userid);
        
        if($_->{type} == 1) {
            push @grps, $_->{groupid};
        } else {
            push @{$groups{$_->{linkid}}}, $_->{groupid};
        }
    }
    my @list = ();
    while(@grps) {
        my $g = shift @grps;
        push @list, $g;
        next    unless($groups{$g});
        push @grps, @{$groups{$g}};
        delete $groups{$g};
    }
    my %hash = map {$_ => 1} @list;
    my $grps = join(",",keys %hash);
    return $grps;
}

sub GroupSelect {
    my $opt = shift;
    my @rows = $dbi->GetQuery('hash','AllGroups');
    unshift @rows, {groupid => 0, groupname => 'Select A Group' };
    return DropDownRows($opt,'groups','groupid','groupname',@rows);
}

sub GroupSelectMulti {
    my $opt   = shift;
    my $multi = shift || 5;
    my @rows = $dbi->GetQuery('hash','AllGroups');
    unshift @rows, {groupid => 0, groupname => 'Select A Group' };
    return DropDownMultiRows($opt,'groups','groupid','groupname',$multi,@rows);
}


1;

__END__

=back

=head1 SEE ALSO

  Labyrinth

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
