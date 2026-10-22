#!/usr/bin/env perl

# k198: load_yaml and IO::K8s::CRD->load read manifests as YAML 1.2, kubectl
# reads them as YAML 1.1. Two silent, wrong-direction differences:
#   - `privileged: no` / `off` stayed the strings they are, and the Bool
#     normaliser takes every non-empty string except "false" as true.
#   - `defaultMode: 0644` loaded as decimal 644 instead of octal 420 (0400
#     became 400 = mode 0620; 0644 and 0755 exceed 0777 and are rejected).
# Every assertion looks at the SERIALIZED value (canonical JSON text, and the
# to_yaml output reloaded), not at an accessor.

use strict;
use warnings;
use Test::More;
use JSON::PP;
use YAML::PP;
use IO::K8s;
use IO::K8s::CRD;

my $json = JSON::PP->new->canonical;
my $k8s  = IO::K8s->new;

sub pod_yaml {
  my (%f) = @_;
  my $mode = $f{mode} // '0644';
  return <<"YAML";
apiVersion: v1
kind: Pod
metadata:
  name: x
  labels:
    flag: $f{label}
spec:
  hostNetwork: $f{host}
  containers:
  - name: c
    image: i
    securityContext:
      privileged: $f{priv}
  volumes:
  - name: s
    secret:
      secretName: s
      defaultMode: $mode
YAML
}

sub load_pod {
  my ($y) = @_;
  my $objs = $k8s->load_yaml($y);
  return $objs->[0];
}

my @false = qw( no No NO off Off OFF false False FALSE );
my @true  = qw( yes Yes YES on On ON true True TRUE );

subtest 'YAML 1.1 false spellings on Bool fields serialize as JSON false' => sub {
  for my $v (@false) {
    my $pod  = load_pod(pod_yaml(host => $v, priv => $v, label => 'x'));
    my $txt  = $json->encode($pod->TO_JSON);
    like $txt, qr/"hostNetwork":false\b/,  "hostNetwork: $v -> false";
    like $txt, qr/"privileged":false\b/,   "privileged: $v -> false";
    unlike $txt, qr/"(?:hostNetwork|privileged)":(?:true|"[^"]*")/, "$v: no true/string leaked";

    my $re = YAML::PP->new(schema => ['JSON'])->load_string($pod->to_yaml);
    my $retxt = $json->encode($re);
    like $retxt, qr/"privileged":false\b/, "$v: to_yaml reloads privileged as false";
  }
};

subtest 'YAML 1.1 true spellings on Bool fields serialize as JSON true' => sub {
  for my $v (@true) {
    my $pod = load_pod(pod_yaml(host => $v, priv => $v, label => 'x'));
    my $txt = $json->encode($pod->TO_JSON);
    like $txt, qr/"hostNetwork":true\b/, "hostNetwork: $v -> true";
    like $txt, qr/"privileged":true\b/,  "privileged: $v -> true";
  }
};

subtest 'leading-zero octal on an Int field is octal' => sub {
  my %want = ( '0644' => 420, '0755' => 493, '0400' => 256 );
  for my $in (sort keys %want) {
    my $pod = load_pod(pod_yaml(host => 'true', priv => 'true', label => 'x', mode => $in));
    my $txt = $json->encode($pod->TO_JSON);
    like $txt, qr/"defaultMode":$want{$in}(?![\d"])/, "defaultMode: $in -> $want{$in} unquoted in JSON";
    my $re = YAML::PP->new(schema => ['JSON'])->load_string($pod->to_yaml);
    is $re->{spec}{volumes}[0]{secret}{defaultMode}, $want{$in}, "$in: to_yaml reloads as $want{$in}";
  }
};

subtest 'other number forms are not disturbed' => sub {
  for my $case ( [ '420', 420 ], [ '0', 0 ], [ '511', 511 ], [ '0o644', 420 ], [ '0x1A4', 420 ] ) {
    my ( $in, $want ) = @$case;
    my $pod = load_pod(pod_yaml(host => 'true', priv => 'true', label => 'x', mode => $in));
    like $json->encode($pod->TO_JSON), qr/"defaultMode":$want(?![\d"])/, "defaultMode: $in -> $want";
  }
};

subtest 'quoted values stay strings' => sub {
  for my $v (qw( no off yes on No )) {
    my $pod = load_pod(pod_yaml(host => 'true', priv => 'true', label => qq{"$v"}));
    is $pod->TO_JSON->{metadata}{labels}{flag}, $v, "label \"$v\" stays the string $v";
    like $json->encode($pod->TO_JSON), qr/"flag":"\Q$v\E"/, "\"$v\" serialized as a JSON string";
  }
  my $pod = load_pod(pod_yaml(host => 'true', priv => 'true', label => "'0644'"));
  is $pod->TO_JSON->{metadata}{labels}{flag}, '0644', "quoted '0644' stays a string";
};

subtest 'IO::K8s::CRD->load reads YAML 1.1 booleans and octal' => sub {
  for my $case ( [ no => 0 ], [ No => 0 ], [ off => 0 ], [ yes => 1 ], [ On => 1 ] ) {
    my ( $v, $want ) = @$case;
    my $inv = $want ? 'no' : 'yes';
    my $crd = <<"YAML";
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: widgets.k198.example.com
spec:
  group: k198.example.com
  names:
    kind: Widget
    plural: widgets
  scope: Namespaced
  versions:
  - name: v1
    served: $v
    storage: $inv
    schema:
      openAPIV3Schema:
        type: object
        description: "no"
        properties:
          mode:
            type: integer
            default: 0644
YAML
    my $docs = IO::K8s::CRD->load($crd);
    my $txt  = $json->encode($docs->[0]{spec}{versions}[0]);
    my ( $s, $o ) = $want ? ( 'true', 'false' ) : ( 'false', 'true' );
    like $txt, qr/"served":$s\b/,  "served: $v -> $s";
    like $txt, qr/"storage":$o\b/, "storage: $inv -> $o";
    like $txt, qr/"description":"no"/, 'quoted "no" description stays a string';
    like $txt, qr/"default":420(?![\d"])/, 'default: 0644 -> 420';
  }
};

subtest 'bool-looking mapping keys stay strings as written' => sub {
  my $yaml = <<'YAML';
y: 1
on: 2
no: 3
Off: 4
true: 5
n: [ y, no ]
flow: { yes: a, off: b }
nested:
  on: { n: 0644 }
0644: octal-key
YAML
  my $d = IO::K8s->_yaml_parser->load_string($yaml);
  is_deeply [ sort keys %$d ], [ sort qw( y on no Off true n flow nested 0644 ) ],
    'keys are the text as written; several in one mapping do not collide';
  is $d->{on}, 2, 'on: -> key "on"';
  is $d->{n}[0] ? 'true' : 'false', 'true', 'values in a sequence still resolve (y)';
  is $d->{n}[1] ? 'true' : 'false', 'false', 'values in a sequence still resolve (no)';
  is_deeply [ sort keys %{ $d->{flow} } ], [ qw( off yes ) ], 'flow mapping keys stay strings';
  is $d->{nested}{on}{n}, 420, 'value 0644 under a bool-looking key is octal';
  is $d->{'0644'}, 'octal-key', '0644: stays the key "0644"';

  my $objs = $k8s->load_yaml(<<'Y');
apiVersion: v1
kind: ConfigMap
metadata:
  name: x
data:
  y: a
  on: b
  no: c
Y
  is_deeply $json->encode($objs->[0]->TO_JSON->{data}), $json->encode({ y => 'a', on => 'b', no => 'c' }),
    'load_yaml: ConfigMap data keys y/on/no survive';
};

subtest 'IO::K8s::CRD->load keeps y/on/no property names' => sub {
  my $docs = IO::K8s::CRD->load(<<'YAML');
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: widgets.k198.example.com
spec:
  group: k198.example.com
  names: { kind: Widget, plural: widgets }
  scope: Namespaced
  versions:
  - name: v1
    served: yes
    storage: on
    schema:
      openAPIV3Schema:
        type: object
        properties:
          y: { type: integer }
          on: { type: boolean }
          no: { type: string }
YAML
  my $v = $docs->[0]{spec}{versions}[0];
  is_deeply [ sort keys %{ $v->{schema}{openAPIV3Schema}{properties} } ], [ qw( no on y ) ],
    'property names y, on, no are kept';
  like $json->encode($v), qr/"served":true\b.*"storage":true\b|"storage":true\b.*"served":true\b/,
    'values served: yes / storage: on are still true';
};

done_testing;
