package Gantry::Control::C::Pages;
use strict;

use Gantry qw/-TemplateEngine=TT/;

use Data::FormValidator;

use Gantry::Control;
use Gantry::Utils::Validate;
use Gantry::Utils::HTML qw( :all );

use Gantry::Utils::CRUDHelp qw( form_profile );
use Gantry::Plugins::CRUD;

use Gantry::Control::Model::auth_pages;
use Gantry::Control::Model::auth_groups;
use Gantry::Control::Model::auth_group_members;
use Gantry::Control::Model::auth_users;

############################################################
# Variables                                                #
############################################################
our @ISA = ( 'Gantry' ); # Inherit the handler.

our $AUTH_PAGES         = 'Gantry::Control::Model::auth_pages';
our $AUTH_GROUPS        = 'Gantry::Control::Model::auth_groups';
our $AUTH_GROUP_MEMBERS = 'Gantry::Control::Model::auth_group_members';
our $AUTH_USERS         = 'Gantry::Control::Model::auth_users';

my $crud = Gantry::Plugins::CRUD->new(
    add_action      => \&add_page,
    edit_action     => \&edit_page,
    delete_action   => \&delete_page,
    form            => \&page_form,
    redirect        => \&redirect_to_main,
    template        => 'form.tt',
    text_descr      => 'pages',
    use_clean_dates => 1,
);



############################################################
# Functions                                                #
############################################################
#-------------------------------------------------
# $self->do_main( $order )
#-------------------------------------------------
sub do_main {
    my ( $self, $order ) = @_;
    
    # stash template, title
    $self->stash->view->template( 'results.tt' );
    $self->stash->view->title( 'Page Permissions' );
        
    $order ||= 'uri'; # set default order
    
    my $retval = {
        headings => [
            'URI', 'Title', 'Permissions', 'Owner', 'Group'
        ],
        header_options => [ {
            text => 'Add', link => ( $self->location . "/add" ),
        } ],
    };

    my @rows = $AUTH_PAGES->retrieve_all( 
        { 'order_by' => $order } 
    );
    
    foreach my $row ( @rows ) {
        my $id = $row->id;
        
        push(
            @{$$retval{rows}},
            {
                data => [ 
                    ht_a( $row->uri, $row->uri ), 
                    $row->title, 
                    ( $row->user_perm . $row->group_perm . $row->world_perm ),
                    ( $row->owner_id->last_name . ', ' 
                        . $row->owner_id->first_name ),
                    $row->group_id->name, 
                ],
                options => [
                    { 
                        text => 'Edit', 
                        link => ( $self->location . "/edit/$id" ),
                    },
                    { 
                        text => 'Delete',   
                        link => ( $self->location . "/delete/$id" )
                    },
                ]
            }
        );
    }
        
    # stash view data
    $self->stash->view->data( $retval );

} # end do_main

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

sub add_page {
    my( $self, $params, $data ) = @_;
            
    my %param = %{ $params };
               
    # Clean up the variables some.
    for my $bit ( qw( ur uw ux gr gw gx wr ww wx ) ) {
        $param{$bit} = ( $param{$bit} ) ? 1 : 0;
    }
        
    # set user_perm, group_perm, world_perm
    $param{user_perm} = 
        ( $param{ur} * 4 ) 
        + ( $param{uw} * 2 ) 
        + ( $param{ux} * 1 );
        
    $param{group_perm} = 
        ( $param{gr} * 4 ) 
        + ( $param{gw} * 2 ) 
        + ( $param{gx} * 1 );
        
    $param{world_perm} = 
        ( $param{wr} * 4 ) 
        + ( $param{ww} * 2 ) 
        + ( $param{wx} * 1 );
                    
    # remove bits from param hash
    for my $bit ( qw( ur uw ux gr gw gx wr ww wx ) ) {
        delete( $param{$bit} );
    }
                    
    my $new_row = $AUTH_PAGES->create( \%param );
    $new_row->dbi_commit;

} # end do_add

#-------------------------------------------------
# $self->do_delete( $id, $yes )
#-------------------------------------------------
sub do_delete {
    my ( $self, $id, $yes ) = @_;
        
    # Load row values
    my $page = $AUTH_PAGES->retrieve( $id );       
    $crud->delete( $self, $yes, { page => $page } );
    
} # end do_delete

#-------------------------------------------------
# $self->delete_page( $data )
#-------------------------------------------------
sub delete_page {
    my( $self, $data ) = @_;
    
    my $page = $data->{page};
    
    $page->delete;
    $AUTH_PAGES->dbi_commit();

} # end delete_page

#-------------------------------------------------
# $self->do_edit( $id )
#-------------------------------------------------
sub do_edit {
    my ( $self, $id ) = @_;

    # Load row values
    my $page = $AUTH_PAGES->retrieve( $id );

    $crud->edit( $self, { page => $page } );
    
} # end do_edit

#-------------------------------------------------
# $self->edit_page( $param, $data )
#-------------------------------------------------
sub edit_page {
    my( $self, $params, $data ) = @_;
        
    my %param = %{ $params };
    
    my $page = $data->{page};
       
    # Clean up the variables some.
    for my $bit ( qw/ur uw ux gr gw gx wr ww wx/ ) {
        $param{$bit} = ( defined $param{$bit} ) ? 1 : 0;
    }

    $param{user_perm} = 
        ( $param{ur} * 4 ) 
        + ( $param{uw} * 2 ) 
        + ( $param{ux} * 1 );
        
    $param{group_perm} = 
        ( $param{gr} * 4 ) 
        + ( $param{gw} * 2 ) 
        + ( $param{gx} * 1 );
        
    $param{world_perm} = 
        ( $param{wr} * 4 ) 
        + ( $param{ww} * 2 ) 
        + ( $param{wx} * 1 );
                    
    for my $bit ( qw/ur uw ux gr gw gx wr ww wx/ ) {
        delete( $param{$bit} );
    }
                               
    # Make update
    $page->set( %param );
    $page->update;
    $page->dbi_commit;
        
} # end do_edit


#-------------------------------------------------
# _form( $row ? )
#-------------------------------------------------
sub page_form {
    my ( $self, $data ) = @_;       
    
    my $row = $data->{page};
    
    my %param = $self->get_param_hash;
    
    # user permissions
    if ( ( ! defined $param{ur} ) 
            || ( ! defined $param{uw} ) 
            || ( ! defined defined $param{ux} ) ) {
        
        (   $param{ur}, 
            $param{uw}, 
            $param{ux} ) = dec2bin( eval{ $row->user_perm } );
    }
    
    # group permissions
    if ( ( ! defined $param{gr} ) 
            || ( ! defined $param{gw} ) 
            || ( ! defined defined $param{gx} ) ) {
        
        (   $param{gr}, 
            $param{gw}, 
            $param{gx} ) = dec2bin( eval{ $row->{group_perm} } );
    }
    
    # world permissions
    if ( ( ! defined $param{wr} ) 
            || ( ! defined $param{ww} ) 
            || ( ! defined defined $param{wx} ) ) {
        
        (   $param{wr}, 
            $param{ww}, 
            $param{wx} ) = dec2bin( eval{ $row->{world_perm} } );
    }
    
    my @permissions = (
            ht_table(),
                ht_tr(),
                ht_td( { 'class' => 'shd' }, 'Owner' ),
                ht_td( { 'class' => 'shd' }, 'Group' ),
                ht_td( { 'class' => 'shd' }, 'World' ),
                ht_utr(),

                ht_tr(),
                ht_td( { 'class' => 'dta' },    
                        ht_checkbox( 'ur', 1, $param{ur} ), 'Read', ht_br(),
                        ht_checkbox( 'uw', 1, $param{ux} ), 'Write', ht_br(),
                        ht_checkbox( 'ux', 1, $param{ux} ), 'Execute' ),
                ht_td( { 'class' => 'dta' },    
                        ht_checkbox( 'gr', 1, $param{gr} ), 'Read', ht_br(),
                        ht_checkbox( 'gw', 1, $param{gw} ), 'Write', ht_br(),
                        ht_checkbox( 'gx', 1, $param{gx} ), 'Execute' ),
                ht_td( { 'class' => 'dta' },    
                        ht_checkbox( 'wr', 1, $param{wr} ), 'Read', ht_br(),
                        ht_checkbox( 'ww', 1, $param{ww} ), 'Write', ht_br(),
                        ht_checkbox( 'wx', 1, $param{wx} ), 'Execute' ),
                ht_utr(),
            ht_utable() ,
    );
    
    # push groups to array
    my @group_options;
    foreach ( $AUTH_GROUPS->retrieve_all( { order_by => 'name' } ) ) {
        push( @group_options, {
            label => $_->name,
            value => $_->id,
        });
    }
    
    # push users to array
    my @owner_options;
    foreach ( $AUTH_USERS->retrieve_all(
        { order_by => 'last_name, first_name' } ) ) {
        
        push( @owner_options, {
            label => ( $_->last_name . ", " . $_->first_name ),
            value => $_->id,
        });
    }
        
    my $form =  {
        legend  => $self->path_info =~ /edit/i ? 'Edit' : 'Add',
        width   => "400",
        label_width => '40px',
        row     => $row,
        fields => [
            {   name    => 'uri',
                label   => 'URI',
                type    => 'text',
                is      => 'varchar'
            },
            {   name    => 'title',
                label   => 'Title',
                type        => 'text',
                is      => 'varchar',
            },
            {   name    => 'owner_id',
                label   => 'Owner',
                is      => 'int4',
                type        => 'select',
                options     => \@owner_options
            },          
            {   name        => 'group_id',
                label       => 'Group',
                is          => 'int4',
                type        => 'select',
                options     => \@group_options
            },
            {   html     => join( "\n", @permissions ),
                optional => 1,
                type     => 'html',
                is       => 'varchar',
                label    => 'Permissions',
             }
        ]
    };      
            
    return( $form );
    
} # end form

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

Gantry::Control::C::Pages - Page based control adminstration.

=head1 SYNOPSIS

  use Gantry::Control::C::Pages;

=head1 DESCRIPTION

This module is the frontend for the Gantry::Control::Authz::PageBased
authentication handler. One would specify pages as well as the
permissions with this frontend module.

=head1 APACHE

Sample Apache configuration.

  <Location /admin/pages >
    SetHandler  perl-script

    PerlSetVar  title   "Page Accesst: "

    PerlSetVar  dbconn  "dbi:Pg:dbname=..."
    PerlSetVar  dbuser  "<database_username>"
    PerlSetVar  dbpass  "<database_password>"
    PerlSetVar  dbcommit  off

    PerlHandler Gantry::Control::C::Pages
  </Location>

=head1 DATABASE 

This is the auth_pages table that is used by this module. It also uses
the auth_users and auth_groups tables for reference. 
    
  create table "auth_pages" (
    "id"            int4 default nextval('auth_pages_seq'::text) NOT NULL,
    "user_perm"     int4,
    "group_perm"    int4,
    "world_perm"    int4,
    "owner_id"      int4,
    "group_id"      int4,
    "uri"           varchar,
    "title"         varchar
  );

=head1 METHODS

=over 4

=item add_page

Gantry::Plugins::CRUD callback.

=item delete_page

Gantry::Plugins::CRUD callback.

=item do_add

Called by Gantry handler.

=item do_delete

Called by Gantry handler.

=item do_edit

Called by Gantry handler.

=item do_main

Called by Gantry handler.

=item edit_page

Gantry::Plugins::CRUD callback.

=item page_form

The form description.

=item redirect_to_main

Gantry::Plugins::CRUD callback.

=back

There is also one method designed to be called by template wrappers.

=over 4

=item site_links

Returns site nav links and their text.

=back

=head1 SEE ALSO

Gantry::Control(3), Gantry::Control::C::Users(3), Gantry::Control::C::Groups(3),
Gantry::Control::C::Authz::PageBased(3)

=head1 LIMITATIONS

=head1 AUTHOR

Tim Keefer <tkeefer@gmail.com>
Nicholas Studt <nstudt@angrydwarf.org>

=head1 COPYRIGHT

Copyright (c) 2005-6, Tim Keefer.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
