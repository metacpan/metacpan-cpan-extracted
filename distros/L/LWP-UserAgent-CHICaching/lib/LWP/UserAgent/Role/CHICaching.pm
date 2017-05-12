package LWP::UserAgent::Role::CHICaching;

use 5.006000;
use CHI;
use Moo::Role;
use Types::Standard qw(Str Bool Ref InstanceOf);
use Types::URI -all;

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.04';

=pod

=encoding utf-8

=head1 NAME

LWP::UserAgent::Role::CHICaching - A role to allow LWP::UserAgent to cache with CHI

=head1 SYNOPSIS

Compose it into a class, e.g.

  package LWP::UserAgent::MyCacher;
  use Moo;
  extends 'LWP::UserAgent';
  with 'LWP::UserAgent::Role::CHICaching',
       'LWP::UserAgent::Role::CHICaching::SimpleKeyGen',
       'LWP::UserAgent::Role::CHICaching::SimpleMungeResponse';


=head1 DESCRIPTION

This is a role for creating caching user agents. When the client makes
a request to the server, sometimes the response should be cached, so
that no actual request has to be sent at all, or possibly just a
request to validate the cache. HTTP 1.1 defines how to do this. This
role makes it possible to use the very flexible L<CHI> module to
manage such a cache. See L<LWP::UserAgent::CHICaching> for a finished
class you can use.


=head2 Attributes and Methods

=over

=item C<< cache >>

Used to set the C<CHI> object to be used as cache in the constructor.



=item C<< request_uri >>

The Request-URI of the request. When set, it will clear the C<key>,
but should probably be left to be used internally for now.

=item C<< request >>

Wrapping L<LWP::UserAgent>'s request method.

=item C<< is_shared >>

A boolean value to set whether the cache can be shared. The default is
that it is.

=item C<< heuristics_opts >>

A hashref that is passed to the C<freshness_lifetime> method of
L<HTTP::Response>, and used to determine the behaviour of the
heuristic lifetime. By default, heuristic freshness lifetime is off,
only standards-compliant freshness lifetime (i.e. based on the
C<Cache-Control> and C<Expires> headers) are used.

=back

=head2 Implemented elsewhere

The following are required by this role, but implemented
elsewhere. See L<LWP::UserAgent::Role::CHICaching::SimpleKeyGen> and
L<LWP::UserAgent::Role::CHICaching::SimpleMungeResponse> for further explanations.

=over

=item C<< key >>, C<< clear_key >>

The key to use for a response.

=item C<< cache_vary($response) >>

A method that returns true if the response may be cached even if it
contains a C<Vary> header, false otherwise. The L<HTTP::Response>
object will be passed to it as a parameter.

=item C<< cache_set($response, $expires_in) >>

A method that takes the L<HTTP::Response> from the client and an
expires time in seconds and set the actual cache.

=item C<< finalize($cached) >>

A method that takes the cached entry as an argument, and will return a
L<HTTP::Response> to return to the client.

=back

=cut

has cache => (
				  is => 'ro',
				  isa => InstanceOf['CHI::Driver'],
				  required => 1,
				 );


requires 'key';
requires 'cache_vary';
requires 'finalize';
requires 'cache_set';

has request_uri => (
						  is =>'rw',
						  isa => Uri,
						  coerce => 1,
						  trigger => sub { shift->clear_key },
						 );

has is_shared => (
						is => 'rw',
						isa => Bool,
						default => 1);

has heuristics_opts => (
								is => 'rw',
								isa => Ref['HASH'],
								default => sub {return {heuristic_expiry => 0}}
							  );

around request => sub {
	my ($orig, $self) = (shift, shift);
	my @args = @_;
	my $request = $args[0];

	return $self->$orig(@args) if $request->method ne 'GET';

	$self->request_uri($request->uri);

	my $cached = $self->cache->get($self->key); # CHI will take care of expiration

	my $expires_in = 0;
	if (defined($cached)) {
		######## Here, we decide whether to reuse a cached response.
		######## The standard describing this is:
		######## http://tools.ietf.org/html/rfc7234#section-4
		$cached->header('Age' => $cached->current_age);
		return $self->finalize($cached); # TODO: Deal with no-transform
	} else {
		my $res = $self->$orig(@args);

		######## Here, we decide whether to store a response
		######## This is defined in:
		######## http://tools.ietf.org/html/rfc7234#section-3
		# Quoting the standard

		## A cache MUST NOT store a response to any request, unless:
		
		## o  The request method is understood by the cache and defined as being
		##    cacheable, and
		# TODO: Ok, only GET supported, see above

		## o  the response status code is understood by the cache, and
		if ($res->is_success) { # TODO: Cache only successful responses for now

			# First, we deal superficially with the Vary header, for the
			# full complexity see
			# http://tools.ietf.org/html/rfc7234#section-4.1
			return $res unless ($self->cache_vary($res));

			my $cc = join('|',$res->header('Cache-Control')); # Since we only do string matching, this should be ok
			if (defined($cc)) {
				## o  the "no-store" cache directive (see Section 5.2) does not appear
				##    in request or response header fields, and
				return $res if ($cc =~ m/no-store|no-cache/); # TODO: Improve no-cache use
				if ($self->is_shared) {
					## o  the "private" response directive (see Section 5.2.2.6) does not
					##    appear in the response, if the cache is shared, and
					return $res if ($cc =~ m/private/);
					## o  the Authorization header field (see Section 4.2 of [RFC7235]) does
					##    not appear in the request, if the cache is shared, unless the
					##    response explicitly allows it (see Section 3.2), and
					if ($request->header('Authorization')) {
						return $res unless ($cc =~ m/public|must-revalidate|s-maxage/);
					}
				}
				## o  the response either:
				##
				##    *  contains an Expires header field (see Section 5.3), or
				##    *  contains a max-age response directive (see Section 5.2.2.8), or
				# This is implemented in HTTP::Response, but it relates to the old RFC2616
				# and doesn't support shared caches.
				$expires_in = $res->freshness_lifetime(%{$self->heuristics_opts}) || 0;

				##    *  contains a s-maxage response directive (see Section 5.2.2.9)
				##       and the cache is shared, or

				if ($self->is_shared && ($cc =~ m/s-maxage\s*=\s*(\d+)/)) {
					$expires_in = $1;
				}



				##    *  contains a Cache Control Extension (see Section 5.2.3) that
				##       allows it to be cached, or
				# TODO

				##    *  has a status code that is defined as cacheable by default (see
				##       Section 4.2.2), or
				# TODO: We only do GET

				##    *  contains a public response directive (see Section 5.2.2.5).
				# We do not specifically deal with this

			}
			if ($expires_in > 0) {
				$self->cache_set($res, $expires_in);
			}
		}
		return $res;
	}
};

1;

__END__

=head1 LIMITATIONS

Will only cache C<GET> requests, and only successful responses.

The module does not validate and does not serve stale responses, even
when it would be allowed to do so. It nevertheless does most of
RFC7234.

=head1 BUGS

Please report any bugs to
L<https://github.com/kjetilk/p5-lwp-useragent-chicaching/issues>.


=head1 AUTHOR

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 ACKNOWLEDGEMENTS

It was really nice looking at the code of L<LWP::UserAgent::WithCache>, when I wrote this.

Thanks to Matt S. Trout for rewriting this to a Role.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2015, 2016 by Kjetil Kjernsmo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.



