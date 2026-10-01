use strict;
use warnings;
use Test::More;

use lib 't/lib';
use Kubernetes::Comb::Client::Fake;
use Kubernetes::Comb::Endpoint;
use TestComb::Configurable;

# nats in getty, offering what the test says.
sub comb {
  my ( @offers ) = @_;
  return TestComb::Configurable->new(
    name      => 'nats',
    namespace => 'getty',
    k8s       => Kubernetes::Comb::Client::Fake->new,
    offers    => [ @offers ? @offers : { name => 'client', port => 4222 } ]
  );
}

# A redirected endpoint: local name and port, the upstream address.
sub redirected {
  my ( $name, $port, $address, %args ) = @_;
  return Kubernetes::Comb::Endpoint->new( name => $name, port => $port, cluster => $address, %args );
}

sub bridge {
  my ( $comb, @endpoints ) = @_;
  my $f = $comb->bridge_manifests(@endpoints);
  isa_ok $f, 'Future', 'bridge_manifests';
  return $f;
}

sub manifests {
  my $f = bridge(@_);
  return $f->is_done ? [ $f->get ] : 'failed: '.$f->failure;
}

sub cannot {
  my ( $comb, $endpoints, $re, $what ) = @_;
  my $f = bridge( $comb, @$endpoints );
  ok $f->is_failed, $what.': fails';
  is( ( $f->failure )[1], 'bridge', $what.': category bridge' );
  like $f->failure, $re, $what.': why';
}

my %tcp_client = ( name => 'client', port => 4222, protocol => 'TCP' );

subtest 'a host name: ExternalName' => sub {
  is_deeply manifests( comb(), redirected( client => 4222, 'NATS.dev.example.com:4222' ) ), [ {
    apiVersion => 'v1',
    kind       => 'Service',
    metadata   => { name => 'nats' },
    spec       => { type => 'ExternalName', externalName => 'nats.dev.example.com', ports => [ {%tcp_client} ] }
  } ], 'a Service of the Comb\'s name, no selector, no cluster IP';
};

subtest 'a host in the cluster gets the cluster domain' => sub {
  my $comb = comb();
  is manifests( $comb, redirected( client => 4222, 'nats.platform.svc:4222' ) )->[0]{spec}{externalName},
    'nats.platform.svc.cluster.local', 'cluster.local by default';
  $comb = TestComb::Configurable->new( name => 'nats', namespace => 'getty', cluster_domain => 'dev.internal',
    offers => [ { name => 'client', port => 4222 } ] );
  is manifests( $comb, redirected( client => 4222, 'nats.platform.svc:4222' ) )->[0]{spec}{externalName},
    'nats.platform.svc.dev.internal', 'or cluster_domain';
};

subtest 'ExternalName cannot map ports' => sub {
  cannot( comb(), [ redirected( client => 4222, 'nats.dev.example.com:14222' ) ],
    qr/Service nats: endpoint client is port 4222 here but 14222 at nats\.dev\.example\.com, and an ExternalName Service cannot map ports/,
    'another port upstream' );
};

subtest 'endpoints sharing a Service' => sub {
  my $comb = comb( { name => 'client', port => 4222 }, { name => 'monitor', port => 8222 } );
  is_deeply manifests( $comb,
    redirected( client  => 4222, 'nats.dev.example.com:4222' ),
    redirected( monitor => 8222, 'nats.dev.example.com:8222' )
  )->[0]{spec}{ports}, [ {%tcp_client}, { name => 'monitor', port => 8222, protocol => 'TCP' } ],
    'one host: one Service, a port each';

  cannot( $comb, [
    redirected( client  => 4222, 'nats.dev.example.com:4222' ),
    redirected( monitor => 8222, 'monitor.dev.example.com:8222' )
  ], qr/Service nats: an ExternalName Service points at one host, but its endpoints are at client at nats\.dev\.example\.com, monitor at monitor\.dev\.example\.com/,
    'two hosts' );
};

subtest 'an endpoint with a Service of its own' => sub {
  my $comb = comb( { name => 'client', port => 4222 }, { name => 'monitor', port => 8222, service => 'nats-monitor' } );
  my $manifests = manifests( $comb,
    redirected( client  => 4222, 'nats.dev.example.com:4222' ),
    redirected( monitor => 8222, 'monitor.dev.example.com:8222' )
  );
  is_deeply [ map { $_->{metadata}{name}.' -> '.$_->{spec}{externalName} } @$manifests ],
    [ 'nats -> nats.dev.example.com', 'nats-monitor -> monitor.dev.example.com' ], 'one Service each';
};

subtest 'an IPv4 address: selector-less Service and EndpointSlice' => sub {
  is_deeply manifests( comb(), redirected( client => 4222, '10.0.0.5:14222' ) ), [
    {
      apiVersion => 'v1',
      kind       => 'Service',
      metadata   => { name => 'nats' },
      spec       => { ipFamilies => [ 'IPv4' ], ipFamilyPolicy => 'SingleStack', ports => [ {%tcp_client} ] }
    },
    {
      apiVersion  => 'discovery.k8s.io/v1',
      kind        => 'EndpointSlice',
      metadata    => {
        name   => 'nats-1',
        labels => {
          'kubernetes.io/service-name'             => 'nats',
          'endpointslice.kubernetes.io/managed-by' => 'kubernetes-comb'
        }
      },
      addressType => 'IPv4',
      ports       => [ { name => 'client', port => 14222, protocol => 'TCP' } ],
      endpoints   => [ { addresses => [ '10.0.0.5' ] } ]
    }
  ], 'the slice may point at another port';
};

subtest 'an IPv6 address' => sub {
  my $manifests = manifests( comb(), redirected( client => 4222, '[2001:DB8:0::5]:4222' ) );
  is_deeply $manifests->[0]{spec}{ipFamilies}, [ 'IPv6' ], 'an IPv6 Service';
  is $manifests->[1]{addressType}, 'IPv6', 'an IPv6 slice';
  is_deeply $manifests->[1]{endpoints}, [ { addresses => [ '2001:db8::5' ] } ], 'the address in canonical form';
};

subtest 'addresses sharing a Service' => sub {
  my $comb = comb( map { +{ name => $_, port => 4000 } } qw( a b c ) );
  my $manifests = manifests( $comb,
    redirected( a => 4000, '10.0.0.5:4001' ),
    redirected( b => 4000, '10.0.0.6:4002' ),
    redirected( c => 4000, '10.0.0.5:4003' )
  );
  is scalar @$manifests, 3, 'a Service and a slice per address';
  is_deeply [ map { [ $_->{metadata}{name}, $_->{endpoints}, [ map { $_->{name}.':'.$_->{port} } @{ $_->{ports} } ] ] } @{$manifests}[ 1, 2 ] ], [
    [ 'nats-1', [ { addresses => [ '10.0.0.5' ] } ], [ 'a:4001', 'c:4003' ] ],
    [ 'nats-2', [ { addresses => [ '10.0.0.6' ] } ], [ 'b:4002' ] ]
  ], 'each slice with the ports of its address';
};

subtest 'what one Service cannot bridge' => sub {
  my $comb = comb( { name => 'client', port => 4222 }, { name => 'monitor', port => 8222 } );
  cannot( $comb, [ redirected( client => 4222, 'nats.dev.example.com:4222' ), redirected( monitor => 8222, '10.0.0.5:8222' ) ],
    qr/Service nats: its endpoints point at both host names and IP addresses \(client at nats\.dev\.example\.com, monitor at 10\.0\.0\.5\)/,
    'a name and an address' );
  cannot( $comb, [ redirected( client => 4222, '10.0.0.5:4222' ), redirected( monitor => 8222, '[2001:db8::5]:8222' ) ],
    qr/both IPv4 and IPv6 addresses/, 'two address families' );
  cannot( $comb, [ Kubernetes::Comb::Endpoint->new( name => 'client', port => 4222 ) ],
    qr/endpoint client has no address/, 'no address' );
  cannot( $comb, [ redirected( client => 4222, 'nats:4222:1' ) ],
    qr/endpoint client has the address nats:4222:1, not host:port/, 'an address that is none' );
  cannot( $comb, [ redirected( client => 4222, 'a.example:1' ), redirected( monitor => 8222, 'b.example:8222' ) ],
    qr/points at one host, but .*; Service nats: endpoint client is port 4222 here but 1 at a\.example/, 'every problem told' );
};

subtest 'protocols' => sub {
  my $comb = comb( map { +{ name => $_, port => 5000, protocol => $_ } } qw( udp sctp http ) );
  is_deeply [ map { $_->{protocol} } @{ manifests( $comb,
    map { redirected( $_ => 5000, 'x.example:5000', protocol => $_ ) } qw( udp sctp http )
  )->[0]{spec}{ports} } ], [ qw( UDP SCTP TCP ) ], 'udp, sctp, anything else runs on TCP';
};

subtest 'no endpoints, no bridge' => sub {
  is_deeply manifests( comb() ), [], 'nothing';
};

done_testing;
