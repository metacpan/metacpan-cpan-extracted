package Form::Factory::Feature::Role::Check;
$Form::Factory::Feature::Role::Check::VERSION = '0.022';
use Moose::Role;

requires qw( check );

# ABSTRACT: features that check control values


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Feature::Role::Check - features that check control values

=head1 VERSION

version 0.022

=head1 SYNOPSIS

  package MyApp::Feature::Bar;
  use Moose;

  with qw(
      Form::Factory::Feature
      Form::Factory::Feature::Role::Check
  );

  sub check {
      my $self = shift;

      # Check the value for errors, it must contain Bar
      my $value = $self->control->{something}->current_value;
      unless ($value =~ /\bBar\b/) {
          $self->result->error('control must contain Bar');
          $self->result->is_valid(0);
      }
      else {
          $self->result->is_valid(1);
      }
  }

  package Form::Factory::Feature::Custom::Bar;
  sub register_implementation { 'MyApp::Feature::Bar' }

=head1 DESCRIPTION

Features that check the correctness of control values implement this role. This runs after input has been consumed and cleaned and before it is processed. The check here is meant to verify whether the input is valid and ready for processing. Mark the result as invalid to prevent processing. In general, it's a good idea to return an error if you do that. This is also a good place to return warnings.

=head1 ROLE METHODS

=head2 check

The check method is run after the data has been cleaned up and is intended for checking whether or not the data given is ready to be processed. A feature checking the input for valdation should set the C<is_valid> flag on the result. If you do not set C<is_valid>, then you will not influence whether or not the action is considered valid and ready to move on to the processing stage.

This method is passed no arguments other than the object it is being called on. The return value is ignored. If you check method needs to output anything, it should do so through the attached C<result> object.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
