#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use IO::K8s;

my $k8s = IO::K8s->new;

# Test load() with .pk8s file
subtest 'load() with .pk8s file' => sub {
    my ($fh, $filename) = tempfile(SUFFIX => '.pk8s', UNLINK => 1);
    print $fh q{
        ConfigMap {
            name => 'test-config',
            namespace => 'default',
            data => { key => 'value' }
        };

        Pod {
            name => 'test-pod',
            namespace => 'default',
            spec => {
                containers => [{
                    name => 'app',
                    image => 'nginx:latest',
                }],
            }
        };
    };
    close $fh;

    my $objs = $k8s->load($filename);
    is(ref($objs), 'ARRAY', 'load() returns arrayref');
    is(scalar(@$objs), 2, 'loaded 2 objects');

    my ($cm, $pod) = @$objs;
    is($cm->kind, 'ConfigMap', 'first object is ConfigMap');
    is($cm->metadata->name, 'test-config', 'ConfigMap has correct name');
    is($cm->data->{key}, 'value', 'ConfigMap has correct data');

    is($pod->kind, 'Pod', 'second object is Pod');
    is($pod->metadata->name, 'test-pod', 'Pod has correct name');
};

# Test load_yaml() with YAML file
subtest 'load_yaml() with file' => sub {
    my ($fh, $filename) = tempfile(SUFFIX => '.yaml', UNLINK => 1);
    print $fh q{---
apiVersion: v1
kind: ConfigMap
metadata:
  name: yaml-config
  namespace: default
data:
  hello: world
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: yaml-deploy
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: test
  template:
    metadata:
      labels:
        app: test
    spec:
      containers:
      - name: app
        image: nginx
};
    close $fh;

    my $objs = $k8s->load_yaml($filename);
    is(ref($objs), 'ARRAY', 'load_yaml() returns arrayref');
    is(scalar(@$objs), 2, 'loaded 2 objects from YAML');

    my ($cm, $deploy) = @$objs;
    is($cm->kind, 'ConfigMap', 'first object is ConfigMap');
    is($cm->metadata->name, 'yaml-config', 'ConfigMap name correct');

    is($deploy->kind, 'Deployment', 'second object is Deployment');
    is($deploy->metadata->name, 'yaml-deploy', 'Deployment name correct');
    is($deploy->spec->replicas, 3, 'Deployment replicas correct');
};

# Test load_yaml() with string
subtest 'load_yaml() with string' => sub {
    my $yaml = q{---
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
type: Opaque
data:
  password: cGFzc3dvcmQ=
};

    my $objs = $k8s->load_yaml($yaml);
    is(scalar(@$objs), 1, 'loaded 1 object from YAML string');
    is($objs->[0]->kind, 'Secret', 'object is Secret');
    is($objs->[0]->metadata->name, 'my-secret', 'Secret name correct');
};

# Test to_yaml() on objects
subtest 'to_yaml() on objects' => sub {
    my $pod = $k8s->new_object('Pod',
        metadata => { name => 'yaml-test', namespace => 'default' },
        spec => { containers => [{ name => 'app', image => 'nginx' }] }
    );

    my $yaml = $pod->to_yaml;
    like($yaml, qr/^---/, 'YAML starts with ---');
    like($yaml, qr/kind: Pod/, 'contains kind: Pod');
    like($yaml, qr/name: yaml-test/, 'contains name');
};

# Test save() on objects
subtest 'save() on objects' => sub {
    my $pod = $k8s->new_object('Pod',
        metadata => { name => 'save-test', namespace => 'default' },
        spec => { containers => [{ name => 'app', image => 'nginx' }] }
    );

    my ($fh, $filename) = tempfile(SUFFIX => '.yaml', UNLINK => 1);
    close $fh;

    my $result = $pod->save($filename);
    is($result, $pod, 'save() returns object for chaining');

    open my $rfh, '<', $filename or die "Cannot read $filename: $!";
    my $content = do { local $/; <$rfh> };
    close $rfh;

    like($content, qr/kind: Pod/, 'saved file contains kind');
    like($content, qr/name: save-test/, 'saved file contains name');
};

# Test type validation in load_yaml() - single error
subtest 'type validation - single error' => sub {
    my $invalid_yaml = q{---
apiVersion: v1
kind: Pod
metadata:
  name: invalid
spec:
  containers:
  - name: app
    image: nginx
    ports:
    - containerPort: "not-a-number"
};

    eval { $k8s->load_yaml($invalid_yaml) };
    like($@, qr/type constraint/, 'invalid type throws error');
};

# Test type validation - collect all errors
subtest 'type validation - collect all errors' => sub {
    my $invalid_yaml = q{---
apiVersion: v1
kind: Pod
metadata:
  name: pod1
spec:
  containers:
  - name: app
    image: nginx
    ports:
    - containerPort: "invalid1"
---
apiVersion: v1
kind: Pod
metadata:
  name: pod2
spec:
  containers:
  - name: app
    image: nginx
    ports:
    - containerPort: "invalid2"
};

    my ($objs, $errors) = $k8s->load_yaml($invalid_yaml, collect_errors => 1);
    is(ref($errors), 'ARRAY', 'errors is arrayref');
    is(scalar(@$errors), 2, 'collected 2 errors');
    like($errors->[0], qr/pod1|invalid1/, 'first error mentioned');
    like($errors->[1], qr/pod2|invalid2/, 'second error mentioned');
};

# k71 (P7): collect_errors above is only ever exercised with an
# all-invalid stream. A mixed stream -- most documents valid, one bad -- is
# the realistic case (a big manifest bundle where one Kind has a typo) and
# never had its own test: this asserts the good documents still come back as
# objects (not dropped or short-circuited by the bad one) alongside exactly
# the one collected error, named with its kind/name prefix.
subtest 'type validation - collect_errors on a mixed 3-doc stream (2 valid, 1 invalid)' => sub {
    my $mixed_yaml = q{---
apiVersion: v1
kind: ConfigMap
metadata:
  name: good-config
data:
  hello: world
---
apiVersion: v1
kind: Pod
metadata:
  name: bad-pod
spec:
  containers:
  - name: app
    image: nginx
    ports:
    - containerPort: "not-a-number"
---
apiVersion: v1
kind: Secret
metadata:
  name: good-secret
type: Opaque
data:
  password: cGFzc3dvcmQ=
};

    my ($objs, $errors) = $k8s->load_yaml($mixed_yaml, collect_errors => 1);
    is(ref($objs), 'ARRAY', 'objects is arrayref');
    is(scalar(@$objs), 2, 'the two valid documents came back as objects');
    is(ref($errors), 'ARRAY', 'errors is arrayref');
    is(scalar(@$errors), 1, 'exactly the one invalid document was collected as an error, not more');

    is($objs->[0]->kind, 'ConfigMap', 'first valid object is the ConfigMap');
    is($objs->[0]->metadata->name, 'good-config', 'first valid object retains its identity');
    is($objs->[1]->kind, 'Secret', 'second valid object is the Secret');
    is($objs->[1]->metadata->name, 'good-secret',
        'second valid object retains its identity -- the bad document in between did not swallow it');

    like($errors->[0], qr/\APod\/bad-pod:/,
        'the collected error is prefixed with the failing document\'s kind/name');
};

done_testing;
