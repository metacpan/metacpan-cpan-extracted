package Form::Factory::Feature::Role::InitializeControl;
$Form::Factory::Feature::Role::InitializeControl::VERSION = '0.022';
use Moose::Role;

requires qw( initialize_control );

# ABSTRACT: control features that work on just constructed controls


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Feature::Role::InitializeControl - control features that work on just constructed controls

=head1 VERSION

version 0.022

=head1 SYNOPSIS

  package MyApp::Feature::Control::LoadDBValue;
  use Moose;

  with qw(
      Form::Factory::Feature
      Form::Factory::Feature::Role::Control
      Form::Factory::Feature::Role::InitializeControl
  );

  sub check_control { 
      my ($self, $control) = @_;

      # nasty ducks and they typings
      die "control action has no record"
          unless $control->action->can('record');
  }

  sub initialize_control {
      my $self    = shift;
      my $action  = $self->action;
      my $control = $self->control;

      my $name   = $control->name;
      my $record = $action->record;

      # Set the default value from the record value
      $control->default_value( $record->$name );
  }

  package Form::Factory::Feature::Control::Custom::LoadDatabaseValue;
  sub register_implementation { 'MyApp::Feature::Control::LoadDBValue' }

=head1 DESCRIPTION

This role may be implemented by a control feature that needs to access a control and do something with it immediately after the control has been completely constructed.

The feature must implement the C<initialize_control> method.

=head1 ROLE METHODS

=head2 initialize_control

This method is called on the feature immediately after the control has been completely constructed. This method is called with no arguments and the return value is ignored.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
