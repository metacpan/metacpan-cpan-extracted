# Kubernetes-REST

A Perl REST Client for the Kubernetes API

## Description

Kubernetes::REST provides a simple, object-oriented interface to the Kubernetes API using IO::K8s resource classes. The IO::K8s classes know their own metadata (API version, kind, whether they're namespaced), so URL building is automatic.

For async applications, see [Net::Async::Kubernetes](https://metacpan.org/pod/Net::Async::Kubernetes) which builds on top of Kubernetes::REST and IO::K8s with IO::Async.

## Installation

```bash
cpanm Kubernetes::REST
```

## Synopsis

```perl
use Kubernetes::REST;

my $api = Kubernetes::REST->new(
    server => { endpoint => 'https://kubernetes.local:6443' },
    credentials => { token => $token },
);

# List pods
my $pods = $api->list('Pod', namespace => 'default');
for my $pod ($pods->items->@*) {
    say $pod->metadata->name;
}

# Get a specific pod
my $pod = $api->get('Pod', name => 'my-pod', namespace => 'default');

# Create a pod
my $new_pod = $api->create($pod_object);

# Update a pod
my $updated = $api->update($pod);

# Patch a pod (partial update)
my $patched = $api->patch('Pod', 'my-pod',
    namespace => 'default',
    patch     => { metadata => { labels => { env => 'staging' } } },
);

# Delete a pod
$api->delete($pod);

# Watch for changes
my $rv = $api->watch('Pod',
    namespace => 'default',
    on_event  => sub {
        my ($event) = @_;
        say $event->type . ': ' . $event->object->metadata->name;
    },
);

# Get pod logs (one-shot)
my $text = $api->log('Pod', 'my-pod',
    namespace => 'default',
    tailLines => 100,
);

# Stream pod logs (like kubectl logs -f)
$api->log('Pod', 'my-pod',
    namespace => 'default',
    follow    => 1,
    on_line   => sub {
        my ($event) = @_;
        say $event->line;
    },
);

# Port-forward session (requires duplex-capable IO backend)
my $session = $api->port_forward('Pod', 'my-pod',
    namespace => 'default',
    ports     => [8080, 8443],
    on_frame  => sub {
        my ($channel, $payload) = @_;
        ...
    },
);

# Exec session (requires duplex-capable IO backend)
my $exec = $api->exec('Pod', 'my-pod',
    namespace => 'default',
    command   => ['sh', '-c', 'id'],
    on_frame  => sub {
        my ($channel, $payload) = @_;
        ...
    },
);
```

## Using kubeconfig

```perl
use Kubernetes::REST::Kubeconfig;

# Uses $KUBECONFIG env var, falls back to ~/.kube/config
my $api = Kubernetes::REST::Kubeconfig->new->api;

# Use a specific kubeconfig and context
my $api = Kubernetes::REST::Kubeconfig->new(
    kubeconfig_path => '/path/to/kubeconfig',
    context_name    => 'my-cluster',
)->api;
```

Supports token auth, client certificates (file and inline base64), exec credential plugins, in-memory PEM for inline certificate data, and in-cluster service account auto-detection.

## In-Cluster (Inside Kubernetes Pods)

When running inside a Kubernetes pod, no configuration is needed. `Kubernetes::REST::Kubeconfig` automatically detects the pod's mounted service account token:

```perl
use Kubernetes::REST::Kubeconfig;

# Works inside a pod - no kubeconfig needed
my $api = Kubernetes::REST::Kubeconfig->new->api;

my $pods = $api->list('Pod', namespace => 'default');
```

If no kubeconfig file is found and the service account token is present at `/var/run/secrets/kubernetes.io/serviceaccount/token`, the client configures itself automatically using the token and the cluster CA certificate.

## HTTP Debugging

The default HTTP backend uses LWP::UserAgent, which supports LWP::ConsoleLogger for inspecting HTTP traffic:

```perl
use LWP::ConsoleLogger::Easy qw(debug_ua);

my $api = Kubernetes::REST->new(
    server      => { endpoint => 'https://kubernetes.local:6443' },
    credentials => { token => $token },
);

# Attach logger to see all HTTP requests/responses
debug_ua($api->io->ua);

$api->list('Pod', namespace => 'default');  # now shows HTTP traffic
```

To use HTTP::Tiny instead:

```perl
use Kubernetes::REST::HTTPTinyIO;

my $api = Kubernetes::REST->new(
    server      => ...,
    credentials => ...,
    io          => Kubernetes::REST::HTTPTinyIO->new,
);
```

## Pluggable IO Architecture

The HTTP transport is decoupled via `Kubernetes::REST::Role::IO`. Implement `call($req)` and `call_streaming($req, $callback)` to plug in any HTTP backend (async, testing, etc.):

```perl
package My::AsyncIO;
use Moo;
with 'Kubernetes::REST::Role::IO';

sub call { ... }
sub call_streaming { ... }
```

## Building Blocks for Async Wrappers

Async wrappers like [Net::Async::Kubernetes](https://metacpan.org/pod/Net::Async::Kubernetes) need access to the request/response pipeline without going through the synchronous convenience methods. The following public methods provide a stable API for this:

- `expand_class($short)` - Resolve short name (e.g., `'Pod'`) to full IO::K8s class
- `build_path($class, %args)` - Build REST API URL path from class metadata
- `prepare_request($method, $path, %opts)` - Build HTTP request with auth headers
- `check_response($response, $context)` - Validate HTTP status (croaks on error)
- `inflate_object($class, $response)` - Decode JSON response to typed object
- `inflate_list($class, $response)` - Decode JSON response to typed list
- `process_watch_chunk($class, \$buf, $chunk)` - Parse NDJSON watch stream
- `process_log_chunk(\$buf, $chunk)` - Parse plain-text log stream

```perl
# Example: async log streaming
my $class = $rest->expand_class('Pod');
my $path = $rest->build_path($class, name => $name, namespace => $ns) . '/log';
my $req = $rest->prepare_request('GET', $path, parameters => { follow => 'true' });

# Execute through your own event loop
my $buffer = '';
$async_http->request($req->url, sub {
    my ($chunk) = @_;
    for my $event ($rest->process_log_chunk(\$buffer, $chunk)) {
        say $event->line;
    }
});
```

## CLI Tools

### kube_client

Interactive CLI for Kubernetes CRUD operations:

```bash
kube_client get Pod -n default
kube_client get Pod my-pod -n default
kube_client create -f pod.json
kube_client delete Pod my-pod -n default
```

### kube_watch

Watch Kubernetes resources for changes in real-time:

```bash
# Watch all pods across all namespaces
kube_watch Pod

# Watch pods in a specific namespace
kube_watch Pod -n default

# Filter by event type
kube_watch Pod -T ADDED,DELETED

# Filter by label
kube_watch Deployment -n production -l app=web

# JSON output for piping
kube_watch Pod -o json | jq '.object.metadata.name'

# Custom timestamp format
kube_watch Pod -F time      # 14:23:01
kube_watch Pod -F iso       # 2025-02-12T14:23:01+0100
```

## Custom Resource Definitions (CRDs)

Register your own CRD classes and use them with the same API:

```perl
use My::StaticWebSite;

my $api = Kubernetes::REST->new(
    server      => ...,
    credentials => ...,
    resource_map => {
        StaticWebSite => '+My::StaticWebSite',
    },
);

my $site = $api->new_object(StaticWebSite =>
    metadata => { name => 'my-blog', namespace => 'default' },
    spec     => { domain => 'blog.example.com', replicas => 2 },
);
my $created = $api->create($site);
```

See `Kubernetes::REST::Example` for full CRD documentation including AutoGen from cluster OpenAPI specs.

## Features

- **Simple API**: `list()`, `get()`, `create()`, `update()`, `patch()`, `delete()`, `watch()`, `log()`, `port_forward()`, `exec()`
- **Kubeconfig support**: Token auth, client certs, exec credential plugins, in-cluster service account auto-detection
- **Pluggable HTTP backend**: LWP::UserAgent (default), HTTP::Tiny, or custom
- **HTTP debugging**: LWP::ConsoleLogger support out of the box
- **Patch support**: Strategic merge patch, JSON merge patch (RFC 7396), JSON patch (RFC 6902)
- **Watch API**: Stream resource changes with resumable watches via resourceVersion tracking
- **Pod Log API**: Retrieve or stream pod logs with `log()`, supports follow, tailLines, container selection, and more
- **Pod Port-Forward API**: `port_forward()` request/session API for duplex-capable backends
- **Pod Exec API**: `exec()` request/session API for duplex-capable backends
- **Automatic URL building**: Uses IO::K8s class metadata to construct proper API endpoints
- **CRD support**: Use custom resource classes with the standard API
- **Short class names**: Use `'Pod'` instead of `'IO::K8s::Api::Core::V1::Pod'`
- **Type safety**: All objects are strongly typed using IO::K8s classes
- **CLI tools**: `kube_client` for CRUD, `kube_watch` for live event streaming
- **Backwards compatibility**: Deprecated pre-v1 API still works (with warnings)

## See Also

- [Net::Async::Kubernetes](https://metacpan.org/pod/Net::Async::Kubernetes) - Async Kubernetes client for IO::Async
- [IO::K8s](https://metacpan.org/pod/IO::K8s) - Kubernetes resource classes
- [LWP::ConsoleLogger](https://metacpan.org/pod/LWP::ConsoleLogger) - HTTP traffic debugging

## Links

- [CPAN](https://metacpan.org/pod/Kubernetes::REST)
- [Kubernetes API Documentation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.31/)

## License

Apache 2.0

## Authors

- Torsten Raudssus (GETTY) - Current maintainer
- Jose Luis Martinez Torres (JLMARTIN) - Original author
