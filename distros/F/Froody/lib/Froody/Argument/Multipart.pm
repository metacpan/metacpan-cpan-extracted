package Froody::Argument::Multipart;
use strict;
use warnings;
use base 'Froody::Argument';
use Carp qw( croak );

sub type { 'multipart' , 'file' }

sub process {
  my ($class, $param, $check) = @_;

  # Special case - if we're passed ['filename'] as the arg, treat
  # it as a file upload. Mostly for testing purposes.
  if (ref( $param ) eq 'ARRAY' and !ref($param->[0]) ) {
    my @upload = @$param;
    croak("need a filename for now (TODO)") unless $upload[0];
    open my $fh, $upload[0] or croak("Can't open file $upload[0]: $!");
    return [Froody::Upload->new
                          ->fh($fh)
                          ->filename($upload[0])
                          ->client_filename($upload[1] || $upload[0])];

  }

  if (ref($param) ne 'ARRAY') {
    $param = [$param];
  }

  my $i = 0;
  for my $val (@$param) {
    $check->(  ref $val eq 'Froody::Upload',
                "Element $i is not an upload record");
    ++$i;
  }

  return $param;
}

1;

=head1 NAME

Froody::Argument::Multipart - Froody argument type handler for multipart attachments

=head1 AUTHORS

Copyright Fotango 2006.  All rights reserved.

Please see the main L<Froody> documentation for details of who has worked
on this project.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
