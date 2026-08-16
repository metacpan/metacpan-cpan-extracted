#!/usr/bin/env perl
# The k8s attribute delegates IO::K8s' object methods onto the client, so
# $api->load_yaml(...) and $api->k8s->load_yaml(...) are the same call. This
# pins the delegated set - a method dropped from the handles list is a silently
# broken caller, since $api->foo would die rather than fall back to k8s->foo.
use strict;
use warnings;
use utf8;
use Test::More;
use Test::Exception;
use Encode ();
use File::Temp qw(tempdir);
use Path::Tiny qw(path);
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";

use Test::Kubernetes::Mock qw(mock_api);

my @DELEGATED = qw(
    new_object
    inflate
    json_to_object
    struct_to_object
    object_to_json
    object_to_struct
    expand_class
    load
    load_yaml
);

my $api = mock_api();

subtest 'every delegated method is reachable on the client' => sub {
    can_ok $api, @DELEGATED;
    can_ok $api->k8s, @DELEGATED;
};

# load_yaml parses characters, not bytes - the manifest below is written with
# 'use utf8' in effect, so it already is characters.
my $YAML = <<'YAML';
apiVersion: v1
kind: ConfigMap
metadata:
  name: delegation-test
  namespace: default
data:
  greeting: "Grüße"
---
apiVersion: v1
kind: Namespace
metadata:
  name: delegation-ns
YAML

subtest 'load_yaml delegates, with the same result as through k8s' => sub {
    my $direct = $api->load_yaml($YAML);
    my $through = $api->k8s->load_yaml($YAML);

    is scalar @$direct, 2, 'both documents of the manifest come back';
    is_deeply
        [map { $api->object_to_struct($_) } @$direct],
        [map { $api->object_to_struct($_) } @$through],
        'delegated load_yaml gives what the k8s instance gives';

    isa_ok $direct->[0], 'IO::K8s::Api::Core::V1::ConfigMap';
    is $direct->[0]->data->{greeting}, "Gr\x{fc}\x{df}e",
        'characters survive the delegated call unmangled';
};

subtest 'object_to_struct and object_to_json delegate' => sub {
    my $cm = $api->new_object(ConfigMap => {
        metadata => { name => 'round-trip', namespace => 'default' },
        data => { greeting => "Grüße" },
    });

    is_deeply $api->object_to_struct($cm), $api->k8s->object_to_struct($cm),
        'object_to_struct matches the call through k8s';
    is $api->object_to_json($cm), $api->k8s->object_to_json($cm),
        'object_to_json matches the call through k8s';

    # The pairs already delegated are round trips of each other.
    is_deeply $api->object_to_struct($api->struct_to_object($api->object_to_struct($cm))),
        $api->object_to_struct($cm),
        'struct_to_object/object_to_struct round trip';
};

subtest 'load delegates for .pk8s manifests' => sub {
    my $file = path(tempdir(CLEANUP => 1))->child('delegation.pk8s');
    $file->spew_utf8(<<'PK8S');
ConfigMap {
    name => 'from-pk8s',
    namespace => 'default',
    data => { key => 'value' },
};
PK8S

    my $objects = $api->load("$file");
    is scalar @$objects, 1, 'one resource loaded from the pk8s manifest';
    is $objects->[0]->metadata->name, 'from-pk8s', 'and it is the one declared';
    is_deeply [map { $api->object_to_struct($_) } @$objects],
        [map { $api->object_to_struct($_) } @{ $api->k8s->load("$file") }],
        'delegated load gives what the k8s instance gives';
};

subtest 'the delegated methods act on this client\'s own k8s instance' => sub {
    # Delegation must not conjure a second IO::K8s with a different resource
    # map; expand_class is the one that would show it.
    is $api->expand_class('Pod'), $api->k8s->expand_class('Pod'),
        'expand_class resolves through the same resource map';
};

done_testing;
