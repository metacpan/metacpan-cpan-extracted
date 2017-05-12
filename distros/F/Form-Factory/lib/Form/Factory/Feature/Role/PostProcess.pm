package Form::Factory::Feature::Role::PostProcess;
$Form::Factory::Feature::Role::PostProcess::VERSION = '0.022';
use Moose::Role;

requires qw( post_process );

# ABSTRACT: features that run just after processing


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Feature::Role::PostProcess - features that run just after processing

=head1 VERSION

version 0.022

=head1 SYNOPSIS

  package MyApp::Feature::Qux;
  use Moose;

  with qw(
      Form::Factory::Feature
      Form::Factory::Feature::Role::PostProcess
  );

  sub post_process {
      my $self = shift;
      MyApp::Logger->info('Ending the process.');
  }

  package Form::Factory::Feature::Custom::Qux;
  sub register_implementation { 'MyApp::Feature::Qux' }

=head1 DESCRIPTION

Features that run something immediately after the action runs may implement this role. This feature will run after the action does whether it succeeds or not. It will not run if an exception is thrown.

=head1 ROLE METHOD

=head2 post_process

This method is called immediately after the C<run> method is called. It is passed no arguments other than the feature object it is called upon. It's return value is ignored.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
