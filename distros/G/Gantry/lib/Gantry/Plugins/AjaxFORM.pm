package Gantry::Plugins::AjaxFORM;

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

sub process_action {
    my $self = shift;

    if ( defined $self->{process_action} ) {
        return $self->{process_action}
    }
    else {
        croak 'process_action not defined or misspelled';
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

sub user_data {
    my $self = shift;
    return $self->{user_data}
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
# $self->process( $your_self )
#-------------------------------------------------
sub process {
    my ( $self, $your_self ) = @_;

    my $form;
    my $show_form = 0;
    my $params = $your_self->get_param_hash();

    if ($params->{cancel}) { 

        # Redirect if user pressed 'Cancel'

        return $self->cancel_action->($your_self, $params, 'cancel');

    } else {

        # get and hold the form desription

        $form = $self->form->($your_self, $self->user_data);

        # Check form data

        my $results = Data::FormValidator->check(
            $params,
            form_profile($form->{fields}),
        );

        # check to see if we need to display the form

        $show_form = 1 if (keys %{$params} == 0);
        $show_form = 1 if ($results->has_invalid);
        $show_form = 1 if ($results->has_missing);

        if ($show_form) {

            # order is important, first put in the form...

            $your_self->stash->view->form($form);

            # ...then add any error results

            if ($your_self->method eq 'POST') {
 
                $your_self->stash->view->form->results($results);
 
            }
 
        } else {

            # remove submit button entry

            delete $params->{submit};

            if ($self->turn_off_clean_params) {

                if ($self->use_clean_dates) {

                    clean_dates($params, $form->{fields});

                }

            } else { clean_params($params, $form->{fields}); }

            # do something with the form data

            $self->process_action->($your_self, $params, $self->user_data);

            # move along, we're all done here

            return $self->success_action->($your_self, $params, 'submit');

        }

    }

} # END: process

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

Gantry::Plugins::AjaxFORM - helper for AJAX based Form processing

=head1 SYNOPSIS

    use Gantry::Plugins::AjaxFORM;

    sub do_main {
        my ( $self ) = @_;

        my $data = "something';
        $self->stash->view->template('form.tt');

        my $form = Gantry::Plugins::AjaxFORM->new(
            process_action  => \&user_process,
            cancel_action   => \&user_cancel,
            success_action  => \&user_success,
            form            => \&user_form,
            user_data       => $data,
            text_descr      => 'database row description',
            use_clean_dates => 1,
            turn_off_clean_params => 1,
        );

        $form->process($self);

    }

    sub user_process {
        my ( $self , $params, $data ) = @_;

        # do somthing interesting with the data

    }

    sub user_success {
        my ( $self, $params, $action ) = @_;

        $self->do_main( );

    }

    sub user_cancel {
        my ( $self, $params, $action ) = @_;

        $self->do_main( );

    }

    sub form {
        my ( $self, $data ) = @_;

        return {name   => 'form',
                row    => $data->{row},
                fields => [{name => 'name',
                            label => 'Name',
                            type => 'text',
                            is => 'varchar'}]
               };

    }
   
=head1 DESCRIPTION

This module is used for basic form processing. Instead of writing the
same form processing code over and over again. You can use this module 
instead. This module is sensitive to server side relocations so it will
work with AJAX based systems.  

Notice: most plugins export methods into your package, this one does NOT.

This module does the following basic form handling:

    redispatch to listing page if user presses cancel
    if form parameters are valid:
        callback to action method
    else:
        if method is POST:
            add form validation errors
        (re)display form

=head1 METHODS

This is an object oriented only module (it doesn't export like the other
plugins).  

=over 4

=item process

Dispatches to the form handler. Called from the do_* function.

=item new

Constructs a new AjaxFORM helper.  Pass in a list of the following callbacks
and config parameters (similar, but not the same as in CRUD):

=over 4

=item process_action (a code ref)

Called with:

    your self object
    hash of form parameters
    user specific data

Called only when the form parameters are valid. Do anything you want with
the data. You should try not to die.

=item form (a code ref)

Called with:

    your self object
    user specific data

This needs to return just like the _form method required by
C<Gantry::Plugins::AutoCRUD>.  See its docs for details.
The only difference between these is that the AutoCRUD calls
_form with your self object and the row being edited (during editing)
whereas this method ALWAYS receives both your self object and the
data you supplied.

=item cancel_action (a code ref)

Called with:

    your self object
    the form parameters
    the action

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
    the form parameter
    the action

Just like the C<cancel_action>, but triggered when the user presses the Cancel 
button.

=item user_data

Data to be passed to the form and process actions.

=item text_descr

Same as in CRUD/AjaxCRUD/AutoCRUD.

The text string used in the page titles and in the delete confirmation
message.

=item use_clean_dates (optional, defaults to false)

Same as in CRUD/AjaxCRUD/AutoCRUD.

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

Same as in CRUD/AjaxCRUD/AutoCRUD.

By default, right before an SQL insert or update, the params hash from the
form is passed through the clean_params routine which sets all non-boolean
fields which are false to undef.  This prevents SQL errors with ORMs that
can correctly translate blank strings into nulls for non-string types.

If you really don't want this routine, set turn_off_clean_params.  If you
turn it off, you can use_clean_dates, which only sets false dates to undef.

=back

=back

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

 Gantry::Plugins::CRUD

 Gantry::Plugins::AjaxCRUD

 Gantry::Plugins::AutoCRUD

 Gantry and the other Gantry::Plugins

=head1 AUTHOR

Kevin L. Esteb

=head1 COPYRIGHT and LICENSE

Copyright (c) 2006, Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
