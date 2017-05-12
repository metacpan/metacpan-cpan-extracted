package Froody::Argument::Number;

use strict;
use warnings;

use base 'Froody::Argument';

sub type { 'number' }

sub process {
  my ($class, $param, $check) = @_;
  $check->( 0 , "not a number")
    unless $param =~ m/^\d*$/;
  return $param;
}

1;

=head1 NAME

Froody::Argument::Number - Froody argument type handler for numeric arguments

=head1 AUTHORS

Copyright Fotango 2006.  All rights reserved.

Please see the main L<Froody> documentation for details of who has worked
on this project.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
