package Form::Factory::Control;
$Form::Factory::Control::VERSION = '0.022';
use Moose::Role;

use Form::Factory::Control::Choice;
use List::Util qw( first );

requires qw( default_isa );

# ABSTRACT: high-level API for working with form controls


has action => (
    is        => 'ro',
    does      => 'Form::Factory::Action',
    required  => 1,
    weak_ref  => 1,
);


has name => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
);


has documentation => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_documentation',
);


has features => (
    is        => 'ro',
    isa       => 'ArrayRef',
    required  => 1,
    default   => sub { [] },
);


has value => (
    is        => 'rw',
    predicate => 'has_value',
);


has default_value => (
    is        => 'rw',
    predicate => 'has_default_value',
);


has control_to_value => (
    is        => 'ro',
    isa       => 'Str|CodeRef',
    predicate => 'has_control_to_value',
);


has value_to_control => (
    is        => 'ro',
    isa       => 'Str|CodeRef',
    predicate => 'has_value_to_control',
);


sub current_value {
    my $self = shift;

    $self->value(@_) if @_;

    return $self->value         if $self->has_value;
    return $self->default_value if $self->has_default_value;
    return scalar undef;
}


sub has_current_value {
    my $self = shift;
    return $self->has_value || $self->has_default_value;
}


sub convert_value_to_control {
    my ($self, $value) = @_;

    for my $feature (@{ $self->features }) {
        next unless $feature->does('Form::Factory::Feature::Role::ControlValueConverter');

        $value = $feature->value_to_control($value);
    }

    if ($self->has_value_to_control) {
        my $converter = $self->value_to_control;
        if (ref $converter) {
            $value = $converter->($self->action, $self, $value);
        }
        else {
            $value = $self->action->$converter($self, $value);
        }
    }

    return $value;
}


sub convert_control_to_value {
    my ($self, $value) = @_;

    for my $feature (@{ $self->features }) {
        next unless $feature->does('Form::Factory::Feature::Role::ControlValueConverter');

        $value = $feature->control_to_value($value);
    }

    if ($self->has_control_to_value) {
        my $converter = $self->control_to_value;
        if (ref $converter) {
            $value = $converter->($self->action, $self, $value);
        }
        else {
            $value = $self->action->$converter($self, $value);
        }
    }

    return $value;
}


sub set_attribute_value {
    my ($self, $action, $attribute) = @_;

    my $value = $self->current_value;
    if (defined $value) {
        $value = $self->convert_control_to_value($value);
        $attribute->set_value($action, $value);
    }
    else {
        $attribute->clear_value($action);
    }
}


sub get_feature_by_name {
    my ($self, $name) = @_;
    return first { $_->name eq $name } @{ $self->features };
}


sub has_feature {
    my ($self, $name) = @_;
    return 1 if $self->get_feature_by_name($name);
    return '';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Control - high-level API for working with form controls

=head1 VERSION

version 0.022

=head1 SYNOPSIS

  package MyApp::Control::Slider;
  use Moose;

  with qw(
      Form::Feature::Control
      Form::Feature::Control::Role::ScalarValue
  );

  has minimum_value => (
      is        => 'rw',
      isa       => 'Num',
      required  => 1,
      default   => 0,
  );

  has maximum_value => (
      is        => 'rw',
      isa       => 'Num',
      required  => 1,
      default   => 100,
  );

  has value => (
      is        => 'rw',
      isa       => 'Num',
      required  => 1,
      default   => 50,
  );

  sub current_value {
      my $self = shift
      if (@_) { $self->value(shift) }
      return $self->value;
  }

  package Form::Factory::Control::Custom::Slider;
  sub register_implementation { 'MyApp::Control::Slider' }

=head1 DESCRIPTION

Allows for high level processing, validation, filtering, etc. of form control information.

=head1 ATTRIBUTES

=head2 action

This is the action to which the control is attached. This is a weak reference to prevent memory leaks.

=head2 name

This is the base name for the control.

=head2 documentation

This holds a copy the documentation attribute of the original meta attribute.

=head2 features

This is the list of L<Form::Factory::Feature::Role::Control> features associated with the control.

=head2 value

This is the value of the control. This attribute provides a C<has_value> predicate. See L</current_value>.

=head2 default_value

This is the default or fallback value for the control used when L</value> is not set. This attribute provides a C<has_default_value> predicate. See L</current_value>.

=head2 control_to_value

This may be a method name or a code reference that can be run in order to coerce the control's current value to the action attribute's value during action processing. The given method or subroutine will always be called with 3 arguments:

=over

=item 1

The action object the control has been attached to.

=item 2

The control object we are converting from.

=item 3

The current value of the control.

=back

The method or subroutien should return the converted value.

This attribute provides a C<has_control_to_value> predicate.

=head2 value_to_control

This is either a method name (to be called on the action the control is connected with) to a code reference. This method or subroutine will be called to conver the action attribute value to the control's value.

The method or subroutine will always be called with three arguments:

=over

=item 1

The action object the control belongs to.

=item 2

The control object that will receive the value.

=item 3

The value of the attribute that is being assigned to the control.

=back

The method or subroutine should return the converted value.

This attribute provides a C<has_value_to_control> predicate.

=head1 METHODS

=head2 current_value

This is the current value of the control. If L</value> is set, then that is returned. If that is not set, but L</defautl_value> is set, then that is returned. If neither are set, then C<undef> is returned.

This may also be passed a value. In which case the L</value> is set and that value is returned.

=head2 has_current_value

Returns true if either C<value> or C<default_value> is set.

=head2 convert_value_to_control

Given an attribute value, convert it to a control value. This will cause any associated L<Form::Factory::Feature::Role::ControlValueConverter> features to run and run the L</value_to_control> conversion. The value to convert should be passed as the lone argument. The converted value is returned.

=head2 convert_control_to_value

Given a control value, convert it to an attribute value. This will run any L<Form::Factory::Feature::Role::ControlValueConverter> features and the L</control_to_value> conversion (if set). The value to convert should be passed as the only argument and the converted value is returned.

=head2 set_attribute_value

  $control->set_attribute_value($action, $attribute);

Sets the value of the action attribute with current value of teh control.

=head2 get_feature_by_name

  my $feature = $control->get_feature_by_name($name);

Given a feature name, it returns the named feature object. Returns C<undef> if no such feature is attached to this control.

=head2 has_feature

  if ($control->has_feature($name)) {
      # do something about it...
  }

Returns a true value if the named feature is attached to this control. Returns false otherwise.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
