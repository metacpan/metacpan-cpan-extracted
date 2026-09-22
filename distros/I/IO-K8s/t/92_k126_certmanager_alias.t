#!/usr/bin/env perl
# k126: CRD source generation must preserve cert-manager's distinct Venafi
# credentials-reference schema, merge aliases whose wire DSL differs only in
# contextual documentation, and fail closed before a target file loses a
# non-identical generated class. All CRD documents are literal local fixtures.
use strict;
use warnings;
use utf8;
use Test::More;
use Test::Exception;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Open3 qw(open3);
use Path::Tiny qw(path);
use Symbol qw(gensym);

use IO::K8s::AutoGen;
use IO::K8s::CRD;
use IO::K8s::CRD::Emitter;
use IO::K8s::CertManager::V1::ClusterIssuer;
use IO::K8s::CertManager::V1::Issuer;
use IO::K8s::CertManager::V1::LocalObjectReference;

sub spec_schema {
  my ($class) = @_;
  return $class->to_crd->TO_JSON
    ->{spec}{versions}[0]{schema}{openAPIV3Schema}{properties}{spec};
}

sub nested_property {
  my ($schema, @path) = @_;
  for my $part (@path) {
    $schema = $schema->{properties}{$part};
  }
  return $schema;
}

sub selector_schema {
  my ($object_description, $value_description, $type, $options) = @_;
  return {
    type        => 'object',
    description => $object_description,
    properties  => {
      value => {
        type        => $type,
        description => $value_description,
        %{ $options // {} },
      },
    },
  };
}

sub collision_root {
  my ($kind, $right_type, $right_options, $description_suffix) = @_;
  my ($left_suffix, $right_suffix) = ref $description_suffix eq 'ARRAY'
    ? @$description_suffix
    : (($description_suffix // ''), ($description_suffix // ''));
  my $schema = {
    type => 'object',
    'x-kubernetes-group-version-kind' => [ {
      group   => 'collision.example.com',
      version => 'v1',
      kind    => $kind,
    } ],
    properties => {
      spec => {
        type       => 'object',
        properties => {
          left => selector_schema(
            'Issuer-local SecretKeySelector.' . $left_suffix,
            'Name of the Issuer credential.' . $left_suffix,
            'string',
          ),
          right => selector_schema(
            'ClusterIssuer-global SecretKeySelector.' . $right_suffix,
            'Name of the ClusterIssuer credential.' . $right_suffix,
            $right_type,
            $right_options,
          ),
        },
      },
    },
  };
  return IO::K8s::AutoGen::get_or_generate(
    'collision.example.com.v1.' . $kind,
    $schema,
    {},
    'IO::K8s::_AUTOGEN_k126_' . $kind,
    api_version     => 'collision.example.com/v1',
    kind            => $kind,
    resource_plural => lc($kind) . 's',
    is_namespaced   => 1,
  );
}

sub crd_document {
  my ($kind, $plural, $field, $leaf_type, $minimum) = @_;
  my $object_description = $kind eq 'Issuer'
    ? 'Issuer-local SecretKeySelector.'
    : 'ClusterIssuer-global SecretKeySelector.';
  my $value_description = $kind eq 'Issuer'
    ? 'Name of the Issuer credential.'
    : 'Name of the ClusterIssuer credential.';
  my $minimum_line = defined $minimum ? "                      minimum: $minimum\n" : '';
  return <<"YAML";
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: $plural.cert-manager.io
spec:
  group: cert-manager.io
  names:
    kind: $kind
    plural: $plural
  scope: Namespaced
  versions:
    - name: v1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                $field:
                  type: object
                  description: $object_description
                  properties:
                    value:
                      type: $leaf_type
                      description: $value_description
$minimum_line
YAML
}

sub run_command {
  my (@command) = @_;
  my $stderr = gensym;
  my $pid = open3(undef, my $stdout, $stderr, @command);
  local $/;
  my $out = <$stdout> // '';
  my $err = <$stderr> // '';
  waitpid $pid, 0;
  return ($? >> 8, $out . $err);
}

sub drift_collision_run {
  my ($same, $mode) = @_;
  my $dir = tempdir(CLEANUP => 1);
  path($dir, 'issuer.yaml')->spew_utf8(
    crd_document('Issuer', 'issuers', 'left', 'string'),
  );
  path($dir, 'clusterissuer.yaml')->spew_utf8(
    crd_document(
      'ClusterIssuer',
      'clusterissuers',
      'right',
      $same ? 'string' : 'integer',
      $same ? undef : 1,
    ),
  );
  path($dir, 'overlay.yaml')->spew_utf8(<<'YAML');
base: V1
kinds:
  Issuer:
    names:
      Spec::Left: SecretKeySelector
  ClusterIssuer:
    names:
      Spec::Right: SecretKeySelector
YAML

  return run_command(
    $^X,
    "$FindBin::Bin/../maint/crd-drift-check.pl",
    '--provider', 'CertManager',
    '--dir', $dir,
    '--overlay', "$dir/overlay.yaml",
    '--' . $mode,
  );
}

sub output_sources_for {
  my ($output, $path) = @_;
  return $output =~ m{^#### \Q$path\E\n(.*?)(?=^#### |\z)}msg;
}

subtest 'Venafi credentialsRef keeps cert-manager schema, not core LocalObjectReference' => sub {
  my $expected = {
    properties => { name => { type => 'string' } },
    required   => ['name'],
    type       => 'object',
  };
  my @cases = (
    [ 'Issuer NGTS',         'IO::K8s::CertManager::V1::Issuer',        qw(venafi ngts credentialsRef) ],
    [ 'Issuer TPP',          'IO::K8s::CertManager::V1::Issuer',        qw(venafi tpp credentialsRef) ],
    [ 'ClusterIssuer NGTS',  'IO::K8s::CertManager::V1::ClusterIssuer', qw(venafi ngts credentialsRef) ],
    [ 'ClusterIssuer TPP',   'IO::K8s::CertManager::V1::ClusterIssuer', qw(venafi tpp credentialsRef) ],
  );
  for my $case (@cases) {
    my ($label, $class, @path) = @$case;
    my $credentials_ref = nested_property(spec_schema($class), @path);
    ok(!exists $credentials_ref->{properties}{name}{default},
      "$label credentialsRef has no LocalObjectReference name default on the CRD wire");
    is_deeply($credentials_ref, $expected,
      "$label credentialsRef has required name and no invented default on the CRD wire");
  }
};

subtest 'the established cert-manager local reference keeps its allowed empty default' => sub {
  my $schema = IO::K8s::CRD::_schema_for_class(
    'IO::K8s::CertManager::V1::LocalObjectReference',
  );
  my $has_required_name = grep { $_ eq 'name' } @{ $schema->{required} // [] };
  ok(!$has_required_name,
    'the non-Venafi LocalObjectReference name remains schema-optional');
  is_deeply($schema->{properties}{name}, { default => '', type => 'string' },
    'the non-Venafi LocalObjectReference wire schema still permits its established empty name default');
};

subtest 'the emitter rejects every functional target collision with complete provenance' => sub {
  my @cases = (
    [
      'Different',
      'integer',
      { minimum => 1 },
      'a different field type and option',
    ],
    [
      'OptionOnly',
      'string',
      { pattern => '^[a-z]+$' },
      'an option-only difference with the same scalar type',
    ],
  );
  for my $case (@cases) {
    my ($kind, $right_type, $right_options, $difference) = @$case;
    my $root = collision_root($kind, $right_type, $right_options);
    my $left  = $root . '::Spec::Left';
    my $right = $root . '::Spec::Right';
    my $emitter = IO::K8s::CRD::Emitter->new(
      base  => 'TestK126' . $kind . '::V1',
      names => {
        $left  => 'Shared',
        $right => 'Shared',
      },
    );
    my $target = 'TestK126' . $kind . '/V1/Shared.pm';
    throws_ok { $emitter->render($root) }
      qr{(?=.*\Q$target\E)(?=.*\Q$left\E)(?=.*\Q$right\E)}s,
      "$difference names Shared.pm plus both logical generated classes before rejecting it";
  }
};

subtest 'the emitter shares a SecretKeySelector target when only documentation differs' => sub {
  my $aliases = collision_root('DescriptionAlias', 'string');
  my $left    = $aliases . '::Spec::Left';
  my $right   = $aliases . '::Spec::Right';

  my $preview = IO::K8s::CRD::Emitter->new(
    base  => 'TestK126DescriptionPreview::V1',
    names => {
      $left  => 'IssuerSecretKeySelector',
      $right => 'ClusterIssuerSecretKeySelector',
    },
  )->render($aliases);
  my $left_source = $preview->{'TestK126DescriptionPreview/V1/IssuerSecretKeySelector.pm'};
  my $right_source = $preview->{'TestK126DescriptionPreview/V1/ClusterIssuerSecretKeySelector.pm'};
  like($left_source, qr/Issuer-local SecretKeySelector/, 'one alias has its Issuer-specific ABSTRACT/POD');
  like($right_source, qr/ClusterIssuer-global SecretKeySelector/, 'the other alias has its ClusterIssuer-specific ABSTRACT/POD');
  is_deeply(
    [ grep { /^k8s / } split /\n/, $left_source ],
    [ grep { /^k8s / } split /\n/, $right_source ],
    'the two contextually documented classes have the same functional DSL',
  );

  my $emitter = IO::K8s::CRD::Emitter->new(
    base  => 'TestK126DescriptionAlias::V1',
    names => {
      $left  => 'SecretKeySelector',
      $right => 'SecretKeySelector',
    },
  );
  my $files;
  lives_ok { $files = $emitter->render($aliases) }
    'the description-only aliases may reuse one SecretKeySelector target';
  return unless $files;

  my $target = 'TestK126DescriptionAlias/V1/SecretKeySelector.pm';
  is(scalar(grep { $_ eq $target } keys %$files), 1,
    'the shared SecretKeySelector target is kept exactly once');
  my $source = $files->{$target};
  is_deeply([ grep { /^k8s / } split /\n/, $source ], [ 'k8s value => Str;' ],
    'the retained source has the expected scalar wire DSL without a type or option change');

  my $class = 'TestK126DescriptionAlias::V1::SecretKeySelector';
  ok(eval "$source\n1;", 'the retained source compiles') or diag $@;
  is_deeply($class->new(value => 'credential')->TO_JSON, { value => 'credential' },
    'the retained alias serializes the expected SecretKeySelector wire shape');
  my $schema = IO::K8s::CRD::_schema_for_class($class);
  is($schema->{type}, 'object', 'the retained alias is an object schema');
  is_deeply($schema->{properties}, { value => { type => 'string' } },
    'the retained alias re-emits the expected schema form');
};

subtest 'the emitter shares a target when Unicode exists only in contextual documentation' => sub {
  my $aliases = collision_root(
    'UnicodeDescriptionAlias',
    'string',
    undef,
    [ '', ' Documentation mentions Gültigkeit.' ],
  );
  my $left  = $aliases . '::Spec::Left';
  my $right = $aliases . '::Spec::Right';
  my $emitter = IO::K8s::CRD::Emitter->new(
    base  => 'TestK126UnicodeDescriptionAlias::V1',
    names => {
      $left  => 'SecretKeySelector',
      $right => 'SecretKeySelector',
    },
  );
  my $files;
  lives_ok { $files = $emitter->render($aliases) }
    'a documentation-only use utf8 difference does not turn an alias into a collision';
  return unless $files;

  my $source = $files->{'TestK126UnicodeDescriptionAlias/V1/SecretKeySelector.pm'};
  like($source, qr/^use utf8;$/m,
    'the retained documented source still declares use utf8 for its Unicode POD');
  like($source, qr/^=encoding UTF-8$/m,
    'the retained documented source declares UTF-8 POD encoding');
  is_deeply([ grep { /^k8s / } split /\n/, $source ], [ 'k8s value => Str;' ],
    'the Unicode documentation difference leaves the generated wire DSL unchanged');
  ok(eval "$source\n1;", 'the retained Unicode-documentation source compiles') or diag $@;
};

subtest 'local --render and --suggest retain one description-only alias and reject schema changes' => sub {
  my $target = 'IO/K8s/CertManager/V1/SecretKeySelector.pm';
  my $provenance = qr{
    (?=.*non-identical\ GVK\ sources)
    (?=.*SecretKeySelector\.pm)
    (?=.*cert-manager\.io/v1/Issuer)
    (?=.*cert-manager\.io/v1/ClusterIssuer)
  }xs;
  for my $mode (qw(render suggest)) {
    my ($different_status, $different_output) = drift_collision_run(0, $mode);
    isnt($different_status, 0,
      "--$mode rejects different Issuer/ClusterIssuer field types or options targeting SecretKeySelector.pm");
    like($different_output, $provenance,
      "--$mode names SecretKeySelector.pm plus both colliding cert-manager.io/v1 GVK sources");

    my ($alias_status, $alias_output) = drift_collision_run(1, $mode);
    is($alias_status, 0,
      "--$mode permits schema-identical Issuer/ClusterIssuer SecretKeySelector aliases with contextual documentation");
    next unless $alias_status == 0;

    my @shared = output_sources_for($alias_output, $target);
    is(scalar @shared, 1,
      "--$mode emits the shared SecretKeySelector source exactly once without fixing which documentation wins");
    next unless @shared == 1;
    is_deeply([ grep { /^k8s / } split /\n/, $shared[0] ], [ 'k8s value => Str;' ],
      "--$mode retains the expected functional DSL in the shared source");
  }
};

done_testing;
