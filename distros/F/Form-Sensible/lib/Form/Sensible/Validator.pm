package Form::Sensible::Validator;

use Moose; 
use namespace::autoclean;
use Form::Sensible::Validator::Result;
use Form::Sensible::DelegateConnection;
use Carp qw/croak/;

## this module provides the basics for validation of a Form.

has 'config' => (
    is          => 'rw',
    isa         => 'HashRef',
    required    => 1,
    default     => sub { return { }; },
    lazy        => 1,
);

has 'message_delegate' => (
    is          => 'rw',
    isa         => 'Form::Sensible::DelegateConnection',
    required    => 1,
    default     => sub {
                            return FSConnector( sub { 
                                                my $caller = shift;
                                                my $field = shift;
                                                my $message = shift;
                                                
                                                my $fieldname = $field->display_name;
                                                $message =~ s/_FIELDNAME_/$fieldname/g;
                                                      
                                                return $message;
                                   });
                   },
    lazy        => 1,
    coerce      => 1,
    # additional options
);

# returns a Form::Sensible::Validator::Result
sub validate {
    my ($self, $form) = @_;
    
    ## validation follows this process: Validate each field in order, using
    ## the order provided by the form.  If all of those succeed, then proceed to 
    ## complete form validation if provided.
    
    ## Prepare our validation result - it will be 'valid' unless we fail something.
    my $validation_result = Form::Sensible::Validator::Result->new();
    
    foreach my $field ($form->get_fields()) {
        if(ref $field eq 'Form::Sensible::Field::SubForm') {
            $validation_result->merge_from_result($field->form->validate);
            next;
        }

        my $fieldname = $field->name;
        my $results = $self->validate_field($field);
        
        if (scalar keys %{$results}) {
            if (exists($results->{'errors'})) {
                foreach my $error (@{$results->{'errors'}}) {
                    $validation_result->add_error($fieldname, $self->message_delegate->($self, $field, $error));
                }
            }
            
            if (exists($results->{'missing'})) {
                foreach my $missing (@{$results->{'missing'}}) {
                    $validation_result->add_error($fieldname, $self->message_delegate->($self, $field, $missing));
                }
            }
        }
    }
    
    if ($validation_result->is_valid()) {
        if (defined($form->validation->{'code'}) && ref($form->validation->{'code'}) eq 'CODE') {
            my $results = $form->validation->{'code'}->($form, $validation_result);
        }
    }
    return $validation_result;
}

sub validate_field {
    my ($self, $field) = @_;
    
    my $results = {};
    my @errors;
    if (defined($field->value) && $field->value ne '') {
        
        ## field has value, so we run the field validators
        ## first regex. 
#        if (defined($field->validation->{'regex'})) {
#            my $invalid = $self->validate_field_with_regex($field, $field->validation->{'regex'});
#            if ($invalid) {
#                push @errors, $invalid;
#            }
#        }
        ## if we have a coderef, and we passed regex, run the coderef.  Otherwise we
        ## don't bother. 
#        if (defined($field->validation->{'code'}) && $#errors == -1) {
#            my $invalid = $self->validate_field_with_coderef($field, $field->validation->{'code'});
#            if ($invalid) {
#                push @errors, $invalid;
#            }
#        }
        ## finally, we run the fields internal validate routine
        my @results = $field->validate($self);
        foreach my $error (@results) {
            if (defined($error) && $error ne '0') {
                push @errors, $error;
            }
        }
    } elsif ($field->validation->{'required'}) {
        ## field was required but was empty.
        if (exists($field->validation->{'missing_message'})) {
            $results->{'missing'} = [ $field->validation->{'missing_message'} ];
        } else {
            $results->{'missing'} = [ '_FIELDNAME_ is a required field but was not provided.' ];
        }
    }
    if ($#errors > -1) {
        $results->{'errors'} = [ @errors ];
    }
    return $results;
}

sub validate_field_with_regex {
    my ($self, $field, $regex) = @_;
    
    return $field->validate_with_regex($regex);
#    if (ref($regex) ne 'Regexp') {
#        $regex = qr/$regex/;
#    }
    
#    if ($field->value !~ $regex) {
#        if (exists($field->validation->{'invalid_message'})) {
#            return $field->validation->{'invalid_message'};
#        } else {
#            return "_FIELDNAME_ is invalid.";
#        }
#    } else {
#        return 0;
#    }
}

sub validate_field_with_coderef {
    my ($self, $field, $code) = @_;

    return $field->validate_with_coderef($code);

#    if (ref($code) ne 'CODE') {
#        croak('Bad coderef provided to validate_field_with_coderef');
#    }
    
#    my $results = $code->($field->value, $field);
#    
    ## if we get $results of 0 or a message, we return it.
    ## if we get $results of simply one, we generate the invalid message
#    if ($results && $results eq "1") {
#        if (exists($field->validation->{invalid_message})) {
#            return $field->validation->{invalid_message};
#        } else {
#            return "_FIELDNAME_ is invalid.";
#        }
#    } else {
#        return $results;
#    }
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Form::Sensible::Validator - Default Validator for Form::Sensible forms

=head1 SYNOPSIS

    use Form::Sensible::Validator;
    
    my $object = Form::Sensible::Validator->new();

    $validator_result = $object->validate($form);

=head1 DESCRIPTION

Form::Sensible::Validator performs the grunt work of validating a form.  It 
understands how to handle regex based field validation as well as 
coderef based field validation.  It also is responsible for calling 
field-type specific validation.  Usually this class is not manipulated 
directly.  Instead, C<< $form->validate() >> is used, which in turn calls
the validator already associated with the form (or creates one if none is
already defined).

=head1 METHODS

=over 8

=item C<validate($form)> 

Performs validation of a Form. Returns a
L<Form::Sensible::Validator::Result|Form::Sensible::Validator::Result> object
with the results of form validation for the passed form.

=item C<validate_field($field)> 

Performs complete validation on the given field.  Returns an array of 
hashes containing error messaging (or an empty array on success.) Each hash
returned will contain a key of either C<'error'> or C<'missing'> and 
a value containing the error message.

=item C<validate_field_with_regex($field, $regex)>

Internal routine to perform regex based validation of a field. 

=item C<validate_field_with_coderef($field, $coderef)>

Internal routine to perform code based validation of a field. When called, the
C<$coderef> is called with the field's value as the first argument, and the
field itself as the second:
    
    $coderef->($field_value, $field);

The subroutine is expected to return 0 on successful validation, or an
appropriate error message on failed validation. This may seem somewhat
confusing, returning 0 on a valid field. It may help to think of the coderef
as being the equivalent of a C<is_field_invalid()> routine.

=back

=head2 DELEGATE CONNECTIONS

=over 4

=item message_delegate: ($caller, $field, $message)

The message_delegate is used to assemble error and other validation related
messages. By default the message_delegate simply loads $message and replaces
any occurance of C<_FIELDNAME_> with the field's name. Should return the processed
message.  This is an ideal place to handle localization of messages or other 
customization.  If no translation can be found, you are strongly encouraged
to return the message as is (with C<_FIELDNAME_> converted to the actual field
name, of course.)

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