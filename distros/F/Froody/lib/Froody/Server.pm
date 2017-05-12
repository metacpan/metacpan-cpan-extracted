=head1 NAME

Froody::Server - baseclass for Froody::Server

=head1 DESCRIPTION

A Froody server. use as:

  #!/usr/bin/perl

  use warnings;
  use strict;
  
  use Froody::Server;
  Froody::Server->dispatch();

..in a CGI script that is a Froody endpoint.

This server accepts a CGI request as the Froody request, and will dispatch
the method, and return the XML of the response as the result of the HTTP
request. If the dispatcher throws an error, we catch it and wrap it in
a L<Froody::Response> object that represents the error.

You can pass a namespace to dispatch into to the L<dispatch()> call, to
override the default L<Froody::Dispatch> namespace. This is strongly
recommended, or your code will be fairly useless.

=cut

package Froody::Server;
use base qw( Froody::Base );

use warnings;
use strict;

use CGI;
use Scalar::Util qw( blessed );
use Params::Validate qw(:all);
use Froody::Dispatch;
use Froody::Response;

use Froody::Logger;
my $logger = get_logger("froody.server");

use Froody::Renderer::json;

# XXX: move down to autoload when doing autodetect
eval q{
    use Apache::Constants;
    use Froody::Request::Apache;
    use Froody::Server::Apache;
};

use Froody::Server::CGI;

=head1 METHODS

=over 4

=item dispatch()

Detects the environment that the Froody server is running under, assembles
a request, and dispatches it. Replies to the request with the XML response.

=cut

sub dispatch {
  my $class = shift;

  my $server = $class->server_class->new;
  my $request = $server->request_class->new;
  my $response = $class->dispatcher->dispatch(
      method => $request->method,
      params => $request->params || {},
  );
  
  # lookup what type of output the request asked for then send
  # the correct header and response rendered for that type
  my $type = $request->type;
  
  $server->send_header($response, $class->content_type_for_type($type));
  
  my $render_method = "render_$type";
  my $bytes = $response->$render_method;
  $server->send_body($bytes);
}

=item dispatcher()

Returns a dispatcher object set up for this server with the correct
request, response and error classes. I find this useful for getting
a dispatcher object for testing against when I have a server class with
lots of customization in.

=cut

our $D_CACHE;
sub dispatcher {
  my $class = shift;
  unless ($D_CACHE->{ ref($class) || $class }) {
    my $server = $class->server_class->new;
    my $dispatcher = $class->dispatch_class->new;
    $dispatcher->response_class($server->response_class)
               ->error_class($server->error_class);
    $dispatcher->error_style('response');
    $D_CACHE->{ ref($class) || $class } = $dispatcher;
  }
  return $D_CACHE->{ ref($class) || $class };
}

=item send_header($response, $content_type)

Implemented by subclasses.  Should send the headers to the client
using the content type passed.  Should call the $response's cookies
method and dtrt with that.

=item send_body($bytes)

Implmented by subclasses.  Sends the body of the connection.  $bytes should
be a rendered response.

=item handler

Handler for apache. Passes the request off to C<dispatch()> and returns
C<&Apache::OK> if it succeeds.

=cut

sub handler : method {
  my ($class, $r) = @_;
  $class->dispatch();
  return &Apache::OK;
}

=item content_type_for_type($type) / content_type_for_type($type, $header);

Gets and sets the header for a type of server.

=cut

my $h4t = {
	xml => "text/xml; charset=utf-8",
	json => 'text/json',
};

sub content_type_for_type {
   my $class = shift;
   my $type  = shift;
   unless (@_)
     { return $h4t->{ $type } or Froody::Error->throw('froody.type.notknown', "unknown type '$type'"); }
   $h4t->{ $type } = shift;
   return $class;
}


=back

=head2 Subclassing

There's serveral methods you might want to override in subclasses of
these.  In particular these methods define what helper classes this
uses:

=over

=item server_class

=item dispatch_class

=item request_class

=item error_class

=item response_class

=cut

sub server_class {
    return 'Froody::Server::Apache' if $ENV{MOD_PERL};
    return 'Froody::Server::CGI';
}

sub dispatch_class { "Froody::Dispatch" }

sub request_class { "Froody::Request" }

sub response_class { "Froody::Response" }

sub error_class { "Froody::Response::Error" }

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

L<Froody>, L<Froody::Dispatch>,
L<Froody::Server::Standalone>, L<Froody::Server::CGI>, L<Froody::Server::Apache>

=cut

1;
