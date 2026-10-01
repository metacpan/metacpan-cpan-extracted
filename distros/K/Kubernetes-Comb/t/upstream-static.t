use strict;
use warnings;
use Test::More;

use lib 't/lib';
use JSON::MaybeXS qw( JSON );
use Kubernetes::Comb::Endpoint;
use Kubernetes::Comb::Upstream::Static;
use TestComb::Configurable;
use TestComb::Fixtures qw( comb_cr );
use Kubernetes::Comb::Client::Fake;

my $class = 'Kubernetes::Comb::Upstream::Static';

sub endpoints_of {
  my ( $upstream ) = @_;
  return [ map { $_->to_crd->TO_JSON } @{ $upstream->endpoints->get } ];
}

subtest 'endpoints as hashrefs or objects' => sub {
  my $upstream = $class->new( endpoints => [
    { name => 'client', port => 4222, cluster => 'nats.dev.example:4222', external => 'nats.example.com:4222' },
    Kubernetes::Comb::Endpoint->new( name => 'monitor', port => 8222, protocol => 'tcp', external => '10.0.0.5:8222' )
  ] );
  ok $upstream->DOES('Kubernetes::Comb::Role::Upstream'), 'does the role';
  my $f = $upstream->endpoints;
  isa_ok $f, 'Future';
  ok $f->is_done, 'already done';
  isa_ok $_, 'Kubernetes::Comb::Endpoint' for @{ $f->get };
  is_deeply endpoints_of($upstream), [
    { name => 'client', protocol => 'tcp', port => 4222, cluster => 'nats.dev.example:4222', external => 'nats.example.com:4222' },
    { name => 'monitor', protocol => 'tcp', port => 8222, external => '10.0.0.5:8222' }
  ], 'as given';
  isnt $upstream->endpoints->get, $upstream->endpoints->get, 'a fresh arrayref each time';
  is_deeply endpoints_of( $class->new ), [], 'default: none';
};

subtest 'status' => sub {
  my $f = $class->new->status;
  ok $f->is_done, 'already done';
  is_deeply $f->get, { reachable => 1, phase => 'Running', via => [] }, 'default: reachable, Running, no layers';
  is_deeply $class->new( phase => 'Pending', via => [ 'docker' ], message => 'starting' )->status->get,
    { reachable => 1, phase => 'Pending', via => [ 'docker' ], message => 'starting' }, 'as built';
  is $class->new( reachable => 0 )->status->get->{reachable}, 0, 'unreachable';
  is $class->new( reachable => JSON->false )->status->get->{reachable}, 0, 'a JSON false, as the custom resource has it';
};

subtest 'construction dies on what is no endpoint' => sub {
  ok !eval { $class->new( endpoints => [ 'nats:4222' ] ); 1 }, 'a plain string';
  like $@, qr/an endpoint is a hashref or a Kubernetes::Comb::Endpoint, got a plain scalar/, '... saying so';
  ok !eval { $class->new( endpoints => [ { name => 'client' } ] ); 1 }, 'an endpoint without port';
  like $@, qr/port/, '... naming it';
};

subtest 'from the custom resource' => sub {
  my $k8s = Kubernetes::Comb::Client::Fake->new;
  $k8s->add( comb_cr( name => 'geoip', class => 'TestComb::Configurable', spec => {
    upstream => {
      class     => $class,
      endpoints => [ { name => 'api', port => 443, cluster => 'geoip.vendor.example:443' } ],
      via       => [ 'vendor' ]
    }
  } ) );
  my $comb = TestComb::Configurable->new(
    crd    => $k8s->object( Comb => 'geoip', namespace => 'platform' ),
    k8s    => $k8s,
    offers => [ { name => 'api', port => 443 } ]
  );
  my ( $upstream ) = $comb->_resolve_upstream->get;
  isa_ok $upstream, $class;
  is_deeply $upstream->via, [ 'vendor' ], 'via';
  is_deeply endpoints_of($upstream),
    [ { name => 'api', protocol => 'tcp', port => 443, cluster => 'geoip.vendor.example:443' } ], 'endpoints';
};

done_testing;
