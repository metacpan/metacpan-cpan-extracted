package Gantry::Plugins::AjaxCRUD;

use strict;
use Carp;
use Data::FormValidator;

use Gantry::Utils::CRUDHelp qw( clean_dates clean_params form_profile );

use base 'Exporter';

our @EXPORT_OK = qw( select_multiple_closure );

#-----------------------------------------------------------
# Constructor
#-----------------------------------------------------------

sub new {
    my $class     = shift;
    my $callbacks = { @_ };

    unless ( defined $callbacks->{template} ) {
        $callbacks->{template} = 'form.tt';
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

sub setup_action {
    my $self = shift;

    if ( defined $self->{setup_action} ) {
        return $self->{setup_action}
    }
    else {
        croak 'setup_action not defined or misspelled';
    }
}

sub cancel_action {
    my $self = shift;

    if ( defined $self->{cancel_action} ) {
        return $self->{cancel_action}
    }
    else {
        croak 'cancel_action not defined or misspelled';
    }
}

sub success_action {
    my $self = shift;

    if ( defined $self->{success_action} ) {
        return $self->{success_action}
    }
    else {
        croak 'success_action not defined or misspelled';
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

#-----------------------------------------------------------
# Methods users call
#-----------------------------------------------------------

#-------------------------------------------------
# $self->add( $your_self, { put => 'your', data => 'here' } )
#-------------------------------------------------
sub add {
    my ( $self, $your_self, $data ) = @_;

    eval {
        $self->setup_action->( $your_self, $data, 'add', $self->text_descr );
    };  # failure means they don't wan this

    my $params   = $your_self->get_param_hash();

    # Redirect if user pressed 'Cancel'
    if ( $params->{cancel} ) {

        return $self->cancel_action->( $your_self, $data, 'add', 'cancel' );

    }

    # get and hold the form description
    my $form = $self->form->( $your_self, $data );

    # Check form data
    my $show_form = 0;

    $show_form = 1 if ( keys %{ $params } == 0 );

    my $results = Data::FormValidator->check(
        $params,
        form_profile( $form->{fields} ),
    );

    $show_form = 1 if ( $results->has_invalid );
    $show_form = 1 if ( $results->has_missing );

    if ( $show_form ) {
        # order is important, first put in the form...
        $your_self->stash->view->form( $form );

        # ... then add error results
        if ( $your_self->method eq 'POST' ) {
            $your_self->stash->view->form->results( $results );
        }
    }
    else {
        # remove submit button entry
        delete $params->{submit};

        if ( $self->turn_off_clean_params ) {
            if ( $self->use_clean_dates ) {
                clean_dates( $params, $form->{ fields } );
            }
        }
        else {
            clean_params( $params, $form->{ fields } );
        }

        $self->add_action->( $your_self, $params, $data );

        # move along, we're all done here

        return $self->success_action->( $your_self, $data, 'submit', 'add' );
    }
} # END: add

#-------------------------------------------------
# $self->edit( $your_self, { put => 'your', data => 'here' } );
#-------------------------------------------------
sub edit {
    my ( $self, $your_self, $data ) = @_;

    eval {
        $self->setup_action->( $your_self, $data, 'edit', $self->text_descr );
    }; # failure means they don't wan this

    my %params = $your_self->get_param_hash();

    # Redirect if 'Cancel'
    if ( $params{cancel} ) {

        return $self->cancel_action->( $your_self, $data, 'cancel', 'edit' );

    }

    # get and hold the form description
    my $form = $self->form->( $your_self, $data );

    croak 'Your form callback gave me nothing' unless defined $form and $form;

    my $show_form = 0;

    $show_form = 1 if ( keys %params == 0 );

    # Check form data
    my $results = Data::FormValidator->check(
        \%params,
        form_profile( $form->{fields} ),
    );

    $show_form = 1 if ( $results->has_invalid );
    $show_form = 1 if ( $results->has_missing );

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
        
        # remove submit button param
        delete $params{submit};

        if ( $self->turn_off_clean_params ) {
            if ( $self->use_clean_dates ) {
                clean_dates( \%params, $form->{ fields } );
            }
        }
        else {
            clean_params( \%params, $form->{ fields } );
        }

        $self->edit_action->( $your_self, \%params, $data );
        
        # all done, move along

        return $self->success_action->( $your_self, $data, 'submit', 'edit' );
    }
} # END: edit

#-------------------------------------------------
# $self->delete( $your_self, $confirm, { other => 'data' } )
#-------------------------------------------------
sub delete {
    my ( $self, $your_self, $yes, $data ) = @_;

    eval {
        $self->setup_action->(
                $your_self, $data, 'delete', $self->text_descr
        );
    }; # failure means they don't wan this

    if ( $your_self->params->{cancel} ) {

        return $self->cancel_action->( $your_self, $data, 'cancel', 'delete' );

    }

    if ( ( defined $yes ) and ( $yes eq 'yes' ) ) {

        $self->delete_action->( $your_self, $data );

        # Move along, it's already dead

        return $self->success_action->( $your_self, $data, 'submit', 'delete' );
    }
    else {
        $your_self->stash->view->form->message (
            'Delete ' . $self->text_descr() . '?'
        );
    }
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

Gantry::Plugins::AjaxCRUD - helper for AJAX based CRUD work

=head1 SYNOPSIS

    use Gantry::Plugins::AjaxCRUD;

    my $user_crud = Gantry::Plugins::AjaxCRUD->new(
        add_action      => \&user_insert,
        edit_action     => \&user_update,
        delete_action   => \&user_delete,
        form            => \&user_form,
        setup_action    => \&user_setup,
        cancel_action   => \&user_cancel,
        success_action  => \&user_success,
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

    sub user_success {
        my $self = shift;

        $self->do_main( @_ );
    }

    sub user_cancel {
        my $self = shift;

        $self->do_main( @_ );
    }

    sub user_setup {
        my ( $self, $data, $action, $text_descr ) = @_;

        $self->template_wrapper('nowrapper.tt');
        $self->stash->view->template('form.tt');

        $self->stash->view->title('Add' . $text_descr)
                if ($action eq 'add');
        $self->stash->view->title('Edit' . $text_descr)
                if ($action eq 'edit');
        $self->stash->view->title('Delete' . $text_descr)
                if ($action eq 'delete');

    }

=head1 DESCRIPTION

This module is very similar to C<Gantry::Plugins::CRUD>, but it is aimed
at AJAX based systems.  Therefore, it resists all urges to refresh the
page.  This leads to three extra callbacks as shown in the summary above
and discussed below.

For those who don't know, CRUD is short for CReate, Update, and Delete.
(Some people include retrieve in this list, but users of Perl ORMs can
use those for retrievals.)  While AJAX stands for Asynchronous JavaScript 
and XML.  With varying emphasis on the XML part. 

What this all means, is that your application is now being driven from 
the browser and not from the server.  So a differant style of CRUD needs to
be used.

Notice: most plugins export methods into your package, this one does NOT.

This module differs from C<Gantry::Plugins::AutoCRUD> in the same ways
that C<Gantry::Plugins::CRUD> does.  It differs from C<Gantry::Plugins::CRUD>
in how it responds to requests.  This module exists to support AJAX forms.
As such, it does not do anything which might cause a page refresh by the
browser.

This module still does basically the same things that CRUD does:

    redispatch to listing page if user presses cancel
    if form parameters are valid:
        callback to action method
    else:
        if method is POST:
            add form validation errors
        (re)display form

And as such is an almost drop in replace for CRUD.

=head1 METHODS

This is an object oriented only module (it doesn't export like the other
plugins).  It has many of the same methods as C<Gantry::Plugins::CRUD> plus
three extras.

=over 4

=item new

Constructs a new AjaxCRUD helper.  Pass in a list of the following callbacks
and config parameters (similar, but not the same as in CRUD):

=over 4

=item add_action (a code ref)

Same as in CRUD.

Called with:

    your self object
    hash of form parameters
    the data you passed to add

Called only when the form parameters are valid. You should insert into the 
database and not die (unless the insert fails, then feel free to die).  You 
don't need to change your location, but you may.

=item edit_action (a code ref)

Same as in CRUD.

Called with:

    your self object
    hash of form parameters
    the data you passed to edit

Called only when form parameters are valid. You should update and not die 
(unless the update fails, then feel free to die).  You don't need to change 
your location, but you may.

=item delete_action (a code ref)

Same as in CRUD.

Called with:

    your self object
    the data you passed to delete

Called only when the user has confirmed that a row should be deleted.
You should delete the corresponding row and not die (unless the delete
fails, then feel free to die).  You don't need to change your location,
but you may.

=item form (a code ref)

Same as in CRUD.

Called with:

    your self object
    the data you passed to add or edit

This needs to return just like the _form method required by
C<Gantry::Plugins::AutoCRUD>.  See its docs for details.
The only difference between these is that the AutoCRUD calls
_form with your self object and the row being edited (during editing)
whereas this method ALWAYS receives both your self object and the
data you supplied.

=item setup_action (a code ref)

Called with:

    your self object
    the data you passed to add, edit or deltet
    the desired action (add, edit or delete)
    the text description

This method is called immediately by C<add_action>, C<edit_action>, and
C<delete_action> to set the forms title and template. The default action
for CRUD is to use form.tt as the template and to wrap your form with the 
site template. Using the site wrapper will cause a page reload. By exposing 
this default, you can change how this is handled.

In the above example this is done by calling $self->template_wrapper() 
with the template nowrapper.tt. What nowrapper.tt needs to do, depends on
which AJAX toolkit is being used on the browser. But it could be just as
simple as the following:

    [% content %]

At this point your form is now just a HTML fragment.

Another example, lets say that your boss has just returned from the latest 
Web Developer conference and is all aglow with the possibilites of an AJAX 
front end. He has deemed that all forms should be rendered on the client 
side and JSON will be used to send the form parameters. What to do? 
Well CPAN to the rescue. Install the TT filter for JSON, along with the 
JSON.pm module. Now create a template named json.tt like this:

    [% USE JSON %]
    [% view.data.json %]

Change the froms template from form.tt to json.tt and add the following 
statement:

    $self->content_type('application/json');

You are now sending your form as a JSON datastream.

=item cancel_action (a code ref)

Called with:

    your self object
    the data you passed to add, edit or deltet
    the action (add, edit or delete)
    the user request

Triggered by the user successfully submitting the form.
This and C<success_action> replaces the redirect callback used by
C<Gantry::Plugins::CRUD>.  They should redispatch directly to a do_* method
like this:

    sub _my_cancel_action {
        my $self = shift;

        $self->do_something( @_ );
    }

=item success_action (a code ref)

Called with:

    your self object
    the data you passed to add, edit or delete
    the action (add, edit or delete)
    the user request

Just like the C<cancel_action>, but triggered when the user presses the Cancel 
button.

=item text_descr

Same as in CRUD.

The text string used in the page titles and in the delete confirmation
message.

=item use_clean_dates (optional, defaults to false)

Same as in CRUD.

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

Same as in CRUD.

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

Call this in your do_add on a C<Gantry::Plugins::AjaxCRUD> instance:

    sub do_special_add {
        my $self = shift;
        $crud_obj->add( $self, { data => \@_ } );
    }

It will die unless you passed the following to the constructor:

        add_action
        form

=item edit

Call this in your do_edit on a C<Gantry::Plugins::AjaxCRUD> instance:

    sub do_special_edit {
        my $self = shift;
        my $id   = shift;
        my $row  = Data::Model->retrieve( $id );
        $crud_obj->edit( $self, { id => $id, row => $row } );
    }

It will die unless you passed the following to the constructor:

        edit_action
        form

=item delete

Call this in your do_delete on a C<Gantry::Plugins::AjaxCRUD> instance:

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

 Gantry::Plugins::CRUD (for the same approach with page refreshes)

 Gantry::Plugins::AutoCRUD (for simpler situations)

 Gantry and the other Gantry::Plugins

=head1 AUTHOR

Kevin Esteb

=head1 COPYRIGHT and LICENSE

Copyright (c) 2006, Kevin Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
