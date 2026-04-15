---
name: perl-kubernetes-rest
description: "Kubernetes::REST — How to talk to the Kubernetes API from Perl"
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# Kubernetes::REST — K8s API Client for Perl

## Connect

```perl
my $api = Kubernetes::REST->new(
    server      => { endpoint => 'https://k8s.local:6443' },
    credentials => { token => $token },
);

# With SSL options
my $api = Kubernetes::REST->new(
    server => {
        endpoint          => 'https://k8s.local:6443',
        ssl_verify_server => 1,
        ssl_ca_file       => '/path/to/ca.crt',
    },
    credentials => { token => $token },
);
```

## CRUD

```perl
# List — returns IO::K8s::List object
my $list = $api->list('Pod', namespace => 'default', labelSelector => 'app=web');
for my $pod ($list->items->@*) { say $pod->metadata->name }

# Get
my $pod = $api->get('Pod', 'my-pod', namespace => 'default');

# Create — pass IO::K8s object
my $ns = $api->new_object(Namespace => { metadata => { name => 'foo' } });
my $created = $api->create($ns);

# Update (PUT — full replacement)
$pod->metadata->labels({ app => 'updated' });
my $updated = $api->update($pod);

# Patch (partial: strategic/merge/json)
my $patched = $api->patch('Pod', 'my-pod',
    namespace => 'default',
    patch     => { metadata => { labels => { env => 'staging' } } },
    type      => 'strategic',   # default
);
# or with object:
$api->patch($pod, patch => { ... });

# Delete
$api->delete($pod);
$api->delete('Pod', 'my-pod', namespace => 'default');
```

All return typed IO::K8s objects (not hashrefs). Lists return IO::K8s::List.

## Watch

```perl
my $last_rv = $api->watch('Pod',
    namespace       => 'default',
    timeout         => 300,
    resourceVersion => '12345',
    labelSelector   => 'app=web',
    on_event => sub {
        my ($event) = @_;   # Kubernetes::REST::WatchEvent
        say $event->type;                    # ADDED, MODIFIED, DELETED
        say $event->object->metadata->name;  # Typed IO::K8s object
    },
);
# Returns last resourceVersion for resumable watches
```

## Log

```perl
# One-shot
my $text = $api->log('Pod', 'my-pod', namespace => 'default', tailLines => 100);

# Streaming
$api->log('Pod', 'my-pod',
    namespace => 'default',
    follow    => 1,
    on_line   => sub {
        my ($event) = @_;  # Kubernetes::REST::LogEvent
        say $event->line;
    },
);
```

## Duplex (exec, attach, port_forward)

Require an IO backend with `call_duplex` (e.g. Net::Async::Kubernetes).

```perl
$api->exec('Pod', 'my-pod',
    namespace => 'default',
    command   => ['sh', '-c', 'echo hello'],
    stdout    => 1, stderr => 1,
    on_frame  => sub { my ($channel, $payload) = @_; ... },
);

$api->attach('Pod', 'my-pod',
    namespace => 'default', container => 'app',
    stdin => 1, stdout => 1,
    on_frame => sub { ... },
);

$api->port_forward('Pod', 'my-pod',
    namespace => 'default',
    ports     => [8080, 8443],
    on_frame  => sub { my ($channel, $payload) = @_; ... },
);
```

## CRD Support

```perl
my $api = Kubernetes::REST->new(
    resource_map => {
        %{ IO::K8s->default_resource_map },
        MyResource => '+My::K8s::V1::MyResource',
    },
    resource_map_from_cluster => 0,
    ...
);
$api->list('MyResource', namespace => 'default');
```

## Pluggable IO

Default: `Kubernetes::REST::LWPIO` (LWP). For async, use `Net::Async::Kubernetes`.

```perl
use Kubernetes::REST::HTTPTinyIO;
my $api = Kubernetes::REST->new(
    io => Kubernetes::REST::HTTPTinyIO->new(...),
    ...
);
```
