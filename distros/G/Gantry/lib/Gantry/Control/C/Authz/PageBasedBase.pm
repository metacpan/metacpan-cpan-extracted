package Gantry::Control::C::Authz::PageBasedBase;

use strict;
use Gantry::Control;

use constant MP2 => (
    exists $ENV{MOD_PERL_API_VERSION} and
    $ENV{MOD_PERL_API_VERSION} >= 2 
);

# must explicitly import for mod_perl2
BEGIN {
    if (MP2) {
        require Gantry::Engine::MP20;
        Gantry::Engine::MP20->import();
    }
}

############################################################
# Functions                                                #
############################################################

######################################################################
# Main Execution Begins Here                                         #
######################################################################
sub handler : method {
    my ( $self, $r ) = @_;

    my $user_model          = $self->user_model;
    my $group_members_model = $self->group_members_model();

    # Check Exclude paths
    if ( $r->dir_config( 'exclude_path' ) ) {
        foreach my $p ( split( /\s*;\s*/, $r->dir_config( 'exclude_path' ) ) ) {
            if ( $r->path_info =~ /^$p$/ ) {
                return( $self->status_const( 'OK' ) );
            }
        }
    } # end if exclude_path
    
    my $requires = $r->requires; 

    # If we don't have any requirements get out !
    return( $self->status_const( 'DECLINED' ) ) if ( ! $requires );
    
    # Who's the user ?
    my $user = $r->user;
    
    # get the uri and fill @p.
    my @p   = split( '/', $r->uri );
    @p      = 'index.html' if ( scalar( @p ) < 1 );
            
    # Get the users groups and put them in a hash.
    my ( %groups, %group_ids, $uperm, $gperm, $wperm, $uid, $oid, $gid );
    
    if( $user ) {
        
        my @user_row = $user_model->search( user_name => $user ); 
        
        # set user id
        $uid = $user_row[0]->id;
        
        # get groups for user
        my @group_rows = $group_members_model->search( 
                user_id => $user_row[0]->id
        );
        
        foreach ( @group_rows ) {
            $groups{$_->group_id->name} = 1;
            $group_ids{$_->group_id} = 1;
        }
    } # end: if user                
    
    # make the check uri database calls here.
    ( $uperm, $gperm, $wperm, $oid, $gid ) = $self->lookup_uri( @p );
    
    # This should actually be Forbidden I believe.
    if ( $self->status_const( 'OK' ) 
                ne $self->do_requires( $requires, $user, \%groups ) ) {
        return( $self->status_const( 'FORBIDDEN' ) );
    }
        
    # compare against world
    return( $self->status_const( 'OK' ) ) if ( ( dec2bin( $wperm ) )[0] );

    # compare against group
    if ( defined $group_ids{$gid} ) {
        return( $self->status_const( 'OK' ) ) if ( ( dec2bin( $gperm ) )[0] );
    }
    
    # compare against user
    if ( $oid == $uid ) {
        return( $self->status_const( 'OK' ) ) if ( ( dec2bin( $uperm ) )[0] );
    }

    # This should actually be Forbidden I believe.
    # fail if all else dosen't work :( -- bye
    $r->note_basic_auth_failure;

    return( $self->status_const( 'FORBIDDEN' ) );

} # END $self->handler

#-------------------------------------------------
# do_requires( $requires, $user, $groups )
#-------------------------------------------------
sub do_requires {
    my ( $self, $requires, $user, $groups ) = @_;

    for my $req_ent ( @$requires ) {
        my ( $req, @rest ) = split( /\s+/, $req_ent->{requirement} );

        # This is kinda odd. Do I really need this ?
        if ( lc( $req ) eq 'valid-user' ) {
            return( $self->status_const( 'OK' ) );
        }
        elsif( lc( $req ) eq 'user' ) {
            for my $valid_user ( @rest ) {
                return( $self->status_const( 'OK' ) ) 
                    if ( $user eq $valid_user );
            }
        }
        elsif( lc( $req ) eq 'group' ) {
            for my $valid_group ( @rest ) {
                return( $self->status_const( 'OK' ) ) 
                    if ( exists $$groups{$valid_group} );
            }
        }
    }

} # END do_requires

#-------------------------------------------------
# $self->lookup_uri( @p )
#-------------------------------------------------
sub lookup_uri {
    my ( $self, @p ) = @_;

    # Sane staring point, nothing works ;)
    my ( $uperm, $gperm, $wperm, $oid, $gid ) = ( 0, 0, 0, 0, 0 );

    # Leave now if no @p
    return( $uperm, $gperm, $wperm, $oid, $gid ) if ( scalar( @p ) < 1 );

    # Figure out what the uri is.
    my $uri = join( '/', @p );
    $uri    = "/$uri" if ( $uri !~ /^\// );

    # Do the lookup.
    my @page_row = Gantry::Control::Model::auth_pages->search( uri => $uri );

    # If we find it set the vals.
    if ( @page_row ) {
        ( $uperm, $gperm, $wperm, $oid, $gid ) = (
            $page_row[0]->user_perm, 
            $page_row[0]->group_perm, 
            $page_row[0]->world_perm, 
            $page_row[0]->owner_id, 
            $page_row[0]->group_id 
        );

    }
    else {
        # Take one down and pass it around
        pop( @p );

        ( $uperm, $gperm, $wperm, $oid, $gid ) = $self->lookup_uri( @p );
    }

    # Return what we have.
    return( $uperm, $gperm, $wperm, $oid, $gid );

} # end lookup_uri

#-------------------------------------------------
# $self->import( $self, @options )
#-------------------------------------------------
sub import {
    my ( $self, @options ) = @_;
    
    my( $engine, $tplugin );
    
    foreach (@options) {
        
        # Import the proper engine
        if (/^-Engine=(.*)$/) { 
            $engine = "Gantry::Engine::$1";
            eval "use $engine"; 
            if ( $@ ) {
                die "unable to load engine $1 ($@)";
            }   
        }
        
    }
    
} # end: import

# EOF
1;

__END__

=head1 NAME 

Gantry::Control::C::Authz::PageBasedBase - Page based access control.

=head1 SYNOPSIS

  use Gantry::Control::C::Authz::PageBasedSubClass;

=head1 DESCRIPTION

This handler is the authorization portion for page based authorization.
It will authenticate only users who have been allowed from the
administrative interface into a particular uri.  The module returns
FORBIDDEN if you do not have access to a particular uri.

=head1 APACHE

This is a sample of how to set up Authorization only on a location.

  <Location /location/to/auth >
    AuthType    Basic
    AuthName    "Manual"

    PerlSetVar  dbconn  "dbi:Pg:dbname=..."
    PerlSetVar  dbuser  "<database_username>"
    PerlSetVar  dbpass  "<database_password>"
    PerlSetVar  dbcommit  off
                    
    PerlAuthenHandler Gantry::C::Control::AuthenSubClass
    PerlAuthzHandler  Gantry::C::Control::Authz::PageBasedSubClass

    require     valid-user
  </Location>

Choose a subclass to match your other database ORM scheme.  Use
Gantry::C::Control::Authz::PageBasedCDBI if you use Class::DBI (or something
descended from it), otherwise use Gantry::C::Control::Authz::PageBasedRegular.

=head1 DATABASE 

These are the authentication tables that this handler uses.

  create table "auth_pages" (
    "id"         int4 primary key default nextval('auth_pages_seq') NOT NULL,
    "user_perm"  int4,
    "group_perm" int4,
    "world_perm" int4,
    "owner_id"   int4,
    "group_id"   int4,
    "uri"        varchar,
    "title"      varchar
  );

  create table "auth_groups" (
    "id"          int4 primary key default nextval('auth_groups_seq') NOT NULL,
    "name"        varchar,
    "description" text
  );

  create table "auth_group_members" (
    "id"        int4 primary key default nextval('auth_group_members_seq') 
                NOT NULL,
    "user_id"   int4,
    "group_id"  int4    
  );

=head1 METHODS

=over 4

=item handler

The mod_perl page based authz handler.

=item do_requires

For internal use.

=item lookup_uri

For internal use.

=back

=head1 SEE ALSO

Gantry::Control::C::Pages(3), Gantry::Control::C::Authz(3), 
Gantry::Control(3), Gantry(3)

=head1 LIMITATIONS

Pages must be defined for this to work, otherwise everything returns 
FORBIDDEN to the user.

=head1 AUTHOR

Tim Keefer <tkeefer@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2005-6, Tim Keefer.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

