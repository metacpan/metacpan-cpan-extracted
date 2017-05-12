package Form::Sensible::Validator::Result;

use Moose; 
use Data::Dumper;
use namespace::autoclean;

has 'error_fields' => (
    is          => 'rw',
    isa         => 'HashRef',
    required    => 1,
    default     => sub { return {}; },
    lazy        => 1,
);

has 'missing_fields' => (
    is          => 'rw',
    isa         => 'HashRef',
    required    => 1,
    default     => sub { return {}; },
    lazy        => 1,
);

sub add_error {
    my ($self, $fieldname, $message) = @_;
    
    if (ref($message) && $message->isa('Form::Sensible::Validator::Result')) {
        $self->merge_from_result($message);
    } else {
        if (!exists($self->error_fields->{$fieldname})) {
            $self->error_fields->{$fieldname} = [];
        }
        push @{$self->error_fields->{$fieldname}}, $message;
    }
}

sub add_missing {
    my ($self, $fieldname, $message) = @_;
    
    if (ref($message) && $message->isa('Form::Sensible::Validator::Result')) {
        $self->merge_from_result($message);
    } else {
        if (!exists($self->missing_fields->{$fieldname})) {
            $self->missing_fields->{$fieldname} = [];
        }
        push @{$self->missing_fields->{$fieldname}}, $message;
    }
}

sub is_valid {
    my ($self) = shift;
    
    if ((scalar keys %{$self->error_fields}) || (scalar keys %{$self->missing_fields})) {
        return 0;
    } else {
        return 1;
    }
}

# if we have a validation result instead of a message in the error routines, we will need to
# merge the values from the provided result into the current result

sub merge_from_result {
    my ($self, $result) = @_;
    
    foreach my $fieldname (keys %{$result->error_fields}) {
        if (!exists($self->error_fields->{$fieldname})) {
            $self->error_fields->{$fieldname} = [];
        }
        push @{$self->error_fields->{$fieldname}}, @{$result->error_fields->{$fieldname}};
    }
    foreach my $fieldname (keys %{$result->missing_fields}) {
        if (!exists($self->missing_fields->{$fieldname})) {
            $self->missing_fields->{$fieldname} = [];
        }
        push @{$self->missing_fields->{$fieldname}}, @{$result->missing_fields->{$fieldname}};
    }
}

## below here are things that make Form::Sensible::Validator results behave 
## more like FormValidator::Simple 

sub has_missing {
    my $self = shift;
    
    if (scalar keys %{$self->missing_fields}) {
        return 1;
    } else {
        return 0;
    }
}

sub has_invalid {
    my $self = shift;
    
    if (scalar keys %{$self->error_fields}) {
        return 1;
    } else {
        return 0;
    }
}

sub has_error {
    my $self = shift;
    
    return !$self->is_valid();
}

sub success {
    my $self = shift;
    
    return $self->is_valid();
}

sub missing {
    my $self = shift;
    
    if ($#_ != -1) {
        if (exists($self->missing_fields->{$_[0]})) {
            return 1;
        }
    } else {
        return keys %{$self->missing_fields};
    }
}

sub invalid {
    my $self = shift;
    
    if ($#_ != -1) {
        if (exists($self->error_fields->{$_[0]})) {
            return $self->error_fields->{$_[0]};
        } else {
            return 0;
        }
    } else {
        return keys %{$self->error_fields};
    }
} 

sub error {
    my $self = shift;
    
    if ($#_ == -1) {
        return keys %{$self->missing_fields}, keys %{$self->error_fields};
    } else {
        if ($_[1] eq 'NOT_BLANK' && exists($self->missing_fields->{$_[0]})) {
            return 1;
        } else {
            return exists($self->error_fields->{$_[0]});
        }
    }
}

sub messages_for {
    my ($self, $fieldname) = @_;
    
    my @messages;
    if (exists($self->error_fields->{$fieldname})) {
        push @messages, @{$self->error_fields->{$fieldname}};
    }
    if (exists($self->missing_fields->{$fieldname})) {
         push @messages, @{$self->missing_fields->{$fieldname}};
    }
    
    return @messages;
    
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Form::Sensible::Validator::Result - Validation results for a given form.

=head1 SYNOPSIS
    
    my $result = $form->validate();

    if (!$result->is_valid()) {
         foreach my $key ( keys %{$result->error_fields()} ) {
             foreach my $message ( @{ $result->error_fields->{$key} } ) {
                    print $message;
             }
         }
    }

=head1 DESCRIPTION

The C<Form::Sensible::Validator::Result|Form::Sensible::Validator::Result>
class is used to store the results of form validation. It is very simple to
work with and has some additional methods to make it more familiar to anyone
who has used L<FormValidator::Simple>.  The additional methods are intended
to function similar to the L<FormValidator::Simple Results class|FormValidator::Simple::Results>

=head1 METHODS

=over 8

=item C<is_valid()> 

Returns true if the form passed validation, false otherwise.  

=item C<error_fields>

Returns a hashref containing C<< fieldname => error_array >> pairs.  Each field
with an error will be present as a key in this hash and the value will be an
arrayref containing one or more error messages.

=item C<missing_fields>

Works exactly as error_fields, only contains only entries for fields that 
were required but were not present. 

=item C<add_error($fieldname, $message)> 

Adds $message as an error on the field provided. There can be more than one error message
for a given field.

=item C<add_missing($fieldname, $message)> 

Adds $message as an missing field error on the field provided. Like errors, there can be
more than one missing field message for a given field.

=back

The following routines are things that make Form::Sensible::Validator results behave 
more like C<FormValidator::Simple|FormValidator::Simple>'s Result class.

=item 8

=item C<has_missing>

Returns true if there were missing values in the form;

=item C<has_invalid>

Returns true if any fields in the form were invalid. 

=item C<has_error>

Returns true if there are any invalid or missing fields with the form validation.  
Essentially the inverse of L<is_valid>

=item C<success>

Synonym for L<is_valid>. Returns true if all fields passed validation.

=item C<missing($fieldname)>

If C<$fieldname> is provided, returns true if the field provided was missing, false otherwise.
If no fieldname is provided, returns an array of fieldnames that were missing in the form.

=item C<invalid($fieldname)>

If C<$fieldname> is provided, returns true if the field provided was invalid, false otherwise.
If no fieldname is provided, returns an array of fieldnames that were invalid in the form.
 
=item C<error($fieldname)>

If C<$fieldname> is provided, returns true if the field provided was either missing or invalid, false otherwise.
If no fieldname is provided, returns an array of fieldnames that were either missing or invalid in the form.

=item C<message_for($fieldname)>

Returns all the error messages (including errors and missing notifications) for the fieldname provided. 
Returns an empty array if there are no errors on the given field.

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