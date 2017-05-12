package Froody::Argument::Text;

use strict;
use warnings;

use base 'Froody::Argument';

sub type { 'text' }

# process_text is documented
sub process {
  my ($class, $param) = @_;
  return $param;
}

1;

=head1 NAME

Froody::Argument::Text - Froody argument type handler for raw text

=head1 AUTHORS

Copyright Fotango 2006.  All rights reserved.

Please see the main L<Froody> documentation for details of who has worked
on this project.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
