package McBain::WithWebSocket;

# ABSTRACT: Load a McBain API as a WebSocket server

use warnings;
use strict;

use Carp;
use JSON;
use Net::WebSocket::Server;

our $VERSION = "2.000000";
$VERSION = eval $VERSION;

my $json = JSON->new->convert_blessed;

=head1 NAME
 
McBain::WithWebSocket - Load a McBain API as a WebSocket server

=head1 SYNOPSIS

	# write your API as you normally would, and create
	# a simple server script:

	#!/usr/bin/perl -w

	use warnings;
	use strict;
	use MyAPI -withWebSocket;

	MyAPI->start(80); # default port is 8080

	# if your API is object oriented
	MyAPI->new(%attrs)->start(80);

=head1 DESCRIPTION

C<McBain::WithWebSocket> turns your L<McBain> API into a L<WebSocket|https://en.wikipedia.org/wiki/WebSocket>
server using L<Net::WebSocket::Server>.

The created server will be a JSON-in JSON-out service. When a client sends a message to
the server, it is expected to be a JSON string, which will be converted into a hash-ref
and serve as the payload for the API. The payload must have a C<path> key, which holds
the complete path of the route/method to invoke (for example, C<GET:/math/sum>). The
results from the API will be formatted into JSON as well and sent back to the client.

Note that if an API method does not return a hash-ref, this runner module will automatically
turn it into a hash-ref to ensure that conversion into JSON will be possible. The created
hash-ref will have one key - holding the method's name, with whatever was returned from the
method as its value. For example, if method C<GET:/divide> in topic C</math> returns an
integer (say 7), then the client will get the JSON C<{ "GET:/math/divide": 7 }>. To avoid this
behavior, make sure your API's methods return hash-refs.

=head2 EXAMPLE CLIENT

I haven't succeeded in creating a Perl WebSocket client using any of the related modules on
CPAN. Documentation in this area seems to be extremely lacking. On the other hand, I created
a very simply client with NodeJS in about two minutes. If you need to test your C<McBain> API
running as a WebSocket server, and have a similar problem, take a look at the C<client.js>
file in the examples directory of this distribution.

=head2 SUPPORTED HTTP METHODS

This runner support all methods natively supported by L<McBain>. That is: C<GET>, C<PUT>,
C<POST>, C<DELETE> and C<OPTIONS>.

The C<OPTIONS> method is special. It returns a hash-ref of methods supported by a specific
route, including description and parameter definitions, if any. See L<McBain/"OPTIONS-REQUESTS">
for more information.

=head1 METHODS EXPORTED TO YOUR API

=head2 start( [ $port ] )

Starts the WebSocket server, listening on the supplied port. If C<$port> is not provided,
C<8080> is used by default.

=head1 METHODS REQUIRED BY MCBAIN

=head2 init( $target )

Creates and exports the L<start()|/"start( [ $port ] )"> method for your API's root package.

=cut

sub init {
	my ($class, $target) = @_;

	if ($target->is_root) {
		no strict 'refs';
		*{"${target}::start"} = sub {
			my ($pkg, $port) = @_;

			Net::WebSocket::Server->new(
				listen => $port || 8080,
				on_connect => sub {
					my ($serv, $conn) = @_;

					$conn->on(
						utf8 => sub {
							my ($conn, $payload) = @_;

							$conn->send_utf8($pkg->call($payload));
						}
					);
				}
			)->start;
		};
	}
}

=head2 generate_env( $req )

Receives the request JSON and creates C<McBain>'s standard env
hash-ref from it.

=cut

sub generate_env {
	my ($self, $payload) = @_;

	$payload = $json->decode($payload);

	confess { code => 400, error => "Namespace must match <METHOD>:<ROUTE> where METHOD is one of GET, POST, PUT, DELETE or OPTIONS" }
		unless $payload->{path} =~ m/^(GET|POST|PUT|DELETE|OPTIONS):[^:]+$/;

	my ($method, $route) = split(/:/, delete($payload->{path}));

	return {
		METHOD	=> $method,
		ROUTE		=> $route,
		PAYLOAD	=> $payload
	};
}

=head2 generate_res( $env, $res )

Converts the result from an API method in JSON. Read the discussion under
L</"DESCRIPTION"> for more info.

=cut

sub generate_res {
	my ($self, $env, $res) = @_;

	$res = { $env->{METHOD}.':'.$env->{ROUTE} => $res }
		unless ref $res eq 'HASH';

	return $json->encode($res);
}

=head2 handle_exception( $err )

Formats exceptions into JSON.

=cut

sub handle_exception {
	my ($class, $err) = @_;

	return $json->encode($err);
}

=head1 CONFIGURATION AND ENVIRONMENT
   
No configuration files are required.
 
=head1 DEPENDENCIES
 
C<McBain::WithWebSocket> depends on the following CPAN modules:
 
=over

=item * L<Carp>

=item * L<JSON>
 
=item * L<Net::WebSocket::Server>
 
=back

=head1 INCOMPATIBILITIES WITH OTHER MODULES

None reported.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-McBain-WithWebSocket@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=McBain-WithWebSocket>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc McBain::WithWebSocket

You can also look for information at:

=over 4
 
=item * RT: CPAN's request tracker
 
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=McBain-WithWebSocket>
 
=item * AnnoCPAN: Annotated CPAN documentation
 
L<http://annocpan.org/dist/McBain-WithWebSocket>
 
=item * CPAN Ratings
 
L<http://cpanratings.perl.org/d/McBain-WithWebSocket>
 
=item * Search CPAN
 
L<http://search.cpan.org/dist/McBain-WithWebSocket/>
 
=back
 
=head1 AUTHOR
 
Ido Perlmuter <ido@ido50.net>
 
=head1 LICENSE AND COPYRIGHT
 
Copyright (c) 2014, Ido Perlmuter C<< ido@ido50.net >>.
 
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, either version
5.8.1 or any later version. See L<perlartistic|perlartistic>
and L<perlgpl|perlgpl>.
 
The full text of the license can be found in the
LICENSE file included with this module.
 
=head1 DISCLAIMER OF WARRANTY
 
BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.
 
IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
 
=cut

1;
__END__
