=head1 NAME

Froody::Apache

=head1 DESCRIPTION

Froody::Apache

=head2 Methods

=over

=cut

package Froody::Server::Apache;
use warnings;
use strict;
use base qw( Froody::Server );

eval q{
  use Apache::Constants;
  use Apache::Cookie;
};

use Froody::Request::Apache;
sub request_class { "Froody::Request::Apache" }

sub send_header {
  my $class = shift;
  my $response = shift;
  my $content_type = shift;

  my $r = Apache->request();

  if (my $cookies = $response->cookie) {
    warn "Baking cookies";
    for my $c ( ref($cookies) ? @$cookies : ($cookies) ) {
      my $cookie = Apache::Cookie->new( $r, %{ $c } );
      $cookie->bake;
    }
  }
  $r->header_out("Cache-Control" => "no-cache");
  $r->send_http_header($content_type || 'application/xml');
}

sub send_body {
  my $class = shift;
  my $bytes = shift;

  my $r = Apache->request();
  $r->print($bytes)
}

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

L<Froody>, L<Froody::Request>

=cut

1;
