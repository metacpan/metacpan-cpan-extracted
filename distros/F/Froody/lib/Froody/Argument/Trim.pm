package Froody::Argument::Trim;

use strict;
use warnings;

use base qw(Froody::Argument);

sub type {
  "trim";
}

sub process {
  my ($self, $param, $check ) = @_;

  $param =~ s/^\s+//;
  $param =~ s/\s+$//;
  
  return $param;
}

1;
__END__
=head1 NAME

Froody::Argument::Trim - trim leading and trailing whitespace

=head1 AUTHORS

Copyright Fotango 2006.  All rights reserved.

Please see the main L<Froody> documentation for details of who has worked
on this project.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
