use strict;
use warnings;
use Test::More;

use IO::K8s;
use JSON::MaybeXS qw( decode_json );
use Kubernetes::Comb::CRD;
use Kubernetes::Comb::CRD::Comb;

my $json = JSON::MaybeXS->new( canonical => 1 );
my $k8s  = IO::K8s->new( with => ['Kubernetes::Comb::CRD'] );

# The example of SPEC section 6, every field set.
my $spec_example = <<'JSON';
{
  "apiVersion": "comb.internal/v1",
  "kind": "Comb",
  "metadata": { "name": "nats", "namespace": "platform", "generation": 3 },
  "spec": {
    "class": "MyApp::Comb::NATS",
    "dependsOn": [ "db", "infra/vault" ],
    "config": { "cluster_size": 3, "jetstream": { "enabled": true, "store": "10Gi" } },
    "enabled": true,
    "upstream": {
      "class": "Kubernetes::Comb::Upstream::K8s",
      "context": "dev",
      "namespace": "platform",
      "name": "nats"
    }
  },
  "status": {
    "phase": "Running",
    "conditions": [
      { "type": "Ready", "status": "True", "reason": "UpstreamRunning",
        "message": "borrowed from dev", "lastTransitionTime": "2026-09-26T12:00:00Z" }
    ],
    "managedResources": [
      { "apiVersion": "v1", "kind": "Service", "namespace": "platform", "name": "nats" }
    ],
    "endpoints": [
      { "name": "client", "protocol": "tcp", "port": 4222,
        "cluster": "nats.platform.svc:4222", "external": "nats.example.com:4222" }
    ],
    "upstream": {
      "class": "Kubernetes::Comb::Upstream::K8s",
      "context": "dev",
      "reachable": true,
      "phase": "Running",
      "via": [ "dev", "prod" ],
      "observedAt": "2026-09-26T12:00:00Z"
    },
    "observedGeneration": 3
  }
}
JSON

subtest 'SPEC example inflates to the typed classes' => sub {
  my $cr = $k8s->inflate($spec_example);
  isa_ok $cr, 'Kubernetes::Comb::CRD::Comb';
  is $cr->api_version, 'comb.internal/v1', 'api_version';
  is $cr->kind, 'Comb', 'kind';
  is $cr->resource_plural, 'combs', 'plural';
  ok $cr->DOES('IO::K8s::Role::Namespaced'), 'namespaced';

  my $spec = $cr->spec;
  isa_ok $spec, 'Kubernetes::Comb::CRD::CombSpec';
  is $spec->class, 'MyApp::Comb::NATS', 'spec.class';
  is_deeply $spec->dependsOn, [ 'db', 'infra/vault' ], 'spec.dependsOn';
  is $spec->config->{cluster_size}, 3, 'spec.config is free-form';
  is $spec->enabled, 1, 'spec.enabled';
  ok $spec->has_upstream, 'spec.upstream exists';
  is $spec->upstream->{context}, 'dev', 'spec.upstream keeps upstream-specific keys';

  my $status = $cr->status;
  isa_ok $status, 'Kubernetes::Comb::CRD::CombStatus';
  is $status->phase, 'Running', 'status.phase';
  isa_ok $status->conditions->[0], 'Kubernetes::Comb::CRD::CombCondition';
  isa_ok $status->managedResources->[0], 'Kubernetes::Comb::CRD::CombResource';
  isa_ok $status->endpoints->[0], 'Kubernetes::Comb::CRD::CombEndpoint';
  is $status->endpoints->[0]->port, 4222, 'endpoint port';
  isa_ok $status->upstream, 'Kubernetes::Comb::CRD::CombUpstreamStatus';
  is $status->upstream->reachable, 1, 'status.upstream.reachable';
  is_deeply $status->upstream->via, [ 'dev', 'prod' ], 'status.upstream.via';
  is $status->observedGeneration, 3, 'status.observedGeneration';

  ok $cr->is_condition_true('Ready'), 'IO::K8s condition helpers see the conditions';
};

subtest 'SPEC example survives a JSON round trip' => sub {
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  my $cr = $k8s->inflate($spec_example);
  is $json->encode( decode_json( $cr->to_json ) ),
     $json->encode( decode_json($spec_example) ),
     'TO_JSON reproduces the document';
  my $again = Kubernetes::Comb::CRD::Comb->from_json( $cr->to_json );
  is $again->to_json, $cr->to_json, 'from_json of to_json is stable';
  is_deeply \@warnings, [], 'no deprecation or stringify warnings for config/upstream';
};

subtest 'spec.upstream: absent, null and set stay apart' => sub {
  my %base = ( apiVersion => 'comb.internal/v1', kind => 'Comb', metadata => { name => 'x' } );

  my $absent = $k8s->inflate({ %base, spec => { class => 'A' } });
  ok !$absent->spec->has_upstream, 'absent: no upstream key';
  ok !exists decode_json( $absent->to_json )->{spec}{upstream}, 'absent: not written';

  my $null = $k8s->inflate( '{"apiVersion":"comb.internal/v1","kind":"Comb",'
    .'"metadata":{"name":"x"},"spec":{"class":"A","upstream":null}}' );
  ok $null->spec->has_upstream, 'null: the key exists';
  ok !defined $null->spec->upstream, 'null: the value is undef';
  my $written = decode_json( $null->to_json );
  ok exists $written->{spec}{upstream} && !defined $written->{spec}{upstream},
    'null: written back as null';
  ok( Kubernetes::Comb::CRD::Comb->from_json( $null->to_json )->spec->has_upstream,
    'null: survives the round trip' );

  my $built = Kubernetes::Comb::CRD::Comb->new( %base, spec => { class => 'A', upstream => undef } );
  ok $built->spec->has_upstream, 'null through new() and the coercion';

  my $direct = Kubernetes::Comb::CRD::CombSpec->new( class => 'A', upstream => undef );
  ok $direct->has_upstream && !defined $direct->upstream, 'null through CombSpec->new';

  my $other_nulls = Kubernetes::Comb::CRD::CombSpec->FROM_HASH(
    { class => 'A', dependsOn => undef, enabled => undef } );
  is_deeply $other_nulls->TO_JSON, { class => 'A' }, 'other null fields count as absent';

  ok !eval { Kubernetes::Comb::CRD::CombSpec->FROM_STRUCT( [] ); 1 }, 'FROM_STRUCT refuses a non-hash';
  like $@, qr/needs a hashref/, '... with a message';
};

subtest 'spec.class is required, enabled is tri-state' => sub {
  ok !eval { Kubernetes::Comb::CRD::CombSpec->new( config => {} ); 1 }, 'no class dies';
  is +Kubernetes::Comb::CRD::CombSpec->new( class => 'A' )->enabled, undef, 'unset is automatic';
  my $off = Kubernetes::Comb::CRD::CombSpec->FROM_HASH({ class => 'A', enabled => JSON::MaybeXS::false });
  is $off->enabled, 0, 'false is off';
  is $json->encode( $off->TO_JSON ), '{"class":"A","enabled":false}', 'false is written as false';
};

subtest 'condition status is an enum' => sub {
  ok !eval { Kubernetes::Comb::CRD::CombCondition->new( type => 'Ready', status => 'yes' ); 1 },
    'status outside True/False/Unknown dies';
};

subtest 'to_crd: the CustomResourceDefinition' => sub {
  my $crd = Kubernetes::Comb::CRD::Comb->to_crd;
  isa_ok $crd, 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinition';
  my $doc = decode_json( $crd->to_json );
  is $doc->{metadata}{name}, 'combs.comb.internal', 'metadata.name';
  is $doc->{spec}{group}, 'comb.internal', 'group';
  is $doc->{spec}{scope}, 'Namespaced', 'scope';
  is_deeply $doc->{spec}{names},
    { kind => 'Comb', plural => 'combs', singular => 'comb', listKind => 'CombList' }, 'names';

  my ( $version ) = @{ $doc->{spec}{versions} };
  is $version->{name}, 'v1', 'version';
  ok $version->{served} && $version->{storage}, 'served and storage';
  is_deeply $version->{subresources}, { status => {} }, 'status subresource';

  my $schema = $version->{schema}{openAPIV3Schema}{properties};
  is_deeply $schema->{spec}{required}, ['class'], 'spec.class is required in the schema';
  my $upstream = $schema->{spec}{properties}{upstream};
  ok $upstream->{nullable}, 'spec.upstream is nullable, so the API server keeps a null';
  ok $upstream->{'x-kubernetes-preserve-unknown-fields'}, 'spec.upstream keeps unknown keys';
  ok $schema->{spec}{properties}{config}{'x-kubernetes-preserve-unknown-fields'},
    'spec.config keeps unknown keys';
  is_deeply [ sort keys %{ $schema->{status}{properties} } ],
    [qw( conditions endpoints managedResources observedGeneration phase upstream )],
    'status properties';
};

subtest 'to_crd: group, kind and plural overrides' => sub {
  my $crd = Kubernetes::Comb::CRD::Comb->to_crd(
    group => 'comb.example.com', kind => 'Cell', plural => 'cells' );
  is $crd->metadata->name, 'cells.comb.example.com', 'metadata.name follows';
  is $crd->spec->group, 'comb.example.com', 'group';
  my $names = $crd->spec->names;
  is_deeply [ map { $names->$_ } qw( kind singular listKind plural ) ],
    [qw( Cell cell CellList cells )], 'names';
  is_deeply decode_json( $crd->to_json )->{spec}{versions}[0]{subresources},
    { status => {} }, 'still with the status subresource';

  is +Kubernetes::Comb::CRD::Comb->to_crd->spec->group, 'comb.internal',
    'the class default is untouched';

  ok !eval { Kubernetes::Comb::CRD::Comb->to_crd( grop => 'x' ); 1 }, 'unknown argument dies';
  like $@, qr/unknown argument\(s\) grop/, '... naming it';
  ok !eval { Kubernetes::Comb::CRD::Comb->to_crd( group => '' ); 1 }, 'empty group dies';
};

{
  package MyApp::CRD::Comb;
  use Moo; extends 'Kubernetes::Comb::CRD::Comb';
  sub api_version { 'comb.example.com/v1' }
}

subtest 'another API group: the three-line subclass' => sub {
  is +MyApp::CRD::Comb->kind, 'Comb', 'kind';
  is +MyApp::CRD::Comb->resource_plural, 'combs', 'plural inherited';
  ok +MyApp::CRD::Comb->DOES('IO::K8s::Role::Namespaced'), 'namespaced inherited';

  my $crd = MyApp::CRD::Comb->to_crd;
  is $crd->metadata->name, 'combs.comb.example.com', 'to_crd follows the subclass group';
  is_deeply decode_json( $crd->to_json )->{spec}{versions}[0]{subresources},
    { status => {} }, 'with the status subresource';

  my $provider = Kubernetes::Comb::CRD->new( crd_class => 'MyApp::CRD::Comb' );
  is_deeply $provider->resource_map, {
    'Comb'                     => '+MyApp::CRD::Comb',
    'comb.example.com/v1/Comb' => '+MyApp::CRD::Comb'
  }, 'resource map of the provider';

  my $cr = IO::K8s->new( with => [$provider] )->inflate({
    apiVersion => 'comb.example.com/v1', kind => 'Comb',
    metadata   => { name => 'nats' }, spec => { class => 'A', upstream => undef }
  });
  isa_ok $cr, 'MyApp::CRD::Comb';
  ok $cr->spec->has_upstream, 'with the same spec semantics';
  is decode_json( $cr->to_json )->{apiVersion}, 'comb.example.com/v1', 'written in its group';
};

subtest 'resource map provider' => sub {
  my $provider = Kubernetes::Comb::CRD->new;
  ok $provider->DOES('IO::K8s::Role::ResourceMap'), 'is an IO::K8s resource map provider';
  is $provider->crd_class, 'Kubernetes::Comb::CRD::Comb', 'default class';
  is_deeply $provider->resource_map, {
    'Comb'                  => '+Kubernetes::Comb::CRD::Comb',
    'comb.internal/v1/Comb' => '+Kubernetes::Comb::CRD::Comb'
  }, 'Kind and qualified name';
  is $k8s->expand_class('Comb'), 'Kubernetes::Comb::CRD::Comb', 'IO::K8s resolves the Kind';
};

done_testing;
