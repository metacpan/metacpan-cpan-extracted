=head1 NAME

Froody::Base - base class for Froody classes

=head1 DESCRIPTION

A base class for all Froody classes, provides useful methods.

=head1 METHODS

=over 4

=cut

package Froody::Base;

use warnings;
use strict;

use Params::Validate ();
use Froody::Error;

use Froody::Logger;
my $logger = get_logger("froody.base");

use base qw( Class::Accessor::Chained::Fast );

use UNIVERSAL::require;

use Carp qw(croak);

=item new()

A constructor.  Doesn't take any parameters.  Throws an exception if some
are passed.

=cut


sub new
{
  my $class = shift;
  
  my $fields = shift || {};
  
  my $self = $class->SUPER::new({(ref($class) ? %$class : ()), 
                                 %$fields
                                });
  $self->init;
  return $self;
}

=item init

Called from new.  Designed to be overridden.  Remember to call your
parent init!

=cut

sub init { return }

=item validate_class(@_, { ... })

A utility wrapper around Params::Validate that also makes sure that it's
being called as a class method, eg.

  sub class_method {
    my $class = shift;
    my %args = $class->validate_class(@_, { ... } )
    ...

see L<Params::Validate> for details on the function.

=cut

sub validate_class {
  my $class = shift;
  Froody::Error->throw("perl.methodcall.class", 
    "A class method was called in an instance context") if ref($class);
  $class->_validate(@_);
}

=item validate_object(@_, { ... })

A utility wrapper around Params::Validate that also makes sure that it's
being called as an object method, eg.

  sub object_method {
    my $self = shift;
    my %args = $self->validate_class(@_, { ... } )
    ...

see L<Params::Validate> for details on the function.

=cut

sub validate_object {
  my $self = shift;
  Froody::Error->throw("perl.methodcall.instance",
    "A instance method was called in object context ") unless ref($self);
  $self->_validate(@_);
}

=item validate_either(@_, { ... })

A utility wrapper around Params::Validate that does nothing else, for
methods that can be class or object methods.

  sub class_method {
    my $class = shift;
    my %args = $class->validate_either(@_, { ... } )
    ...

see L<Params::Validate> for details on the function.

=cut

sub validate_either {
  my $self = shift;
  $self->_validate(@_);
}

sub _validate {
  my $class = shift;
  my $spec = pop || {};
  local $Carp::CarpLevel = 4; # hide internals.
  my %h = eval { Params::Validate::validate(@_, $spec) };
  # TODO - it would be really nice to actually throw meta-information
  # about what is missing, what doesn't validate, etc..
  if ($@) {
    Froody::Error->throw("perl.methodcall.param", $@);
  }
  return %h;
}

1;

=back

=head1 BUGS

None known.

Please report any bugs you find via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Froody>

=head1 AUTHOR

Copyright Fotango 2005.  All rights reserved.

Please see the main L<Froody> documentation for details of who has worked
on this project.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Froody>

=cut

1;
