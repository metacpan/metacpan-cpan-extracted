package Form::Sensible::Field;

use Moose;
use namespace::autoclean;
use Carp;
use Data::Dumper;
use Class::MOP;
use Form::Sensible::DelegateConnection;


has 'name' => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
);

has 'display_name' => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    default     => sub {
                            my $name = ucfirst(shift->name());
                            $name =~ s/_/ /g;
                            return $name;
                        },
    lazy        => 1,
);

has 'field_type' => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    builder     => '_default_field_type',
    lazy        => 1
);

## validation contains args to the validator that will be used
## by default, the hashref can contain 'regex' - a ref to a
## regex.  or 'code' - a code ref.  If both are present,
## the regex will be checked first, then if that succeeds
## the coderef will be processed.

has 'validation' => (
    is          => 'rw',
    isa         => 'HashRef',
    required    => 1,
    default     => sub { return { required => 0 }; },
    lazy        => 1,
);

## render hints is a hashref that gives hints about rendering
## for the various renderers.  for example:
## render_hints->{HTML} = hash containing information about
## how the field should be rendered.

has 'render_hints' => (
    is          => 'rw',
    isa         => 'HashRef',
    required    => 1,
    builder     => '_default_render_hints',
    lazy        => 1,
);

## note the default behavior is to squash arrays if accepts_multiple is not set.
## if you need different behavior in your subclass, you have to override the default
## value delegate.

has 'value_delegate' => (
    is          => 'rw',
    isa         => 'Form::Sensible::DelegateConnection',
    required    => 1,
    default     => sub {
                            my $self = shift;
                            my $value = $self->default_value;
                            my $sub =  sub {
                                                      my $caller = shift;

                                                      if ($#_ > -1) {
                                                          if (ref($_[0]) eq 'ARRAY' && !($caller->accepts_multiple)) {
                                                              $value = $_[0]->[0];
                                                          } else {
                                                              $value = $_[0];
                                                          }
                                                      }
                                                      return $value;
                                                  };
                            return FSConnector($sub);
                   },
    lazy        => 1,
    coerce      => 1,
    # additional options
);

has 'accepts_multiple' => (
    is          => 'rw',
    isa         => 'Bool',
    required    => 1,
    default     => 0,
);

has 'editable' => (
    is          => 'rw',
    isa         => 'Bool',
    required    => 1,
    default     => 1,
);

## calling format:  ($field, $value) return an arrayref containing error messages if invalid or false (scalar) if valid
## it may be help to think of it as asking the delegate 'is this invalid'
has 'validation_delegate' => (
    is          => 'rw',
    isa         => 'Form::Sensible::DelegateConnection',
    required    => 1,
    default     => sub {
                            return FSConnector(sub { return; });
                   },
    lazy        => 1,
    coerce      => 1,
    # additional options
);

has 'default_value' => (
    is          => 'rw',
);

sub _default_field_type {
    my $self = shift;

    my $class = ref($self);
    $class =~ m/::([^:]*)$/;
    return lc($1);
}

sub _default_render_hints {
    my $self = shift;

    return {};
}

sub required {
    my $self = shift;

    if ($#_ > -1) {
        $self->validation->{'required'} = $_[0];
    }
    return $self->validation->{'required'} || 0;
}

sub flatten {
    my ($self, $template_only) = @_;

    my %config = map { $_ => $self->$_ }
        qw(name display_name default_value field_type render_hints);

    my $class = ref($self);
    if ($class =~ /^Form::Sensible::Field::(.*)$/) {
        $class = $1;
    } else {
        $class = '+' . $class;
    }

    $config{'field_class'} = $class;

    if (!$template_only) {
        $config{'value'} = $self->value;
    }

    if ($self->accepts_multiple) {
        $config{'accepts_multiple'} =$self->accepts_multiple;
    }

    $config{'validation'} = {};
    foreach my $key (keys %{$self->validation}) {
        my $value = $self->validation->{$key};
        $value = "$value" if ref($value);
        $config{'validation'}{$key} = $value;
    }
    my $additional = $self->get_additional_configuration($template_only);
    foreach my $key (keys %{$additional}) {
        $config{$key} = $additional->{$key};
    }

    return \%config;
}

## hook for adding additional config without having to do 'around' every time.
sub get_additional_configuration {
    my ($self) = @_;

    return {};
}

## built-in field specific validation.  Regex and code validation run first.
## by default just calls the validation_delegate.
sub validate {
    my ($self) = @_;

    my @errors;

    if (defined($self->validation->{'regex'})) {
        push @errors, $self->validate_with_regex($self->validation->{'regex'});
    }
    ## if we have a coderef, and we passed regex, run the coderef.  Otherwise we
    ## don't bother.
    if (defined($self->validation->{'code'}) && $#errors == -1) {
        push @errors, $self->validate_with_coderef($self->validation->{'code'});
    }
    if (defined($self->validation_delegate)) {
        push @errors, $self->validation_delegate->($self, $self->value);
    }

    return grep { defined } @errors;

}


sub validate_with_regex {
    my ($self, $regex) = @_;

    if (ref($regex) ne 'Regexp') {
        $regex = qr/$regex/;
    }
    return if $self->value() =~ $regex;
    return exists($self->validation->{'invalid_message'})
        ? $self->validation->{'invalid_message'}
        : '_FIELDNAME_ is invalid.';
}

sub validate_with_coderef {
    my ($self, $code) = @_;

    if (ref($code) ne 'CODE') {
        croak('Bad coderef provided to validate_field_with_coderef');
    }

    my $results = $code->($self->value(), $self);

    ## if we get $results of "false" or a message, we return it.
    ## if we get $results of simply one, we generate the invalid message
    return $results if ! $results || $results ne "1";
    return exists($self->validation->{'invalid_message'})
        ? $self->validation->{'invalid_message'}
        : '_FIELDNAME_ is invalid.';
}


sub value {
    my $self = shift;

    return $self->value_delegate->($self,@_);
}

## restores a flattened field structure.
sub create_from_flattened {
    my ($class, $fieldconfig ) = @_;

    my $fieldclass = $fieldconfig->{'field_class'};
    if (!$fieldclass) {
        croak "Unable to restore flattened field, no field class defined";
    }
    my $class_to_load;
    if ($fieldclass =~ /^\+(.*)$/) {
        $class_to_load = $1;
    } else {
        $class_to_load = 'Form::Sensible::Field::' . $fieldclass;
    }
    Class::MOP::load_class($class_to_load);

    # copy because we are going to remove class, as it wasn't there to begin with.
    my $config = { %{$fieldconfig} };
    delete $config->{'field_class'};
    #print Dumper($config);
    return $class_to_load->new(%{$fieldconfig});
}

## clears the value for a field.
sub clear_state {
    my $self = shift;

    $self->value(undef);
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Form::Sensible::Field - Field base class for Form::Sensible

=head1 SYNOPSIS

    use Form::Sensible::Field;
    
    my $field = Form::Sensible::Field->create_from_flattened( {
        field_class => 'Text',
        name => 'username',
        validation => {  regex => '^[0-9a-z]*$'  }
     } );
    
    $field->value('bob');
    
    my $saveforlater = $field->flatten();

=head1 DESCRIPTION

Form::Sensible::Field provides the basic functionality for all field types in
Form::Sensible. All form field classes indended for use with Form::Sensible
should extend Form::Sensible::Field.  Form::Sensible is distributed with the
following field classes:

=over 8

=item L<Text|Form::Sensible::Field::Text>

Simple text field, for storage of simple strings of text. Defaults to a
maximum length of 256. If you are looking for multi-line text, it's probably
better to use the LongText type.

=item L<LongText|Form::Sensible::Field::LongText>

Similar to the Text field type, only intended for longer, multi-line strings
of text.

=item L<Select|Form::Sensible::Field::Select>

Multiple-choice field type.  Provides for selecting one or more items out of a
group of pre-defined options.

=item L<Toggle|Form::Sensible::Field::Toggle>

Similar to the select type, but provides for only on/off state.

=item L<Number|Form::Sensible::Field::Number>

Number field type.  Contains options for defining number-specific options and
limits such as decimal or integer, upper and lower bounds, etc.

=item L<Trigger|Form::Sensible::Field::Trigger>

A Trigger.  Causes something to happen, most often form validation and
processing. Trigger fields are most often rendered as buttons in graphical
interfaces.

=item L<FileSelector|Form::Sensible::Field::FileSelector>

A File selector.  Used to pick a file.  Works locally or as a file upload,
depending on your renderer.

=item L<SubForm|Form::Sensible::Field::SubForm>

A field type that allows you to include an entire other form into the current
form.  Useful for creating blocks of fields which can be included into other
forms easily.

=back

We believe that almost all form-based values can fit into these types. Keep in
mind that these are not intended to represent all I<presentations> of form
data. Select fields, for example could be rendered as a dropdown select-box or
as a group of checkboxes, depending on the renderer selected and the
render_hints provided.

If you feel we've missed something, please drop us a line, or drop by
#form-sensible on irc.perl.org.

=head1 ATTRIBUTES

=over 8

=item C<name>

The field name, used to identify this field in your program.

=item C<display_name>

The name used when displaying messages about this field, such as errors, etc.
Defaults to C<<uc($field->name)>>.

=item C<field_type>
A string identifying this type of field.  Normally defaults to the last
portion of the classname, for example, for the C<Form::Simple::Field::Text>
class the field_type would be 'text'.

=item C<validation>

Hashref containing information used in validation of this field. The content
of the hashref depends on the validator being used. If the built-in
L<Form::Sensible::Validator> is being used, the three keys that may be present
are C<required>, C<regex> and C<code>. The C<required> element should contain a
true/false value indicating whether the field must be present for validation to
pass. The C<regex> element should contain either a regex pattern or a regex
reference to be applied to the field. The C<code> element should contain an
code reference used to validate the field's value. For more information, see
L<Form::Sensible::Validator>.

=item C<render_hints>

Hashref containing hints to help the renderer render this field.  The hints available
depend on the renderer being used.

=item C<value>

The current value for this field.

=item C<accepts_multiple>

Can the field support multiple values.  Defaults to false.  If an array of values is
passed as the value on a field that doesn't accept multiple values, only the first
value will be used, the remainder will be ignored.

=item C<default_value>

The default value to use if none is provided.

=item C<editable>

Returns whether or not the field's value is editable.

=back

=head1 METHODS

=over 8

=item C<validate()>

Validation specific to the field.  This is usually used to provide validation that only
applies to the given type of field, for example, ensuring that the value provided
matches the available options in a select box.

=item C<clear_state()>

Clears the state for this field.  In most cases simply clears out the value
field, but may do additional state-cleaning work on complex fields.   Note that
if you subclass the Field class and then provide a custom C<value()> routine or
attribute, you B<MUST> also override C<clear_state> in your subclass.

=item C<create_from_flattened()>

Creates a new field object using the provided flattened field information.  Note that
this will use the C<field_class> element in the provided hash to determine the appropriate
object type to create.

=item C<flatten([$template_only])>

Flattens the current field into a non-blessed hashref that can be used to recreate the
field later.  If C<$template_only> is provided and is true, only the data required to
re-create the field is provided, and no additional state (such as the current value)
is returned.

=item C<get_additional_configuration()>

Helper function to C<flatten()>, used by subclasses to add additional
information specific to the subclass type into the flattened hash structure.
Should return a hashref to be merged into the flattened field hash.

=item C<required([optional value])

Getter/setter for requiring this field for validation.

=back

=head1 DELEGATES

=over 8

=item value_delegate->($self, [optional value])

The C<value_delegate> is called to get or set the value for this field.
The first argument is the Field object itself, which will be the only
parameter if it is called as a getter.  If called as a setter, an
additional value argument will be passed.  In both scenarios, the
delegate should return the field's (new) value.

=item validation_delegate->($self, $value)

The C<validation_delegate> is called to validate the value given for the field.
As with all delegates, the first argument is the field itself, the second argument
is the value to be validated.  The delegate is expected to return an arrayref containing
error messages if invalid, or false (scalar) if valid.  It may be help to think of
it as the field asking the delegate 'is this invalid.'

Note that each field type may have its own validation rules which will be performed
before the C<validation_delegate> is called.

=back

=head1 PRIVATE METHODS

=head2 _default_field_type

Builder for C<field_type> attribute. Lowercases the innermost namespace of the
class name and returns it.

=head2 _default_render_hints

Builder for C<render_hints> attribute. Returns an empty hashref.

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
