package Froody::Argument;
use strict;
use warnings;

use Module::Pluggable search_path => 'Froody::Argument',
                      inner => 1,
                      sub_name => 'argument_types';
                      
sub type {
  Froody::Error->throw('froody.unimplemented', "Beat someone for not finishing things");
}

our $types;

sub _types {
  my $self = shift;

  return $types if defined $types;
  
  return $types = { map { _register_type_names($_) } $self->argument_types };
}

sub _register_type_names {
  my $handler = shift;
  unless ($handler->can('type')) {
     return (); 
  }
  return map { $_ => $handler } $handler->type;
}

BEGIN {
  __PACKAGE__->_types(); 
}


sub process {
  my ($class, $type, $param, $check) = @_;
  
  my $validator = $class->_types()->{$type}
    or return $param;
  
  my $f = $validator->can("process")
    or return $param;

  $f->($class, $param, $check);
}

sub add_path {
  my ($class, $path) = @_;

  $types = undef;
  $class->SUPER::search_path(add => $path);
}

1;

=head1 NAME

Froody::Argument - Froody argument type handler

=head1 DESCRIPTION

If you want to register a new type handler with Froody, create a
module in the Froody::Argument::* namespace. It will automagically be
registered with the type handler framework.

=head1 METHODS

Froody::Argument plugins are required to implement the following
methods:

=over

=item type 

The name of the type

=item process($param_value, $check_callback)

Handles validation for a given type.  If there's a possiblity of
failure, the C<$check_callback> should be called. It takes two
arguments - a test value (a true value for passing), and 
a message which describes how the value failed type validation.

=item add_path($module name) 

Register a new set of type handlers under the path indicated by
C<$module name>.

=back

=head1 AUTHORS

Copyright Fotango 2006.  All rights reserved.

Please see the main L<Froody> documentation for details of who has worked
on this project.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
