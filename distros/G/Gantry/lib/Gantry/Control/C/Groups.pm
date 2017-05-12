package Gantry::Control::C::Groups;
use strict; 

use Gantry qw/-TemplateEngine=TT/;

use Data::FormValidator;
use HTML::Prototype;

use Gantry::Utils::Validate;
use Gantry::Control::Model::auth_users;
use Gantry::Control::Model::auth_groups;
use Gantry::Control::Model::auth_group_members;

use Gantry::Utils::CRUDHelp qw( form_profile );
use Gantry::Plugins::CRUD;

my $AUTH_USERS = 'Gantry::Control::Model::auth_users';
my $AUTH_GROUPS = 'Gantry::Control::Model::auth_groups';
my $AUTH_GROUP_MEMBERS = 'Gantry::Control::Model::auth_group_members';

my $crud = Gantry::Plugins::CRUD->new(
    add_action      => \&_add,
    edit_action     => \&_edit,
    delete_action   => \&_delete,
    form            => \&_form,
    redirect        => \&redirect_to_main,
    template        => 'form.tt',
    text_descr      => 'Group',
    use_clean_dates => 1,
);

############################################################
# Variables                                                #
############################################################
our @ISA = ( 'Gantry' ); # Inherit the handler.


############################################################
# Functions                                                #
############################################################

#-------------------------------------------------
# $self->do_main( $order )
#-------------------------------------------------
sub do_main {
    my ( $self, $order ) = @_;
    
    $order ||= 1;

    my $order_map = {
        1 => 'name',
        2 => 'ident',
    };
    
    # stash template and title
    $self->stash->view->template( 'results.tt' );
    $self->stash->view->title( 'Groups' );
        
    my $location = $self->location;
    
    my $retval = {
        headings => [ 
            '<a href="' . $self->location . '/main/1">Group Name</a>', 
            '<a href="' . $self->location . '/main/2">Ident</a>', 
            'Description' ],
        header_options  => [ {
            text => 'Add', link => ( "$location/add" ),
        } ],
    };

    my @rows = Gantry::Control::Model::auth_groups->retrieve_all( 
        { 'order_by' => $order } 
    );
    
    foreach my $row ( @rows ) {
        my $id = $row->id;
        push( @{$$retval{rows}}, {
            data => [ 
                $row->name, 
                $row->ident,
                $row->description, 
            ],
            options => [
                { text => 'Members', link => "$location/members/$id" },
                { text => 'Edit',    link => "$location/edit/$id" },
                { text => 'Delete',  link => "$location/delete/$id" },
            ]
        });
    }
    
    # stash view data
    $self->stash->view->data( $retval );

} # end: do_main

sub redirect_to_main {
    my ( $self, $data ) = @_;
    
    return $self->location;
    
}

#-------------------------------------------------
# $self->do_add( $r )
#-------------------------------------------------
sub do_add {
    my ( $self ) = ( shift );
   
    $crud->add( $self );

} # end do_add

sub _add {
    my( $self, $params, $data ) = @_;
            
    my %param = %{ $params };
                            
    # Clean up the variables some.
    $param{description} =~ s/\r//g;
    $param{description} =~ s/\n/<BR>/g;
    $param{name}        =~ s/\s+/\_/g;
                                            
    my $new_row = $AUTH_GROUPS->create( \%param );
    $new_row->dbi_commit;
        
} # end do_add

#-------------------------------------------------
# $self->do_delete( $id, $yes )
#-------------------------------------------------
sub do_delete {
    my ( $self, $id, $yes ) = @_;
        
    # Load row values
    my $row = $AUTH_GROUPS->retrieve( $id );       
    $crud->delete( $self, $yes, { row => $row } );
    
} # end do_delete

#-------------------------------------------------
# $self->delete_page( $data )
#-------------------------------------------------
sub _delete {
    my( $self, $data ) = @_;
    
    my $row = $data->{row};
    
    $row->delete;
    $AUTH_GROUPS->dbi_commit();

} # end delete_page

#-------------------------------------------------
# $self->do_edit( $id )
#-------------------------------------------------
sub do_edit {
    my ( $self, $id ) = @_;

    # Load row values
    my $row = $AUTH_GROUPS->retrieve( $id );

    $crud->edit( $self, { row => $row } );
    
} # end do_edit

#-------------------------------------------------
# $self->_edit( $param, $data )
#-------------------------------------------------
sub _edit {
    my( $self, $params, $data ) = @_;
        
    my %param = %{ $params };
    
    my $row = $data->{row};
                                       
    # Clean up the variables some.
    $param{description} =~ s/\r//g;
    $param{description} =~ s/\n/<BR>/g;
    $param{name}        =~ s/\s+/\_/g;
                                       
    # Make update
    $row->set( %param );
    $row->update;
    $row->dbi_commit;
        
} # end do_edit

#-------------------------------------------------
# $self->do_members( $id )
#-------------------------------------------------
sub do_members {
    my ( $self, $id ) = ( shift, shift );
    
    # stash template and title
    $self->stash->view->title( 'Add/Remove Members' );
    $self->stash->view->template( 'form_ajax.tt' );
        
    my $ajax = HTML::Prototype->new;    
        
    my @users = Gantry::Control::Model::auth_users->retrieve_all( 
        order_by => 'last_name');
        
    my %groups;
    foreach ( Gantry::Control::Model::auth_group_members->search( 
        group_id => $id ) ) {
        
        $groups{$_->user_id} = 1;
    }
    
    my @fields;
    foreach ( @users ) {
        my $name    = ( $_->last_name . ",&nbsp;" . $_->first_name );
        my $user_id = $_->user_id;
        
        # set callback
        my $callback = $ajax->observe_field( "user_id_$user_id", { 
            url => ( $self->location . '/ajax_edit' ) ,
            with => (
                "'cmd=member\&val='+value+'\&user_id=$user_id"
                . "\&group_id=$id'" 
            ),
            update => "view", 
        } );
        
        push( @fields, {
            id      => "user_id_$user_id",
            name    => "user_id_$user_id",
            label   => $name,
            type    => 'checkbox',
            default_value => 1,
            checked => $groups{$user_id}, 
            callback => $callback,
        });
    }

    my $form =  {
        ajax_java_script => $ajax->define_javascript_functions,
        legend  => "Add/Remove Members",
        back    => $$self{location},
        fields  => \@fields
    };      
            
    # stash form        
    $self->stash->view->form( $form );
        
} # end do_members

#-------------------------------------------------
# $self->do_ajax_edit( )
#-------------------------------------------------
sub do_ajax_edit {
    my( $self ) = ( shift );
    
    $self->template_disable( 1 );       # turn off frame for ajax
        
    my %param = $self->get_param_hash;
    
    # check for errors
    my @errors;
    push( @errors, "missing user_id" )  if ! defined $param{user_id};
    push( @errors, "missing group_id" ) if ! defined $param{group_id};
    return( "Ajax Error:<Br />", join( "<br />", @errors ) ) if @errors;
    
    # form returns 'undefined' fom unchecked boxes, make them 0
    $param{val} = 0 if $param{val} eq 'undefined';
    
    # update send_to preference 
    if ( $param{cmd} eq "member" ) {
        
        # Add member
        if ( $param{val} ) {
            my $new_member = 
                Gantry::Control::Model::auth_group_members->find_or_create(
                    {   user_id => $param{user_id}, 
                        group_id => $param{group_id} 
                    });
                    
            $new_member->dbi_commit;
            
            return( "Status: Added " . $new_member->user_id->first_name );
        }
        # Remove member
        else {
                        
            my @rem_member = 
                Gantry::Control::Model::auth_group_members->search(
                    user_id  => $param{user_id},
                    group_id => $param{group_id} 
                );

            foreach ( @rem_member ) {
                $_->delete;
            }

            Gantry::Control::Model::auth_group_members->dbi_commit;
            
            return( 
                "Status: Removed " . 
                Gantry::Control::Model::auth_users->retrieve( 
                    user_id => $param{user_id} 
                )->first_name 
            );
        }

    }
        
    return ( 'Invalid Ajax Action' ); 

} # end: do_ajax_edit

#-------------------------------------------------
# _form( $row ? )
#-------------------------------------------------
sub _form {
    my ( $self, $data ) = @_;       
    
    my $row = $data->{row};
    
    my $form =  {
        legend => $self->path_info =~ /edit/i ? 'Edit' : 'Add',
        row    => $row,
        fields => [
            {   name    => 'name',
                label   => 'Group Name',
                type    => 'text',
                is      => 'varchar',
            },
            {   name    => 'ident',
                label   => 'Ident',
                type    => 'text',
                is      => 'varchar',
                optional => 1,
            },
            {   name    => 'description',
                label   => 'Description',
                type    => 'textarea',
                rows    => 7,
                cols    => 40,
                is      => 'varchar',
            },
        ]
    };      
            
    return( $form );

} # END form

sub site_links {
    my $self = shift;
    
    return( [
        { link => ($self->app_rootp . '/users'), label => 'Users' },
        { link => ($self->app_rootp . '/groups'), label => 'Groups' },
        { link => ($self->app_rootp . '/pages'), label => 'Pages' },
    ] );       
}

# EOF
1;

__END__

=head1 NAME 

Gantry::Control::C::Groups - Group management for the Gantry library

=head1 SYNOPSIS

  use Gantry::Control::C::Groups;

=head1 DESCRIPTION

This module handles all of the group manipulation for the authorization
and authentication handlers. It's pretty mundane by itself.

=head1 APACHE

Sample Apache configuration.

  <Location /admin/groups >
    SetHandler  perl-script

    PerlSetVar  SiteTitle       "Group Management: "

    PerlSetVar  dbconn  "dbi:Pg:dbname=..."
    PerlSetVar  dbuser  "<database_username>"
    PerlSetVar  dbpass  "<database_password>
    PerlSetVar  DatabaseCommit  off
                   
    PerlHandler Gantry::Control::C::Groups
  </Location>

=head1 DATABASE 

These are the group authentication/authorization tables used by this
module. They are also used by the authen and authz handlers this package
contains.
  
  create table "auth_users" (
    see C<Gantry::Control::C::User> 
  );
  
  create table "auth_groups" (
    "id"            int4 default nextval('auth_groups_seq'::text) NOT NULL,
    "name"          varchar,
    "description"   text
  );

  create table "auth_group_members" (
    "id"        int4 default nextval('auth_group_members_seq'::text) NOT NULL,
    "user_id"   int4,
    "group_id"  int4    
  );

=head1 METHODS

The methods are all url mapped handlers called by Gantry::handler, except
redirect_to_main which is a Gantry::Plugins::CRUD callback which decides
where to go when a button driven action is complete.

=over 4

=item do_add

=item do_ajax_edit

=item do_delete

=item do_edit

=item do_main

=item do_members

=item redirect_to_main

=back

There is also one method designed to be called by templates (especially
wrappers).

=over 4

=item site_links

Returns nav links and their text.

=back

=head1 SEE ALSO

Gantry::Control::C::Users(3), Gantry::Control(3), Gantry::Control::Users(3),
Gantry(3)

=head1 LIMITATIONS

The group name should be safe for use in the apache configuration files
but I am not going to force this down peoples throat as any string can
be made safe if escaped correctly.

=head1 AUTHOR

Tim Keefer <tkeefer@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2005-6, Tim Keefer.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
