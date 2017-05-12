package Form::Factory::Feature::Role::Control;
$Form::Factory::Feature::Role::Control::VERSION = '0.022';
use Moose::Role;

requires qw( check_control );

# ABSTRACT: Form features tied to particular controls


has control => (
    is          => 'ro',
    does        => 'Form::Factory::Control',
    required    => 1,
    weak_ref    => 1,
    initializer => sub {
        my ($self, $value, $set, $attr) = @_;
        $self->check_control($value);
        $set->($value);
    },
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Feature::Role::Control - Form features tied to particular controls

=head1 VERSION

version 0.022

=head1 SYNOPSIS

  package MyApp::Feature::Control::Color;
  use Moose;

  with qw( 
      Form::Factory::Feature 
      Form::Factory::Feature::Role::Check
      Form::Factory::Feature::Role::Control 
      Form::Factory::Feature::Role::CustomControlMessage
  );

  has recognized_colors => (
      is        => 'ro',
      isa       => 'ArrayRef[Str]',
      required  => 1,
      default   => sub { [ qw( red orange yellow green blue purple black white ) ] },
  );

  sub check_control {
      my ($self, $control) = @_;

      die "color feature is only for scalar valued controls"
          unless $control->does('Form::Factory::Control::Role::ScalarValue');
  }

  sub check {
      my $self  = shift;
      my $value = $self->control->current_value;

      unless (grep { $value eq $_ } @{ $self->recognized_colors }) {
          $self->control_error('the %s does not look like a color');
          $self->result->is_valid(0);
      }
  }

  package Form::Factory::Feature::Control::Custom::Color;
  sub register_implementation { 'MyApp::Feature::Control::Color' }

And then used in an action via:

  package MyApp::Action::Foo;
  use Form::Factory::Processor;

  has_control favorite_primary_color => (
      control  => 'select_one',
      options  => {
          available_choices => [
              map { Form::Factory::Control::Choice->new($_, ucfirst $_) }
                qw( red yellow blue )
          ],
      },
      features => {
          color => {
              recognized_colors => [ qw( red yellow blue ) ],
          },
      },
  );

=head1 DESCRIPTION

This role is required for any feature attached directly to a control using C<has_control>.

=head1 ATTRIBUTES

=head2 control

This is the control object the feature has been attached to.

=head1 ROLE METHODS

=head2 check_control

All features implementing this role must implement a C<check_control> method. This method is called when the L</control> attribute is initialized during construction. It should be defined like this:

  sub check_control {
      my ($self, $control) = @_;

      # do something...
  }

Here C<$self> is the feature object. Be careful when using this, though, since this object is not fully constructed.

The C<$control> argument is the control this feature is being attached to. You are expected to verify that your feature is compatible with the control given.

The return value of this method is ignored. If the control is incompatible with your feature, your feature should die with a message explaining the problem.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
