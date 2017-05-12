package Form::Factory::Action::Role;
$Form::Factory::Action::Role::VERSION = '0.022';
use Moose::Role;

use Carp ();

# ABSTRACT: Role implemented by action roles


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Action::Role - Role implemented by action roles

=head1 VERSION

version 0.022

=head1 SYNOPSIS

  package MyApp::Action::Foo;
  use Form::Factory::Processor::Role;

  has_control bar => (
      type => 'text',
  );

=head1 DESCRIPTION

This is the role implemented by all form action roles. Do not use this directly, but use L<Form::Factory::Processor::Role>, which performs the magic required to make your class implement this role.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
