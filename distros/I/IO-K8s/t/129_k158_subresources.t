#!/usr/bin/env perl
# k158, part 2: a class declares the subresources its CRD serves.
#
# Claims:
#   * `use IO::K8s::APIObject subresources => {...}` installs a fixed
#     identity class method, validated at import: only status (an empty
#     hash) and scale (specReplicasPath and statusReplicasPath, optional
#     labelSelectorPath); anything else croaks naming class and key;
#   * to_crd / IO::K8s::CRD->new write each class's subresources into its
#     versions[] entry, and nothing without the parameter;
#   * symmetry (k112): add_crd carries a version's subresources into the
#     generated class, so to_crd writes them back; a malformed section
#     fails before the class is marked begun;
#   * IO::K8s::CRD::Emitter renders the import parameter, and leaves it out
#     when told to (what maint/crd-drift-check.pl --check does while the
#     shipped provider classes declare none).
use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use JSON::MaybeXS qw( decode_json );

use IO::K8s;
use IO::K8s::AutoGen;
use IO::K8s::CRD;
use IO::K8s::CRD::Emitter;

{
  package Test158Sub::Plain;
  use IO::K8s::APIObject
    api_version     => 'k158sub.example.com/v1',
    resource_plural => 'plains';
  with 'IO::K8s::Role::Namespaced';

  k8s spec => Opaque;

  1;
}

{
  package Test158Sub::Status;
  use IO::K8s::APIObject
    api_version     => 'k158sub.example.com/v1',
    resource_plural => 'statuses',
    subresources    => { status => {} };
  with 'IO::K8s::Role::Namespaced';

  k8s spec   => Opaque;
  k8s status => Opaque;

  1;
}

my %SCALE = (
  specReplicasPath   => '.spec.replicas',
  statusReplicasPath => '.status.replicas',
  labelSelectorPath  => '.status.selector'
);

{
  package Test158Sub::Scaled;
  use IO::K8s::APIObject
    api_version     => 'k158sub.example.com/v1',
    resource_plural => 'scaleds',
    subresources    => {
      status => {},
      scale  => {
        specReplicasPath   => '.spec.replicas',
        statusReplicasPath => '.status.replicas',
        labelSelectorPath  => '.status.selector'
      }
    };

  k8s spec   => { replicas => Int };
  k8s status => { replicas => Int, selector => Str };

  1;
}

{
  package Test158Sub::V1beta1::Widget;
  use IO::K8s::APIObject
    api_version     => 'k158multi.example.com/v1beta1',
    resource_plural => 'widgets';

  k8s spec => Opaque;

  1;
}

{
  package Test158Sub::V1::Widget;
  use IO::K8s::APIObject
    api_version     => 'k158multi.example.com/v1',
    resource_plural => 'widgets',
    subresources    => { status => {} };

  k8s spec => Opaque;

  1;
}

sub versions_of { decode_json($_[0]->to_json)->{spec}{versions} }

# -- the identity method ----------------------------------------------------

subtest 'subresources is a fixed identity method' => sub {
  is_deeply(Test158Sub::Status->subresources, { status => {} }, 'class method');
  is_deeply(Test158Sub::Scaled->subresources, { status => {}, scale => { %SCALE } }, 'status and scale');
  my $obj = Test158Sub::Status->new(metadata => { name => 's' });
  is_deeply($obj->subresources, { status => {} }, 'on an instance too');

  my $copy = Test158Sub::Scaled->subresources;
  $copy->{scale}{specReplicasPath} = '.spec.other';
  $copy->{extra} = {};
  is_deeply(Test158Sub::Scaled->subresources, { status => {}, scale => { %SCALE } },
    'every call returns a fresh copy; editing one changes nothing');

  throws_ok { Test158Sub::Status->subresources({}) }
    qr/subresources is fixed for this class and cannot be set/, 'an argument croaks (k67)';
  ok(!Test158Sub::Plain->can('subresources'), 'a class without the parameter has no such method');
};

# -- to_crd and IO::K8s::CRD->new -------------------------------------------

subtest 'to_crd writes versions[].subresources from the class' => sub {
  my $plain = versions_of(Test158Sub::Plain->to_crd);
  ok(!exists $plain->[0]{subresources}, 'no parameter, no key -- as before');

  like(Test158Sub::Status->to_crd->to_json, qr/"subresources":\{"status":\{\}\}/,
    'status: an empty object on the wire');
  is_deeply(versions_of(Test158Sub::Scaled->to_crd)->[0]{subresources},
    { status => {}, scale => { %SCALE } }, 'status and scale');
};

subtest 'IO::K8s::CRD->new takes each version from its own class' => sub {
  my $crd = IO::K8s::CRD->new(
    classes => [ 'Test158Sub::V1beta1::Widget', 'Test158Sub::V1::Widget' ],
    storage => 'v1',
  );
  my $versions = versions_of($crd);
  is($versions->[0]{name}, 'v1beta1', 'first version');
  ok(!exists $versions->[0]{subresources}, 'v1beta1 declares none');
  is_deeply($versions->[1]{subresources}, { status => {} }, 'v1 declares status');
};

# -- validation at import ---------------------------------------------------

my $n = 0;
sub declare {
  my ($subresources) = @_;
  my $class = 'Test158Sub::Bad' . ++$n;
  my $ok = eval "package $class; use IO::K8s::APIObject api_version => 'k158bad.example.com/v1',"
    . " resource_plural => 'bads', subresources => $subresources; 1";
  return $ok ? undef : $@;
}

subtest 'validation at import croaks naming the class and the key' => sub {
  my @cases = (
    [ '[]',                                            qr/Test158Sub::Bad\d+: subresources must be a hashref/, 'not a hashref' ],
    [ 'undef',                                         qr/Test158Sub::Bad\d+: subresources must be a hashref/, 'undef' ],
    [ '{ status => {}, foo => {} }',                   qr/Test158Sub::Bad\d+: unknown subresource 'foo' \(known: scale, status\)/, 'unknown subresource' ],
    [ '{ status => { enabled => 1 } }',                qr/Test158Sub::Bad\d+: subresource 'status' must be an empty hashref/, 'status with content' ],
    [ '{ status => 1 }',                               qr/Test158Sub::Bad\d+: subresource 'status' must be an empty hashref/, 'status not a hash' ],
    [ '{ scale => [] }',                               qr/Test158Sub::Bad\d+: subresource 'scale' must be a hashref/, 'scale not a hash' ],
    [ "{ scale => { statusReplicasPath => '.s' } }",   qr/Test158Sub::Bad\d+: subresource 'scale' needs 'specReplicasPath'/, 'specReplicasPath missing' ],
    [ "{ scale => { specReplicasPath => '.s' } }",     qr/Test158Sub::Bad\d+: subresource 'scale' needs 'statusReplicasPath'/, 'statusReplicasPath missing' ],
    [ "{ scale => { specReplicasPath => '.a', statusReplicasPath => '.b', replicas => '.c' } }",
      qr/Test158Sub::Bad\d+: unknown key 'replicas' in subresource 'scale' \(known: labelSelectorPath, specReplicasPath, statusReplicasPath\)/, 'unknown scale key' ],
    [ "{ scale => { specReplicasPath => '.a', statusReplicasPath => '.b', labelSelectorPath => '' } }",
      qr/Test158Sub::Bad\d+: 'labelSelectorPath' in subresource 'scale' must be a non-empty string/, 'empty labelSelectorPath' ],
    [ "{ scale => { specReplicasPath => ['.a'], statusReplicasPath => '.b' } }",
      qr/Test158Sub::Bad\d+: 'specReplicasPath' in subresource 'scale' must be a non-empty string/, 'a path that is a reference' ],
  );
  for my $case (@cases) {
    my ($source, $re, $label) = @$case;
    like(declare($source) // 'lived', $re, $label);
  }
  is(declare('{}'), undef, 'an empty hashref declares no subresource and is allowed');
  is(declare("{ scale => { specReplicasPath => '.a', statusReplicasPath => '.b' } }"), undef,
    'scale without labelSelectorPath is allowed');
  is_deeply(versions_of("Test158Sub::Bad$n"->to_crd)->[0]{subresources},
    { scale => { specReplicasPath => '.a', statusReplicasPath => '.b' } }, 'and written as given');
};

# -- add_crd / AutoGen symmetry (k112) --------------------------------------

sub manifest {
  my (%subresources) = @_;
  return {
    apiVersion => 'apiextensions.k8s.io/v1',
    kind       => 'CustomResourceDefinition',
    metadata   => { name => 'gadgets.k158crd.example.com' },
    spec       => {
      group => 'k158crd.example.com',
      scope => 'Namespaced',
      names => { kind => 'Gadget', plural => 'gadgets', singular => 'gadget', listKind => 'GadgetList' },
      versions => [
        { name => 'v1alpha1', served => JSON::MaybeXS::true, storage => JSON::MaybeXS::false,
          schema => { openAPIV3Schema => { type => 'object', properties => { spec => { type => 'object', properties => { size => { type => 'integer' } } } } } } },
        { name => 'v1', served => JSON::MaybeXS::true, storage => JSON::MaybeXS::true,
          %subresources,
          schema => { openAPIV3Schema => { type => 'object', properties => {
            spec   => { type => 'object', properties => { replicas => { type => 'integer' } } },
            status => { type => 'object', properties => { replicas => { type => 'integer' }, selector => { type => 'string' } } },
          } } } },
      ],
    },
  };
}

subtest 'add_crd carries subresources into the class, to_crd writes them back' => sub {
  my $subresources = { status => {}, scale => { %SCALE } };
  my $crd = manifest(subresources => $subresources);

  my $served = IO::K8s::CRD->served_versions($crd);
  ok(!exists $served->[0]{subresources}, 'served_versions: v1alpha1 has none');
  is_deeply($served->[1]{subresources}, $subresources, 'served_versions: v1 carries them');

  my $k8s = IO::K8s->new;
  my $classes = $k8s->add_crd($crd)->{Gadget};
  my ($alpha, $v1) = @{$classes}{qw( k158crd.example.com/v1alpha1 k158crd.example.com/v1 )};
  ok(!$alpha->can('subresources'), 'the v1alpha1 class has no subresources method');
  is_deeply($v1->subresources, $subresources, 'the v1 class returns the manifest\'s subresources');
  throws_ok { $v1->subresources({}) } qr/subresources is fixed for this class/, 'fixed there too';

  is_deeply(versions_of($v1->to_crd)->[0]{subresources}, $subresources, 'to_crd of the v1 class writes them');
  my $versions = versions_of(IO::K8s::CRD->new(classes => [ $alpha, $v1 ], storage => 'v1'));
  ok(!exists $versions->[0]{subresources}, 'round trip: v1alpha1 still without');
  is_deeply($versions->[1]{subresources}, $crd->{spec}{versions}[1]{subresources},
    'round trip CRD -> class -> to_crd: v1 subresources as in the manifest');
};

subtest 'the knob fixture: status on v1 only' => sub {
  my $k8s = IO::K8s->new;
  my $classes = $k8s->add_crd("$FindBin::Bin/data/crd-knob.yaml")->{Knob};
  is_deeply($classes->{'opts.example.com/v1'}->subresources, { status => {} }, 'v1 serves status');
  ok(!$classes->{'opts.example.com/v1alpha1'}->can('subresources'), 'v1alpha1 declares none');
};

subtest 'a malformed subresources section fails before the class is begun' => sub {
  my $k8s = IO::K8s->new;
  throws_ok { $k8s->add_crd(manifest(subresources => { status => { on => 1 } })) }
    qr/subresource 'status' must be an empty hashref/, 'add_crd croaks on it';
  my $classes;
  lives_ok { $classes = $k8s->add_crd(manifest(subresources => { status => {} })) }
    'the repaired manifest works in the same instance: nothing was marked failed';
  is_deeply($classes->{Gadget}{'k158crd.example.com/v1'}->subresources, { status => {} }, 'and carries status');
};

# -- the emitter ------------------------------------------------------------

subtest 'the emitter renders the import parameter' => sub {
  my $crd = manifest(subresources => { status => {}, scale => { %SCALE } });
  my $generated = IO::K8s::CRD->generate($crd, 'IO::K8s::_AUTOGEN_k158emit');
  my $root = $generated->{'k158crd.example.com/v1'};

  my $files = IO::K8s::CRD::Emitter->new(base => 'Test158Emit::V1', version => '1.108')->render($root);
  my $src = $files->{'Test158Emit/V1/Gadget.pm'};
  like($src, qr/^use IO::K8s::APIObject\n    api_version     => 'k158crd\.example\.com\/v1',\n    resource_plural => 'gadgets',\n    subresources    => \{\n        scale  => \{\n            labelSelectorPath  => '\.status\.selector',\n            specReplicasPath   => '\.spec\.replicas',\n            statusReplicasPath => '\.status\.replicas'\n        \},\n        status => \{\}\n    \};$/m,
    'scale and status, sorted and aligned, no trailing commas');
  for my $path (sort keys %$files) {
    ok(eval "$files->{$path}\n1;", 'compiles: '.$path) or diag $@;
  }
  is_deeply(Test158Emit::V1::Gadget->subresources, { status => {}, scale => { %SCALE } },
    'the rendered class declares the same subresources');
  is_deeply(versions_of(Test158Emit::V1::Gadget->to_crd)->[0]{subresources},
    { status => {}, scale => { %SCALE } }, 'and its to_crd writes them');

  my $alpha = IO::K8s::CRD::Emitter->new(base => 'Test158EmitA::V1alpha1', version => '1.108')
    ->render($generated->{'k158crd.example.com/v1alpha1'});
  like($alpha->{'Test158EmitA/V1alpha1/Gadget.pm'},
    qr/^use IO::K8s::APIObject\n    api_version     => 'k158crd\.example\.com\/v1alpha1',\n    resource_plural => 'gadgets';$/m,
    'a version without subresources renders as before');

  my $status_only = IO::K8s::CRD::Emitter->new(base => 'Test158EmitS::V1', version => '1.108')
    ->render(IO::K8s::CRD->generate(manifest(subresources => { status => {} }), 'IO::K8s::_AUTOGEN_k158emits')
      ->{'k158crd.example.com/v1'});
  like($status_only->{'Test158EmitS/V1/Gadget.pm'},
    qr/^    resource_plural => 'gadgets',\n    subresources    => \{ status => \{\} \};$/m,
    'status alone stays on one line');

  my $scale_only = IO::K8s::CRD::Emitter->new(base => 'Test158EmitC::V1', version => '1.108')
    ->render(IO::K8s::CRD->generate(
      manifest(subresources => { scale => { specReplicasPath => '.spec.replicas', statusReplicasPath => '.status.replicas' } }),
      'IO::K8s::_AUTOGEN_k158emitc')->{'k158crd.example.com/v1'});
  like($scale_only->{'Test158EmitC/V1/Gadget.pm'},
    qr/^    subresources    => \{\n        scale => \{\n            specReplicasPath   => '\.spec\.replicas',\n            statusReplicasPath => '\.status\.replicas'\n        \}\n    \};$/m,
    'scale alone: aligned on its own key');
  my $empty = IO::K8s::CRD::Emitter->new(base => 'Test158EmitE::V1', version => '1.108')
    ->render(IO::K8s::CRD->generate(manifest(subresources => {}), 'IO::K8s::_AUTOGEN_k158emite')
      ->{'k158crd.example.com/v1'});
  like($empty->{'Test158EmitE/V1/Gadget.pm'}, qr/^    subresources    => \{\};$/m,
    'an empty declaration renders as {}, round-tripping subresources: {}');

  my $without = IO::K8s::CRD::Emitter->new(base => 'Test158EmitW::V1', version => '1.108', subresources => 0)
    ->render($root);
  like($without->{'Test158EmitW/V1/Gadget.pm'},
    qr/^use IO::K8s::APIObject\n    api_version     => 'k158crd\.example\.com\/v1',\n    resource_plural => 'gadgets';$/m,
    'subresources => 0 leaves the parameter out');
};

done_testing;
