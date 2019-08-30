package Data::Object::Role::Proxyable;

use 5.014;

use strict;
use warnings;

use Moo::Role;

use Carp ();

our $VERSION = '1.09'; # VERSION

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

=head1 METHODS

This package implements the following methods.

=cut

=head2 autoload

  AUTOLOAD(Str $arg1, Str $arg2, Any @args) : Any

The AUTOLOAD method is called when the object doesn't have the method being
called. This method is called and handled automatically.

=over 4

=item AUTOLOAD example

  $self->AUTOLOAD($class, $method, @args);

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