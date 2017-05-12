# Ginger::Reference::Permission::Manager::Default
# Version 0.01
# Copyright (C) 2013 David Helkowski

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.  You may also can
# redistribute it and/or modify it under the terms of the Perl
# Artistic License.
  
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

=head1 NAME

Ginger::Reference::Permission::Manager::Default - Ginger::Reference Component

=head1 VERSION

0.02

=cut

package Ginger::Reference::Permission::Manager::Default;
use Class::Core 0.03 qw/:all/;
use strict;
use vars qw/$VERSION/;
use XML::Bare qw/xval/;
use Data::Dumper;
$VERSION = "0.02";

sub init {
    my ( $core, $self ) = @_;
    my $methods = $self->{'methods'} = [];
    my $meth_hash = $self->{'meth_hash'} = {};
    my $xml = $self->{'_xml'};
    my $method = xval $xml->{'method'};
    my @meths = split( /,/,$method );
    my $prefixes = $self->{'prefixes'} = {};
    for my $methname ( @meths ) {
        my $meth = $core->get_mod( $methname );
        my $prefix_list = $meth->get_prefixes();
        for my $prefix ( @$prefix_list ) {
            $prefixes->{ $prefix } = $meth;
        }
        push( @$methods, $meth );
        $meth_hash->{ $methname } = $meth;
    }
    if( ! keys %$prefixes ) {
        undef $self->{'prefixes'};
    }
}

# get a list of all known permissions
sub list_permissions {
    my ( $core, $self ) = @_;
    $Data::Dumper::Maxdepth = 2;
    #print Dumper( $self );
     # go through chosen method modules and get groups
    my @perms;
    my $meths = $self->{'methods'};
    my %hash;
    for my $meth ( @$meths ) {
        my $meth_perms = $meth->list_permissions();
        for my $key ( keys %$meth_perms ) {
            $hash{ $key } = $meth_perms->{ $key };
        }
        #print Dumper( $meth_perms );
        #push( @perms, @$meth_perms );
    }
    return \%hash;
}

sub group_list {
    # may not wish to list LDAP groups since there would be tons...
}

# get a list of permissions provided by a specific group
sub group_get_permissions {
    my ( $core, $self ) = @_;
    my $group = $core->get('group'); # this is the text name of the group
    my $meth = $self->group_select_method( group => $group );
    return $meth->group_get_permissions( group => $group );
}

# Figure out which method handles this group based upon the group prefix
sub group_select_method {
    my ( $core, $self ) = @_;
    my $group = $core->get('group');
    my $pref = $self->{'prefixes'};
    my $meth;
    if( $group =~ m/^([a-z]+)_(.+)/ ) {
        my $prefix = $1;
        $meth = $pref->{ $prefix };
    }
    else {
        $meth = $pref->{ 'none' };
        if( !$meth ) {
            die "No permission method set to handle groups with no prefix - gp=$group";
        }
    }
    return $meth;
}

# get a list of all of the members of a group
sub group_get_members {
    # figure out which method handles this group and send it off to that
    
}

sub group_add_permission {
}

sub group_delete_permission {
}

sub group_add {
}

sub group_delete {
}

# get all the permissions provided by belonging to multiple groups
sub groupset_get_permissions {
    my ( $core, $self ) = @_;
    my $groups = $core->get('groups');
    my %permhash;
    for my $gpname ( @$groups ) {
        my $gp_perms = $self->group_get_permissions( group => $gpname );
        for my $gp_perm ( keys %$gp_perms ) {
            $permhash{ $gp_perm } = 1;
        }
    }
    return \%permhash;
}

sub user_list {
    # may not wish to list ldap users since there would be many
}

sub user_add {
}

sub user_delete {
}

# get all permissions associated with a user
sub user_get_permissions {
    my ( $core, $self ) = @_;
    my $user = $core->get('user');
    
    my $groups = $self->user_get_groups( user => $user ); # will return an array reference of group names
    
    my $perms = $self->groupset_get_permissions( groups => $groups ); # should take an array reference of group names
        # returns a hash with the keys being the names of the permissions
    
    # for each method, check direct user permissions
    my $meths = $self->{'methods'};
    for my $meth ( @$meths ) {
        my $user_perms = $meth->user_get_permissions( user => $user );
        #print Dumper( $user_perms );
        # add user_perms into perms
        for my $user_perm ( keys %$user_perms ) {
            $perms->{ $user_perm } = 1;
        }
    }
    
    # for each method; run a check on the final user permissions before returning them
    # method->integrate_permissions
    
    return $perms; # returns a hash of all of the user permissions ( the keys are the names of the permissions )
}

sub user_get_groups {
    my ( $core, $self ) = @_;
    my $user = $core->get('user');
    # go through chosen method modules and get groups
    my @groups;
    my $meths = $self->{'methods'};
    for my $meth ( @$meths ) {
        my $meth_groups = $meth->user_get_groups( user => $user );
        push( @groups, @$meth_groups );
    }
    return \@groups;
}

sub user_add_permission {
    # add a new user permission of some type
    # this will be passed to each method; first one to handle it "succeeds"
}

sub user_delete_permisson {
}

sub group_add_member {
}

sub group_delete_member {
}

sub user_exists {
    my ( $core, $self ) = @_;
    my $user = $core->get('user');
    
    my $meths = $self->{'methods'};
    for my $meth ( @$meths ) {
        return 1 if( $meth->user_exists( user => $user ) );
    }
    return 0;
}

sub user_check_pw {
    my ( $core, $self ) = @_;
    $self = $self->{'src'} if( $self->{'src'} );
    my $user = $core->get('user');
    my $pass = $core->get('pw');
    my $meths = $self->{'methods'};
    for my $meth ( @$meths ) {
       if( $meth->user_check_pw( user => $user, pw => $pass ) ) {
           $core->set('ok', 1 );
           return;
       }
    }
    
    $core->set('ok',0);
    return;
}

1;

__END__

=head1 SYNOPSIS

Component of L<Ginger::Reference>

=head1 DESCRIPTION

Component of L<Ginger::Reference>

=head1 LICENSE

  Copyright (C) 2013 David Helkowski
  
  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License as
  published by the Free Software Foundation; either version 2 of the
  License, or (at your option) any later version.  You may also can
  redistribute it and/or modify it under the terms of the Perl
  Artistic License.
  
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

=cut