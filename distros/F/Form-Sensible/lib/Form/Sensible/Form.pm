package Form::Sensible::Form;

use Moose; 
use namespace::autoclean;
use Form::Sensible::DelegateConnection;
use Form::Sensible::Validator;
use Carp qw/croak/;
use Data::Dumper;
use Class::MOP;    ## I don't believe this is required

## a form is a collection of fields. Different form types will work differently.

## the Concept basically follows a flow:
##
## 1) Form is created.
## 2) Fields are created and added to the Form
## 3) Form is rendered
## 4) user takes action - filling in fields, etc.
## 5) user indicates an action (form is complete (submit) or cancelled)
## 6) If cancelled, form triggers cancel action.

## 7) if submitted - form calls validators in turn on each of it's fields (and finally a
##               'last step' validation that runs against all fields, if provided.)

## 7a) if validation fails - failed_validation action is called - most often re-render of the form with messages.

## 7b) if validation succeeds - complete_action is called.

has 'name' => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    default     => 'form',
);

has '_fields' => (
    is          => 'rw',
    isa         => 'HashRef[Form::Sensible::Field]',
    required    => 1,
    default     => sub { return {}; },
    lazy        => 1,
);

has 'field_order' => (
    is          => 'rw',
    isa         => 'ArrayRef[Str]',
    required    => 1,
    default     => sub { return []; },
    lazy        => 1,
);

has 'renderer' => (
    is          => 'rw',
    isa         => 'Form::Sensible::Renderer',
);

has 'render_hints' => (
    is          => 'rw',
    isa         => 'HashRef',
    required    => 1,
    default     => sub { return {}; },
    lazy        => 1,
);

## validation hints - FULL form validation
## runs _after_ field validation.
has 'validation' => (
    is          => 'rw',
    isa         => 'HashRef',
    required    => 1,
    default     => sub { return {}; },
    lazy        => 1,
);

## DEPRECATION WARNING.  validator_args is deprecated, as is validator_result and validator
## all of these are replaced via the validation_delegate. DUE FOR REMOVAL 2010-08-30
has 'validator_args' => (
    is          => 'rw',
    isa         => 'ArrayRef',
    required    => 1,
    default     => sub { return []; },
    lazy        => 1,
);

has 'validator_result' => (
    is          => 'rw',
    isa         => 'Form::Sensible::Validator::Result',
    required    => 0,
    clearer     => '_clear_validator_result',
);

has 'validator' => (
    is          => 'rw',
    isa         => 'Form::Sensible::Validator',
    lazy        => 1,
    builder     => '_create_validator'
);

## calling format:  ($form, $fieldname) returns true/false whether the field should be processed.
has 'should_process_field_delegate' => (
    is          => 'rw',
    isa         => 'Form::Sensible::DelegateConnection',
    required    => 1,
    default     => sub {
                            return FSConnector(sub { return 1; });
                   },
    lazy        => 1,
    coerce      => 1,
    # additional options
);

has 'validation_delegate' => (
    is          => 'rw',
    isa         => 'Form::Sensible::DelegateConnection',
    required    => 1,
    default     => sub {
                            my $self = shift;
                            my $validator;
                            if (defined($self->validation->{'validator_class'})) {
                                $validator = $self->_create_validator();
                            } else {
                                $validator = Form::Sensible::Validator->new();
                            }

                            return FSConnector( sub { 
                                                my $caller = shift;
                                                
                                                return $validator->validate($caller);
                                   });
                   },
    lazy        => 1,
    coerce      => 1,
    # additional options
);

## adds a field to the form.  If position is specified, places it at the
## given position, otherwise places it at the end of the form.  
## returns the new fields position in the form.
## Note that fieldname does not necessarily need to be the same as $field->name
## though you may get odd behavior if you accidentally insert multiple fields with
## the same $field->name

sub add_field {
    my ($self, $field, $fieldname, $position) = @_;
    
    if (!$fieldname) {
        if (ref($field) =~ /^Form::Sensible::Field/) {
            $fieldname = $field->name;
        } elsif (ref($field) eq 'HASH') {
            $fieldname = $field->{'name'};
        } 
    }
    
    if (defined($self->_fields->{$fieldname})) {
        $self->remove_field($fieldname);
    }
    
    ## this will cause an unblessed hash passed to add_field to auto-create
    ## the appropriate field type.
    if (ref($field) eq 'HASH') {
        my $newfield = $field;
        $field = Form::Sensible::Field->create_from_flattened($newfield);
    }
    
    if ($field->isa('Form::Sensible::Field::SubForm') && $field->form == $self) {
        croak "Unable to add sub-form. sub-form is the same as me. Infinite recursion will occur, dying now instead of later.";
    }
    
    $self->_fields->{$fieldname} = $field;
    
    ## if position is larger than the current form size
    ## reset position so the field is added to the end of the
    ## list.
    
    if ($position && $position > $#{$self->field_order}) {
        $position = undef;
    }
    if (!$position) {
        push @{$self->field_order}, $fieldname;
        $position = $#{$self->field_order};
    } else {
        splice @{$self->field_order}, $position, 0, $fieldname;
    }
    return $position;
}

## removes a field from the form by name.  Returns the removed field 
## or undef if the field was not present in the form.
sub remove_field {
    my ($self, $fieldname) = @_;
    
    my $field = $self->field($fieldname);
    delete($self->_fields->{$fieldname});
    foreach my $i (0..$#{$self->field_order}) {
        if ($self->field_order->[$i] eq $fieldname ) {
            splice @{$self->field_order}, $i, 1;
            last;
        }
    }
    return $field;
}

## moves a field from one position to another.  This may not work the way 
## I think because the field is removed and then replaced, depending on it's 
## original position, it may not appear where the user expects.  Need to work 
## on that.
sub reorder_field {
    my ($self, $fieldname, $newposition) = @_;
    
    my $field = $self->remove_field($fieldname);
    return $self->add_field($field, $fieldname, $newposition);
}

## returns the field requested or undef if a field by that name is not found
sub field {
    my ($self, $fieldname) = @_;
    
    return $self->_fields->{$fieldname};
}

## returns a hash containing all the fields in the current form 
## fields is DEPRECATED.  DO NOT USE IT.
sub fields {
    my $self = shift;
    
    return { %{$self->_fields} };
}

## Returns an array of all the fields in the form in field_order 
## obeying should_process_field_delegate.
sub get_fields {
    my $self = shift;
    
    my @active_fields;
    foreach my $fieldname (@{$self->field_order}) {
        if ($self->should_process_field_delegate->($self, $fieldname)) {
            push @active_fields, $self->field($fieldname);
        }
    }
    return @active_fields;   
}


## returns the fieldnames in the current form in their presentation order
sub fieldnames {
    my $self = shift;
    
    return @{$self->field_order};
}

sub _create_validator {
    my ($self) = @_;
    
    my $validator;

    ## first see if we have had our validator class overridden
    my $classname;
    if (defined($self->validation->{'validator_class'})) {
        ## we have, so get the class name and instantiate an object of that class
        $classname = $self->validation->{'validator_class'};
    } else {
        ## otherwise, we create a Form::Sensible::Validator object.
        $classname = '+Form::Sensible::Validator';
    }
    if ($classname =~ /^\+(.*)$/) {
        $classname = $1;
    } else {
        $classname = 'Form::Sensible::Validator::' . $classname;
    }
    Class::MOP::load_class($classname);
    $validator = $classname->new(@{$self->validator_args});
    
    return $validator;
}


sub validate {
    my ($self) = @_;

    my $result = $self->validation_delegate->($self);
    
    ## for now - validation_results() are set automatically if validate is run from the form.
    ## this is deprecated and will be removed.  DUE FOR REMOVAL 2010-07-30
    $self->validator_result($result);
    
    return $result;
}

sub render {
    my ($self) = shift;
    
    if ($self->renderer) {
        return $self->renderer->render($self, @_);
    } else {
        croak __PACKAGE__ . '->render() called but no renderer defined for this form (' . $self->name . ')';
    }
}

sub set_values {
    my ($self, $values) = @_;
    
    foreach my $fieldname ( $self->fieldnames ) {
        if (exists($values->{$fieldname})) {
            $self->field($fieldname)->value($values->{$fieldname});
        }
    }
}

sub get_all_values {
    my $self = shift;
    
    my $value_hash = {};
    foreach my $fieldname ( $self->fieldnames ) {
        $value_hash->{$fieldname} = $self->field($fieldname)->value();
    }
    return $value_hash;
}

sub clear_state {
    my $self = shift;
    
    foreach my $fieldname ( $self->fieldnames ) {
        $self->field($fieldname)->clear_state();
    }
    
    ## DUE FOR REMOVAL 2010-07-30
    $self->_clear_validator_result();
}

sub delegate_all_field_values {
    my $self = shift;
    my $value_delegate = shift;

    foreach my $field ($self->get_fields()) {
        $field->value_delegate( $value_delegate );
    }
}

sub delegate_all_field_values_to_hashref {
    my $self = shift;
    my $hashref = shift;
    
    # We only need one value delegate object because it gets the name from the field's name.
    # So we save a bit of memory by not creating a separate delegate object for each field
    my $value_delegate = FSConnector( sub { 
                              my $caller = shift;
                              my $fieldname = $caller->name();

                              if ($#_ > -1) {   
                                  if (ref($_[0]) eq 'ARRAY' && !($caller->accepts_multiple)) {
                                      $hashref->{$fieldname} = $_[0]->[0];
                                  } else {
                                      $hashref->{$fieldname} = $_[0];
                                  }
                              }
                              return $hashref->{$fieldname}; 
                          });
    
    $self->delegate_all_field_values($value_delegate);
}



sub flatten {
    my ($self, $template_only) = @_;
    
    my $form_hash = {
    	                    'name' => $self->name,
    	                    'render_hints' => $self->render_hints,
    	                    'validation' => $self->validation,
    	                    'field_order' => $self->field_order,
    	            };

    $form_hash->{'fields'} = {};

    foreach my $fieldname ( $self->fieldnames ) {
        $form_hash->{'fields'}{$fieldname} = $self->field($fieldname)->flatten($template_only);
    }
    return $form_hash; 
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Form::Sensible::Form - Form::Sensible's Form class

=head1 SYNOPSIS

    use Form::Sensible::Form;
    
    my $form = Form::Sensible::Form->new( name => 'login_form' );

    $form->add_field({ ... });
    
    # later
    
    $form->set_values( $cgi->Vars );
    
    my $validation_result = $form->validate();

    if ( !$validation_result->is_valid() ) {
        # re-render form with errors.
    }

=head1 DESCRIPTION

Form::Sensible::Form is the main class in the Form::Sensible module. It
represents a complete set of fields to be presented to the user in more or
less a single transaction. Unlike an HTML form which has certain presentation
and behaviors associated with it, a Form::Sensible::Form is simply a container
of fields. Forms exist primarily as a handle to allow easy operation upon a
group of fields simultaneously. I< Note that while Forms may only contain
Fields, it is possible to include forms into other forms by using subforms
(L<Form::Sensible::Field::SubForm>) >

Note also that Renderer and Validator objects are built to operate on 
potentially multiple Forms during their lifecycle. The C<render()> and 
C<validate()> are primarily convenience routines.

=head1 ATTRIBUTES

=over 8

=item C<name>

The name of this form. Used mainly to identify a particular form within renderers.

=item C<render_hints>

A hashref containing global form-level rendering hints. Render hints are used
to give renderers clues as to how the form should be rendered.

=item C<validation>

Hashref containing arguments to be used during complete form validation (which
runs after each individual field's validation has run.) Currently only
supports a single key, C<code> which provides a coderef to run to validate the
form. When run, the form, and a prepared C<Form::Sensible::Validator::Result>
object are passed to the subroutine call.

=back

I<The following attributes are set during normal operating of the Form object, and do not
need to be set manually.  They may be overridden, but if you don't know exactly what 
you are doing, you are likely to run into very hard to debug problems.>

=over 8

=item C<field_order>

An array reference containing the fieldnames for the fields in the form in the
order that they should be presented. While this may be set manually, it's
generally preferred to use the C<add_field> and C<reorder_field> to set field
order.

=back

=head1 DELEGATES

Delegates are objects that help determine certain behaviors.  These delegates
allow control over form behavior without subclassing.  See L<Form::Sensible::DelegateConnection> for
more information.

=over 8

=item should_process_field_delegate->($self, $fieldname)  

Returns true/false on whether the field should be included in general form processing.  Default
behavior is to always return true, hence indicating all fields present should be processed. 
This is used when C<<$form->get_fields()>> is called.  It essentially gives you a 
mechanism for disabling rendering and validation of particular fields on demand.  

=item validation_delegate->($self)  

Runs validation on the form.  Returns a L<Form::Sensible::Validator::Result> object representing the results
of the validation process.  If not provided and C<<$form->validate()>> is run, a L<Form::Sensible::Validator> 
object will be created.

=back

=head1 METHODS

=over 8

=item C<new( %options )>

Creates a new Form object with the provided options.  All the attributes above may be passed.

=item C<delegate_all_field_values( $delegate_connection )>

Loops over all fields in the form and delegates their values to the provided C<$delegate_connection>

=item C<delegate_all_field_values_to_hashref( $hashref )>

Loops over all fields in the form and delegates their values to the given hashref using the
field's name as the key. Note that this will capture the hashref provided within a closure. If your 
form / field objects are likely to outlive your hashref, such as in the case of a persistent form object
used within a Catalyst Request it is recommended that you instead delegate the values to an 
intermediate object that can obtain the values for the current request


=item C<add_field( $field, $fieldname, $position )>

Adds the provided field to the form with the given fieldname and position. If
C<$fieldname> is not provided the field will be asked for it's name via it's
C<< $field->name >> method call. If C<$position> is not provided the field
will be appended to the form. The C<$field> argument may be an object of a
subclass of L<Form::Sensible::Field> OR a simple hashref which will be passed
to L<Form::Sensible::Field>s C< create_from_flattened() > method in order to
create a field.

=item C<remove_field( $fieldname )>

Removes the field identified by C<$fieldname> from the form.  Using this will
update the order of all fields that follow this one as appropriate. 
Returns the field object that was removed.

=item C<reorder_field( $fieldname, $new_position )>

Moves the field identified by C<$fieldname> to C<$new_position> in the form. All
other fields positions are adjusted accordingly.

=item C<field( $fieldname )>

Returns the field object identified by $fieldname. 

=item C<get_fields()>

Returns an array containing all the fields in the current form in field order.  
Affected by C<should_process_field_delegate>. If C<should_process_field_delegate> returns
false for a given field, it will be excluded from the results of C<get_fields()>.  
B<NOTE:> When performing any action on all fields in a form, you should use this method 
to ensure that any fields that should not be processed are excluded. 

=item C<fieldnames()>

Returns an array of all the fieldnames in the current form.  Order is not guaranteed, if you 
need the field names in presentation-order, use C<field_order()> instead.

=item C<set_values( $values )>

Uses the hashref C<$values> to set the value for each field in the form. This
is a shortcut routine only and is functionally equivalent to calling 
C<< $field->value( $values->{$fieldname} ) >> for each value in the form.

=item C<get_all_values()>

Retrieves the current values for each field in the form and returns them in a hashref.

=item C<clear_state()>

Clears all state related data from the form.  Returns form to the state it was in
prior to having any values set or validation run.

=item C< validate() >

Validates the form based on the validation rules provided for each field during form 
creation.  Delegates it's work via the C<validation_delegate> set for this form.  If no
C<validation_delegate> object is set, a new C<Form::Sensible::Validator> will be created and
attached as appropriate.

=item C<flatten( $template_only )>

Returns a hashref containing the state of the form and all it's fields. This
can be used to re-create the entire form at a later time via
L<Form::Sensible>s C<create_form()> method call. If C<$template_only> is true,
then only the structure of the form is saved and no values or other state will
be included in the returned hashref.

=back

=head2 DEPRECATED

These method calls have been deprecated and will be removed.  They
exist here only to help make sense of existing code... and to warn you 
they are being removed.

=over 8

=item C<fields()>  (DEPRECATED 2010-06-13 - To be removed 2010-08-30)

Returns an hashref containing all the fields in the current form

=item C<validator> (DEPRECATED 2010-06-13 - To be removed 2010-08-30)

The validator object associated with this form, if any. 

=item C<validator_result> (DEPRECATED 2010-06-13 - To be removed 2010-08-30)

Contains a C<Form::Sensible::Validator::Result> object if this form has had
it's C<validate()> method called. 

=item C<validator_args> (DEPRECATED 2010-06-13 - To be removed 2010-08-30)

Hashref containing arguments to the validator class to be used when a validator object is created 'on demand'.

=item C<renderer> (DEPRECATED 2010-06-13 - To be removed 2010-08-30)

The renderer object associated with this form, if any.  

=item C<render( @options )> (DEPRECATED 2010-06-13 - To be removed 2010-08-30)

Renders the current form using the C<renderer> object set for this form.

=back 

=head1 AUTHOR

Jay Kuri - E<lt>jayk@cpan.orgE<gt>

=head1 SPONSORED BY

Ionzero LLC. L<http://ionzero.com/>

=head1 SEE ALSO

L<Form::Sensible>

=head1 LICENSE

Copyright 2009 by Jay Kuri E<lt>jayk@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut