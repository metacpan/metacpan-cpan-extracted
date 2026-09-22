#!/usr/bin/env perl
# k121: VolumeGroupSnapshot was added in external-snapshotter v8.6.0.
#
# The literal structures below are pinned to the three official CRDs under
# client/config/crd/groupsnapshot.storage.k8s.io_*.yaml and to
# client/apis/volumegroupsnapshot/{v1,v1beta1,v1beta2}/types.go at v8.6.0.
# They intentionally do not read those inputs: this test has no cache,
# filesystem fixture, cluster, or network dependency.
use strict;
use warnings;
use Test::More;
use Test::Exception;
use JSON::MaybeXS ();
use Module::Runtime qw( require_module );

use IO::K8s;
use IO::K8s::CRD;
use IO::K8s::VolumeSnapshot;

my $GROUP = 'groupsnapshot.storage.k8s.io';
my @TRACKS = qw( V1 V1beta1 V1beta2 );
my %API_VERSION = (
  V1      => $GROUP.'/v1',
  V1beta1 => $GROUP.'/v1beta1',
  V1beta2 => $GROUP.'/v1beta2'
);
my @KINDS = qw( VolumeGroupSnapshot VolumeGroupSnapshotClass VolumeGroupSnapshotContent );
my %KIND_INFO = (
  VolumeGroupSnapshot        => { plural => 'volumegroupsnapshots',        namespaced => 1 },
  VolumeGroupSnapshotClass   => { plural => 'volumegroupsnapshotclasses',  namespaced => 0 },
  VolumeGroupSnapshotContent => { plural => 'volumegroupsnapshotcontents', namespaced => 0 }
);
my @COMMON_TYPES = qw(
  VolumeGroupSnapshot
  VolumeGroupSnapshotClass
  VolumeGroupSnapshotContent
  VolumeGroupSnapshotSpec
  VolumeGroupSnapshotSource
  VolumeGroupSnapshotStatus
  VolumeGroupSnapshotContentSpec
  VolumeGroupSnapshotContentStatus
  VolumeGroupSnapshotContentSource
  GroupSnapshotHandles
);

sub class_for {
  my ($track, $name) = @_;
  return 'IO::K8s::VolumeSnapshot::'.$track.'::'.$name;
}

sub leaf_type_for {
  my ($track) = @_;
  return $track eq 'V1beta1' ? 'VolumeSnapshotHandlePair' : 'VolumeSnapshotInfo';
}

sub all_model_classes {
  my @classes;
  for my $track (@TRACKS) {
    push @classes, map { class_for($track, $_) } @COMMON_TYPES;
    push @classes, class_for($track, leaf_type_for($track));
  }
  return @classes;
}

# This is deliberately an evalled runtime load rather than `use` statements
# for the new classes. Before k121's implementation exists, every missing
# model is a failed assertion instead of a compile-time abort that hides the
# remainder of this regression contract.
sub model_class_loads {
  my ($class) = @_;
  my $loaded = eval {
    require_module($class);
    die $class.' has no constructor' unless $class->can('new');
    1;
  };
  return ($loaded ? 1 : 0, $@);
}

my %model_loaded;
subtest 'the checked-in model surface contains exactly the 33 reachable group-snapshot types' => sub {
  for my $class (all_model_classes()) {
    my ($loaded, $error) = model_class_loads($class);
    $model_loaded{$class} = $loaded;
    ok($loaded, $class.' is a loadable model class') or diag($error);
  }

  # v1/v1beta2 deliberately refer to VolumeSnapshotInfo. The upstream Go
  # source retains a commented former member in v1, but no CRD schema reaches
  # a VolumeSnapshotHandlePair there, so shipping it would expose dead API.
  for my $track (qw( V1 V1beta2 )) {
    my $class = class_for($track, 'VolumeSnapshotHandlePair');
    my ($loaded) = model_class_loads($class);
    ok(!$loaded, $class.' is not shipped: no served schema references it');
  }

  # The distribution's generic IO::K8s::List handles list Kinds. Do not
  # recreate the nine removed per-Kind list classes for this new provider.
  for my $track (@TRACKS) {
    for my $kind (@KINDS) {
      my $class = class_for($track, $kind.'List');
      my ($loaded) = model_class_loads($class);
      ok(!$loaded, $class.' is not shipped: generic List owns list envelopes');
    }
  }
};

my $models_available = !grep { !$model_loaded{$_} } all_model_classes();

subtest 'VolumeSnapshot provider raw map, all nine GVKs, and storage short names' => sub {
  my $provider = IO::K8s::VolumeSnapshot->new;
  is_deeply(
    $provider->resource_map,
    {
      VolumeSnapshot        => 'VolumeSnapshot::V1::VolumeSnapshot',
      VolumeSnapshotClass   => 'VolumeSnapshot::V1::VolumeSnapshotClass',
      VolumeSnapshotContent => 'VolumeSnapshot::V1::VolumeSnapshotContent',

      VolumeGroupSnapshot        => 'VolumeSnapshot::V1beta2::VolumeGroupSnapshot',
      VolumeGroupSnapshotClass   => 'VolumeSnapshot::V1beta2::VolumeGroupSnapshotClass',
      VolumeGroupSnapshotContent => 'VolumeSnapshot::V1beta2::VolumeGroupSnapshotContent',

      'groupsnapshot.storage.k8s.io/v1/VolumeGroupSnapshot'
        => 'VolumeSnapshot::V1::VolumeGroupSnapshot',
      'groupsnapshot.storage.k8s.io/v1/VolumeGroupSnapshotClass'
        => 'VolumeSnapshot::V1::VolumeGroupSnapshotClass',
      'groupsnapshot.storage.k8s.io/v1/VolumeGroupSnapshotContent'
        => 'VolumeSnapshot::V1::VolumeGroupSnapshotContent',
      'groupsnapshot.storage.k8s.io/v1beta1/VolumeGroupSnapshot'
        => 'VolumeSnapshot::V1beta1::VolumeGroupSnapshot',
      'groupsnapshot.storage.k8s.io/v1beta1/VolumeGroupSnapshotClass'
        => 'VolumeSnapshot::V1beta1::VolumeGroupSnapshotClass',
      'groupsnapshot.storage.k8s.io/v1beta1/VolumeGroupSnapshotContent'
        => 'VolumeSnapshot::V1beta1::VolumeGroupSnapshotContent'
    },
    'raw provider map preserves the three snapshot entries and registers nine group-snapshot routes'
  );

  my $k8s = IO::K8s->new(with => ['IO::K8s::VolumeSnapshot']);
  for my $track (@TRACKS) {
    for my $kind (@KINDS) {
      my $want = class_for($track, $kind);
      is(
        $k8s->expand_class($kind, $API_VERSION{$track}),
        $want,
        $API_VERSION{$track}.'/'.$kind.' resolves as its exact GVK'
      );
    }
  }

  for my $kind (@KINDS) {
    is(
      $k8s->expand_class($kind),
      class_for('V1beta2', $kind),
      $kind.' bare short name resolves to storage v1beta2'
    );
  }
};

sub field_names {
  my ($class) = @_;
  return [ sort keys %{ $class->_k8s_attr_info } ];
}

my %FIELD_NAMES = (
  VolumeGroupSnapshot        => [qw( metadata spec status )],
  VolumeGroupSnapshotClass   => [qw( deletionPolicy driver metadata parameters )],
  VolumeGroupSnapshotContent => [qw( metadata spec status )],
  VolumeGroupSnapshotSpec    => [qw( source volumeGroupSnapshotClassName )],
  VolumeGroupSnapshotSource  => [qw( selector volumeGroupSnapshotContentName )],
  VolumeGroupSnapshotStatus  => [qw( boundVolumeGroupSnapshotContentName creationTime error readyToUse )],
  VolumeGroupSnapshotContentSpec => [qw(
    deletionPolicy
    driver
    source
    volumeGroupSnapshotClassName
    volumeGroupSnapshotRef
  )],
  VolumeGroupSnapshotContentStatus => [qw(
    creationTime
    error
    readyToUse
    volumeGroupSnapshotHandle
  )],
  VolumeGroupSnapshotContentSource => [qw( groupSnapshotHandles volumeHandles )],
  GroupSnapshotHandles             => [qw( volumeGroupSnapshotHandle volumeSnapshotHandles )],
  VolumeSnapshotInfo               => [qw( creationTime readyToUse restoreSize snapshotHandle volumeHandle )],
  VolumeSnapshotHandlePair         => [qw( snapshotHandle volumeHandle )]
);

sub expected_field_names {
  my ($track, $type) = @_;
  my @names = @{ $FIELD_NAMES{$type} };
  push @names, $track eq 'V1beta1'
    ? 'volumeSnapshotHandlePairList'
    : 'volumeSnapshotInfoList'
    if $type eq 'VolumeGroupSnapshotContentStatus';
  return [ sort @names ];
}

sub schema_for {
  my ($class) = @_;
  return IO::K8s::CRD::_schema_for_class($class);
}

sub schema_default_paths {
  my ($value, $path, $found) = @_;
  if (ref $value eq 'HASH') {
    push @$found, $path if exists $value->{default};
    for my $key (sort keys %$value) {
      schema_default_paths($value->{$key}, $path.'.'.$key, $found);
    }
  } elsif (ref $value eq 'ARRAY') {
    for my $index (0 .. $#$value) {
      schema_default_paths($value->[$index], $path.'['.$index.']', $found);
    }
  }
  return;
}

subtest 'every version has the upstream scopes, field lists, types, and schema-only requireds' => sub {
  plan skip_all => 'k121 model classes are not all available yet' unless $models_available;

  for my $track (@TRACKS) {
    for my $kind (@KINDS) {
      my $class = class_for($track, $kind);
      my $info = $KIND_INFO{$kind};
      is($class->api_version, $API_VERSION{$track}, $track.' '.$kind.' apiVersion');
      is($class->kind, $kind, $track.' '.$kind.' kind');
      is($class->resource_plural, $info->{plural}, $track.' '.$kind.' resource plural');
      if ($info->{namespaced}) {
        ok($class->does('IO::K8s::Role::Namespaced'), $track.' '.$kind.' is namespaced');
      } else {
        ok(!$class->does('IO::K8s::Role::Namespaced'), $track.' '.$kind.' is cluster-scoped');
      }
    }

    my @types = (@COMMON_TYPES, leaf_type_for($track));
    for my $type (@types) {
      my $class = class_for($track, $type);
      my $expected_fields = expected_field_names($track, $type);
      is_deeply(field_names($class), $expected_fields, $track.' '.$type.' models exactly its upstream fields');

      my @schema_fields = @$expected_fields;
      push @schema_fields, qw( apiVersion kind )
        if $type =~ /\AVolumeGroupSnapshot(?:Class|Content)?\z/;
      is_deeply(
        [ sort keys %{ schema_for($class)->{properties} } ],
        [ sort @schema_fields ],
        $track.' '.$type.' emits the same field list to its CRD schema'
      );
    }

    my $source_info = class_for($track, 'VolumeGroupSnapshotSource')->_k8s_attr_info;
    ok($source_info->{selector}{is_object}, $track.' source.selector is a typed object');
    is(
      $source_info->{selector}{class},
      'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector',
      $track.' source.selector reuses the stock LabelSelector'
    );

    my $content_spec_info = class_for($track, 'VolumeGroupSnapshotContentSpec')->_k8s_attr_info;
    ok($content_spec_info->{volumeGroupSnapshotRef}{is_object}, $track.' content spec reference is typed');
    is(
      $content_spec_info->{volumeGroupSnapshotRef}{class},
      'IO::K8s::Api::Core::V1::ObjectReference',
      $track.' content spec reference reuses the stock ObjectReference'
    );

    my $status_info = class_for($track, 'VolumeGroupSnapshotContentStatus')->_k8s_attr_info;
    ok($status_info->{readyToUse}{is_bool}, $track.' content status readyToUse is Bool');
    ok($status_info->{creationTime}{is_time}, $track.' content status creationTime is Time');
    ok($status_info->{error}{is_object}, $track.' content status error is typed');
    is(
      $status_info->{error}{class},
      'IO::K8s::VolumeSnapshot::V1::VolumeSnapshotError',
      $track.' content status reuses the shipped VolumeSnapshotError'
    );

    my $group_status_info = class_for($track, 'VolumeGroupSnapshotStatus')->_k8s_attr_info;
    ok($group_status_info->{readyToUse}{is_bool}, $track.' group status readyToUse is Bool');
    ok($group_status_info->{creationTime}{is_time}, $track.' group status creationTime is Time');
    is(
      $group_status_info->{error}{class},
      'IO::K8s::VolumeSnapshot::V1::VolumeSnapshotError',
      $track.' group status reuses the shipped VolumeSnapshotError'
    );

    my $list_name = $track eq 'V1beta1' ? 'volumeSnapshotHandlePairList' : 'volumeSnapshotInfoList';
    my $other_list_name = $track eq 'V1beta1' ? 'volumeSnapshotInfoList' : 'volumeSnapshotHandlePairList';
    ok($status_info->{$list_name}{is_array_of_objects}, $track.' content status '.$list_name.' is a typed object list');
    is(
      $status_info->{$list_name}{class},
      class_for($track, leaf_type_for($track)),
      $track.' content status list reaches its version-specific leaf type'
    );
    ok(!exists $status_info->{$other_list_name}, $track.' does not declare the other version list field');

    my $leaf_info = class_for($track, leaf_type_for($track))->_k8s_attr_info;
    if ($track eq 'V1beta1') {
      ok($leaf_info->{snapshotHandle}{required}, $track.' handle pair snapshotHandle is schema-required');
      ok($leaf_info->{volumeHandle}{required}, $track.' handle pair volumeHandle is schema-required');
    } else {
      ok($leaf_info->{creationTime}{is_int}, $track.' snapshot info creationTime is Int');
      ok($leaf_info->{readyToUse}{is_bool}, $track.' snapshot info readyToUse is Bool');
      ok($leaf_info->{restoreSize}{is_int}, $track.' snapshot info restoreSize is Int');
    }

    my $class_info = class_for($track, 'VolumeGroupSnapshotClass')->_k8s_attr_info;
    is_deeply($class_info->{deletionPolicy}{options}{enum}, [qw( Delete Retain )], $track.' class deletionPolicy enum matches the CRD');
    ok($class_info->{parameters}{is_hash_of_str}, $track.' class parameters is a string map');

    # All required declarations are OpenAPI metadata. The emitter turns these
    # into `required => 'schema'`, so construction stays permissive while
    # to_crd still writes the exact required arrays below.
    my @required_cases = (
      [ 'VolumeGroupSnapshot',        [qw( spec )] ],
      [ 'VolumeGroupSnapshotSpec',    [qw( source )] ],
      [ 'VolumeGroupSnapshotClass',   [qw( deletionPolicy driver )] ],
      [ 'VolumeGroupSnapshotContent', [qw( spec )] ],
      [ 'VolumeGroupSnapshotContentSpec', [qw( deletionPolicy driver source volumeGroupSnapshotRef )] ],
      [ 'GroupSnapshotHandles', [qw( volumeGroupSnapshotHandle volumeSnapshotHandles )] ]
    );
    push @required_cases, [ 'VolumeSnapshotHandlePair', [qw( snapshotHandle volumeHandle )] ]
      if $track eq 'V1beta1';

    for my $case (@required_cases) {
      my ($type, $required) = @$case;
      my $class = class_for($track, $type);
      my $schema = schema_for($class);
      is_deeply(
        [ sort @{ $schema->{required} || [] } ],
        [ sort @$required ],
        $track.' '.$type.' carries the upstream required list in its generated schema'
      );
      lives_ok { $class->new } $track.' '.$type.' required fields remain schema-only at construction';
    }

    # The three source CRDs contain no `default:` nodes. This guard prevents
    # prose about controller behaviour from turning into an invented wire
    # default in this checked-in model.
    for my $kind (@KINDS) {
      my @default_paths;
      schema_default_paths(schema_for(class_for($track, $kind)), '$', \@default_paths);
      is_deeply(\@default_paths, [], $track.' '.$kind.' schema contains no invented defaults');
    }
  }
};

subtest 'all three group-snapshot tracks are served and only v1beta2 is storage' => sub {
  plan skip_all => 'k121 model classes are not all available yet' unless $models_available;

  for my $kind (@KINDS) {
    my $crd = IO::K8s::CRD->new(
      classes => [ map { class_for($_, $kind) } @TRACKS ],
      storage => 'v1beta2'
    );
    my $versions = $crd->spec->versions;
    is($crd->spec->scope, $KIND_INFO{$kind}{namespaced} ? 'Namespaced' : 'Cluster', $kind.' CRD scope agrees across all versions');
    is_deeply([ map { $_->name } @$versions ], [qw( v1 v1beta1 v1beta2 )], $kind.' CRD serves v1, v1beta1, and v1beta2');
    is_deeply([ map { $_->served ? 1 : 0 } @$versions ], [1, 1, 1], $kind.' marks every shipped version served');
    is_deeply([ map { $_->storage ? 1 : 0 } @$versions ], [0, 0, 1], $kind.' marks v1beta2 alone as storage');
  }
};

sub fixture_for {
  my ($track) = @_;
  my $api = $API_VERSION{$track};
  my $list_name = $track eq 'V1beta1' ? 'volumeSnapshotHandlePairList' : 'volumeSnapshotInfoList';

  my $group_snapshot = {
    apiVersion => $api,
    kind       => 'VolumeGroupSnapshot',
    metadata   => {
      name      => 'app-group-snapshot-'.$track,
      namespace => 'default'
    },
    spec => {
      source => {
        selector => {
          matchLabels => { app => 'database' },
          matchExpressions => [{
            key      => 'tier',
            operator => 'In',
            values   => [qw( primary replica )]
          }]
        }
      },
      volumeGroupSnapshotClassName => 'csi-group-snapshot-class'
    },
    status => {
      boundVolumeGroupSnapshotContentName => 'group-content-'.$track,
      creationTime => '2026-01-02T03:04:05Z',
      readyToUse   => 1,
      error        => {
        message => 'controller retry',
        time    => '2026-01-02T03:04:06Z'
      }
    }
  };
  my %group_status_wire = %{ $group_snapshot->{status} };
  $group_status_wire{readyToUse} = JSON::MaybeXS::true;
  my $group_snapshot_wire = {
    %$group_snapshot,
    status => \%group_status_wire
  };

  my $group_snapshot_class = {
    apiVersion => $api,
    kind       => 'VolumeGroupSnapshotClass',
    metadata   => { name => 'csi-group-snapshot-class' },
    driver     => 'example.csi.io',
    parameters => {
      'csi.storage.k8s.io/secret-name'      => 'group-snapshotter',
      'csi.storage.k8s.io/secret-namespace' => 'default'
    },
    deletionPolicy => 'Delete'
  };

  my $list_entry = $track eq 'V1beta1'
    ? {
      volumeHandle   => 'volume-handle-1',
      snapshotHandle => 'snapshot-handle-1'
    }
    : {
      volumeHandle   => 'volume-handle-1',
      snapshotHandle => 'snapshot-handle-1',
      creationTime   => 1735689600000000000,
      readyToUse     => 0,
      restoreSize    => 5368709120
    };
  my %list_entry_wire = %$list_entry;
  $list_entry_wire{readyToUse} = JSON::MaybeXS::false unless $track eq 'V1beta1';

  my $group_snapshot_content = {
    apiVersion => $api,
    kind       => 'VolumeGroupSnapshotContent',
    metadata   => { name => 'group-content-'.$track },
    spec => {
      volumeGroupSnapshotRef => {
        apiVersion      => $api,
        kind            => 'VolumeGroupSnapshot',
        name            => 'app-group-snapshot-'.$track,
        namespace       => 'default',
        resourceVersion => '42',
        uid             => '11111111-2222-3333-4444-555555555555',
        fieldPath       => 'spec.source'
      },
      deletionPolicy => 'Retain',
      driver         => 'example.csi.io',
      volumeGroupSnapshotClassName => 'csi-group-snapshot-class',
      source => {
        groupSnapshotHandles => {
          volumeGroupSnapshotHandle => 'group-snapshot-handle-1',
          volumeSnapshotHandles     => [qw( snapshot-handle-1 snapshot-handle-2 )]
        }
      }
    },
    status => {
      volumeGroupSnapshotHandle => 'group-snapshot-handle-1',
      creationTime              => '2026-01-02T03:04:05Z',
      readyToUse                => 0,
      error                     => {
        message => 'last controller error',
        time    => '2026-01-02T03:04:07Z'
      },
      $list_name => [ $list_entry ]
    }
  };
  my %content_status_wire = %{ $group_snapshot_content->{status} };
  $content_status_wire{readyToUse} = JSON::MaybeXS::false;
  $content_status_wire{$list_name} = [ \%list_entry_wire ];
  my $group_snapshot_content_wire = {
    %$group_snapshot_content,
    status => \%content_status_wire
  };

  return {
    group_snapshot         => $group_snapshot,
    group_snapshot_wire    => $group_snapshot_wire,
    group_snapshot_class   => $group_snapshot_class,
    group_snapshot_content => $group_snapshot_content,
    group_snapshot_content_wire => $group_snapshot_content_wire,
    list_name              => $list_name
  };
}

sub same_wire {
  my ($json, $got, $want, $label) = @_;
  is($json->encode($got), $json->encode($want), $label);
}

subtest 'complete typed wire round-trips stay correct for every served version' => sub {
  plan skip_all => 'k121 model classes are not all available yet' unless $models_available;

  my $json = JSON::MaybeXS->new(utf8 => 1, canonical => 1);
  my $k8s = IO::K8s->new(strict => 1, with => ['IO::K8s::VolumeSnapshot']);

  for my $track (@TRACKS) {
    my $fixture = fixture_for($track);
    my $group = $k8s->new_object('VolumeGroupSnapshot', $fixture->{group_snapshot});
    my $class = $k8s->new_object('VolumeGroupSnapshotClass', $fixture->{group_snapshot_class});
    my $content = $k8s->new_object('VolumeGroupSnapshotContent', $fixture->{group_snapshot_content});

    isa_ok($group, class_for($track, 'VolumeGroupSnapshot'), $track.' group snapshot inflates as the version-specific Kind');
    isa_ok($group->spec, class_for($track, 'VolumeGroupSnapshotSpec'), $track.' group snapshot spec is typed');
    isa_ok($group->spec->source, class_for($track, 'VolumeGroupSnapshotSource'), $track.' group snapshot source is typed');
    isa_ok($group->spec->source->selector, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector', $track.' selector is the stock LabelSelector');
    isa_ok($group->spec->source->selector->matchExpressions->[0], 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelectorRequirement', $track.' selector requirement is typed');
    isa_ok($group->status, class_for($track, 'VolumeGroupSnapshotStatus'), $track.' group status is typed');
    isa_ok($group->status->error, 'IO::K8s::VolumeSnapshot::V1::VolumeSnapshotError', $track.' group status error reuses VolumeSnapshotError');

    isa_ok($class, class_for($track, 'VolumeGroupSnapshotClass'), $track.' group snapshot class is the version-specific Kind');
    ok(!exists $class->TO_JSON->{spec}, $track.' class has no invented spec wrapper');
    ok(!exists $class->TO_JSON->{status}, $track.' class has no invented status wrapper');

    isa_ok($content, class_for($track, 'VolumeGroupSnapshotContent'), $track.' group content inflates as the version-specific Kind');
    isa_ok($content->spec, class_for($track, 'VolumeGroupSnapshotContentSpec'), $track.' content spec is typed');
    isa_ok($content->spec->volumeGroupSnapshotRef, 'IO::K8s::Api::Core::V1::ObjectReference', $track.' content reference is the stock ObjectReference');
    isa_ok($content->spec->source, class_for($track, 'VolumeGroupSnapshotContentSource'), $track.' content source is typed');
    isa_ok($content->spec->source->groupSnapshotHandles, class_for($track, 'GroupSnapshotHandles'), $track.' group handles are typed');
    isa_ok($content->status, class_for($track, 'VolumeGroupSnapshotContentStatus'), $track.' content status is typed');
    isa_ok($content->status->error, 'IO::K8s::VolumeSnapshot::V1::VolumeSnapshotError', $track.' content status error reuses VolumeSnapshotError');
    isa_ok($content->status->{ $fixture->{list_name} }[0], class_for($track, leaf_type_for($track)), $track.' version-specific content list element is typed');

    same_wire($json, $group->TO_JSON, $fixture->{group_snapshot_wire}, $track.' group TO_JSON emits every representative field');
    same_wire($json, $class->TO_JSON, $fixture->{group_snapshot_class}, $track.' class TO_JSON keeps fields directly on the Kind');
    same_wire($json, $content->TO_JSON, $fixture->{group_snapshot_content_wire}, $track.' content TO_JSON emits every representative field');
    is($group->to_json, $json->encode($fixture->{group_snapshot_wire}), $track.' group to_json is canonical wire JSON');
    is($class->to_json, $json->encode($fixture->{group_snapshot_class}), $track.' class to_json is canonical wire JSON');
    is($content->to_json, $json->encode($fixture->{group_snapshot_content_wire}), $track.' content to_json is canonical wire JSON');

    my $from_hash = class_for($track, 'VolumeGroupSnapshotContent')->FROM_HASH($fixture->{group_snapshot_content_wire});
    isa_ok($from_hash->spec->volumeGroupSnapshotRef, 'IO::K8s::Api::Core::V1::ObjectReference', $track.' FROM_HASH retains the typed object reference');
    isa_ok($from_hash->status->{ $fixture->{list_name} }[0], class_for($track, leaf_type_for($track)), $track.' FROM_HASH retains the typed list element');
    is_deeply($from_hash->spec->_unknown_fields, {}, $track.' FROM_HASH does not hide declared content spec fields in the unknown bag');
    is_deeply($from_hash->status->_unknown_fields, {}, $track.' FROM_HASH does not hide declared content status fields in the unknown bag');
    same_wire($json, $from_hash->TO_JSON, $fixture->{group_snapshot_content_wire}, $track.' content FROM_HASH round-trips to the original wire data');

    my $inflated = $k8s->inflate($content->to_json);
    isa_ok($inflated, class_for($track, 'VolumeGroupSnapshotContent'), $track.' inflate dispatches the exact GVK');
    isa_ok($inflated->spec->source->groupSnapshotHandles, class_for($track, 'GroupSnapshotHandles'), $track.' inflate retains deep typed handles');
    same_wire($json, $inflated->TO_JSON, $fixture->{group_snapshot_content_wire}, $track.' inflate round-trips the complete content wire data');

    my $decoded_group = $json->decode($group->to_json);
    my $decoded_content = $json->decode($content->to_json);
    ok(JSON::MaybeXS::is_bool($decoded_group->{status}{readyToUse}), $track.' group readyToUse is a JSON boolean');
    ok(!JSON::MaybeXS::is_bool($decoded_group->{status}{creationTime}), $track.' group creationTime remains a timestamp string');
    ok(JSON::MaybeXS::is_bool($decoded_content->{status}{readyToUse}), $track.' content readyToUse is a JSON boolean');
    if ($track eq 'V1beta1') {
      ok(!exists $decoded_content->{status}{volumeSnapshotInfoList}, $track.' does not serialize the v1/v1beta2 info field');
    } else {
      my $info = $decoded_content->{status}{volumeSnapshotInfoList}[0];
      ok(JSON::MaybeXS::is_bool($info->{readyToUse}), $track.' snapshot info readyToUse is a JSON boolean');
      is($info->{creationTime}, 1735689600000000000, $track.' snapshot info creationTime is an unquoted Int');
      is($info->{restoreSize}, 5368709120, $track.' snapshot info restoreSize is an unquoted Int');
      like($content->to_json, qr/"creationTime":1735689600000000000/, $track.' JSON writes snapshot info creationTime without quotes');
      like($content->to_json, qr/"restoreSize":5368709120/, $track.' JSON writes snapshot info restoreSize without quotes');
    }
  }
};

done_testing;
