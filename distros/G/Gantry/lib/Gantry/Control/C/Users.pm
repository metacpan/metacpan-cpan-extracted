package Gantry::Control::C::Users;
use strict; 

use Gantry qw/-TemplateEngine=TT/;

use Gantry::Utils::Validate;

use Gantry::Control;
use Gantry::Control::Model::auth_users;
use Gantry::Control::Model::auth_group_members;

use Gantry::Utils::CRUDHelp qw( form_profile );
use Gantry::Plugins::CRUD;

my $crud = Gantry::Plugins::CRUD->new(
    add_action      => \&_add,
    edit_action     => \&_edit,
    delete_action   => \&_delete,
    form            => \&_form,

    template        => 'form.tt',
    text_descr      => 'user',
    use_clean_dates => 1,
);

our @ISA = ( 'Gantry' );

my $AUTH_USERS = 'Gantry::Control::Model::auth_users';
my $AUTH_GROUP_MEMBERS = 'Gantry::Control::Model::auth_group_members';

############################################################
# Functions                                                #
############################################################

#-------------------------------------------------
# $self->do_main( $order )
#-------------------------------------------------
sub do_main {
    my ( $self, $order ) = @_;
    
    $order ||= 2;
    
    my $order_map = {
        1 => 'active',
        2 => 'user_id',
        3 => 'user_name',
        4 => 'last_name, first_name',
        5 => 'email'
    };
    
    # stash template name and page title
    $self->stash->view->template( 'results.tt' );
    $self->stash->view->title( 'Users' );

    my $retval = {
        headings       => [
            '<a href="' . $self->location . '/main/1">Active</a>',
            '<a href="' . $self->location . '/main/2">User ID</a>',
            '<a href="' . $self->location . '/main/3">User Name</a>',
            '<a href="' . $self->location . '/main/4">Name</a>',
            '<a href="' . $self->location . '/main/5">E-mail</a>'
        ],
        header_options => [
            {
                text => 'Add',
                link => $self->location() . "/add",
            },
        ],
    };

    my @rows = $AUTH_USERS->retrieve_all( 
        { 'order_by' => $order_map->{$order} } 
    );
    
    foreach my $row ( @rows ) {
        my $id = $row->id;
        push(
            @{$$retval{rows}},
            {
                data => [ 
                    ( $row->active ? 'yes' : 'no' ), 
                    $row->user_id,
                    $row->user_name, 
                    ( $row->last_name . ", " . $row->first_name ), 
                    $row->email  
                ],
                options => [
                    { 
                        text => 'Edit', 
                        link => ( $self->location . "/edit/$id" ) 
                    },
                    { 
                        text => 'Delete',
                        link => ( $self->location . "/delete/$id" ), 
                    },
                ]
            }
        );
    }
    
    # stash view data
    $self->stash->view->data( $retval );
    
} # end do_main  



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
    
    $param{'crypt'} = encrypt( $param{passwd} );
    
    my $new_row = $AUTH_USERS->create( \%param );
    $new_row->dbi_commit;
        
} # end do_add

#-------------------------------------------------
# $self->do_edit( $id )
#-------------------------------------------------
sub do_edit {
    my ( $self, $id ) = @_;

    # Load row values
    my $user = $AUTH_USERS->retrieve( $id );

    $crud->edit( $self, { user => $user } );
    
} # end do_edit

#-------------------------------------------------
# $self->_edit( $param, $data )
#-------------------------------------------------
sub _edit {
    my( $self, $params, $data ) = @_;
        
    my %param = %{ $params };
    
    $param{'crypt'} = encrypt( $param{passwd} );
    
    my $user = $data->{user};
                                       
    # Make update
    $user->set( %param );
    $user->update;
    $user->dbi_commit;
        
} # end do_edit

#-------------------------------------------------
# $self->do_delete( $id, $yes )
#-------------------------------------------------
sub do_delete {
    my ( $self, $id, $yes ) = @_;
        
    # Load row values
    my $user = $AUTH_USERS->retrieve( $id );       
    $crud->delete( $self, $yes, { user => $user } );
    
} # end do_delete

#-------------------------------------------------
# $self->_delete( $data )
#-------------------------------------------------
sub _delete {
    my( $self, $data ) = @_;
    
    my $user = $data->{user};
    
    my @mems = $AUTH_GROUP_MEMBERS->search( user_id => $user->user_id );
    foreach ( @mems ) {
        $_->delete;
    }
    $AUTH_GROUP_MEMBERS->dbi_commit;
    
    $user->delete;
    $AUTH_USERS->dbi_commit();


} # end delete_page

#-------------------------------------------------
# _form( $row ? )
#-------------------------------------------------
sub _form {
    my ( $self, $data ) = @_;       
        
    my $row = $data->{user};
    
    my ( @available_ids, %existing_ids );
    my @users = $AUTH_USERS->retrieve_all();
    foreach ( @users ) {
        ++$existing_ids{ $_->user_id };
    }
    
    for ( my $i = 1; $i < 300; ++$i ) {
        push( @available_ids, { label => $i, value => $i } )
            unless defined $existing_ids{ $i }; 
    }
    
    my @fields;
    
    push( @fields, 
        {   name    => 'user_id',
            is      => 'int4',
            label   => 'User ID',
            type    => 'select',
            options => \@available_ids,
        }
    ) if $self->path_info =~ /add/i;
    
    push( @fields,
        {   name    => 'active',
            label   => 'Active',
            type    => 'select',
            is      => 'boolean',
            options => [
                { label => 'Yes', value => 't' },
                { label => 'No',  value => 'f' },
            ],
        },
        {   name    => 'user_name',
            label   => 'User&nbsp;Name',
            type    => 'text',
            is      => 'varchar',
        },
        {   name    => 'passwd',
            label   => 'Password',
            is      => 'varchar',
            type    => 'password',
        },
        {   name    => 'first_name',
            label   => 'First&nbsp;Name',
            is      => 'varchar',
            type    => 'text',
        },
        {   name    => 'last_name',
            label   => 'Last&nbsp;Name',
            is      => 'varchar',
            type    => 'text',
        },
        {   optional => 1,
            name    => 'email',
            is      => 'varchar',
            label   => 'E-mail',
            type    => 'text',
        }
    );
    
    my $form =  {
        legend => $self->path_info =~ /edit/i ? 'Edit' : 'Add',
        width => 400,
        row => $row,
        fields => \@fields
    };      
            
    return( $form );

} # end _form

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

Gantry::Control::C::Users - User Management 

=head1 SYNOPSIS

  use Gantry::Control::C::Users;
  
=head1 DESCRIPTION

This Handler manages users in the database to facilitate the use of that
information for authentication, autorization, and use in applications. 
This replaces the use of htpasswd for user management and puts more
information at the finger tips of the application.

=head1 APACHE

  <Location /admin/users >
    SetHandler  perl-script

    PerlSetVar  title   "User Management: "

    PerlSetVar  dbconn  "dbi:Pg:dbname=..."
    PerlSetVar  dbuser  "<database_username>"
    PerlSetVar  dbpass  "<database_password>"
    PerlSetVar  dbcommit  off

    PerlHandler Gantry::Control::C::Users
  </Location>

=head1 DATABASE 

This is the auth_users table that is used by this module. It is also
used by the Authentication modules to verify usernames and passwords.
The passwords are ecrypted by the crypt(3) function in perl.

  create table "auth_users" (
    "id"            int4 default nextval('auth_users_seq') NOT NULL,
    "user_id"       int4,
    "active"        bool,
    "user_name"     varchar,
    "passwd"        varchar,
    "crypt"         varchar,
    "first_name"    varchar,
    "last_name"     varchar,
    "email"         varchar
  );

=head1 METHODS

Most of the methods are mapped to urls.

=over 4

=item do_add

=item do_delete

=item do_edit

=item do_main

=item redirect_to_main

Decides where to go after a button press.

=back

One method is provided for templates to call.

=over 4

=item site_links

Provides the site nav links for use at the top and/or bottom of the page.

=back

=head1 SEE ALSO

Gantry::Control(3), Gantry(3)

=head1 LIMITATIONS

The passwords for users are enrypted so they can not be seen at all. In
some situations this could be a very big problem.

=head1 AUTHOR

Tim Keefer <tkeefer@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2005-6, Tim Keefer.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
