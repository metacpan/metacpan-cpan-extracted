package Data::Object::Role::Catchable;

use 5.014;

use strict;
use warnings;

use Moo::Role;

our $VERSION = '1.60'; # VERSION

# METHODS

sub catch {
  my ($self, $error, $kind) = @_;

  $kind = ref($self) if !$kind;

  return UNIVERSAL::isa($error->object, $kind) ? 1 : 0;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Role::Catchable

=cut

=head1 ABSTRACT

Data-Object Catchable Role

=cut

=head1 SYNOPSIS

  use Data::Object::Class;

  with 'Data::Object::Role::Catchable';

=cut

=head1 DESCRIPTION

This role provides functionality for catching thrown exceptions.

=cut

=head1 LIBRARIES

This package uses type constraints defined by:

L<Data::Object::Library>

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 catch

  catch(Object $arg1, ClassName $arg2) : Int

Returns truthy if the objects passed are of the same kind.

=over 4

=item catch example

  my $catch = $self->catch($object, 'App::Exception');

=back

=cut

=head1 CREDITS

Al Newkirk, C<awncorp@cpan.org>, C<+284>

Anthony Brummett, C<abrummet@genome.wustl.edu>, C<+10>

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