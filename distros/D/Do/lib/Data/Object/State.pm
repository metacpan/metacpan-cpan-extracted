package Data::Object::State;

use 5.014;

use strict;
use warnings;

use parent 'Moo';

our $VERSION = '1.50'; # VERSION

# BUILD

sub import {
  my ($class, @args) = @_;

  my $target = caller;

  eval "package $target; use Moo; 1;";

  no strict 'refs';

  *{"${target}::BUILD"} = $class->can('BUILD');
  *{"${target}::renew"} = $class->can('renew');

  return;
}

sub BUILD {
  my ($self, $args) = @_;

  my $class = ref($self) || $self;

  no strict 'refs';

  ${"${class}::data"} = {%$self, %$args} if !${"${class}::data"};

  $_[0] = bless ${"${class}::data"}, $class;

  return $class;
}

# METHODS

sub renew {
  my ($self, @args) = @_;

  my $class = ref($self) || $self;

  no strict 'refs';

  undef ${"${class}::data"};

  return $class->new(@args);
}

1;

=encoding utf8

=head1 NAME

Data::Object::State

=cut

=head1 ABSTRACT

Data-Object Singleton Declaration

=cut

=head1 SYNOPSIS

  package Registry;

  use Data::Object::State;

  extends 'Environment';

  1;

=cut

=head1 DESCRIPTION

This package modifies the consuming package making it a singleton.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Data::Object::Class>

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 renew

  renew(Any @args) : Object

The renew method resets the state and returns a new singleton.

=over 4

=item renew example

  my $renew = $self->renew(@args);

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=head1 PROJECT

L<On GitHub|https://github.com/iamalnewkirk/do>

L<Initiatives|https://github.com/iamalnewkirk/do/projects>

L<Contributing|https://github.com/iamalnewkirk/do/blob/master/CONTRIBUTE.mkdn>

L<Reporting|https://github.com/iamalnewkirk/do/issues>

=head1 SEE ALSO

To get the most out of this distribution, consider reading the following:

L<Data::Object::Class>

L<Data::Object::Role>

L<Data::Object::Rule>

L<Data::Object::Library>

L<Data::Object::Signatures>

=cut