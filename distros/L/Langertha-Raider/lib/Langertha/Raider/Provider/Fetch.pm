package Langertha::Raider::Provider::Fetch;
# ABSTRACT: Internal bounded fetch of a provider manifest from /.well-known/langertha.json
our $VERSION = '0.503';
use Moose;
use namespace::autoclean;
use Carp qw( croak );
use Future;
use Future::AsyncAwait;
use HTTP::Request;
use IO::Async::Loop;
use Net::Async::HTTP;
use Socket qw( AF_INET AF_INET6 inet_pton getnameinfo NI_NUMERICHOST NI_NUMERICSERV );
use Time::HiRes ();
use URI;
use Langertha::Raider::ConnectCheck qw( connect_error );


use constant WELL_KNOWN_PATH => '/.well-known/langertha.json';


has allow_internal => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);


has max_bytes => (
  is      => 'ro',
  isa     => 'Int',
  default => 1_048_576,
);


has timeout => (
  is      => 'ro',
  isa     => 'Num',
  default => 10,
);


has max_redirects => (
  is      => 'ro',
  isa     => 'Int',
  default => 3,
);


has loop => (
  is      => 'ro',
  lazy    => 1,
  builder => '_build_loop',
);

sub _build_loop { IO::Async::Loop->new }


has resolver => (
  is      => 'ro',
  isa     => 'CodeRef',
  lazy    => 1,
  builder => '_build_resolver',
);

sub _build_resolver {
  my ( $self ) = @_;
  return sub {
    my ( $host ) = @_;
    return $self->loop->resolver->getaddrinfo(
      host     => $host,
      service  => 443,
      socktype => 'stream',
      timeout  => $self->timeout,
    )->then(sub {
      my %seen;
      my @addresses = grep { defined && !$seen{$_}++ }
        map { ( getnameinfo($_->{addr}, NI_NUMERICHOST | NI_NUMERICSERV) )[1] } @_;
      return Future->done(@addresses);
    });
  };
}


has ssl_options => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { {} },
);


sub target_url {
  my ( $self, $target ) = @_;
  croak 'no provider given' unless defined $target && length $target;
  croak 'provider target contains spaces or control characters' if $target =~ /[\s\x00-\x1f\x7f]/;
  my $uri;
  if ( $target =~ m{\A[A-Za-z][A-Za-z0-9+.-]*://} ) {
    $uri = URI->new($target);
    croak 'only https is allowed for a provider manifest, not '.$uri->scheme.'://'
      unless lc $uri->scheme eq 'https';
  }
  else {
    croak "provider target '".$target."' is not HOST, HOST:PORT or an https URL" if $target =~ m{[/?#@]};
    $uri = URI->new('https://'.$target);
  }
  croak 'provider target must not carry credentials (userinfo)' if defined $uri->userinfo;
  croak 'provider target must not carry a query' if defined $uri->query;
  croak 'provider target must not carry a fragment' if defined $uri->fragment;
  my $host = $uri->host;
  croak "provider target '".$target."' names no host" unless defined $host && length $host;
  croak "provider target '".$target."' has an invalid port" unless $uri->port =~ /\A\d+\z/ && $uri->port > 0 && $uri->port < 65536;
  my $path = $uri->path;
  croak 'the manifest lives at '.WELL_KNOWN_PATH.' of the origin; give the host or the origin, not '.$path
    unless $path eq '' || $path eq '/' || $path eq WELL_KNOWN_PATH;
  my $url = URI->new('https://'.$uri->host_port.WELL_KNOWN_PATH);
  return $url->canonical->as_string;
}


# [ first address, prefix length, kind ]; the first match wins, so the
# single metadata addresses come before the ranges holding them.
my @V4_RANGES = (
  [ '169.254.169.254', 32, 'metadata' ],   # AWS, GCP, Azure, OpenStack, DigitalOcean, ...
  [ '100.100.100.200', 32, 'metadata' ],   # Alibaba Cloud
  [ '0.0.0.0',          8, 'unspecified' ],
  [ '10.0.0.0',         8, 'private' ],
  [ '100.64.0.0',      10, 'private' ],    # shared address space (carrier-grade NAT)
  [ '127.0.0.0',        8, 'loopback' ],
  [ '169.254.0.0',     16, 'link-local' ],
  [ '172.16.0.0',      12, 'private' ],
  [ '192.0.0.0',       24, 'reserved' ],   # IETF protocol assignments
  [ '192.0.2.0',       24, 'reserved' ],   # documentation
  [ '192.168.0.0',     16, 'private' ],
  [ '198.18.0.0',      15, 'reserved' ],   # benchmarking
  [ '198.51.100.0',    24, 'reserved' ],   # documentation
  [ '203.0.113.0',     24, 'reserved' ],   # documentation
  [ '224.0.0.0',        4, 'multicast' ],
  [ '240.0.0.0',        4, 'reserved-never' ],   # reserved, including broadcast
);

my @V6_RANGES = (
  [ 'fd00:ec2::254', 128, 'metadata' ],    # AWS IPv6 instance metadata
  [ '::',            128, 'unspecified' ],
  [ '::1',           128, 'loopback' ],
  [ 'fc00::',          7, 'private' ],     # unique local
  [ 'fe80::',         10, 'link-local' ],
  [ 'fec0::',         10, 'private' ],     # site-local (deprecated)
  [ 'ff00::',          8, 'multicast' ],
  [ '100::',          64, 'reserved' ],    # discard
  [ '2001:db8::',     32, 'reserved' ],    # documentation
);

my %RELEASABLE = map { $_ => 1 } qw( loopback private link-local reserved );

sub address_kind {
  my ( $self, $address ) = @_;
  ( my $bare = $address // '' ) =~ s/%.*\z//s;
  my $kind = 'invalid';
  if ( my $packed = inet_pton(AF_INET, $bare) ) {
    $kind = $self->_kind_in($packed, AF_INET, \@V4_RANGES);
  }
  elsif ( $packed = inet_pton(AF_INET6, $bare) ) {
    my $v4 = $self->_embedded_v4($packed);
    $kind = defined $v4
      ? $self->_kind_in($v4, AF_INET, \@V4_RANGES)
      : $self->_kind_in($packed, AF_INET6, \@V6_RANGES);
  }
  return $kind eq 'public' ? ('public')
    : $kind eq 'reserved-never' ? ('reserved', 0)
    : ( $kind, $RELEASABLE{$kind} ? 1 : 0 );
}

# The IPv4 address an IPv6 address carries, packed, or undef.
sub _embedded_v4 {
  my ( $self, $packed ) = @_;
  my $prefix96 = substr($packed, 0, 12);
  return substr($packed, 12, 4) if $prefix96 eq ("\0" x 10)."\xff\xff";                 # ::ffff:a.b.c.d
  return substr($packed, 12, 4) if $prefix96 eq ("\0" x 12) && substr($packed, 12, 4) !~ /\A\0\0\0[\0\1]\z/;   # ::a.b.c.d
  return substr($packed, 12, 4) if $prefix96 eq "\0\x64\xff\x9b".("\0" x 8);           # 64:ff9b::/96
  return substr($packed, 2, 4)  if substr($packed, 0, 2) eq "\x20\x02";                # 2002::/16
  return;
}

sub _kind_in {
  my ( $self, $packed, $family, $ranges ) = @_;
  my $bits = unpack 'B*', $packed;
  for my $range (@$ranges) {
    my ( $first, $length, $kind ) = @$range;
    my $net = unpack 'B*', inet_pton($family, $first);
    return $kind if substr($bits, 0, $length) eq substr($net, 0, $length);
  }
  return 'public';
}


sub check_addresses {
  my ( $self, $host, @addresses ) = @_;
  return $host.' resolves to no address' unless @addresses;
  for my $address (@addresses) {
    my ( $kind, $releasable ) = $self->address_kind($address);
    next if $kind eq 'public';
    next if $releasable && $self->allow_internal;
    my $where = ( $address eq $host ? $address.' is' : $host.' resolves to '.$address ).' ('.$kind.' address)';
    return $where.'; only --allow-internal releases loopback, private, link-local and reserved addresses, for a deliberately released internal origin'
      if $releasable;
    return $where.'; never allowed, not even with --allow-internal';
  }
  return;
}


async sub fetch_f {
  my ( $self, $url ) = @_;
  my $t0 = Time::HiRes::time();
  my $timeout = $self->timeout;
  # Made here, not in _fetch_f, so it leaves the loop also when the
  # timeout cancels the fetch half-way.
  my $http = Net::Async::HTTP->new(
    user_agent               => 'raider/'.$self->VERSION,
    max_redirects            => 0,   # followed here, one origin check per hop
    max_connections_per_host => 1,
    decode_content           => 0,   # no Accept-Encoding, nothing to decompress
    fail_on_error            => 0,
  );
  $self->loop->add($http);
  my $settled = await Future->wait_any(
    $self->_fetch_f($url, $http),
    $self->loop->delay_future(after => $timeout)->then(sub {
      Future->done({ status => 'failed', url => $url, error => 'timed out after '.$timeout.'s' });
    }),
  )->followed_by(sub { Future->done($_[0]) });
  $self->loop->remove($http);
  my ( $report ) = $settled->get;
  $report->{url} //= $url;
  $report->{redirects} //= [];
  $report->{elapsed} = 0 + sprintf('%.3f', Time::HiRes::time() - $t0);
  return $report;
}

async sub _fetch_f {
  my ( $self, $url, $http ) = @_;
  my $uri = URI->new($url);
  my $host = $uri->host;
  my %report = ( url => $url, redirects => [] );
  my $failed  = sub { return { %report, status => 'failed',  error => $_[0], @_[ 1 .. $#_ ] } };
  my $refused = sub { return { %report, status => 'refused', error => $_[0], @_[ 1 .. $#_ ] } };

  return $failed->('only https is allowed for a provider manifest') unless $uri->scheme eq 'https';
  # Net::Async::HTTP loads its connector and TLS modules only when it
  # connects; a load failure then leaks the host's connection slot (k107).
  if ( my $error = connect_error($url) ) {
    return $failed->($error);
  }

  my $checked = await $self->check_host_f($host);
  return { %report, %$checked } if $checked->{status};

  return await $self->_hops_f($http, $uri, $checked->{addresses}, \%report, $failed, $refused);
}


async sub check_host_f {
  my ( $self, $host ) = @_;
  my @addresses;
  if ( $self->_is_literal($host) ) {
    @addresses = ( $host );
  }
  else {
    my $resolved = await $self->resolver->($host)->followed_by(sub { Future->done($_[0]) });
    if ( $resolved->is_failed ) {
      my ( $error ) = $resolved->failure;
      $error =~ s/\s+\z//;
      return { status => 'failed', error => 'cannot resolve '.$host.': '.$error };
    }
    @addresses = $resolved->get;
  }
  if ( my $refusal = $self->check_addresses($host, @addresses) ) {
    return { status => 'refused', error => $refusal };
  }
  return { addresses => \@addresses };
}

async sub _hops_f {
  my ( $self, $http, $uri, $addresses, $report, $failed, $refused ) = @_;
  my $origin = $self->origin($uri);
  for my $hop ( 0 .. $self->max_redirects ) {
    my $got = await $self->_get_f($http, $uri, $addresses);
    $report->{address} = $got->{address} if defined $got->{address};
    return $failed->($got->{error}) if defined $got->{error};
    my $response = $got->{response};
    if ( $response->is_redirect && defined( my $location = $response->header('Location') ) ) {
      my $next = URI->new_abs($location, $uri);
      unless ( ( $self->origin($next) // '' ) eq $origin ) {
        return $refused->('redirect to '.$next->as_string.' leaves the origin '.$origin.': not followed',
          location => $next->as_string);
      }
      if ( $hop == $self->max_redirects ) {
        return $failed->('more than '.$self->max_redirects.' redirects');
      }
      push @{ $report->{redirects} }, $next->as_string;
      $uri = $next;
      next;
    }
    return $failed->('HTTP '.$response->status_line.' from '.$uri->as_string)
      unless $response->is_success;
    return { %$report, status => 'completed', final_url => $uri->as_string, body => $response->content };
  }
  return $failed->('more than '.$self->max_redirects.' redirects');
}

# One GET to the checked addresses in turn (the next one only when the
# connection itself failed). Resolves to { response, address } or { error }.
async sub _get_f {
  my ( $self, $http, $uri, $addresses ) = @_;
  my $error;
  for my $i ( 0 .. $#$addresses ) {
    my $address = $addresses->[$i];
    my $got = await $self->_get_one_f($http, $uri, $address);
    return { %$got, address => $address } unless $got->{connect_failed} && $i < $#$addresses;
    $error = $got->{error};
  }
  return { error => $error };
}

async sub _get_one_f {
  my ( $self, $http, $uri, $address ) = @_;
  my $host = $uri->host;
  my $max = $self->max_bytes;
  my $request = HTTP::Request->new(GET => $uri->as_string, [ Accept => 'application/json' ]);
  my $too_large = $self->loop->new_future;
  my $limit_error;
  ( my $bare = $address ) =~ s/%.*\z//s;
  my $req = $http->do_request(
    request => $request,
    host    => $bare,    # the checked address: no second resolution
    port    => $uri->port,
    SSL     => 1,
    %{ $self->ssl_options },
    # After ssl_options, so nothing can switch the checks off.
    SSL_hostname        => $host,
    SSL_verifycn_name   => $host,
    SSL_verifycn_scheme => 'http',
    SSL_verify_mode     => 1,   # SSL_VERIFY_PEER; IO::Socket::SSL loads only on connect
    on_header => sub {
      my ( $response ) = @_;
      # The abort waits for the next loop tick: cancelling the request from
      # inside the connection's read handler leaves it reading for a
      # request that is gone ("Spurious on_read of connection while idle").
      # The error is kept at once, so a response that completes before the
      # abort still counts as too large.
      my $abort = sub {
        ( $limit_error ) = @_;
        $self->loop->later(sub { $too_large->done({ error => $limit_error }) unless $too_large->is_ready });
      };
      my $length = $response->header('Content-Length');
      if ( defined $length && $length =~ /\A\d+\z/ && $length > $max ) {
        $abort->('manifest too large: Content-Length '.$length.' exceeds '.$max.' bytes');
        return sub { return @_ ? () : $response };
      }
      my $body = '';
      my $over;
      return sub {
        if (@_) {
          return if $over;
          $body .= $_[0];
          if ( length $body > $max ) {
            $over = 1;
            $body = '';
            $abort->('manifest too large: more than '.$max.' bytes');
          }
          return;
        }
        $response->content($body);
        return $response;
      };
    },
  );
  my $got = await Future->wait_any(
    $req->then(
      sub { Future->done({ response => $_[0] }) },
      sub {
        my ( $message ) = @_;
        $message =~ s/\s+\z//;
        $message =~ s/ failed \[[^\]]*\]\z//;   # Net::Async::HTTP's "... failed [ssl]" suffix
        # Net::Async::HTTP flattens a connect failure into one message:
        # "ADDRESS:PORT - connect: REASON".
        Future->done({ error => 'fetching '.$uri->as_string.': '.$message,
          connect_failed => ( $message =~ / - connect: / ? 1 : 0 ) });
      },
    ),
    $too_large,
  );
  return defined $limit_error ? { error => $limit_error } : $got;
}

sub origin {
  my ( $self, $uri ) = @_;
  $uri = URI->new($uri) unless ref $uri;
  return unless $uri->can('host');
  return lc( $uri->scheme // '' ).'://'.lc( $uri->host // '' ).':'.( $uri->port // '' );
}


sub _is_literal {
  my ( $self, $host ) = @_;
  ( my $bare = $host ) =~ s/%.*\z//s;
  return inet_pton(AF_INET, $bare) || inet_pton(AF_INET6, $bare) ? 1 : 0;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Provider::Fetch - Internal bounded fetch of a provider manifest from /.well-known/langertha.json

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $fetch = Langertha::Raider::Provider::Fetch->new( allow_internal => 0 );
    my $url   = $fetch->target_url('provider.example');   # croaks on a bad target
    my $got   = $fetch->fetch_f($url)->get;
    # { status => 'completed', url => ..., address => ..., body => ..., redirects => [...] }
    # { status => 'refused' | 'failed', url => ..., error => ..., ... }

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

Fetches a provider manifest (ADR 0007) the way a document from the network
has to be fetched before anything trusts it:

=over

=item * B<https only>, from C</.well-known/langertha.json> of the origin
the target names. A target with userinfo, a query or a fragment is refused
before anything is sent.

=item * B<The target address is checked, and the connection goes to the
checked address.> The host is resolved once, every address it resolves to
is classified (L</address_kind>), and the request is sent to one of those
addresses, never to a name that could resolve differently a second time.
TLS still verifies the certificate against the host name (SNI and
hostname check use the name, not the address).

=item * B<Internal addresses are refused> -- loopback, private (RFC 1918,
shared address space, IPv6 unique local), link-local and reserved ranges --
unless L</allow_internal> is set for a deliberately released internal
Knarr or Skeid origin. Cloud metadata addresses, the unspecified address,
multicast and the 240/4 range are refused always: none of them is ever a
provider. A host whose addresses include one refused address is refused as
a whole.

=item * B<Limits>: L</max_bytes> of body (a larger C<Content-Length> stops
the fetch at the header, a longer body while it arrives), L</timeout>
seconds for everything from resolving to the last byte, L</max_redirects>
redirects. No content encoding is asked for, so nothing is decompressed.

=item * B<A redirect is followed only within the origin> (same scheme,
host and port). A redirect to another origin is not followed and reported
with its target, which is how a credential can never reach another origin
through a redirect -- and this fetch sends none anyway: no
C<Authorization>, no cookies, no API key, only C<Accept> and a
C<User-Agent>.

=back

L</fetch_f> never fails for a network or policy reason; it resolves to a
report whose C<status> says how the fetch ended. Validation of the body is
the caller's job (L<Langertha::Manifest>).

=head2 allow_internal

Release loopback, private, link-local and reserved addresses (see
L</address_kind>). Default false. Never releases a C<never> address.

=head2 max_bytes

Largest body accepted, in bytes. Default 1 MiB.

=head2 timeout

Seconds the whole fetch may take, resolving included. Default 10.

=head2 max_redirects

How many same-origin redirects are followed. Default 3.

=head2 loop

The L<IO::Async::Loop>. Defaults to C<< IO::Async::Loop->new >>.

=head2 resolver

Code reference taking a host name and returning a L<Future> of its
addresses as strings. Defaults to the loop's resolver (C<getaddrinfo>).
An address literal is never handed to it.

=head2 ssl_options

Extra C<SSL_*> arguments for the TLS connection, such as C<SSL_ca_file>.
Default none: the system's CA store. Cannot switch off the certificate or
hostname check -- those are set after it.

=head2 target_url

    my $url = $fetch->target_url('provider.example');        # https://provider.example/.well-known/langertha.json
    my $url = $fetch->target_url('knarr.internal:8443');
    my $url = $fetch->target_url('https://provider.example/');

The manifest URL a command-line target names: C<HOST>, C<HOST:PORT>,
C<[IPv6]:PORT> or an C<https> URL whose path is empty, C</> or the
well-known path itself. Croaks with the reason on anything else: another
scheme (C<http> included), userinfo, a query, a fragment or another path.

=head2 address_kind

    my ( $kind, $releasable ) = $fetch->address_kind('10.0.0.5');   # ( 'private', 1 )
    my ( $kind ) = $fetch->address_kind('93.184.216.34');           # ( 'public' )

Classifies an IPv4 or IPv6 address (a C<%scope> suffix is ignored):
C<public>, or one of C<loopback>, C<private>, C<link-local>, C<reserved>
(releasable with L</allow_internal>) or C<metadata>, C<unspecified>,
C<multicast>, C<invalid> (never). IPv4-mapped, IPv4-compatible, NAT64
(C<64:ff9b::/96>) and 6to4 (C<2002::/16>) IPv6 addresses are classified by
the IPv4 address they carry. The second value is true for a releasable
kind.

=head2 check_addresses

    my $refusal = $fetch->check_addresses($host, @addresses);

C<undef> when every address may be connected to, else the reason the
first one that may not is refused.

=head2 fetch_f

    my $report = await $fetch->fetch_f($url);

Fetches the manifest at C<$url> (from L</target_url>) and resolves to a
report hash:

=over

=item C<status> -- C<completed>, C<refused> (an address or a redirect the
policy does not allow) or C<failed> (network, TLS, HTTP status, a limit).

=item C<url> -- the URL asked for; C<final_url> -- the one the body came
from (after same-origin redirects).

=item C<address> -- the address connected to (once there is one).

=item C<redirects> -- the same-origin locations followed, in order.

=item C<body> -- the body octets (C<completed> only).

=item C<error> -- why (C<refused> and C<failed>); C<location> -- the
target of a redirect that was not followed.

=back

=head2 check_host_f

    my $checked = await $fetch->check_host_f('provider.example');
    # { addresses => [ '93.184.216.34' ] }
    # { status => 'refused' | 'failed', error => ... }

Resolves C<$host> (an address literal stands for itself) and checks every
address with L</check_addresses>. Resolves to the addresses, or to the
C<refused> or C<failed> status and why.

=head2 origin

    my $origin = $fetch->origin('https://Provider.example/v1');   # https://provider.example:443

Scheme, host and port of a URL (string or L<URI>), lower-cased and with
the default port spelled out, so two origins compare with C<eq>; C<undef>
for a URL without a host.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::CLI::Provider> -- C<raider provider inspect>

=item * L<Langertha::Manifest> -- the manifest's schema and validator (core)

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-raider/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
