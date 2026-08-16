#!/usr/bin/env perl
# kube_client create reads YAML as well as JSON. The format is sniffed from the
# content (not the file name) so that '-f -' behaves like '-f file.yaml', and
# multi-document YAML creates every document in order.
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

use Kubernetes::REST::CLI;
use Kubernetes::REST::CLI::Cmd::Create;
use Test::Kubernetes::Mock qw(mock_api);

my $tmpdir = tempdir(CLEANUP => 1);

# The command reads bytes off disk or stdin, so every fixture here is bytes.
sub manifest_file {
    my ($name, $content) = @_;
    my $file = path($tmpdir)->child($name);
    $file->spew_raw(Encode::encode('UTF-8', $content));
    return "$file";
}

sub cmd {
    my (%args) = @_;
    return Kubernetes::REST::CLI::Cmd::Create->new(%args);
}

# A root object the way MooX::Cmd hands it to execute(): a real CLI with the
# mock-backed api injected instead of one built from a kubeconfig.
sub root_with_mock {
    my (%args) = @_;
    my $api = mock_api();
    return Kubernetes::REST::CLI->new(
        api => $api,
        kubeconfig => '/dev/null',
        %args,
    );
}

sub capture_stdout {
    my ($code) = @_;
    my $output = '';
    open my $oldfh, '>&', \*STDOUT;
    {
        local *STDOUT;
        open STDOUT, '>', \$output;
        $code->();
    }
    open STDOUT, '>&', $oldfh;
    return $output;
}

my $YAML_POD = <<'YAML';
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  namespace: default
  labels:
    app: nginx
spec:
  containers:
    - name: nginx
      image: nginx:1.25
      ports:
        - containerPort: 80
YAML

# ============================================================================
# YAML input becomes a typed object
# ============================================================================

subtest 'YAML manifest inflates to a typed object' => sub {
    my $api = mock_api();
    my @objects = cmd(file => manifest_file('pod.yaml', $YAML_POD))
        ->_parse_manifest($api, $YAML_POD);

    is scalar @objects, 1, 'one document, one object';
    isa_ok $objects[0], 'IO::K8s::Api::Core::V1::Pod', 'YAML document';
    is $objects[0]->metadata->name, 'nginx', 'name survives the YAML parse';
    is $objects[0]->metadata->namespace, 'default', 'namespace survives';
    is $objects[0]->metadata->labels->{app}, 'nginx', 'labels survive';

    # Nested structures must be typed too, not left as plain hashrefs - that is
    # the difference between a YAML parse and a YAML parse plus inflation.
    my $container = $objects[0]->spec->containers->[0];
    isa_ok $container, 'IO::K8s::Api::Core::V1::Container', 'nested container';
    is $container->image, 'nginx:1.25', 'container image';
    is $container->ports->[0]->containerPort, 80, 'container port is typed';
};

subtest 'YAML with a leading document marker' => sub {
    my $api = mock_api();
    my @objects = cmd()->_parse_manifest($api, "---\n$YAML_POD");
    is scalar @objects, 1, 'leading --- does not add an empty document';
    is $objects[0]->metadata->name, 'nginx', 'object parsed';
};

subtest 'YAML non-ASCII values arrive as characters, not mojibake' => sub {
    my $api = mock_api();
    my $yaml = <<"YAML";
apiVersion: v1
kind: ConfigMap
metadata:
  name: gr\x{fc}sse
  namespace: default
data:
  greeting: "Gr\x{fc}\x{df}e aus M\x{fc}nchen"
YAML

    # _parse_manifest is handed bytes, exactly as _read_input produces them.
    my @objects = cmd()->_parse_manifest($api, Encode::encode('UTF-8', $yaml));

    is scalar @objects, 1, 'one document';
    is $objects[0]->metadata->name, "gr\x{fc}sse", 'name is a character string';
    is $objects[0]->data->{greeting}, "Gr\x{fc}\x{df}e aus M\x{fc}nchen",
        'value is a character string';
    # 17 characters, 20 UTF-8 bytes - the difference is the whole point.
    is length($objects[0]->data->{greeting}), 17,
        'length counts characters, not UTF-8 bytes';
};

# ============================================================================
# JSON input keeps working exactly as before
# ============================================================================

subtest 'JSON manifest still goes through inflate()' => sub {
    my $api = mock_api();
    my $json = '{"apiVersion":"v1","kind":"Pod","metadata":{"name":"json-pod","namespace":"default"}}';

    my @objects = cmd()->_parse_manifest($api, $json);
    is scalar @objects, 1, 'one object';
    isa_ok $objects[0], 'IO::K8s::Api::Core::V1::Pod', 'JSON document';
    is $objects[0]->metadata->name, 'json-pod', 'name from JSON';
};

subtest 'pretty-printed JSON with leading whitespace is still JSON' => sub {
    my $api = mock_api();
    my $json = qq(\n  {\n    "apiVersion": "v1",\n    "kind": "Namespace",\n)
             . qq(    "metadata": { "name": "leading-space" }\n  }\n);

    my @objects = cmd()->_parse_manifest($api, $json);
    is scalar @objects, 1, 'one object';
    is $objects[0]->kind, 'Namespace', 'kind from JSON';
    is $objects[0]->metadata->name, 'leading-space', 'name from JSON';
};

subtest 'broken JSON is reported by the JSON reader, not the YAML one' => sub {
    my $api = mock_api();
    # YAML::PP parses well-formed JSON too, so a round trip alone cannot show
    # which reader ran. The error message can: a character offset is a
    # JSON::MaybeXS message, YAML::PP reports lines and columns instead. If
    # this fails, the sniff has started sending JSON through the YAML reader.
    my $broken = qq({\n  "apiVersion": "v1",\n  "kind": "Pod",\n);

    throws_ok { cmd()->_parse_manifest($api, $broken) }
        qr/character offset/, 'JSON syntax errors come from the JSON decoder';
};

subtest 'JSON non-ASCII values survive as characters' => sub {
    my $api = mock_api();
    my $json = Encode::encode('UTF-8',
        qq({"apiVersion":"v1","kind":"ConfigMap","metadata":{"name":"j"},)
      . qq("data":{"greeting":"Gr\x{fc}\x{df}e"}}));

    my @objects = cmd()->_parse_manifest($api, $json);
    is $objects[0]->data->{greeting}, "Gr\x{fc}\x{df}e",
        'JSON path decodes UTF-8 the way it always did';
};

# ============================================================================
# Multi-document YAML
# ============================================================================

my $MULTI_YAML = <<'YAML';
apiVersion: v1
kind: Namespace
metadata:
  name: demo
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: demo-config
  namespace: demo
data:
  key: value
---
apiVersion: v1
kind: Service
metadata:
  name: demo-svc
  namespace: demo
spec:
  ports:
    - port: 80
YAML

subtest 'multi-document YAML yields one object per document, in order' => sub {
    my $api = mock_api();
    my @objects = cmd()->_parse_manifest($api, $MULTI_YAML);

    is scalar @objects, 3, 'three documents, three objects';
    is_deeply [map { $_->kind } @objects], [qw(Namespace ConfigMap Service)],
        'document order is preserved - a Namespace first is the whole point';
    isa_ok $objects[0], 'IO::K8s::Api::Core::V1::Namespace', 'first';
    isa_ok $objects[1], 'IO::K8s::Api::Core::V1::ConfigMap', 'second';
    isa_ok $objects[2], 'IO::K8s::Api::Core::V1::Service', 'third';
    is $objects[1]->data->{key}, 'value', 'second document is fully inflated';
};

subtest 'empty documents between separators are skipped' => sub {
    my $api = mock_api();
    my $yaml = "---\n$MULTI_YAML---\n";
    my @objects = cmd()->_parse_manifest($api, $yaml);
    is scalar @objects, 3, 'leading and trailing separators add no objects';
};

# ============================================================================
# Nothing to create
# ============================================================================

subtest 'empty input is refused with the source named' => sub {
    my $api = mock_api();
    throws_ok { cmd(file => '-')->_parse_manifest($api, '') }
        qr/Empty manifest read from stdin/, 'empty stdin names stdin';
    throws_ok { cmd(file => '-')->_parse_manifest($api, "\n \t\n") }
        qr/Empty manifest read from stdin/, 'whitespace-only is empty too';
    throws_ok { cmd(file => '/tmp/whatever.yaml')->_parse_manifest($api, '') }
        qr{Empty manifest read from /tmp/whatever\.yaml}, 'a file names the file';
};

subtest 'YAML without a single document is refused, not silently ignored' => sub {
    my $api = mock_api();
    throws_ok {
        cmd(file => '/tmp/comments.yaml')
            ->_parse_manifest($api, "# just a comment\n---\n---\n")
    } qr{No Kubernetes manifest documents found in /tmp/comments\.yaml},
        'a manifest of comments and separators is an error';
};

subtest 'a YAML document without a kind is refused by the inflater' => sub {
    my $api = mock_api();
    throws_ok { cmd()->_parse_manifest($api, "foo: bar\n") }
        qr/kind/, 'missing kind is reported';
};

# ============================================================================
# Reading the input
# ============================================================================

subtest '_read_input reads a file' => sub {
    my $file = manifest_file('read.yaml', $YAML_POD);
    is cmd(file => $file)->_read_input, Encode::encode('UTF-8', $YAML_POD),
        'file content is returned as bytes';
};

subtest '_read_input reads stdin for -f -' => sub {
    my $input = $YAML_POD;
    open my $fh, '<', \$input or die $!;
    my $got = do {
        local *STDIN = $fh;
        cmd(file => '-')->_read_input;
    };
    is $got, $YAML_POD, 'stdin is slurped whole';
};

subtest '_read_input dies on a missing file' => sub {
    throws_ok { cmd(file => "$tmpdir/does-not-exist.yaml")->_read_input }
        qr/Cannot open .*does-not-exist\.yaml/, 'missing file is reported';
};

# ============================================================================
# execute() end to end against the mock backend
# ============================================================================

subtest 'execute creates a single YAML document' => sub {
    my $root = root_with_mock();
    $root->api->io->add_response('POST', '/api/v1/namespaces/default/pods', {
        apiVersion => 'v1',
        kind => 'Pod',
        metadata => { name => 'nginx', namespace => 'default', uid => 'uid-1' },
    });

    my $c = cmd(file => manifest_file('exec-pod.yaml', $YAML_POD));
    my $rc;
    my $out = capture_stdout(sub { $rc = $c->execute([], [$root]) });

    is $rc, 0, 'execute returns 0';
    like $out, qr/"name"\s*:\s*"nginx"/, 'created object is printed';
    like $out, qr/"uid"\s*:\s*"uid-1"/, 'the printed object is the server reply';
};

subtest 'execute creates a single JSON document from stdin' => sub {
    my $root = root_with_mock();
    $root->api->io->add_response('POST', '/api/v1/namespaces', {
        apiVersion => 'v1',
        kind => 'Namespace',
        metadata => { name => 'from-stdin', uid => 'uid-ns' },
    });

    my $input = '{"apiVersion":"v1","kind":"Namespace","metadata":{"name":"from-stdin"}}';
    open my $fh, '<', \$input or die $!;

    my $c = cmd(file => '-');
    my ($rc, $out);
    $out = capture_stdout(sub {
        local *STDIN = $fh;
        $rc = $c->execute([], [$root]);
    });

    is $rc, 0, 'execute returns 0';
    like $out, qr/"name"\s*:\s*"from-stdin"/, 'created namespace is printed';
};

subtest 'execute creates every document of a multi-document manifest' => sub {
    my $root = root_with_mock();
    my $io = $root->api->io;
    $io->add_response('POST', '/api/v1/namespaces', {
        apiVersion => 'v1', kind => 'Namespace',
        metadata => { name => 'demo', uid => 'uid-ns' },
    });
    $io->add_response('POST', '/api/v1/namespaces/demo/configmaps', {
        apiVersion => 'v1', kind => 'ConfigMap',
        metadata => { name => 'demo-config', namespace => 'demo', uid => 'uid-cm' },
    });
    $io->add_response('POST', '/api/v1/namespaces/demo/services', {
        apiVersion => 'v1', kind => 'Service',
        metadata => { name => 'demo-svc', namespace => 'demo', uid => 'uid-svc' },
    });

    my $c = cmd(file => manifest_file('multi.yaml', $MULTI_YAML));
    my $rc;
    my $out = capture_stdout(sub { $rc = $c->execute([], [$root]) });

    is $rc, 0, 'execute returns 0';
    like $out, qr/uid-ns/,  'namespace created';
    like $out, qr/uid-cm/,  'configmap created';
    like $out, qr/uid-svc/, 'service created';

    my @order = $out =~ /"(uid-(?:ns|cm|svc))"/g;
    is_deeply \@order, [qw(uid-ns uid-cm uid-svc)],
        'output follows document order';
};

subtest 'a failing document in a multi-document manifest names itself' => sub {
    my $root = root_with_mock();
    my $io = $root->api->io;
    # Only the Namespace has a mocked POST; the ConfigMap POST falls through to
    # the mock's 404, which is what the client turns into an error.
    $io->add_response('POST', '/api/v1/namespaces', {
        apiVersion => 'v1', kind => 'Namespace',
        metadata => { name => 'demo', uid => 'uid-ns' },
    });

    my $c = cmd(file => manifest_file('partial.yaml', $MULTI_YAML));
    my $err;
    capture_stdout(sub { eval { $c->execute([], [$root]) }; $err = $@ });

    like $err, qr/Document 2 of 3 \(ConfigMap\)/,
        'the error identifies the document that failed';
    like $err, qr/partial\.yaml/, 'and the manifest it came from';
};

subtest 'a single failing document reports the API error unchanged' => sub {
    my $root = root_with_mock();
    # No POST registered at all - the mock answers 404.
    my $c = cmd(file => manifest_file('lonely.yaml', $YAML_POD));
    my $err;
    capture_stdout(sub { eval { $c->execute([], [$root]) }; $err = $@ });

    ok $err, 'execute dies';
    unlike $err, qr/^Document \d+ of/,
        'a one-document manifest is not decorated with a document number';
};

done_testing;
