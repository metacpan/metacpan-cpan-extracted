package McBain::WithZeroMQ;

# ABSTRACT: Load a McBain API as a ZeroMQ service

use warnings;
use strict;
use 5.10.0;

use Carp;
use JSON;
use ZMQ::LibZMQ3;
use ZMQ::Constants qw(ZMQ_REP);

our $VERSION = "2.000000";
$VERSION = eval $VERSION;

my $json = JSON->new->utf8->convert_blessed;
my $MAX_MSGLEN = 255;

=head1 NAME
 
McBain::WithZeroMQ - Load a McBain API as a ZeroMQ service

=head1 SYNOPSIS

	# write your API as you normally would, and create
	# a simple start-up script:

	#!/usr/bin/perl -w

	use warnings;
	use strict;
	use MyAPI -withZeroMQ;

	MyAPI->work('localhost', 5560);

=head1 DESCRIPTION

C<McBain::WithZeroMQ> turns your L<McBain> API into a L<ZeroMQ REP worker|ZMQ::LibZMQ3>,
making it easy to consume your APIs with ZMQ REQ clients. The generated worker code is based
on the L<request-reply worker example|http://zguide.zeromq.org/pl:rrworker> in the L<ZeroMQ guide|http://zguide.zeromq.org/page:all>. Note that the ZeroMQ request-reply pattern requires
a broker. The guide also has examples for L<a broker|http://zguide.zeromq.org/pl:rrbroker>
and L<a client|http://zguide.zeromq.org/pl:rrclient>, though two scripts based on these examples
are also provided with this module - more for example than actual usage - see L<mcbain-zmq-broker>
and L<mcbain-zmq-client>, respectively.

The workers created by this module receive payloads in JSON format, and convert them into the 
hash-refs your API's methods expect to receive. The payload must have a C<path> key, which holds
the complete path of the route/method to invoke (for example, C<GET:/math/sum>). Results are sent
back to the clients in JSON as well. Note that if an API method does not return a hash-ref, this runner
module will automatically turn it into a hash-ref to ensure that conversion into JSON will
be possible. The created hash-ref will have one key - holding the method's name, with whatever
was returned from the method as its value. For example, if method C<GET:/divide> in topic
C</math> returns an integer (say 7), then the client will get the JSON C<{ "GET:/math/divide": 7 }>.
To avoid, make sure your API's methods return hash-refs.

=head1 METHODS EXPORTED TO YOUR API

=head2 work( [ $host, $port ] )

Connects the ZeroMQ worker created by the module to the ZeroMQ broker
listening at the host and port provided. If none are provided, C<localhost>
and C<5560> are used, respectively.

The method never returns, so that the worker listens for jobs continuously.

=head1 METHODS REQUIRED BY MCBAIN

This runner module implements the following methods required by C<McBain>:

=head2 init( )

Creates the L</"work( $host, $port )"> method for the root topic of the API.

=cut

sub init {
	my ($class, $target) = @_;

	if ($target->is_root) {
		no strict 'refs';
		*{"${target}::work"} = sub {
			my ($pkg, $host, $port) = @_;

			$host ||= 'localhost';
			$port ||= 5560;

			my $context = zmq_init();

			# Socket to talk to clients
			my $responder = zmq_socket($context, ZMQ_REP);
			zmq_connect($responder, "tcp://${host}:${port}");

			while (1) {
				# Wait for next request from client
				my $size = zmq_recv($responder, my $buf, $MAX_MSGLEN);
				return undef if $size < 0;
				my $payload = substr($buf, 0, $size);

				# Process the request
				my $res = $pkg->call($payload);

				# Send reply back to client
				zmq_send($responder, $res, -1);
			}
		};
	}
}

=head2 generate_env( $job )

Receives the JSON payload and generates C<McBain>'s standard env
hash-ref from it.

=cut

sub generate_env {
	my ($self, $payload) = @_;

	$payload = $json->decode($payload);

	confess { code => 400, error => "Payload does not define path to invoke" }
		unless $payload->{path};

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

	return encode_json($res);
}

=head2 handle_exception( $err )

Simply calls C<< $job->send_fail >> to return a job failed
status to the client.

=cut

sub handle_exception {
	my ($class, $err) = @_;

	return $json->encode($err);
}

=head1 CONFIGURATION AND ENVIRONMENT
   
No configuration files are required.
 
=head1 DEPENDENCIES
 
C<McBain::WithZeroMQ> depends on the following CPAN modules:
 
=over

=item * L<Carp>
 
=item * L<ZMQ::Constants>

=item * L<ZMQ::LibZMQ3>

=item * L<JSON>
 
=back

=head1 INCOMPATIBILITIES WITH OTHER MODULES

None reported.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-McBain-WithZeroMQ@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=McBain-WithZeroMQ>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc McBain::WithZeroMQ

You can also look for information at:

=over 4
 
=item * RT: CPAN's request tracker
 
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=McBain-WithZeroMQ>
 
=item * AnnoCPAN: Annotated CPAN documentation
 
L<http://annocpan.org/dist/McBain-WithZeroMQ>
 
=item * CPAN Ratings
 
L<http://cpanratings.perl.org/d/McBain-WithZeroMQ>
 
=item * Search CPAN
 
L<http://search.cpan.org/dist/McBain-WithZeroMQ/>
 
=back
 
=head1 AUTHOR
 
Ido Perlmuter <ido@ido50.net>

=head1 SEE ALSO

L<McBain>

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
