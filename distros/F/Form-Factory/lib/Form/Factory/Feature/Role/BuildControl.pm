package Form::Factory::Feature::Role::BuildControl;
$Form::Factory::Feature::Role::BuildControl::VERSION = '0.022';
use Moose::Role;

requires qw( build_control );

# ABSTRACT: control features that modify control construction


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Feature::Role::BuildControl - control features that modify control construction

=head1 VERSION

version 0.022

=head1 SYNOPSIS

  package MyApp::Feature::Control::CapitalizeLabel;
  use Moose;

  with qw(
      Form::Fctory::Feature
      Form::Factory::Feature::Role::BuildControl
      Form::Factory::Feature::Role::Control
  );

  sub build_control {
      my ($class, $options, $action, $name, $control) = @_;

      # could modify the control type too:
      # $control->{control} = 'full_text';

      $control->{options}{label} = uc $control->{options}{label};
  }

  package Form::Factory::Feature::Control::Custom::CapitalizeLabel;
  sub register_implementation { 'MyApp::Feature::Control::CapitalizeLabel' }

=head1 DESCRIPTION

Control features that do this role are given the opportunity to modify how the control is build for the attribute. Any modifications to the C<$options> hash given, whether to the control or to the options themselves will be passed on when creating the control.

In the life cycle of actions, this happens immediately before the control is created, but after any deferred values are evaluated. This means that the given hash should now look exactly as it will before being passed to the C<new_control> method of the interface.

=head1 ROLE METHODS

=head2 build_control

A feature implementing this role must provide this method. It is defined as follows:

  sub build_control {
      my ($class, $options, $action, $name, $control) = @_;
      
      # do something...
  }

This is called in by the action class immediately before the control is instantiated and gives the feature the opportunity to modify how the control is created.

The C<$class> argument is the name of the feature class. The feature will not have been constructed yet.

The C<$options> argument is the hash of options passed to C<has_control> for this feature. For example, if your feature is named "foo_bar" and you used your feature like this:

  has_control foo_bar => (
      features => {
          foo_bar => {
              framiss_size   => 12,
              trunnion_speed => 42,
          },
      },
  );

The C<$options> would be passed as:

  $options = { framiss_size => 12, trunnion_speed => 42 };

If the feature is just "turned on" with a 1 passed, then the hash reference will be empty (but still passed as a hash reference).

The C<$action> argument is the current action object as of the moment the control is being created.

The C<$name> argument is the name of the control (and action attribute) that this feature is attached to.

The C<$control> argument is a hash reference containing two keys. The "control" key will name the type of control this is. The "options" contains a copy of the options that are about to be passed to the control's constructor. You may modify either of these to modify which control class is constructed (by modifying "control") or the options passed to that constructor (by modifying the "options").

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
