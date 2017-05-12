package Form::Factory::Interface;
$Form::Factory::Interface::VERSION = '0.022';
use Moose::Role;

use Carp ();
use Class::Load;
use Form::Factory::Stasher::Memory;

requires qw( render_control consume_control );

# ABSTRACT: Role for form interface implementations


has stasher => (
    is        => 'ro',
    does      => 'Form::Factory::Stasher',
    required  => 1,
    default   => sub { Form::Factory::Stasher::Memory->new },
    handles   => [ qw( stash unstash ) ],
);


sub new_action {
    my ($self, $class_name, $args) = @_;

    Class::Load::load_class($class_name)
        or Carp::croak("cannot load $class_name: $@");

    return $class_name->new( %$args, form_interface => $self );
}


sub new_control {
    my ($self, $name, $args) = @_;

    my $class_name = Form::Factory->control_class($name);
    return unless $class_name;

    return $class_name->new($args);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Interface - Role for form interface implementations

=head1 VERSION

version 0.022

=head1 SYNOPSIS

  package MyApp::Interface::MyUI;
  use Moose;

  with qw( Form::Factory::Interface );

  sub render_control {
      my ($self, $control, %options) = @_;

      # Draw $control for user
  }

  sub consume_control {
      my ($self, $control, %options) = @_;

      # Consume values from user to fill $control
  }

  package Form::Factory::Interface::Custom::MyUI;
  sub register_implementation { 'MyApp::Interface::MyUI' }

=head1 DESCRIPTION

Defines the contract form interface classes must fulfill.

=head1 ATTRIBUTES

=head2 stasher

A place for remembering things.

=head1 METHODS

=head2 stash

=head2 unstash

See L<Form::Factory::Stash>.

=head2 new_action

  my $action = $interface->new_action('Some::Action::Class', \%options);

Given the name of an action class, it initializes the class for use with this interface. The C<%options> are passed to the constructor.

=head2 new_control

  my $control = $interface->new_control($name, \%options);

Given the short name for a control and a hash reference of initialization arguments, return a fully initialized control.

=head1 ROLE METHODS

The following methods need to implement the following methods.

=head2 render_control

  $interface->render_control($control, %options);

This method is used to render the control in the current form.

=head2 consume_control

  $interface->consume_control($control, %options);

This method is used to consume the values input for a current form.

=head1 CONTROLS

Here's a list of controls and the classes they represent:

=over

=item button

L<Form::Factory::Control::Button>

=item checkbox

L<Form::Factory::Control::Checkbox>

=item full_text

L<Form::Factory::Control::FullText>

=item password

L<Form::Factory::Control::Password>

=item select_many

L<Form::Factory::Control::SelectMany>

=item select_one

L<Form::Factory::Control::SelectOne>

=item text

L<Form::Factory::Control::Text>

=item value

L<Form::Factory::Control::Value>

=back

=head1 SEE ALSO

L<Form::Factory::Action>, L<Form::Factory::Control>, L<Form::Factory::Stasher>

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
