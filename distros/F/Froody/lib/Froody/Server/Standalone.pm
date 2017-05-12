package Froody::Server::Standalone;
use base qw(HTTP::Server::Simple::CGI);

=head1 NAME

Froody::Server::Standalone - standalone server for Froody

=head1 SYNOPSIS

  use Froody::Server::Standalone;
  my $server = Froody::Server::Standalone->new();
  $server->port(4242);
  $server->run;

  # now you'll have a froody server listening on port 4242

=head1 DESCRIPTION

Froody::Server::Standalone is a subvlass of HTTP::Server::Simple::CGI
that has been altered to serve Froody requests

Currently it uses a global dispatcher stored in the global variable
$Froody::Server::Standalone::dispatcher.  If no dispatcher exists when the
first handler comes in one is created automatically and put into this
variable.

This code is very likely to change, but that's the current behavior.

=cut

use Froody;

use strict;
use warnings;

use HTTP::Date;
use Froody::Request::CGI;
use Froody::Dispatch;

use Froody::Server;

sub handle_request
{
  my ($self, $cgi) = @_;
 
  # what are we asking for?
  my $request = Froody::Request::CGI->new($cgi);
  my $type = $request->type;
  
  # dispatch 
  $self->dispatcher->error_style("response");
  my $response = eval {  #Don't allow the server to die on unhandled exceptions.
    $self->dispatcher->dispatch(
        method => $request->method,
        params => $request->params,
    );
  }; #
  
  unless ($@) {
      # send the data back to the browser
      my $method = "render_$type";
      return $self->_send_bytes(
        "200 OK",
        Froody::Server->content_type_for_type($type), 
        $response->$method
      );
  } else {
    $self->_send_bytes("500 Server Error", "text/plain", "$@");
  }
}

=head2 config

=cut

sub config {
    my $self = shift;
    $self->{_dispatcher} = Froody::Dispatch->config(@_);
}

=head2 dispatcher

=cut

sub dispatcher {
  my $self = shift;
  if (@_) {
    $self->{_dispatcher} = shift;
    return $self;
  }
  return $self->{_dispatcher} ||= Froody::Dispatch->new;
}

sub _send_bytes
{
  my $self = shift;
  my $status = shift;
  my $content_type = shift;
  my $bytes = shift;
  my $time = time2str();
  
  # server headers
  print "HTTP/1.0 $status\r\n";

  # standard headers
  print "Content-Type: $content_type\r\n";
  print "Content-Length: ", length($bytes), "\r\n";

  # froody headers (for debugging)
  print "X-Froody-Version: ".$Froody::VERSION."\r\n";
  print "X-Towel: Over drain.\r\n";
  
  # no caching
  print "Cache-Control: no-cache\r\n";
  print "Date: $time\r\n";
  print "Expires: $time\r\n";
  
  # seperator
  print "\r\n";
 
  # content
  print $bytes;
  return;
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

L<Froody>, L<Froody::Dispatch>, L<Froody::Repository>

=cut



1;
