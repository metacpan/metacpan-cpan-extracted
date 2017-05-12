package Froody::Response::String;
use base qw(Froody::Response);

use warnings;
use strict;

use Encode;

=head1 NAME

Froody::Response::String - create a response from a string

=head1 SYNOPSIS

  my $response = Froody::Response::String->new()
                                         ->structure($froody_method)
                                         ->set_string($string)
  print $response->render;

=head1 DESCRIPTION

This is a concrete implementation of Froody::Response.  It takes its input
from a valid Perl string, which you can set with C<set_string>:

  my $frs = Froody::Response::String->new();
  $frs->structure($froody_method);
  $frs->set_string( <<ENDOFRSP );
  <rsp stat="ok">
    <monger>L\x{e9}on Brocard</monger>
  </rsp>
  ENDOFRSP

Note that there's no XML declaration header there - one will be added
automatically.  You can also set the bytes directly:

  my $frs = Froody::Response::String->new();
  $frs->structure($froody_method);
  $frs->set_bytes( <<ENDOFRSP );
  <?xml version="1.0" encoding="utf-8" ?>
  <rsp stat="ok">
    <monger>L\x{c3}\x{a9}on Brocard</monger>
  </rsp>
  ENDOFRSP

In this case you are required to include the XML declaration header (as we
can't create one for you as we have no idea what encoding scheme the bytes are
using)

=cut

# set_string is documented
sub set_string {
  my $self = shift;
  $self->{bytes} = qq{<?xml version="1.0" encoding="utf-8" ?>\n};
  $self->{bytes} .= Encode::encode("utf-8", shift());
  return $self;
}

# set_bytes is documented
sub set_bytes {
  my $self = shift;
  $self->{bytes} = shift;
  return $self;
}

# just return the bytes
sub render { my $self = shift; $self->{bytes} }

=head2 Converting other Responses to Froody::Response::String objects

Once you've loaded this class you can automatically convert other
Froody::Response class instances to Froody::Response::String objects with
the C<as_string> method.

  use Froody::Response::String;
  my $string = Froody::Response::Terse
      ->new()
      ->structure($froody_method)
      ->content(...)
      ->as_string;
  print ref($string);  # prints "Froody::Response::String"

=cut

# rendering this class
# as_string is documented
sub as_string { return $_[0] }
sub Froody::Response::as_string
{
  my $self = shift;
  my $str = Froody::Response::String->new();
  $str->set_bytes($self->render);
  return $str;
}

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

L<Froody>, L<Froody::Response>

=cut

1;
