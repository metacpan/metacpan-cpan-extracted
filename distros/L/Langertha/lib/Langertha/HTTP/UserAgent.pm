package Langertha::HTTP::UserAgent;
# ABSTRACT: LWP::UserAgent that keeps credentials on their origin across redirects
our $VERSION = '0.503';
use Moose;
use MooseX::NonMoose;

extends 'LWP::UserAgent';

use Carp qw( croak );
use Scalar::Util ();
use Langertha::HTTP::Redirect;


has connect_host => (
  is => 'ro',
  isa => 'Maybe[Str]',
);


has connect_address => (
  is => 'ro',
  isa => 'Maybe[Str]',
);


sub FOREIGNBUILDARGS {
  my ( $class, %args ) = @_;
  delete @args{qw( connect_host connect_address )};
  return %args;
}

sub BUILD {
  my ($self) = @_;
  my ( $host, $address ) = ( $self->connect_host, $self->connect_address );
  return unless defined $host || defined $address;
  croak __PACKAGE__ . ": connect_host and connect_address go together"
    unless defined $host && length $host && defined $address;
  my $error = connect_address_error($address);
  croak __PACKAGE__ . ": $error" if $error;
  return;
}

# undef when $address is an IPv4 or IPv6 literal the pin can connect to, else
# why not. Shared with Langertha::Role::HTTP's connect_address check.
sub connect_address_error {
  my ($address) = @_;
  return 'connect_address must be an IP address literal, not undef' unless defined $address;
  require Socket;
  return undef if $address =~ /\A[0-9.]+\z/ && Socket::inet_pton( Socket::AF_INET(), $address );
  return undef if $address =~ /:/ && $address !~ /[\[\]%]/ && Socket::inet_pton( Socket::AF_INET6(), $address );
  return "connect_address must be an IPv4 or IPv6 address literal (no brackets, port or scope), not '$address'";
}


sub redirect_ok {
  my ( $self, $referral, $response ) = @_;
  # The policy first, so its refusal (a POST, even one requests_redirectable
  # allows) names its reason on the response; then LWP's own checks.
  return 0 unless Langertha::HTTP::Redirect::guard_referral( $referral, $response,
    defined $self->connect_address ? $self->connect_host : undef );
  return $self->SUPER::redirect_ok( $referral, $response ) ? 1 : 0;
}


# Where the pin is applied: LWP calls this once per hop (request() follows
# redirects by calling simple_request -> send_request again), so each hop to
# the pinned host is pinned and a hop to another host is not.
sub send_request {
  my ( $self, $request, @rest ) = @_;
  my $address = $self->connect_address;
  my $uri     = $request->uri;
  return $self->SUPER::send_request( $request, @rest )
    unless defined $address && $uri->can('host')
      && lc( $uri->host // '' ) eq lc $self->connect_host;

  # The proxy would resolve the name itself (prepare_request has put it on
  # the request by now); sending the request there would silently unpin it.
  return _pin_failure( $request, 'connect_address ' . $address
      . ' cannot be used for a request that goes through a proxy' )
    if $request->{proxy};

  # LWP::Protocol::http::_new_socket passes $self->_extra_sock_opts($host,
  # $port) after its own PeerAddr (for https after the agent's ssl_opts), and
  # calls $self->_check_sock($request, $socket) before it writes the request:
  # the subclass override points LWP documents. They are wrapped for the
  # duration of this request only, and add something only when the protocol
  # object works for this agent and the host is the pinned one, so another
  # agent's request (from a content callback, say) is never touched. https
  # has its own _extra_sock_opts (calling SUPER without the host), so both
  # are wrapped. Checked against LWP 6.83 / LWP::Protocol::https 6.17; the
  # Client-Peer check below is the backstop if either hook stops being called.
  # LWP::Protocol::https is a hard dependency (ADR 0027).
  require LWP::Protocol::http;
  require LWP::Protocol::https;
  my $http_opts  = \&LWP::Protocol::http::_extra_sock_opts;
  my $https_opts = \&LWP::Protocol::https::_extra_sock_opts;
  my $check      = \&LWP::Protocol::http::_check_sock;
  no warnings 'redefine';
  local *LWP::Protocol::http::_extra_sock_opts = sub {
    return ( $http_opts->(@_), $self->_pin_sock_opts( 'http', @_ ) );
  };
  local *LWP::Protocol::https::_extra_sock_opts = sub {
    return ( $https_opts->(@_), $self->_pin_sock_opts( 'https', @_ ) );
  };
  my $checked;
  local *LWP::Protocol::http::_check_sock = sub {
    $check->(@_);
    $checked = 1 if $self->_pin_check_sock(@_);
  };
  my $response = $self->SUPER::send_request( $request, @rest );
  return _pin_failure( $request, "connect_address $address: no response" ) unless $response;

  my $peer = $response->header('Client-Peer');
  if ( defined $peer ) {
    $peer =~ s/:\d+\z//;
    $peer =~ s/\A\[(.*)\]\z/$1/;
    return _pin_failure( $request, "connect_address $address was not used: LWP connected to $peer" )
      unless same_address( $peer, $address );
  }
  # A response that did not come over a checked connection (a later LWP no
  # longer calling _check_sock, a request_send handler answering in place of
  # the network) is refused too; LWP's own internal error responses (connect
  # failed, ...) never had a connection and pass as they are.
  return _pin_failure( $request, "connect_address $address: the connection was not checked before sending" )
    unless $checked || ( $response->header('Client-Warning') // '' ) eq 'Internal response';
  return $response;
}

# True when $protocol (an LWP::Protocol object) works for this agent and
# $host (possibly [bracketed]) is the pinned host.
sub _pins {
  my ( $self, $protocol, $host ) = @_;
  return 0 unless ref $protocol && ref $protocol->{ua}
    && Scalar::Util::refaddr( $protocol->{ua} ) == Scalar::Util::refaddr($self);
  return 0 unless defined $host;
  $host =~ s/\A\[(.*)\]\z/$1/;
  return lc $host eq lc $self->connect_host ? 1 : 0;
}

# The socket options that connect to the pinned address (the wrapped
# _extra_sock_opts). https calls the http one through SUPER without the host,
# which adds nothing; its own wrapper adds the TLS names.
sub _pin_sock_opts {
  my ( $self, $scheme, $protocol, $host ) = @_;
  return () unless $self->_pins( $protocol, $host );
  $host =~ s/\A\[(.*)\]\z/$1/;
  my $address = $self->connect_address;
  return (
    # Net::HTTP reads PeerAddr (bracketed for IPv6, it parses host:port);
    # IO::Socket::IP prefers PeerHost when both are there.
    PeerAddr => ( $address =~ /:/ ? "[$address]" : $address ),
    PeerHost => $address,
    # Net::HTTPS would derive SNI and the certificate name from the peer,
    # which is now the address: name them after the host. No SNI for an
    # address literal (RFC 6066), as LWP::Protocol::https does.
    $scheme eq 'https'
      ? ( SSL_hostname => ( _is_address($host) ? undef : $host ), SSL_verifycn_name => $host )
      : (),
  );
}

# Before the request is written (the wrapped _check_sock): the socket, new or
# from a conn_cache, must be connected to the pinned address and, over https
# with hostname verification on, hold a certificate for the host. A die here
# becomes LWP's 500 response and nothing is sent.
sub _pin_check_sock {
  my ( $self, $protocol, $request, $socket ) = @_;
  my $uri = $request->uri;
  return unless $uri->can('host') && $self->_pins( $protocol, $uri->host );
  my $address = $self->connect_address;
  my $peer = eval { $socket->peerhost };
  die "connect_address $address was not used: the connection goes to " . ( $peer // 'an unknown peer' ) . "\n"
    unless defined $peer && same_address( $peer, $address );
  # LWP verifies chain and name exactly when verify_hostname is on (it then
  # sets SSL_verify_mode), so the same condition decides both checks here.
  if ( lc( $uri->scheme // '' ) eq 'https' && $self->ssl_opts('verify_hostname') ) {
    my $error = tls_identity_error( $socket, $uri->host, chain => 1, name => 1 );
    die "connect_address $address: $error\n" if $error;
  }
  return 1;
}

# undef when the TLS connection on $handle (an IO::Socket::SSL) passed the
# requested checks for $host, else why not. Shared with Role::AsyncHTTP.
sub tls_identity_error {
  my ( $handle, $host, %check ) = @_;
  if ( $check{chain} ) {
    # _get_ssl_object is IO::Socket::SSL's documented door to the OpenSSL
    # handle ("ACCESS TO INTERNALS"). The verify result is recorded even when
    # the connection was made with SSL_verify_mode => 0, so a session nobody
    # verified does not pass for one that was.
    my $ssl = $handle && $handle->can('_get_ssl_object') ? $handle->_get_ssl_object : undef;
    return "the connection is not a TLS session" unless $ssl;
    require Net::SSLeay;
    my $result = Net::SSLeay::get_verify_result($ssl);
    return "the connection's certificate chain is not verified ("
      . Net::SSLeay::X509_verify_cert_error_string($result) . ')'
      unless $result == Net::SSLeay::X509_V_OK();
  }
  if ( $check{name} ) {
    return "the connection's certificate is not for $host"
      unless $handle && $handle->can('verify_hostname') && $handle->verify_hostname( $host, 'http' );
  }
  return undef;
}



sub _is_address {
  my ($host) = @_;
  require Socket;
  return ( Socket::inet_pton( Socket::AF_INET(), $host ) || Socket::inet_pton( Socket::AF_INET6(), $host ) ) ? 1 : 0;
}

sub same_address {
  my ( $left, $right ) = @_;
  require Socket;
  for my $family ( Socket::AF_INET(), Socket::AF_INET6() ) {
    my ( $l, $r ) = map { Socket::inet_pton( $family, $_ ) } $left, $right;
    return 1 if defined $l && defined $r && $l eq $r;
  }
  # An IPv4 address reported IPv4-mapped (::ffff:a.b.c.d) by an IPv6 socket.
  my ($mapped) = $left =~ /\A::ffff:([0-9.]+)\z/i;
  return defined $mapped && $mapped eq $right ? 1 : 0;
}


# The error response LWP itself gives for a request it could not send.
sub _pin_failure {
  my ( $request, $message ) = @_;
  require HTTP::Response;
  my $response = HTTP::Response->new( 500, $message, [ 'Client-Warning' => 'Internal response',
    'Content-Type' => 'text/plain' ], "$message\n" );
  $response->request($request);
  return $response;
}

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::HTTP::UserAgent - LWP::UserAgent that keeps credentials on their origin across redirects

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    my $ua = Langertha::HTTP::UserAgent->new( agent => 'my-app', timeout => 30 );
    my $engine = Langertha::Engine::Anthropic->new( api_key => $key, user_agent => $ua );

=head1 DESCRIPTION

The L<LWP::UserAgent> an engine builds for its synchronous requests
(L<Langertha::Role::HTTP/user_agent>), and so also the one the synchronous
fallback of the C<_f> methods runs over (L<Langertha::Request::SyncHTTP>). It
takes the same constructor arguments as L<LWP::UserAgent> and differs only in
how it follows redirects: through L<Langertha::HTTP::Redirect>, the policy the
L<Net::Async::HTTP> backend follows as well. A redirect to another origin
carries no credential header (of any name) and no credential in the URL; a
redirect from C<https> to C<http> is not followed (karr k374).

Pass one as C<user_agent> when you bring your own agent and want that policy;
a plain L<LWP::UserAgent> keeps LWP's own redirect behaviour.

Built with L</connect_host> and L</connect_address> it also B<pins> the
connection: a request to that host connects to that address instead of
resolving the name, while the C<Host> header, TLS SNI and the certificate's
name check still use the host name (karr k375). An engine builds its agent
this way when it has a L<Langertha::Role::HTTP/connect_address>.

=head2 connect_host

The host name L</connect_address> applies to (compared case-insensitively
with the host of each request's URL). Given together with
L</connect_address> or not at all.

=head2 connect_address

An IPv4 or IPv6 address literal (no brackets, port or scope). A request to
L</connect_host>, on any port and over C<http> or C<https>, opens its TCP
connection to this address; the name is not resolved. Everything else about
the request still names the host: the C<Host> header, and for C<https> the
SNI (not sent when the host is itself an address literal) and the name the
certificate is checked against (C<SSL_verifycn_name>). Certificate
verification itself stays as the agent's C<ssl_opts> configure it, as for an
unpinned request. Requests to other hosts are not affected.

A redirect from L</connect_host> to another host is not followed (the
returned 3xx carries a C<Client-Warning> saying so): the address was checked
for this host only, and a new host would be resolved again. A request that
would go through a proxy (C<< $ua->proxy >>, C<env_proxy>) fails with a
C<500> response instead of being sent, because the proxy would resolve the
name.

How: for the duration of each pinned request, the two methods
L<LWP::Protocol::http> marks for subclasses to override are wrapped:
C<_extra_sock_opts> (the socket options, for C<http> and C<https>) and
C<_check_sock> (called with the socket before the request is written). They act only for this agent's own protocol objects and only for
the pinned host, so a request another agent sends meanwhile (from a content
callback, say) is not affected. Before anything is written, the socket's
peer must be the pinned address and, over C<https> with LWP's
C<verify_hostname> on, its certificate must be for the host; otherwise the
request is not sent and a C<500> response says why. That also covers a
socket handed out by a C<conn_cache>: an agent sharing its C<conn_cache>
with an unpinned agent could otherwise be given a connection the other agent
opened elsewhere. The C<Client-Peer> comparison after the request is a
backstop in case a later LWP stops calling those hooks, and that one only
detects a wrong peer after the request was sent; a response from a
connection that never passed the check (no C<_check_sock> call, or a
C<request_send> handler answering in place of the network) is refused as
well, with a C<500>. With C<verify_hostname> on (LWP's default) the check
also requires the session's certificate chain to have verified, so a
reused socket another agent opened without verification does not pass.

=head2 connect_address_error

    my $error = Langertha::HTTP::UserAgent::connect_address_error($address);

C<undef> when C<$address> is an IPv4 or IPv6 address literal usable as
L</connect_address>, else a message saying why not.

=head2 redirect_ok

LWP's hook, called with the request it is about to send for a redirect.
Applies L<Langertha::HTTP::Redirect/guard_referral> — which refuses every
method but C<GET> and C<HEAD> whatever C<requests_redirectable> says, and
strips the request in place when it goes to another origin — then refuses what
L<LWP::UserAgent/redirect_ok> refuses. A refusal by the policy is named in a
C<Client-Warning> header on the returned 3xx response. With a
L</connect_address>, a redirect from L</connect_host> to another host is
refused as well.

=head2 tls_identity_error

    my $error = Langertha::HTTP::UserAgent::tls_identity_error( $socket, $host, chain => 1, name => 1 );

C<undef> when the L<IO::Socket::SSL> connection C<$socket> passes the
requested checks, else a message saying which failed: C<chain> requires
OpenSSL's verification result of the session to be C<X509_V_OK> (recorded
even for a session opened without verification), C<name> requires the peer
certificate to be for C<$host> (C<http> scheme rules). Used before a pinned
request is written (L</connect_address>).

=head2 send_request

LWP's per-hop dispatch. Unchanged unless the agent has a L</connect_address>
and the request goes to L</connect_host>; then the connection is pinned as
described there.

=head2 same_address

    Langertha::HTTP::UserAgent::same_address( '::ffff:127.0.0.1', '127.0.0.1' );   # 1

True when two IP address literals are the same address (compared packed, so
C<::1> and C<0:0:0:0:0:0:0:1> match); an IPv4 address reported IPv4-mapped by
an IPv6 socket matches its IPv4 form.

=head1 SEE ALSO

=over

=item * L<Langertha::HTTP::Redirect> - The redirect policy

=item * L<Langertha::Role::HTTP> - Builds this agent as C<user_agent>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
