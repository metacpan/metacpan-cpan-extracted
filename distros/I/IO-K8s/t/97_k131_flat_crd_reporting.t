#!/usr/bin/env perl
# k131: a CRD Kind with typed fields directly at its root has no `spec` to
# compare.  It is neither an opaque spec nor a candidate for --suggest;
# preserve-unknown and genuinely opaque roots must remain reported.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Open3 qw(open3);
use JSON::PP;
use Path::Tiny qw(path);
use Symbol qw(gensym);

my $script = "$FindBin::Bin/../maint/crd-drift-check.pl";
ok(-f $script, 'maint/crd-drift-check.pl is there to test')
  or BAIL_OUT('missing maint/crd-drift-check.pl');

sub crd_document {
  my ($kind, $plural, $scope, $schema) = @_;
  return <<"YAML";
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: $plural.snapshot.storage.k8s.io
spec:
  group: snapshot.storage.k8s.io
  names:
    kind: $kind
    plural: $plural
  scope: $scope
  versions:
    - name: v1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
$schema
YAML
}

sub run_drift {
  my ($document, @flags) = @_;
  my $dir = tempdir(CLEANUP => 1);
  path($dir, 'fixture.yaml')->spew_utf8($document);

  my $stderr = gensym;
  my $pid = open3(
    undef,
    my $stdout,
    $stderr,
    $^X,
    $script,
    '--provider', 'VolumeSnapshot',
    '--dir', $dir,
    '--format', 'json',
    @flags
  );
  local $/;
  my $out = <$stdout> // '';
  my $err = <$stderr> // '';
  waitpid $pid, 0;
  return ($? >> 8, $out, $err);
}

sub decode_report {
  my ($stdout, $label) = @_;
  my $report;
  ok(eval { $report = JSON::PP->new->decode($stdout); 1 },
    "$label leaves stdout as one parseable JSON report") or diag $@;
  return $report;
}

sub gvk_entries {
  my ($report, $key, $gvk) = @_;
  return [ grep { $_->[0] eq $gvk } @{ $report->{providers}[0]{$key} } ];
}

my $class_gvk = 'snapshot.storage.k8s.io/v1/VolumeSnapshotClass';
my $snapshot_gvk = 'snapshot.storage.k8s.io/v1/VolumeSnapshot';

subtest 'an explicitly closed flat root is not an opaque spec or --suggest input' => sub {
  my $flat_root = <<'YAML';
          type: object
          x-kubernetes-preserve-unknown-fields: false
          additionalProperties: false
          properties:
            deletionPolicy:
              type: string
            driver:
              type: string
            parameters:
              type: object
              additionalProperties:
                type: string
YAML
  my ($status, $stdout, $stderr) = run_drift(
    crd_document('VolumeSnapshotClass', 'volumesnapshotclasses', 'Cluster', $flat_root),
    '--suggest'
  );
  is($status, 0, 'the local flat VolumeSnapshotClass fixture is accepted');
  my $report = decode_report($stdout, 'the flat root report');
  return unless $report;

  is_deeply(
    gvk_entries($report, 'opaque_spec', $class_gvk),
    [],
    'VolumeSnapshotClass fields directly at a closed root are not a fictional opaque spec'
  );
  unlike(
    $stderr,
    qr{^#### \QIO/K8s/VolumeSnapshot/V1/VolumeSnapshotClass.pm\E$}m,
    '--suggest emits no VolumeSnapshotClass source for the non-existent spec gap'
  );
};

subtest 'only the unambiguously flat root is exempt from spec reporting' => sub {
  my @opaque_cases = (
    [
      'a schemaless preserve-unknown root',
      'VolumeSnapshotClass',
      'volumesnapshotclasses',
      'Cluster',
      <<'YAML',
          type: object
          x-kubernetes-preserve-unknown-fields: true
YAML
      $class_gvk
    ],
    [
      'an open root with additionalProperties: true',
      'VolumeSnapshotClass',
      'volumesnapshotclasses',
      'Cluster',
      <<'YAML',
          type: object
          properties:
            driver:
              type: string
          additionalProperties: true
YAML
      $class_gvk
    ],
    [
      'an open root with schema-shaped additionalProperties',
      'VolumeSnapshotClass',
      'volumesnapshotclasses',
      'Cluster',
      <<'YAML',
          type: object
          properties:
            driver:
              type: string
          additionalProperties:
            type: string
YAML
      $class_gvk
    ],
    [
      'an explicit preserve-unknown spec on a class whose spec is normally typed',
      'VolumeSnapshot',
      'volumesnapshots',
      'Namespaced',
      <<'YAML',
          type: object
          properties:
            spec:
              type: object
              x-kubernetes-preserve-unknown-fields: true
YAML
      $snapshot_gvk
    ],
    [
      'a closed root without spec when the shipped class does model spec',
      'VolumeSnapshot',
      'volumesnapshots',
      'Namespaced',
      <<'YAML',
          type: object
          properties:
            status:
              type: object
YAML
      $snapshot_gvk
    ]
  );

  for my $case (@opaque_cases) {
    my ($what, $kind, $plural, $scope, $schema, $gvk) = @$case;
    my ($status, $stdout, $stderr) = run_drift(
      crd_document($kind, $plural, $scope, $schema)
    );
    is($status, 0, "$what fixture is accepted");
    my $report = decode_report($stdout, "$what report");
    next unless $report;

    is(scalar @{ gvk_entries($report, 'opaque_spec', $gvk) }, 1,
      "$what remains an opaque spec case");
  }
};

subtest 'a normal typed spec keeps its existing field comparison' => sub {
  my $typed_spec = <<'YAML';
          type: object
          properties:
            spec:
              type: object
              properties:
                source:
                  type: object
                volumeSnapshotClassName:
                  type: string
YAML
  my ($status, $stdout, $stderr) = run_drift(
    crd_document('VolumeSnapshot', 'volumesnapshots', 'Namespaced', $typed_spec)
  );
  is($status, 0, 'the local typed VolumeSnapshot fixture is accepted');
  my $report = decode_report($stdout, 'the typed spec report');
  return unless $report;

  is_deeply(gvk_entries($report, 'opaque_spec', $snapshot_gvk), [],
    'a modelled spec with upstream properties is not opaque');
  is_deeply(gvk_entries($report, 'missing_field', $snapshot_gvk), [],
    'the existing typed source and volumeSnapshotClassName fields remain covered');
  is_deeply(gvk_entries($report, 'extra_field', $snapshot_gvk), [],
    'the normal typed spec comparison does not invent extra fields');
};

done_testing;
