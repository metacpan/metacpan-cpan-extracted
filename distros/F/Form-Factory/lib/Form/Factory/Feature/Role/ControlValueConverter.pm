package Form::Factory::Feature::Role::ControlValueConverter;
$Form::Factory::Feature::Role::ControlValueConverter::VERSION = '0.022';
use Moose::Role;

with qw( Form::Factory::Feature::Role::Control );

requires qw( value_to_control control_to_value );

# ABSTRACT: form features that convert values



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Feature::Role::ControlValueConverter - form features that convert values

=head1 VERSION

version 0.022

=head1 SYNOPSIS

  package MyApp::Feature::Control::Integer;
  use Moose;

  with qw(
      Form::Factory::Feature
      Form::Factory::Feature::Role::ControlValueConverter
  );

  sub check_control {
      my ($self, $cotnrol) = @_;

      die "not a scalar valued control"
          unless $control->does('Form::Factory::Control::Role::ScalarValue');
  }

  sub control_to_value {
      my ($self, $value) = @_;
      return int($value);
  }

  sub value_to_control {
      my ($self, $value) = @_;
      return ''.$value;
  }

=head1 DESCRIPTION

This role is used to provide standard value convertions between control values and action attributes. This allows you to reuse a common conversion by creating a feature to handle it.

Use of this role implies L<Form::Factory::Feature::Role::Control>.

=head1 ROLE METHODS

The feature implementing this role must provide these methods.

=head2 control_to_value

This method is used to convert a value on a control for use in assignment to the action attribute to which it is attached.

This method should be defined like so:

  sub control_to_value {
      my ($self, $value) = @_;

      return # ... converted value ...
  }

The C<$value> here will be teh value to convert. This is usually going to be the C<current_value> of the control, but might be something else, so make sure you use the given value for conversion.

=head2 value_to_control

This method does the reverse of C<control_to_value> and is used to convert the action attribute to the control value. 

It is defined like this:

  sub value_to_control {
      my ($self, $value) = @_;

      return # ... converted value ...
  }

The C<$value> here will be a value from the action attribute (or something of the same type) and the value returned should be appropriate for assigning to the control value.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
