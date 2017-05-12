package Froody::Argument::CSV;

use strict;
use warnings;

use base 'Froody::Argument';

sub type { 'csv' }

sub process {
  my ($class, $param, $check) = @_;
  Carp::cluck unless defined $param;
  return ref($param) eq 'ARRAY' ? $param : [ split(/\s*,\s*/, $param) ];
}

1;

=head1 NAME

Froody::Argument::CSV - Froody argument type handler for comma seperated value records

=head1 AUTHORS

Copyright Fotango 2006.  All rights reserved.

Please see the main L<Froody> documentation for details of who has worked
on this project.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
