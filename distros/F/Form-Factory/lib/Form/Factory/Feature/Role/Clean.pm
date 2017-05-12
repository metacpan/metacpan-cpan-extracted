package Form::Factory::Feature::Role::Clean;
$Form::Factory::Feature::Role::Clean::VERSION = '0.022';
use Moose::Role;

requires qw( clean );

# ABSTRACT: features that clean up control values


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Feature::Role::Clean - features that clean up control values

=head1 VERSION

version 0.022

=head1 SYNOPSIS

  package MyApp::Feature::Foo;
  use Moose;

  with qw(
      Form::Factory::Feature
      Form::Factory::Feature::Role::Control
      Form::Factory::Feature::Role::Clean
  );

  sub clean {
      my $self = shift;

      # Clean up the value, replace it with Foo
      $self->control->{something}->current_value('Foo');
  }

  package Form::Factory::Feature::Foo;
  sub register_implementation { 'MyApp::Feature::Foo' }

=head1 DESCRIPTION

This is for features that run during the clean phase. This runs immediately after the input has been consumed and before it is checked. These features should avoid reporting errors. The intention is for these features to clean up the input automatically before it is checked for errors. This should work with the control values rather than the action attributes directly, since those won't be set yet.

It is possible for the C<clean> method to stop processing by marking the result as invalid, but it is better to do that using L<Form::Factory::Feature::Role::Clean>.

=head1 ROLE METHODS

=head2 clean

This is called immediately after input has been consumed and before the input is checked for errors. This method should be used to clean up the input. It should not be used to validate the input since other clean methods may run after this one and the input is not yet in its final state.

The method will receive no arguments except the object it is called upon and the return value is ignored. Any output it needs to send should be placed in the C<result> object.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
