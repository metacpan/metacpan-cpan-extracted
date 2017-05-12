package Gantry::Plugins::CRUD;

use strict;
use Carp;
use Data::FormValidator;

use Gantry::Utils::CRUDHelp qw(
    clean_dates clean_params form_profile write_file verify_permission
);

use base 'Exporter';

our @EXPORT_OK = qw( select_multiple_closure write_file verify_permission );

#-----------------------------------------------------------
# Constructor
#-----------------------------------------------------------

sub new {
    my $class     = shift;
    my $callbacks = { @_ };

    unless ( defined $callbacks->{template} ) {
        $callbacks->{template} = 'form.tt';
    }
    else {
        $callbacks->{ignore_default_template} = 1;
    }

    return bless $callbacks, $class;
}

#-----------------------------------------------------------
# Accessors, so we don't misspell hash keys
#-----------------------------------------------------------

sub add_action {
    my $self = shift;

    if ( defined $self->{add_action} ) {
        return $self->{add_action};
    }
    else {
        croak 'add_action not defined or misspelled';
    }
}

sub edit_action {
    my $self = shift;

    if ( defined $self->{edit_action} ) {
        return $self->{edit_action}
    }
    else {
        croak 'edit_action not defined or misspelled';
    }
}

sub delete_action {
    my $self = shift;

    if ( defined $self->{delete_action} ) {
        return $self->{delete_action}
    }
    else {
        croak 'delete_action not defined or misspelled';
    }
}

sub form {
    my $self = shift;

    if ( defined $self->{form} ) {
        return $self->{form}
    }
    else {
        croak 'form not defined or misspelled';
    }
}

sub redirect {
    my $self = shift;
    return $self->{redirect}
}

sub template {
    my $self = shift;
    return $self->{template}
}

sub text_descr {
    my $self = shift;
    return $self->{text_descr}
}

sub use_clean_dates {
    my $self = shift;
    return $self->{use_clean_dates};
}

sub turn_off_clean_params {
    my $self = shift;
    return $self->{turn_off_clean_params};
}

sub validator {
    my $self = shift;
    return $self->{validator}
}

#-----------------------------------------------------------
# Methods users call
#-----------------------------------------------------------

#-------------------------------------------------
# $self->add( $your_self, { put => 'your', data => 'here' } )
#-------------------------------------------------
sub add {
    my ( $self, $your_self, $data ) = @_;

    # Use the specified default template in the config if no
    # template was specified to the crud module and there is a
    # default defined.
    if (
        ( ! $self->{ignore_default_template} ) and
        ( $your_self->fish_config( 'default_form_template' ) )
    ) {
        $your_self->stash->view->template(
            $your_self->fish_config( 'default_form_template' )
        );
    }
    else {
        $your_self->stash->view->template( $self->template );
    }

    $your_self->stash->view->title( 'Add ' . $self->text_descr )
            unless $your_self->stash->view->title;

    my $params   = $your_self->get_param_hash();

    # Redirect if user pressed 'Cancel'
    if ( $params->{cancel} ) {
        my $redirect = $self->_find_redirect(
            {
                gantry_site => $your_self,
                data        => $data,
                user_req    => 'add',
                action      => 'cancel',
            }
        );

        return $your_self->relocate( $redirect );
    }

    # get and hold the form description
    my $form = $self->form->( $your_self, $data );

    # Check form data
    my $show_form = 0;
    my $results;

    if ( $your_self->is_post ) {
        $show_form = 1 if ( keys %{ $params } == 0 );

        if ( $self->validator ) {
            $results = $self->validator->(
                {
                    self      => $your_self,
                    params    => $params,
                    form      => $form,
                    profile   => form_profile( $form->{fields} ),
                    action    => 'add',
                }
            );
        }
        else {
            $results = Data::FormValidator->check(
                $params,
                form_profile( $form->{fields} ),
            );
        }

        $show_form = 1 if ( $results->has_invalid );
        $show_form = 1 if ( $results->has_missing );
        $show_form = 1 if ( $form->{ error_text } );
    }
    else {
        $show_form = 1;
    }

    if ( $show_form ) {
        # order is important, first put in the form...
        $your_self->stash->view->form( $form );

        # ... then add error results
        if ( $your_self->method eq 'POST' ) {
            $your_self->stash->view->form->results( $results );
        }
    }
    else {
        my $redirect;
        my $action =    $params->{submit_add_another}
                        ? 'submit_add_another'
                        : 'submit';
        
        # remove submit button entry
        delete $params->{submit};
        delete $params->{submit_add_another};

        if ( $self->turn_off_clean_params ) {
            if ( $self->use_clean_dates ) {
                clean_dates( $params, $form->{ fields } );
            }
        }
        else {
            clean_params( $params, $form->{ fields } );
        }

        $self->add_action->( $your_self, $params, $data );
        
        # Find redirect.
        $redirect = $self->_find_redirect(
            {
                gantry_site => $your_self,
                data        => $data,
                action      => $action,
                user_req    => 'add'
            }
        );

        return $your_self->relocate( $redirect );
    }
} # END: add

#-------------------------------------------------
# $self->edit( $your_self, { put => 'your', data => 'here' } );
#-------------------------------------------------
sub edit {
    my ( $self, $your_self, $data ) = @_;

    # Use the specified default template in the config if no
    # template was specified to the crud module and there is a
    # default defined.
    if (
        ( ! $self->{ignore_default_template} ) and
        ( $your_self->fish_config( 'default_form_template' ) )
    ) {
        $your_self->stash->view->template(
            $your_self->fish_config( 'default_form_template' )
        );
    }
    else {
        $your_self->stash->view->template( $self->template );
    }

    $your_self->stash->view->title( 'Edit ' . $self->text_descr() )
            unless $your_self->stash->view->title;

    my %params = $your_self->get_param_hash();

    # Redirect if 'Cancel'
    if ( $params{cancel} ) {
        my $redirect = $self->_find_redirect(
            {
                gantry_site => $your_self,
                data        => $data,
                action      => 'cancel',
                user_req    => 'edit',
            }
        );
        return $your_self->relocate( $redirect );
    }

    # get and hold the form description
    my $form = $self->form->( $your_self, $data );

    croak 'Your form callback gave me nothing' unless defined $form and $form;

    my $show_form = 0;
    my $results;

    if ( $your_self->is_post ) {
        $show_form = 1 if ( keys %params == 0 );

        # Check form data
        if ( $self->validator ) {
            $results = $self->validator->(
                {
                    self      => $your_self,
                    params    => \%params,
                    form      => $form,
                    profile   => form_profile( $form->{ fields } ),
                    action    => 'edit',
                }
            );
        }
        else {
            $results = Data::FormValidator->check(
                \%params,
                form_profile( $form->{ fields } ),
            );
        }

        $show_form = 1 if ( $results->has_invalid );
        $show_form = 1 if ( $results->has_missing );
        $show_form = 1 if ( $form->{ error_text } );
    }
    else {
        $show_form = 1;
    }

    # Form has errors
    if ( $show_form ) {
        # order matters, get form data first...
        $your_self->stash->view->form( $form );

        # ... then overlay with results
        if ( $your_self->method eq 'POST' ) {
            $your_self->stash->view->form->results( $results );
        }
    
    }
    # Form looks good, make update
    else {
        my $redirect;
        my $action =    $params{submit_add_another}
                        ? 'submit_add_another'
                        : 'submit';
        
        # remove submit button entry
        delete $params{submit};
        delete $params{submit_add_another};
               
        if ( $self->turn_off_clean_params ) {
            if ( $self->use_clean_dates ) {
                clean_dates( \%params, $form->{ fields } );
            }
        }
        else {
            clean_params( \%params, $form->{ fields } );
        }

        $self->edit_action->( $your_self, \%params, $data );
        
        # Find redirect.
        $redirect = $self->_find_redirect(
            {
                gantry_site => $your_self,
                data        => $data,
                action      => $action,
                user_req    => 'edit'
            }
        );
        
        return $your_self->relocate( $redirect );
    }
} # END: edit

#-------------------------------------------------
# $self->delete( $your_self, $confirm, { other => 'data' } )
#-------------------------------------------------
sub delete {
    my ( $self, $your_self, $yes, $data ) = @_;

    $your_self->stash->view->template( 'delete.tt' )
        unless $your_self->stash->view->template();
    $your_self->stash->view->title( 'Delete' )
            unless $your_self->stash->view->title;

    if ( $your_self->params->{cancel} ) {
        my $redirect = $self->_find_redirect(
            {
                gantry_site => $your_self,
                data        => $data,
                action      => 'cancel',
                user_req    => 'delete'
            }
        );
        return $your_self->relocate( $redirect );
    }

    if ( ( defined $yes ) and ( $yes eq 'yes' ) ) {

        $self->delete_action->( $your_self, $data );

        # Move along, it's already dead
        my $redirect = $self->_find_redirect(
            {
                gantry_site => $your_self,
                data        => $data,
                action      => 'submit',
                user_req    => 'delete'
            }
        );
        return $your_self->relocate( $redirect );
    }
    else {
        $your_self->stash->view->form->message (
            'Delete ' . $self->text_descr() . '?'
        );
    }
}

#-----------------------------------------------------------
# Helpers
#-----------------------------------------------------------

sub _find_redirect {
    my ( $self, $args ) = @_;
    my $your_self = $args->{ gantry_site };
    my $data      = $args->{ data };
    my $action    = $args->{ action };
    my $user_req  = $args->{ user_req };

    my $retval;

    my $redirect_sub = $self->redirect;

    if ( $redirect_sub ) {
        $retval = $redirect_sub->( $your_self, $data, $action, $user_req );
    }
    else {
        $retval = $your_self->location();
    }

    return $retval;
}

#-----------------------------------------------------------
# Helper functions offered for export
#-----------------------------------------------------------

sub select_multiple_closure {
    my $field_name  = shift;
    my $db_selected = shift;

    return sub {
        my $id     = shift;
        my $params = shift;

        my @real_keys = grep ! /^\./, keys %{ $params };

        if ( @real_keys ) {
            return unless $params->{ $field_name };
            my @param_ids = split /\0/, $params->{ $field_name };
            foreach my $param_id ( @param_ids ) {
                return 1 if ( $param_id == $id );
            }
        }
        else {
            return $db_selected->{ $id };
        }
    };
}

1;

__END__

=head1 NAME 

Gantry::Plugins::CRUD - helper for somewhat interesting CRUD work

=head1 SYNOPSIS

    use Gantry::Plugins::CRUD;

    my $user_crud = Gantry::Plugins::CRUD->new(
        add_action      => \&user_insert,
        edit_action     => \&user_update,
        delete_action   => \&user_delete,
        form            => \&user_form,
        validator       => \&user_form_validator,
        redirect        => \&redirect_function,
        template        => 'your.tt',  # defaults to form.tt
        text_descr      => 'database row description',
        use_clean_dates => 1,
        turn_off_clean_params => 1,
    );

    sub do_add {
        my ( $self ) = @_;
        $user_crud->add( $self, { data => \@_ } );
    }

    sub user_insert {
        my ( $self, $form_params, $data ) = @_;
        # $data is the value of data from do_add

        my $row = My::Model->create( $params );
        $row->dbi_commit();
    }

    # Similarly for do_delete

    sub do_delete {
        my ( $self, $doomed_id, $confirm ) = @_;
        $user_crud->delete( $self, $confirm, { id => $doomed_id } );
    }

    sub user_delete {
        my ( $self, $data ) = @_;

        my $doomed = My::Model->retrieve( $data->{id} );

        $doomed->delete;
        My::Model->dbi_commit;
    }

=head1 DESCRIPTION

This plugin helps you perform Create, Update, and Delete (commonly called
CRUD, except that R is retrieve which you still have to implement separately).

Warning: most plugins export methods into your package, this one does NOT.

Normally, you can use C<Gantry::Plugins::AutoCRUD> when you are controlling
a single table.  But, since its do_add, do_edit, and do_delete are genuine
template methods*, sometimes it is not enough.  For instance, if you need to
allow a regular user and an admin edit for the same database table, you need
two methods for each action (two for do_add, two for do_edit, and two
for do_delete).  This module can help.

* A template method has a series of steps.  At each step, it calls a method
via a hard coded name.

This module still does basically the same things that AutoCRUD does:

    redirect to listing page if user presses cancel
    if form parameters are valid:
        callback to action method
    else:
        if method is POST:
            add form validation errors
        (re)display form

=head1 CONFIGURATION

The following can be specified in your config to control the behavior
of the plugin.

=over 4

=item default_form_template

Specify form template to use by default. If nothing is specified
it defaults to form.tt. If a template is specified during 
object creation it will override the value specified here.

=back

=head1 METHODS

This is an object oriented only module (it doesn't export like the other
plugins).

=over 4

=item new

Constructs a new CRUD helper.  Pass in a list of the following callbacks
and config parameters:

=over 4

=item add_action (a code ref)

Called with:

    your self object
    hash of form parameters
    the data you passed to add

Called only when the form parameters are valid.
You should insert into the database and not die (unless the insert fails,
then feel free to die).  You don't need to change your location, but you may.

=item edit_action (a code ref)

Called with:

    your self object
    hash of form parameters
    the data you passed to edit

Called only when form parameters are valid.
You should update and not die (unless the update fails, then feel free
to die).  You don't need to change your location, but you may.

=item delete_action (a code ref)

Called with:

    your self object
    the data you passed to delete

Called only when the user has confirmed that a row should be deleted.
You should delete the corresponding row and not die (unless the delete
fails, then feel free to die).  You don't need to change your location,
but you may.

=item form (a code ref)

Called with:

    your self object
    the data you passed to add or edit

This needs to return just like the _form method required by
C<Gantry::Plugins::AutoCRUD>.  See its docs for details.
The only difference between these is that the AutoCRUD calls
_form with your self object and the row being edited (during editing)
whereas this method ALWAYS receives both your self object and the
data you supplied.

=item validator (a code ref)

Optional.

By default, form parameters are validated with Data::FormValidator.  Supply
a validator callback to do your own thing.  Your validator will be called
with a hash reference, which will include the following named arguments:

    self   : your $self,
    params : $params, a hash ref of form paramters
    form   : $form,
    profile: the form_profile of $form
    action : 'add' or 'edit'

Where C<$form> is whatever your form callback returned, usually that is a
hash reference for use by form.tt.  It describes the form and its fields.
See the form parameter to new directly above.

The last parameter is the name of the method from this module making the
callback.  It can only be 'add' or 'edit.'

The C<form_profile> (provided by Gantry::Utils::CRUDHelp) is a hash
reference with three keys:

    required
    optional
    constraint_methods

C<required> and C<optional> are array references of field names.
C<constraint_methods> is a hash reference keyed by field name, storing
a constraint.  See Data::FormValidator for details on constraints.

What you do with those parameters is entirely up to you.

You must return:

    an object which responds to the Data::FormValidator::Results API

You might find L<Gantry::Utils::FormErrors> helpful, since it implements
the required API for you.

But, if you want to implement your own, the objects must respond to:

    has_missing
    has_invalid
    missing
    invalid

The methods prefixes with C<has_> return booleans.  The return values for
the other two depend on how they are called.  If called with no arguments,
they return the number of missing or invalid fields.  If called with an
argument, the argument is the name of a field.  The method returns true
if field is missing or invalid, false otherwise.

Note that you may also set C<error_text> in the form hash.  This will
also count as validation failure.  Use this to get total control of how
your errors are reported.

=item redirect (optional, defaults to $your_self->location() )

NOTE WELL: It is a bad idea to name your redirect callback 'redirect'.
That name is used internally in Gantry.pm.

Where you want to go whenever an action is complete.  If you need control
on a per action basis end your action callback with:

    $your_self->location( 'http://location.of/your/choice' );

Your redirect is called with:

    your self object
    the data you passed to the add, edit, or delete
    the action: 'submit', 'submit_add_another' or 'cancel'
    the user request: 'add', 'edit' or 'delete'

=item template (optional, defaults to form.tt)

The name of your form template.

=item text_descr

The text string used in the page titles and in the delete confirmation
message.

=item use_clean_dates (optional, defaults to false)

This is ignored unless you turn_off_clean_params, since it is redundant
when clean_params is in use.

Make this true if you want your dates cleaned immediately before your
add and edit callbacks are invoked.

Cleaning sets any false fields marked as dates in the form fields list
to undef.  This allows your ORM to correctly insert them as
nulls instead of trying to insert them as blank strings (which is fatal,
at least in PostgreSQL).

For this to work your form fields must have this key: C<<is => 'date'>>.

=item turn_off_clean_params (optional, defaults to false)

By default, right before an SQL insert or update, the params hash from the
form is passed through the clean_params routine which sets all non-boolean
fields which are false to undef.  This prevents SQL errors with ORMs that
can correctly translate blank strings into nulls for non-string types.

If you really don't want this routine, set turn_off_clean_params.  If you
turn it off, you can use_clean_dates, which only sets false dates to undef.

=back

Note that in all cases the submit key is removed from the params hash
by this module before any callback is made.

=item add

Call this in your do_add on a C<Gantry::Plugins::CRUD> instance:

    sub do_special_add {
        my $self = shift;
        $crud_obj->add( $self, { data => \@_ } );
    }

It will die unless you passed the following to the constructor:

        add_action
        form

You may also pass C<redirect> which must return a location suitable for passing
to $your_self->relocate.

=item edit

Call this in your do_edit on a C<Gantry::Plugins::CRUD> instance:

    sub do_special_edit {
        my $self = shift;
        my $id   = shift;
        my $row  = Data::Model->retrieve( $id );
        $crud_obj->edit( $self, { id => $id, row => $row } );
    }

It will die unless you passed the following to the constructor:

        edit_action
        form

You may also pass C<redirect> which must return a location suitable for passing
to $your_self->relocate.

=item delete

Call this in your do_delete on a C<Gantry::Plugins::CRUD> instance:

    sub do_special_delete {
        my $self    = shift;
        my $id      = shift;
        my $confirm = shift;
        $crud_obj->delete( $self, $confirm, { id => $id } );
    }

The C<$confirm> argument is yes if the delete should go ahead and anything
else otherwise.  This allows our standard practice of having delete
urls like this:

    http://somesite.example.com/item/delete/4

which leads to the confirmation form whose submit action is:

    http://somesite.example.com/item/delete/4/yes

which is taken as confirmation.

It will die unless you passed the following to the constructor:

        delete_action

You may also pass C<redirect> which must return a location suitable for passing
to $your_self->relocate.

=back

You can pick and choose which CRUD help you want from this module.  It is
designed to give you maximum flexibility, while doing the most repetative
things in a reasonable way.  It is perfectly good use of this module to
have only one method which calls edit.  On the other hand, you might have
two methods that call edit on two different instances, two methods
that call add on those same instances and a method that calls delete on
one of the instances.  Mix and match.

=head1 HELPER FUNCTIONS

=over 4

=item select_multiple_closure

If you have a form field of type select_multiple, one of the form.tt keys
is selected.  It wants a sub ref so it can reselect items when the form
fails to validate.  This function will generate the proper sub ref (aka
closure).

Parameters:
    form field name
    hash reference of default selections (usually the ones in the database)

Returns: a closure suitable for immediate use as the selected hash key value
for a form field of type select_multiple.

=back

=head1 SEE ALSO

 Gantry::Plugins::AutoCRUD (for simpler situations)

 Gantry and the other Gantry::Plugins

=head1 LIMITATIONS

Currently only one redirection can be defined.  You can get more control
by ending your action callback like this:

    return $self->relocate( 'http://location.of/your/choice' );

=head1 AUTHOR

Phil Crow <philcrow2000@yahoo.com>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2005, Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
