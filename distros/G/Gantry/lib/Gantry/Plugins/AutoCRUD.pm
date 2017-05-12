package Gantry::Plugins::AutoCRUD;

use strict;
use Data::FormValidator;

use Gantry::Utils::CRUDHelp qw(
        clean_params
        form_profile
        write_file
        verify_permission
);

use Exporter;
use Carp;

############################################################
# Variables                                                #
############################################################
our @ISA = qw( Exporter );
our @EXPORT = qw(
    do_add
    do_edit
    do_delete
    form_name
    write_file
);

our $orm_helper;
 
############################################################
# Functions                                                #
############################################################

sub form_name { return 'form.tt'; }

# not exported
sub get_cancel_loc {
    my     $self = shift;
    return( $self->location . ( $self->{__PID__} ? "/main/$$self{__PID__}" : '' ) );
}

# not exported
sub get_submit_loc {
    my     $self   = shift;
    my     $action = shift;
    
    if ( $action eq 'add_another' ) {
        return (
            $self->location . "/add" 
            .  ( $self->{__PID__} ? "/$$self{__PID__}" : '' )     
        )
    }

    return(
        $self->location
        .  ( $self->{__PID__} ? "/main/$$self{__PID__}" : '' ) 
    );
}

#-------------------------------------------------
# $self->do_add( )
#-------------------------------------------------
sub do_add {
    my ( $self, $pid ) = @_;

    $self->{__PID__} = $pid;
    $self->stash->view->template( $self->form_name( 'add' ) );
    $self->stash->view->title( 'Add ' . $self->text_descr( 'add' ) );

    my $params  = $self->get_param_hash();

    # Redirect if user pressed 'Cancel'
    if ( $params->{cancel} ) {
        return $self->relocate( find_cancel_loc( $self, 'add' ) );
    }

    # get and hold the form description
    my $form;
    
    eval {
        $form = $self->form();
    };
    my $full_error = $@;
    unless ( $form ) {
        eval {
            $form = $self->_form();
        };
        $full_error .= $@;
    }
    croak ( 'No form or _form method defined for AutoCRUD do_add ' .
            "[ invocant: $self errors: $full_error ]" )
            unless ( $form );

    # Check form data
    my $show_form = 0;

    # If there are no form parameters, show the form (all the fields might
    # be optional).
    $show_form = 1 if ( keys %{ $params } == 0 );

    my $results = Data::FormValidator->check(
        $params,
        form_profile( $form->{fields} ),
    );

    $show_form = 1 if ( not $self->is_post );
    $show_form = 1 if ( $results->has_invalid );
    $show_form = 1 if ( $results->has_missing );

    # do row auth check to see if they are allowed to add
    my $permissions = $self->controller_config->{ permissions };

    if ( defined $permissions ) {
        verify_permission(
            {
                site        => $self,
                permissions => $permissions,
                params      => $params,
            }
        );
    }

    if ( $show_form ) {

        # order is important, first put in the form...
        $self->stash->view->form( $form );

        # ... then add error results
        if ( $self->method eq 'POST' ) {
            $self->stash->view->form->results( $results );
        }
    }
    else {
        
        # remove submit buttons entries
        my $submit_add_another = delete $params->{submit_add_another};
        delete $params->{submit};
        
        clean_params( $params, $form->{fields} );

        # let subclass massage the params, but only if it wants to
        if ( $self->can( 'add_pre_action' ) ) {
            $self->add_pre_action( $params );
        }

        # update the database
        $orm_helper ||= find_orm_helper( $self );
        my $new_row    = $orm_helper->insert( $self, $params );

        # let the subclass do post add actions
        if ( $self->can( 'add_post_action' ) ) {
            $self->add_post_action( $new_row );
        }

        # move along, we're all done here
        my $redirect;
        if ( $submit_add_another ) {
            $redirect = find_submit_loc( $self, 'add_another' );
        }
        else {
           $redirect = find_submit_loc( $self, 'add' ) 
        }
        
        return $self->relocate( $redirect );
    }
} # END: do_add

#-------------------------------------------------
# $self->do_edit( $id )
#-------------------------------------------------
sub do_edit {
    my ( $self, $id, $pid ) = @_;
    
    $self->{__PID__} = $pid;
    $self->stash->view->template( $self->form_name( 'edit' ) );

    my %params = $self->get_param_hash();

    # Redirect if 'Cancel'
    if ( $params{cancel} ) {
        return $self->relocate( find_cancel_loc( $self, 'edit' ) );
    }

    $orm_helper ||= find_orm_helper( $self );

    # Load data from database
    my $row = $orm_helper->retrieve( $self, $id );

    $self->stash->view->title( 'Edit ' . $self->text_descr( 'edit', $row ) );

    my $show_form = 0;

    $show_form = 1 if ( not $self->is_post );
    $show_form = 1 if ( keys %params == 0 );

    # get and hold the form description
    my $form;
    
    eval {
        $form = $self->form( $row );
    };
    my $full_error = $@;
    unless ( $form ) {
        eval {
            $form = $self->_form( $row );
        };
        $full_error .= $@;
    }
    croak ( 'No form or _form method defined for AutoCRUD do_edit ' .
            "[ invocant: $self errors: $full_error ]" )
            unless ( $form );

    # Check form data
    my $results = Data::FormValidator->check(
        \%params,
        form_profile( $form->{fields} ),
    );

    $show_form = 1 if ( $results->has_invalid );
    $show_form = 1 if ( $results->has_missing );

    # do row auth check to see if they are allowed to add
    my $permissions = $self->controller_config->{ permissions };

    if ( defined $permissions ) {
        verify_permission(
            {
                site        => $self,
                permissions => $permissions,
                params      => \%params,
                row         => $row,
            }
        );
    }

    # Form has errors
    if ( $show_form ) {
        # order matters, get form data first...
        $self->stash->view->form( $form );

        # ... then overlay with results
        if ( $self->method eq 'POST' ) {
            $self->stash->view->form->results( $results );
        }
    }
    # Form looks good, make update
    else {
  
        # remove submit button param
        my $submit_add_another = delete $params{submit_add_another};
        delete $params{submit};

        clean_params( \%params, $form->{fields} );

        # allow child module to make changes
        if ( $self->can( 'edit_pre_action' ) ) {
            $self->edit_pre_action( $row, \%params );
        }

        # make the update
        $orm_helper->update( $self, $row, \%params );

        # allow child to do post update actions
        if ( $self->can( 'edit_post_action' ) ) {
            $self->edit_post_action( $row );
        }

        # all done, move along
        my $redirect;
        if ( $submit_add_another ) {
            $redirect = find_submit_loc( $self, 'add_another' )
        }
        else {
            $redirect = find_submit_loc( $self, 'edit' );
        }

        return $self->relocate( $redirect );
    }
} # END: do_edit

#-------------------------------------------------
# $self->do_delete( $id, $yes )
#-------------------------------------------------
sub do_delete {
    my ( $self, $id, $pid, $yes ) = @_;
    
    # look for a parent id and set the proper variables
    if ( $pid =~ /yes|no/ ) {
        $yes = $pid;
    }
    else {
        $self->{__PID__} = $pid;
    }
    
    $self->stash->view->template( 'delete.tt' );
    $self->stash->view->title( 'Delete' );

    # go back if user cancelled
    if ( $self->params->{cancel} ) {
        return $self->relocate( find_cancel_loc( $self, 'delete' ) );
    }

    $orm_helper ||= find_orm_helper( $self );

    # Get the doomed row
    my $row = $orm_helper->retrieve( $self, $id );

    # do row auth check to see if they are allowed to add
    my $permissions = $self->controller_config->{ permissions };

    if ( defined $permissions ) {
        verify_permission(
            {
                site        => $self,
                permissions => $permissions,
                row         => $row,
            }
        );
    }

    if ( ( defined $yes ) and ( $yes eq 'yes' ) ) {

        # allow subclasses to do things before the delete
        if ( $self->can( 'delete_pre_action' ) ) {
            $self->delete_pre_action( $row );
        }

        # dum dum da dum...
        $orm_helper->delete( $self, $row );

        # allow subclasses to do things after the delete
        if ( $self->can( 'delete_post_action' ) ) {
            $self->delete_post_action( $id );
        }

        # Move along, it's already dead
        return $self->relocate( find_submit_loc( $self, 'delete' ) );
    }
    else {
        $self->stash->view->form->message (
            'Delete ' . $self->text_descr( 'delete', $row ) . '?'
        );
    }
}

#-------------------------------------------------
# The following routines look for user supplied
# methods, but provide fallbacks if the user didn't
# give any.
#-------------------------------------------------

sub find_orm_helper {
    my ( $gantry_site ) = @_;

    if ( $gantry_site->can( 'get_orm_helper' ) ) {
        $orm_helper = $gantry_site->get_orm_helper;
    }
    else {
        $orm_helper = 'Gantry::Plugins::AutoCRUDHelper::CDBI';
    }

    my $orm_helper_file = $orm_helper;

    $orm_helper_file    =~ s{::}{/}g;
    $orm_helper_file   .= '.pm';

    require $orm_helper_file;

    return $orm_helper;
}

sub find_submit_loc {
    my ( $self, $action ) = @_;

    my $submit_loc;

    if ( $self->can( 'get_relocation' ) ) {
        $submit_loc = $self->get_relocation( $action, 'submit' );
    }
    else {
        # see if caller has submit loc sub...
        if ( $self->can( 'get_submit_loc' ) ) {
            $submit_loc = $self->get_submit_loc( $action, 'submit' );
        }
        # ...or use ours
        else {
            $submit_loc = get_submit_loc( $self, $action );
        }
    }

    return $submit_loc;
}

sub find_cancel_loc {
    my ( $self, $action ) = @_;

    my $cancel_loc;

    if ( $self->can( 'get_relocation' ) ) {
        $cancel_loc = $self->get_relocation( $action, 'cancel' );
    }
    else {
        # see if caller has cancel loc sub...
        if ( $self->can( 'get_cancel_loc' ) ) {
            $cancel_loc = $self->get_cancel_loc( $action, 'cancel' );
        }
        # ...or use ours
        else {
            $cancel_loc = get_cancel_loc( $self );
        }
    }

    return $cancel_loc;
}

1;

__END__

=head1 NAME 

Gantry::Plugins::AutoCRUD - provides CRUD support

=head1 SYNOPSIS

In a base class:

  use Gantry qw/-Engine=MP13 -TemplateEngine=Default AutoCRUD/;

Or

  use Gantry qw/-Engine=MP13 -TemplateEngine=TT AutoCRUD/;  

In your subclass:

  use base 'BaseClass';
  use Gantry::Plugins::AutoCRUD;

=head1 DESCRIPTION

This plugin exports do_add, do_edit, and do_delete for modules which
perform straight Create, Update, and Delete (commonly called CRUD,
except that R is retrieve which you still have to implement yourself in
do_main, do_view, etc.).

=head1 METHODS

This module exports the following methods into the site object's class:

=over 4

=item do_add

=item do_edit

=item do_delete

=item form_name (see below)

=back

The handler calls these when the user clicks on the proper links
or types in the proper address by hand.

In order for these to work, you must implement the required
methods from this list yourself:

=over 4

=item text_descr

Return the string which will fill in the blank in the following phrases

    Add _____
    Edit _____
    Delete ____

=item form_name

Optional.
The name of the template which generates the form's html.  There
is a default method provided here, but you can override it.  The
default always returns 'form.tt'.

The method is called through the site object and passed either
'add' or 'edit', in case you need different forms for these two
activities.

If you implement your own, don't import the one provided here (or
Perl will warn about subroutine redefinition).

=item get_orm_helper

Optional, defaults to

    sub get_orm_helper {
        return 'Gantry::Plugins::AutoCRUDHelper::CDBI';
    }

Implement this if you are not using Class::DBI as your ORM.  Return the
name of your ORM helper.  For instance, if you use DBIx::Class implement
this in your controller (or in something your controller inherits from):

    sub get_orm_helper {
        return 'Gantry::Plugins::AutoCRUDHelper::DBIxClass';
    }

If you need to implement your own helper, see L<AutoCRUDHelpers> below
and/or look at any module in Gantry::Plugins::AutoCRUDHelper::* for advice.

=item get_relocation

Optional.
Called with the name of the current action and whether the user clicked
submit or cancel like this:

    $self->get_relocation( 'add', 'cancel' );

Possible actions are add, edit, or delete.  Clicks are either cancel
or submit.

Returns the url where users should go if they submit or cancel a form.
If defined, this method is used for both submit and cancel actions.
This means that get_submit_loc and get_cancel_loc are ignored.

=item get_cancel_loc

Optional.
Called with the action the user is cancelling (add, edit, or delete).
Returns the url where users should go if they cancel form submission.
Ignored if get_relocation is defined, otherwise defaults to
$self->location.

=item get_submit_loc

Optional.
Called with the action the user is submitting (add, edit, or delete).
Returns the url where users should go after they successfully submit a form.
Ignored if get_relocation is defined, otherwise defaults to
$self->location.

Instead of implementing get_relocation or get_submit_loc, 
you could implement one or more *_post_action method which alter the location
attribute of the self object.  Then the default behavior of get_submit_loc
would guide you to that location.  In this case, you could still implement
get_cancel_loc to control where bailing out takes the user.

=item get_model_name

Return the name of your data model package.  If your base class knows
this name you might want to do something like this:

    sub get_model_name { return $_[0]->companies_model }

This way, the model name is only in one place.

=item form

[ For historical reasons, you can name this _form, but that is deprecated
and subject to change. ]

Called as a method on your self object with:

    the row object from the data model (if one is available)

This describes the entry form for do_add and do_edit.  Return a hash
with at least a fields key.
You can add to this any keys that your template is expecting.

The fields key stores an array reference.  The array elements are
hashes with at least these keys (your template may be expecting others):

=over 4

=item name

The name of the column in the database table and the field in the web form.

=item label

What the user will see as the name of the field on the web form.

=item optional

Optional.  If included and true, the field will be optional.
Otherwise, the field will be required.

=item constraint

Optional.  Any valid Data::FormValidator constraint.

=back

Remember that your template may be expecting other keys like type,
display_size, default_value, date_select and others that vary by type.

The default template in the sample apps uses options for select types
and both rows and cols for textarea types.

=item add_pre_action

  sub add_pre_action {
    my ( $self, $params ) = @_;
    ...  
  }   

Optional.
Called immediately before a new row is inserted into the database with
the hash that will be passed directly to the ORM helper's insert method.
Adjust any parameters in the hash you like (fill in dates,
remove things that can't have '' as a value, etc.).

=item add_post_action

  sub add_post_action {
    my ( $self, $new_row ) = @_;
    ...  
  }   

Optional.
Called immediately after a new row has been inserted (and committed) into
the database with the newly minted row object.  This is a useful place
to make change log entries, send email, etc.

=item edit_pre_action
  
  sub edit_pre_action {
    my ( $self, $row, $params ) = @_;
    ...  
  }   

Optional.
Like add_pre_action, but receives the row to be updated and the params hash
that is about to be set on it.

=item edit_post_action

  sub edit_post_action {
    my ( $self, $row, $params ) = @_;
    ...  
  }   

Optional.
Just like add_post_action, but for edit.

=item delete_pre_action

  sub delete_pre_action {
    my ( $self, $row, $params ) = @_;
    ...  
  }   

Optional.
Called just before a row is removed from the database with the row
object.

=item delete_post_action

  sub delete_post_action {
    my ( $self, $row, $params ) = @_;
    ...  
  }   

Optional.
Called just after a row has been removed from the database with the former
row's id.

=back

=head1 INTERNAL METHODS

These are methods used internally to figure out where to go on button presses
and who should help the ORM manage the database.

=over 4

=item find_orm_helper

=item find_cancel_loc

=item find_submit_loc

=back

=head1 AutoCRUDHelpers

If there is not a Gantry::Plugins::AutoCRUD::* module for your ORM, you
can easily implement your own.  Here's how.

Create a module (the name is completely up to you, but something in the
Gantry::Plugins::AutoCRUD:: namespace may be easier for others to find).
In it implement four methods:

=over 4

=item insert

Parameters:
    $class              - invoking class name
    $gantry_site_object - the current Gantry site object
    $params             - a hash to be inserted into a new row
Return:
    the newly created row

Puts a new row into a table of the database.  You must determine
the table name by querying $gantry_site_object.  For instance, if the app
uses CDBI models, your table name is:

    $gantry_site_object->get_model_name

For DBIx::Class models, your table name is:

    $gantry_site->get_model_name->table_name();

=item retrieve

Parameters:
    $class              - invoking class name
    $gantry_site_object - the current Gantry site object
    $id                 - the primary key of a row (single column only)
Return:
    the row whose id is $id

Given a unique one column primary key, called $id, return the corresponding
row.  See the discussion under insert for how to find your table name.

=item update

Parameters:
    $class              - invoking class name
    $gantry_site_object - the current Gantry site object
    $row                - the row object to update
    $params             - a hash to be inserted into a new row
Return:
    whatever you like (ignored)

Given an ORM object, update the underlying data.

=item delete

Parameters:
    $class              - invoking class name
    $gantry_site_object - the current Gantry site object
    $row                - the row object to update
Return:
    whatever you like (ignored)

Given an ORM object, delete the underlying row.

=back

=head1 SEE ALSO

 Gantry::Plugins::AutoCRUD::CDBI

 Gantry::Plugins::AutoCRUD::DBIxClass

 Gantry::Plugins::CRUD

 The Billing sample app

 Gantry and the other Gantry::Plugins

=head1 LIMITATIONS

These methods only work one way.  If you need more flexibility, you
will have to code your own method and nothing here will help you
(but Gantry::Plugins::CRUD might).

The idea is to do the work for the 60-80% of your modules which manage
data in one table one row at a time, leaving you to work on the ones
that are more interesting.

=head1 AUTHOR

Phil Crow <philcrow2000@yahoo.com>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2005, Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
