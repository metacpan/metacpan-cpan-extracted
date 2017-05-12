=head1 NAME

Froody::CGI

=head1 DESCRIPTION

Froody for cgi environment

=cut

package Froody::Server::CGI;
use warnings;
use strict;
use base qw( Froody::Server );
use CGI;
use Scalar::Util qw( blessed );
use Params::Validate qw(:all);

use Froody::Dispatch;
use Froody::Response;

use Froody::Request::CGI;
sub request_class { "Froody::Request::CGI" }

=head1 METHODS

=over 4

=cut

sub send_header
{
  my $class = shift;
  my $response = shift;
  my $content_type = shift;
  
  print CGI::header(
    -type => $content_type,
    $response->cookie ? ( -cookie => $response->cookie ) : (),
  );
}

sub send_body
{
  my $class = shift;
  my $bytes = shift;
  
  print $bytes;
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

L<Froody>, L<Froody::Server>

=cut

1;

1;

