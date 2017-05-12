package Froody::Argument::Email;

use strict;
use warnings;

use base qw(Froody::Argument);
use Email::Valid;

sub type {
  "email";
}

sub process {
  my ($self, $param, $check ) = @_;
  
  my $email = Email::Valid->address($param);
  
  $check->( $email && $email eq $param, "Email not valid" );

  return $param;
}

1;
__END__
=head1 NAME

Froody::Argument::Email - trim leading and trailing whitespace

=head1 AUTHORS

Copyright Fotango 2006.  All rights reserved.

Please see the main L<Froody> documentation for details of who has worked
on this project.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
