package Data::Object::Role::Proxyable;

use 5.014;

use strict;
use warnings;

use Moo::Role;

use Carp ();

our $VERSION = '1.87'; # VERSION

# BUILD

sub AUTOLOAD {
  my ($self) = @_;

  my (@namespace) = our $AUTOLOAD =~ /^(.+)::(.+)$/;

  my ($package, $method) = @namespace;

  my $build = $package->can('BUILDPROXY');

  my $error = qq(Can't locate object method "$method" via package "$package");

  Carp::confess($error) unless $build && ref($build) eq 'CODE';

  my $proxy = $build->($package, $method, @_);

  Carp::confess($error) unless $proxy && ref($proxy) eq 'CODE';

  goto &$proxy;
}

sub DESTROY {
  return;
}

# METHODS

1;

=encoding utf8

=head1 NAME

Data::Object::Role::Proxyable

=cut

=head1 ABSTRACT

Data-Object Proxyable Role

=cut

=head1 SYNOPSIS

  use Data::Object::Class;

  with 'Data::Object::Role::Proxyable';

  sub BUILDPROXY {
    my ($class, $method, @args) = @_;

    return if $method eq 'execute'; # die with method missing error

    return sub { time }; # process method call
  }

=cut

=head1 DESCRIPTION

This role provides a wrapper around the AUTOLOAD routine which processes calls
to routines which don't exist.

=cut

=head1 LIBRARIES

This package uses type constraints defined by:

L<Data::Object::Library>

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 autoload

  AUTOLOAD(Str $arg1, Str $arg2, Object $self, Any @args) : Any

The AUTOLOAD method is called when the object doesn't have the method being
called. This method is called and handled automatically.

=over 4

=item AUTOLOAD example

  AUTOLOAD($class, $method, $self, @args);

=back

=cut

=head2 destroy

  DESTROY() : Any

The DESTROY method is called when the object goes out of scope. This method is
called and handled automatically.

=over 4

=item DESTROY example

  $self->DESTROY();

=back

=cut

=head1 CREDITS

Al Newkirk, C<+317>

Anthony Brummett, C<+10>

Adam Hopkins, C<+2>

José Joaquín Atria, C<+1>

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated here,
https://github.com/iamalnewkirk/do/blob/master/LICENSE.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/do/wiki>

L<Project|https://github.com/iamalnewkirk/do>

L<Initiatives|https://github.com/iamalnewkirk/do/projects>

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