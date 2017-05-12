package McBain::WithPSGI;

# ABSTRACT: Load a McBain API as a RESTful PSGI web service

use warnings;
use strict;

use Carp;
use JSON::MaybeXS qw/JSON/;
use Plack::Request;
use Plack::Component;

our $VERSION = "2.001001";
$VERSION = eval $VERSION;

my $json = JSON->new->utf8->allow_blessed->convert_blessed;

=head1 NAME
 
McBain::WithPSGI - Load a McBain API as a RESTful PSGI web service

=head1 SYNOPSIS

	# write your API as you normally would, and create
	# a simple psgi file:

	#!/usr/bin/perl -w

	use warnings;
	use strict;
	use MyAPI -withPSGI;

	my $app = MyAPI->to_app;

=head1 DESCRIPTION

C<McBain::WithPSGI> turns your L<McBain> API into a RESTful L<PSGI> web service based on
L<Plack>, thus making C<McBain> a web application framework.

The created web service will be a JSON-in JSON-out service. Requests to your application
are expected to have a C<Content-Type> of C<application/json; charset=UTF-8>. The JSON body
of a request will be the payload. The results of the API will be formatted into JSON as
well.

Note that if an API method does not return a hash-ref, this runner module will automatically
turn it into a hash-ref to ensure that conversion into JSON will be possible. The created
hash-ref will have one key - holding the method's name, with whatever was returned from the
method as its value. For example, if method C<GET:/divide> in topic C</math> returns an
integer (say 7), then the client will get the JSON C<{ "GET:/math/divide": 7 }>.

=head2 SUPPORTED HTTP METHODS

This runner support all methods natively supported by L<McBain>. That is: C<GET>, C<PUT>,
C<POST>, C<DELETE> and C<OPTIONS>. To add support for C<HEAD> requests, use L<Plack::Middleware::Head>.

The C<OPTIONS> method is special. It returns a list of all HTTP methods allowed by a specific
route (in the C<Allow> header). The response body will be the same hash-ref returned by
C<McBain> for C<OPTIONS> requests, JSON encoded.

=head2 CAVEATS AND CONSIDERATIONS

The HTTP protocol does not allow C<GET> requests to have content, so your C<GET> routes will
not be able to receive parameters from a request's JSON body as all other methods do.
If your C<GET> routes I<must> receive parameters (for example, you might have a route that
returns a list of objects with support for pagination), C<McBain::WithPSGI> supports parameters
from the query string. They will be validated like all parameters, and they can be used in
non-C<GET> requests too. Note that they take precedence over body parameters.

The downside to this is that the parameters cannot be complex structures, though if the query string
defines a certain key several times, its generated value will be an array reference. For example,
let's look at the following route:

	get '/params_from_query' => (
		params => {
			some_string => { required => 1 },
			some_array => { array => 1, min_length => 2 }
		},
		cb => sub {
			my ($api, $params) = @_;
			return $params;
		}
	);

This route isn't particularly interesting, as it simply returns the parameters it receives. It does,
however, enforce the existence of the C<some_string> parameter, and expects C<some_array> to be an
array reference of at least 2 items. A request to C</params_from_query?some_string=this_is_my_string&some_array=Hello&some_array=World> will yield the
following result:

	{ "some_string": "this_is_my_string", "some_array": ["Hello", "World"] }

=head1 METHODS EXPORTED TO YOUR API

None.

=head1 METHODS REQUIRED BY MCBAIN

=head2 init( $target )

Makes the root topic of your API inherit L<Plack::Component>, so that it
officially becomes a Plack app. This will provide your API with the C<to_app()>
method.

=cut

sub init {
	my ($class, $target) = @_;

	if ($target->is_root) {
		no strict 'refs';
		push(@{"${target}::ISA"}, 'Plack::Component');
	}
}

=head2 generate_env( $psgi_env )

Receives the PSGI env hash-ref and creates McBain's standard env hash-ref
from it.

=cut

sub generate_env {
	my ($self, $psgi_env) = @_;

	my $req = Plack::Request->new($psgi_env);

	my $payload = $req->content ? $json->decode($req->content) : {};

	# also take parameters from query string, if any
	# and let them have precedence over request content
	my $query = $req->query_parameters->mixed;
	foreach (keys %$query) {
		$payload->{$_} = $query->{$_};
	}

	return {
		METHOD	=> $req->method,
		ROUTE		=> $req->path,
		PAYLOAD	=> $payload
	};
}

=head2 generate_res( $env, $res )

Converts the result of an API method to JSON, and returns a standard PSGI
response array-ref.

=cut

sub generate_res {
	my ($self, $env, $res) = @_;

	my @headers = ('Content-Type' => 'application/json; charset=UTF-8');

	if ($env->{METHOD} eq 'OPTIONS') {
		push(@headers, 'Allow' => join(',', keys %$res));
	}

	$res = { $env->{METHOD}.':'.$env->{ROUTE} => $res }
		unless ref $res eq 'HASH';

	return [200, \@headers, [$json->encode($res)]];
}

=head2 handle_exception( $err )

Formats exceptions into JSON and returns a standard PSGI array-ref.

=cut

sub handle_exception {
	my ($class, $err) = @_;

	return [delete($err->{code}), ['Content-Type' => 'application/json; charset=UTF-8'], [$json->encode($err)]];
}

=head1 CONFIGURATION AND ENVIRONMENT

No configuration files are required.

=head1 DEPENDENCIES
 
C<McBain::WithPSGI> depends on the following CPAN modules:
 
=over

=item * L<Carp>

=item * L<JSON::MaybeXS>
 
=item * L<Plack>
 
=back

=head1 INCOMPATIBILITIES WITH OTHER MODULES

None reported.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-McBain-WithPSGI@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=McBain-WithPSGI>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc McBain::WithPSGI

You can also look for information at:

=over 4
 
=item * RT: CPAN's request tracker
 
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=McBain-WithPSGI>
 
=item * AnnoCPAN: Annotated CPAN documentation
 
L<http://annocpan.org/dist/McBain-WithPSGI>
 
=item * CPAN Ratings
 
L<http://cpanratings.perl.org/d/McBain-WithPSGI>
 
=item * Search CPAN
 
L<http://search.cpan.org/dist/McBain-WithPSGI/>
 
=back
 
=head1 AUTHOR
 
Ido Perlmuter <ido@ido50.net>
 
=head1 LICENSE AND COPYRIGHT
 
Copyright (c) 2013-2015, Ido Perlmuter C<< ido@ido50.net >>.
 
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
