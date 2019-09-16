package Data::Object::Role::Throwable;

use 5.014;

use strict;
use warnings;

use Moo::Role;

our $VERSION = '1.76'; # VERSION

# BUILD
# METHODS

sub throw {
  my ($self, $message) = @_;

  require Data::Object::Exception;

  my $class = 'Data::Object::Exception';

  @_ = ($class => ($message, $self));

  goto $class->can('throw');
}

1;

=encoding utf8

=head1 NAME

Data::Object::Role::Throwable

=cut

=head1 ABSTRACT

Data-Object Throwable Role

=cut

=head1 SYNOPSIS

  use Data::Object::Class;

  with 'Data::Object::Role::Throwable';

=cut

=head1 DESCRIPTION

This package provides mechanisms for throwing the object as an exception.

=cut

=head1 LIBRARIES

This package uses type constraints defined by:

L<Data::Object::Library>

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 throw

  throw(Str $arg1) : Object

The throw method throws an exception with the object and message.

=over 4

=item throw example

  $self->throw($message);

=back

=cut

=head1 CREDITS

Al Newkirk, C<+296>

Anthony Brummett, C<+10>

José Joaquín Atria, C<+1>

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=head1 PROJECT

L<GitHub|https://github.com/iamalnewkirk/do>

L<Projects|https://github.com/iamalnewkirk/do/projects>

L<Milestones|https://github.com/iamalnewkirk/do/milestones>

L<Contributing|https://github.com/iamalnewkirk/do/blob/master/CONTRIBUTE.mkdn>

L<Issues|https://github.com/iamalnewkirk/do/issues>

=head1 SEE ALSO

To get the most out of this distribution, consider reading the following:

L<Do>

L<Data::Object>

L<Data::Object::Class>

L<Data::Object::ClassHas>

L<Data::Object::Role>

L<Data::Object::RoleHas>

L<Data::Object::Library>

=cut