package Kubernetes::REST;
our $VERSION = '1.104';
# ABSTRACT: A Perl REST Client for the Kubernetes API
use Moo;
use Carp qw(croak carp);
use Scalar::Util qw(blessed);
use Module::Runtime qw(require_module);
use JSON::MaybeXS ();
use Kubernetes::REST::Server;
use Kubernetes::REST::AuthToken;
use Kubernetes::REST::LWPIO;
use Kubernetes::REST::HTTPRequest;
use IO::K8s;
use IO::K8s::List;
use Kubernetes::REST::WatchEvent;
use Kubernetes::REST::LogEvent;

has server => (
    is => 'ro',
    required => 1,
    coerce => sub {
        my $val = $_[0];
        return $val if blessed($val) && $val->isa('Kubernetes::REST::Server');
        Kubernetes::REST::Server->new($val);
    },
);


has credentials => (
    is => 'ro',
    required => 1,
    coerce => sub {
        my $val = $_[0];
        return $val if blessed($val) && $val->can('token');
        return Kubernetes::REST::AuthToken->new($val) if ref($val) eq 'HASH';
        return $val;
    }
);


has io => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $s = $self->server;
        Kubernetes::REST::LWPIO->new(
            ssl_verify_server => $s->ssl_verify_server,
            (defined $s->ssl_cert_pem  ? (ssl_cert_pem  => $s->ssl_cert_pem)  : ()),
            (defined $s->ssl_cert_file ? (ssl_cert_file => $s->ssl_cert_file) : ()),
            (defined $s->ssl_key_pem   ? (ssl_key_pem   => $s->ssl_key_pem)   : ()),
            (defined $s->ssl_key_file  ? (ssl_key_file  => $s->ssl_key_file)  : ()),
            (defined $s->ssl_ca_pem    ? (ssl_ca_pem    => $s->ssl_ca_pem)    : ()),
            (defined $s->ssl_ca_file   ? (ssl_ca_file   => $s->ssl_ca_file)   : ()),
        );
    },
);


has _json => (is => 'ro', default => sub { JSON::MaybeXS->new });

# IO::K8s instance - configured with same resource_map
has k8s => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        return IO::K8s->new(
            resource_map => $self->resource_map,
        );
    },
    handles => [qw(
        new_object
        inflate
        json_to_object
        struct_to_object
        expand_class
    )],
);


# Set to 0 to use IO::K8s defaults instead of loading from cluster
has resource_map_from_cluster => (is => 'ro', default => sub { 1 });


# Cluster version - fetched once per instance
has cluster_version => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $response = $self->_request('GET', '/version');
        return 'unknown' if $response->status >= 400;
        my $info = $self->_json->decode($response->content);
        return $info->{gitVersion} // 'unknown';
    },
);


# Resource map - loads from cluster by default, cached per instance (lazy)
has resource_map => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        return IO::K8s->default_resource_map unless $self->resource_map_from_cluster;
        return $self->_load_resource_map_from_cluster;
    },
);


# Public method to fetch resource map from cluster's OpenAPI spec
sub fetch_resource_map {
    my ($self) = @_;


    my $response = $self->_request('GET', '/openapi/v2');

    if ($response->status >= 400) {
        croak "Could not load resource map from cluster: " . $response->status;
    }

    my $spec = $self->_json->decode($response->content);
    my %map;

    for my $path (keys %{$spec->{paths} // {}}) {
        my $methods = $spec->{paths}{$path};
        for my $method (keys %$methods) {
            my $op = $methods->{$method};
            next unless ref $op eq 'HASH';
            my $gvk = $op->{'x-kubernetes-group-version-kind'};
            next unless $gvk;

            my $kind = $gvk->{kind} // '';
            my $version = $gvk->{version} // '';
            my $group = $gvk->{group} // '';

            next if $kind =~ /List$/;
            next unless $kind && $version;

            my $version_path = ucfirst($version);
            my $new_path;

            # Extension APIs have different base paths in IO::K8s
            if ($group eq 'apiextensions.k8s.io') {
                my $group_path = 'Apiextensions';
                $new_path = "ApiextensionsApiserver::Pkg::Apis::${group_path}::${version_path}::${kind}";
            } elsif ($group eq 'apiregistration.k8s.io') {
                my $group_path = 'Apiregistration';
                $new_path = "KubeAggregator::Pkg::Apis::${group_path}::${version_path}::${kind}";
            } else {
                # Standard API resources use Api:: prefix
                my $group_path = $group eq '' ? 'Core' : ucfirst(lc((split /\./, $group)[0]));
                $new_path = "Api::${group_path}::${version_path}::${kind}";
            }

            # Prefer stable versions
            if (!$map{$kind} || $version !~ /alpha|beta/) {
                $map{$kind} = $new_path;
            }
        }
    }

    return \%map;
}

# Fetch full OpenAPI spec from cluster (cached)
has _openapi_spec => (
    is => 'lazy',
    builder => sub {
        my $self = shift;
        my $response = $self->_request('GET', '/openapi/v2');
        croak "Could not fetch OpenAPI spec: " . $response->status if $response->status >= 400;
        return $self->_json->decode($response->content);
    },
);

# Get schema definition for a specific type
# $kind can be: 'Pod', 'IO::K8s::Api::Core::V1::Pod', or OpenAPI name like 'io.k8s.api.core.v1.Pod'
sub schema_for {
    my ($self, $kind) = @_;


    my $spec = $self->_openapi_spec;
    my $defs = $spec->{definitions} // {};

    # If it's already an OpenAPI definition name
    if (exists $defs->{$kind}) {
        return $defs->{$kind};
    }

    # Convert class name to OpenAPI definition name
    my $class = $self->expand_class($kind);
    # IO::K8s::Api::Core::V1::Pod -> io.k8s.api.core.v1.Pod
    my $def_name = $class;
    $def_name =~ s/^IO::K8s:://;
    $def_name =~ s/::/./g;
    $def_name = 'io.k8s.' . $def_name;
    # Lowercase all path components except the final type name
    my @parts = split /\./, $def_name;
    $parts[$_] = lc($parts[$_]) for 0 .. $#parts - 1;
    $def_name = join '.', @parts;

    return $defs->{$def_name};
}

# Compare local class against cluster schema
# Returns comparison result from IO::K8s::Resource->compare_to_schema
sub compare_schema {
    my ($self, $kind) = @_;


    my $class = $self->expand_class($kind);
    require_module($class);

    my $schema = $self->schema_for($kind);
    croak "Schema not found for $kind" unless $schema;

    return $class->compare_to_schema($schema);
}

# Internal wrapper with fallback for lazy loading
sub _load_resource_map_from_cluster {
    my ($self) = @_;
    my $map = eval { $self->fetch_resource_map };
    if ($@) {
        carp "Could not load resource map from cluster, using default: $@";
        return IO::K8s->default_resource_map;
    }
    return $map;
}

# V0 API compatibility - returns group wrapper objects
sub _v0_group {
    my ($self, $group) = @_;
    my $class = "Kubernetes::REST::$group";
    require_module($class);
    return $class->new(api => $self);
}

sub Core { shift->_v0_group('Core') }
sub Apps { shift->_v0_group('Apps') }
sub Batch { shift->_v0_group('Batch') }
sub Networking { shift->_v0_group('Networking') }
sub Storage { shift->_v0_group('Storage') }
sub Policy { shift->_v0_group('Policy') }
sub Autoscaling { shift->_v0_group('Autoscaling') }
sub RbacAuthorization { shift->_v0_group('RbacAuthorization') }
sub Certificates { shift->_v0_group('Certificates') }
sub Coordination { shift->_v0_group('Coordination') }
sub Events { shift->_v0_group('Events') }
sub Scheduling { shift->_v0_group('Scheduling') }
sub Authentication { shift->_v0_group('Authentication') }
sub Authorization { shift->_v0_group('Authorization') }
sub Admissionregistration { shift->_v0_group('Admissionregistration') }
sub Apiextensions { shift->_v0_group('Apiextensions') }
sub Apiregistration { shift->_v0_group('Apiregistration') }

# Build URL path from class metadata
sub _build_path {
    my ($self, $class, %args) = @_;

    require_module($class);

    # Get metadata from class
    my $api_version = $class->can('api_version') ? $class->api_version : undef;
    croak "Cannot determine api_version for $class - override api_version() in your CRD class"
        unless defined $api_version;
    my $kind = $class->can('kind') ? $class->kind : (split('::', $class))[-1];
    my $is_namespaced = $class->does('IO::K8s::Role::Namespaced');

    # Use explicit resource_plural if available, otherwise auto-pluralize
    my $resource;
    if ($class->can('resource_plural') && $class->resource_plural) {
        $resource = $class->resource_plural;
    } else {
        $resource = lc($kind);
        if ($resource =~ /(?:ss|sh|ch|x|z)$/) {
            $resource .= 'es';        # class -> classes, ingress -> ingresses
        } elsif ($resource =~ /[^aeiou]y$/) {
            $resource =~ s/y$/ies/;   # policy -> policies
        } elsif ($resource !~ /s$/) {
            $resource .= 's';         # pod -> pods
        }
    }

    # Build path based on API group
    my $path;
    if ($api_version =~ m{/}) {
        # Has group: apps/v1 -> /apis/apps/v1/...
        $path = "/apis/$api_version";
    } else {
        # Core: v1 -> /api/v1/...
        $path = "/api/$api_version";
    }

    if ($is_namespaced && $args{namespace}) {
        $path .= "/namespaces/$args{namespace}";
    }

    $path .= "/$resource";

    if ($args{name}) {
        $path .= "/$args{name}";
    }

    return $path;
}

# ============================================================================
# REQUEST / RESPONSE PIPELINE
#
# The API methods (list, get, create, etc.) are built on a 3-step pipeline:
#
#   1. _prepare_request  - builds an HTTPRequest (method, url, headers, body)
#   2. io->call          - executes the request (pluggable: HTTP::Tiny, async, mock)
#   3. _check_response / _inflate_object / _inflate_list - processes the response
#
# This separation allows different IO backends (sync, async, mock) to slot in
# at step 2 without touching request preparation or response processing.
# ============================================================================

sub _prepare_request {
    my ($self, $method, $path, %opts) = @_;

    my $url = $self->server->endpoint . $path;
    my $content_type = $opts{content_type} // 'application/json';
    my $body = $opts{body};
    my $parameters = $opts{parameters};
    my $extra_headers = $opts{headers} // {};

    # Append query parameters to URL
    if ($parameters && %$parameters) {
        my @pairs;
        for my $key (sort keys %$parameters) {
            my $val = $parameters->{$key};
            next unless defined $val;
            if (ref($val) eq 'ARRAY') {
                push @pairs, map { "$key=$_" } grep { defined } @$val;
            } else {
                push @pairs, "$key=$val";
            }
        }
        if (@pairs) {
            $url .= ($url =~ /\?/ ? '&' : '?') . join('&', @pairs);
        }
    }

    my %headers = (
        'Content-Type' => $content_type,
        'Accept' => 'application/json',
    );

    # Only add Authorization header when a token is available
    # (client-certificate auth doesn't need a Bearer token)
    my $token = $self->credentials->token;
    if (defined $token && length $token) {
        $headers{'Authorization'} = 'Bearer ' . $token;
    }
    if ($extra_headers && ref($extra_headers) eq 'HASH') {
        @headers{keys %$extra_headers} = values %$extra_headers;
    }

    return Kubernetes::REST::HTTPRequest->new(
        method => $method,
        url => $url,
        headers => \%headers,
        ($body ? (content => $self->_json->encode($body)) : ()),
    );
}

sub _check_response {
    my ($self, $response, $context) = @_;
    if ($response->status >= 400) {
        croak "Kubernetes API error ($context): "
            . $response->status . " " . ($response->content // '');
    }
    return $response;
}

sub _inflate_object {
    my ($self, $class, $response) = @_;
    return $self->k8s->json_to_object($class, $response->content);
}

sub _inflate_list {
    my ($self, $class, $response) = @_;
    my $struct = $self->_json->decode($response->content);
    my @objects;
    for my $item (@{$struct->{items} // []}) {
        my $obj = eval { $self->k8s->struct_to_object($class, $item) };
        push @objects, $obj if $obj;
    }
    return IO::K8s::List->new(items => \@objects, item_class => $class);
}

sub _process_watch_chunk {
    my ($self, $class, $buffer_ref, $chunk) = @_;
    $$buffer_ref .= $chunk;

    my @events;
    while ($$buffer_ref =~ s/^([^\n]*)\n//) {
        my $line = $1;
        next unless length $line;

        my $data = eval { $self->_json->decode($line) };
        next unless $data;

        my $type = $data->{type} // '';
        my $raw_object = $data->{object} // {};

        # Track resourceVersion for resumability
        my $rv;
        if ($raw_object->{metadata} && $raw_object->{metadata}{resourceVersion}) {
            $rv = $raw_object->{metadata}{resourceVersion};
        }

        # Inflate the object (ERROR events stay as hashrefs)
        my $object;
        if ($type eq 'ERROR') {
            $object = $raw_object;
        } else {
            $object = eval { $self->k8s->struct_to_object($class, $raw_object) }
                // $raw_object;
        }

        push @events, {
            event => Kubernetes::REST::WatchEvent->new(
                type   => $type,
                object => $object,
                raw    => $raw_object,
            ),
            resourceVersion => $rv,
            is_error        => ($type eq 'ERROR' ? 1 : 0),
            error_code      => ($type eq 'ERROR' ? ($raw_object->{code} // 0) : 0),
        };
    }

    return @events;
}

sub _process_log_chunk {
    my ($self, $buffer_ref, $chunk) = @_;
    $$buffer_ref .= $chunk;

    my @events;
    while ($$buffer_ref =~ s/^([^\n]*)\n//) {
        my $line = $1;
        push @events, Kubernetes::REST::LogEvent->new(line => $line);
    }

    return @events;
}

# ============================================================================
# PUBLIC BUILDING BLOCKS FOR ASYNC WRAPPERS
#
# These methods expose the internal request/response pipeline as a stable API
# for async wrappers (e.g. Net::Async::Kubernetes) that need to build requests,
# process responses, and handle streaming without going through the sync
# convenience methods (list, get, watch, log, port_forward, exec, attach, etc.).
# ============================================================================

sub build_path {
    my ($self, @args) = @_;


    return $self->_build_path(@args);
}

sub prepare_request {
    my ($self, @args) = @_;


    return $self->_prepare_request(@args);
}

sub check_response {
    my ($self, @args) = @_;


    return $self->_check_response(@args);
}

sub inflate_object {
    my ($self, @args) = @_;


    return $self->_inflate_object(@args);
}

sub inflate_list {
    my ($self, @args) = @_;


    return $self->_inflate_list(@args);
}

sub process_watch_chunk {
    my ($self, @args) = @_;


    return $self->_process_watch_chunk(@args);
}

sub process_log_chunk {
    my ($self, @args) = @_;


    return $self->_process_log_chunk(@args);
}

# Convenience: prepare + call in one step (used by sync CRUD methods)
sub _request {
    my ($self, $method, $path, $body, %opts) = @_;
    my $req = $self->_prepare_request($method, $path,
        body => $body,
        %opts,
    );
    return $self->io->call($req);
}

sub list {
    my ($self, $short_class, %args) = @_;


    # Extract query parameters before building path
    my $label_selector = delete $args{labelSelector};
    my $field_selector = delete $args{fieldSelector};

    my $class = $self->expand_class($short_class);
    my $path = $self->_build_path($class, %args);

    my %params;
    $params{labelSelector} = $label_selector if defined $label_selector;
    $params{fieldSelector} = $field_selector if defined $field_selector;

    my $response = %params
        ? $self->_request('GET', $path, undef, parameters => \%params)
        : $self->_request('GET', $path);
    $self->_check_response($response, "list $short_class");

    return $self->_inflate_list($class, $response);
}

sub get {
    my ($self, $short_class, @rest) = @_;


    # Support: get('Kind', 'name'), get('Kind', 'name', namespace => 'ns'),
    #          get('Kind', name => 'name'), get('Kind', name => 'name', namespace => 'ns')
    my %args;
    if (@rest == 1) {
        $args{name} = $rest[0];
    } elsif (@rest >= 2 && $rest[0] !~ /^(name|namespace)$/) {
        # First arg is name, rest are key=value pairs
        $args{name} = shift @rest;
        %args = (%args, @rest);
    } elsif (@rest % 2 == 0) {
        %args = @rest;
    } else {
        croak "Invalid arguments to get()";
    }

    my $class = $self->expand_class($short_class);
    croak "name required for get" unless $args{name};

    my $path = $self->_build_path($class, %args);
    my $response = $self->_request('GET', $path);
    $self->_check_response($response, "get $short_class");

    return $self->_inflate_object($class, $response);
}

sub create {
    my ($self, $object) = @_;


    my $class = ref($object);
    my $namespace = $object->can('metadata') && $object->metadata
        ? $object->metadata->namespace
        : undef;

    my $path = $self->_build_path($class, namespace => $namespace);
    my $response = $self->_request('POST', $path, $object->TO_JSON);
    $self->_check_response($response, "create " . ref($object));

    return $self->_inflate_object($class, $response);
}

sub update {
    my ($self, $object) = @_;


    my $class = ref($object);
    my $metadata = $object->metadata or croak "object must have metadata";
    my $name = $metadata->name or croak "object must have metadata.name";
    my $namespace = $metadata->namespace;

    my $path = $self->_build_path($class, name => $name, namespace => $namespace);
    my $response = $self->_request('PUT', $path, $object->TO_JSON);
    $self->_check_response($response, "update " . ref($object));

    return $self->_inflate_object($class, $response);
}

my %PATCH_TYPES = (
    strategic => 'application/strategic-merge-patch+json',
    merge     => 'application/merge-patch+json',
    json      => 'application/json-patch+json',
);

sub patch {
    my ($self, $class_or_object, @rest) = @_;


    my ($class, $name, $namespace, $patch, $patch_type);

    if (ref($class_or_object) && blessed($class_or_object)) {
        # Object passed: patch($object, patch => {...})
        my $object = $class_or_object;
        $class = ref($object);
        my $metadata = $object->metadata or croak "object must have metadata";
        $name = $metadata->name or croak "object must have metadata.name";
        $namespace = $metadata->namespace;
        my %args = @rest;
        $patch = $args{patch} // croak "patch requires 'patch' parameter";
        $patch_type = $args{type} // 'strategic';
    } else {
        # Class + name: patch('Pod', 'name', namespace => 'ns', patch => {...})
        my %args;
        if (@rest >= 1 && !ref($rest[0]) && $rest[0] !~ /^(name|namespace|patch|type)$/) {
            $args{name} = shift @rest;
            %args = (%args, @rest);
        } elsif (@rest % 2 == 0) {
            %args = @rest;
        } else {
            croak "Invalid arguments to patch()";
        }

        $class = $self->expand_class($class_or_object);
        $name = $args{name} or croak "name required for patch";
        $namespace = $args{namespace};
        $patch = $args{patch} // croak "patch requires 'patch' parameter";
        $patch_type = $args{type} // 'strategic';
    }

    my $content_type = $PATCH_TYPES{$patch_type}
        // croak "Unknown patch type '$patch_type' (use: strategic, merge, json)";

    my $path = $self->_build_path($class, name => $name, namespace => $namespace);
    my $response = $self->_request('PATCH', $path, $patch,
        content_type => $content_type);
    $self->_check_response($response, "patch $class");

    return $self->_inflate_object($class, $response);
}

sub delete {
    my ($self, $class_or_object, @rest) = @_;


    my ($class, $name, $namespace);

    if (ref($class_or_object)) {
        # Object passed
        my $object = $class_or_object;
        $class = ref($object);
        my $metadata = $object->metadata or croak "object must have metadata";
        $name = $metadata->name or croak "object must have metadata.name";
        $namespace = $metadata->namespace;
    } else {
        # Support: delete('Kind', 'name'), delete('Kind', 'name', namespace => 'ns'),
        #          delete('Kind', name => 'name'), delete('Kind', name => 'name', namespace => 'ns')
        my %args;
        if (@rest == 1) {
            $args{name} = $rest[0];
        } elsif (@rest >= 2 && $rest[0] !~ /^(name|namespace)$/) {
            # First arg is name, rest are key=value pairs
            $args{name} = shift @rest;
            %args = (%args, @rest);
        } elsif (@rest % 2 == 0) {
            %args = @rest;
        } else {
            croak "Invalid arguments to delete()";
        }

        $class = $self->expand_class($class_or_object);
        $name = $args{name} or croak "name required for delete";
        $namespace = $args{namespace};
    }

    my $path = $self->_build_path($class, name => $name, namespace => $namespace);
    my $response = $self->_request('DELETE', $path);
    $self->_check_response($response, "delete $class");

    return 1;
}

sub ensure {
    my ($self, $object) = @_;


    if (ref($object) eq 'HASH') {
        my $kind = $object->{kind} or croak "ensure: hashref must have 'kind'";
        my $class = $self->expand_class($kind);
        $object = $self->k8s->struct_to_object($class, $object);
    }

    my $class = ref($object);
    croak "ensure requires an IO::K8s object or hashref" unless blessed($object);
    (my $kind = $class) =~ s/.*:://;
    my $metadata = $object->metadata or croak "object must have metadata";
    my $name = $metadata->name or croak "object must have metadata.name";
    my $namespace = $metadata->namespace;

    my $path = $self->_build_path($class, name => $name, namespace => $namespace);

    my $existing = eval {
        my $response = $self->_request('GET', $path);
        return undef if $response->status == 404;
        $self->_check_response($response, "ensure get $kind/$name");
        $self->_inflate_object($class, $response);
    };
    my $get_err = $@;
    die $get_err if $get_err && $get_err !~ /\b404\b/;

    if ($existing) {
        return $existing if $kind eq 'PersistentVolumeClaim';
        if ($kind eq 'Job') {
            my $status = $existing->status;
            my $succeeded = $status && $status->succeeded;
            my $active    = $status && $status->active;
            return $existing if $succeeded || $active;
            eval { $self->delete($existing) };
            return $self->create($object);
        }
        $object->metadata->resourceVersion($existing->metadata->resourceVersion);
        my $updated = eval { $self->update($object) };
        return $updated if $updated;
        if ($@ =~ /\b409\b/) {
            $existing = $self->_request('GET', $path);
            $self->_check_response($existing, "ensure refetch $kind/$name");
            $existing = $self->_inflate_object($class, $existing);
            $object->metadata->resourceVersion($existing->metadata->resourceVersion);
            return $self->update($object);
        }
        die $@;
    }

    my $created = eval { $self->create($object) };
    return $created if $created;

    if ($@ =~ /\b409\b/) {
        my $response = $self->_request('GET', $path);
        $self->_check_response($response, "ensure post-409 get $kind/$name");
        $existing = $self->_inflate_object($class, $response);
        return $existing if $kind eq 'PersistentVolumeClaim';
        $object->metadata->resourceVersion($existing->metadata->resourceVersion);
        return $self->update($object);
    }
    die $@;
}

sub ensure_all {
    my ($self, @objects) = @_;


    return map { $self->ensure($_) } @objects;
}

sub ensure_only {
    my ($self, %args) = @_;


    my $label      = $args{label} or croak "ensure_only requires 'label'";
    my @objects    = @{$args{objects} || []};
    my @kinds      = @{$args{kinds} || []};
    my @namespaces = @{$args{namespaces} || [undef]};

    for my $obj (@objects) {
        next unless ref($obj) eq 'HASH';
        my $kind = $obj->{kind} or croak "ensure_only: hashref must have 'kind'";
        my $class = $self->expand_class($kind);
        $obj = $self->k8s->struct_to_object($class, $obj);
    }

    my @results = $self->ensure_all(@objects);

    my %expected;
    for my $obj (@objects) {
        (my $kind = ref $obj) =~ s/.*:://;
        my $key = join("\0", $kind, $obj->metadata->namespace // '');
        $expected{$key}{$obj->metadata->name} = 1;
    }

    for my $kind (@kinds) {
        for my $ns (@namespaces) {
            my %list_args = (labelSelector => $label);
            $list_args{namespace} = $ns if defined $ns;
            my $list = eval { $self->list($kind, %list_args) };
            next unless $list;
            for my $item (@{$list->items}) {
                my $item_ns = $item->metadata->namespace // '';
                my $key = join("\0", $kind, $item_ns);
                next if $expected{$key} && $expected{$key}{$item->metadata->name};
                eval { $self->delete($item) };
            }
        }
    }

    return @results;
}

sub watch {
    my ($self, $short_class, %args) = @_;


    my $on_event = delete $args{on_event}
        or croak "watch requires 'on_event' callback";
    my $timeout          = delete $args{timeout} // 300;
    my $resource_version = delete $args{resourceVersion};
    my $label_selector   = delete $args{labelSelector};
    my $field_selector   = delete $args{fieldSelector};

    my $class = $self->expand_class($short_class);
    my $path = $self->_build_path($class, %args);

    my %params = (
        watch          => 'true',
        timeoutSeconds => $timeout,
    );
    $params{resourceVersion} = $resource_version if defined $resource_version;
    $params{labelSelector}   = $label_selector   if defined $label_selector;
    $params{fieldSelector}   = $field_selector   if defined $field_selector;

    my $req = $self->_prepare_request('GET', $path, parameters => \%params);

    my $buffer = '';
    my $last_rv = $resource_version;
    my $got_410 = 0;

    my $data_callback = sub {
        my ($chunk) = @_;
        for my $result ($self->_process_watch_chunk($class, \$buffer, $chunk)) {
            $last_rv = $result->{resourceVersion} if $result->{resourceVersion};
            $got_410 = 1 if $result->{error_code} == 410;
            $on_event->($result->{event});
        }
    };

    my $response = $self->io->call_streaming($req, $data_callback);

    $self->_check_response($response, "watch $short_class");

    croak "Watch expired (410 Gone): resourceVersion too old, re-list to get a fresh resourceVersion"
        if $got_410;

    return $last_rv;
}

sub log {
    my ($self, $short_class, @rest) = @_;


    # Support: log('Pod', 'name', ...) and log('Pod', name => 'name', ...)
    my %args;
    if (@rest >= 1 && !ref($rest[0]) && $rest[0] !~ /^(name|namespace|container|follow|tailLines|sinceSeconds|sinceTime|timestamps|previous|limitBytes|on_line)$/) {
        $args{name} = shift @rest;
        %args = (%args, @rest);
    } elsif (@rest % 2 == 0) {
        %args = @rest;
    } else {
        croak "Invalid arguments to log()";
    }

    croak "name required for log" unless $args{name};

    my $on_line      = delete $args{on_line};
    my $container    = delete $args{container};
    my $follow       = delete $args{follow};
    my $tail_lines   = delete $args{tailLines};
    my $since_seconds = delete $args{sinceSeconds};
    my $since_time   = delete $args{sinceTime};
    my $timestamps   = delete $args{timestamps};
    my $previous     = delete $args{previous};
    my $limit_bytes  = delete $args{limitBytes};

    my $class = $self->expand_class($short_class);
    my $path = $self->_build_path($class, %args) . '/log';

    my %params;
    $params{container}    = $container     if defined $container;
    $params{follow}       = 'true'         if $follow;
    $params{tailLines}    = $tail_lines    if defined $tail_lines;
    $params{sinceSeconds} = $since_seconds if defined $since_seconds;
    $params{sinceTime}    = $since_time    if defined $since_time;
    $params{timestamps}   = 'true'         if $timestamps;
    $params{previous}     = 'true'         if $previous;
    $params{limitBytes}   = $limit_bytes   if defined $limit_bytes;

    if ($on_line) {
        # Streaming mode
        my $req = $self->_prepare_request('GET', $path, parameters => \%params);

        my $buffer = '';
        my $data_callback = sub {
            my ($chunk) = @_;
            for my $event ($self->_process_log_chunk(\$buffer, $chunk)) {
                $on_line->($event);
            }
        };

        my $response = $self->io->call_streaming($req, $data_callback);
        $self->_check_response($response, "log $short_class");

        # Process any remaining data in buffer (last line without trailing newline)
        if (length $buffer) {
            $on_line->(Kubernetes::REST::LogEvent->new(line => $buffer));
        }

        return;
    } else {
        # One-shot mode
        my $response = $self->_request('GET', $path, undef,
            %params ? (parameters => \%params) : (),
        );
        $self->_check_response($response, "log $short_class");

        return $response->content;
    }
}

sub port_forward {
    my ($self, $short_class, @rest) = @_;


    my %args;
    if (@rest >= 1 && !ref($rest[0]) && $rest[0] !~ /^(name|namespace|ports|subprotocol|on_open|on_frame|on_close|on_error)$/) {
        $args{name} = shift @rest;
        %args = (%args, @rest);
    } elsif (@rest % 2 == 0) {
        %args = @rest;
    } else {
        croak "Invalid arguments to port_forward()";
    }

    croak "name required for port_forward" unless $args{name};

    my $ports = delete $args{ports};
    croak "ports required for port_forward" unless defined $ports;
    $ports = [$ports] unless ref($ports) eq 'ARRAY';
    croak "ports required for port_forward" unless @$ports;
    for my $p (@$ports) {
        croak "invalid port '$p' for port_forward"
            unless defined($p) && $p =~ /^\d+$/ && $p > 0 && $p <= 65535;
    }

    my $subprotocol = delete $args{subprotocol} // 'v4.channel.k8s.io';
    my $on_open  = delete $args{on_open};
    my $on_frame = delete $args{on_frame};
    my $on_close = delete $args{on_close};
    my $on_error = delete $args{on_error};

    my $class = $self->expand_class($short_class);
    my $path = $self->_build_path($class, %args) . '/portforward';

    my $req = $self->_prepare_request('GET', $path,
        parameters => { ports => $ports },
        headers    => {
            Accept                 => '*/*',
            Connection             => 'Upgrade',
            Upgrade                => 'websocket',
            'Sec-WebSocket-Protocol' => $subprotocol,
        },
    );

    my $io = $self->io;
    unless ($io->can('call_duplex')) {
        croak "IO backend does not support port_forward(): missing call_duplex()";
    }

    return $io->call_duplex($req,
        on_open  => $on_open,
        on_frame => $on_frame,
        on_close => $on_close,
        on_error => $on_error,
    );
}

sub exec {
    my ($self, $short_class, @rest) = @_;


    my %args;
    if (@rest >= 1 && !ref($rest[0]) && $rest[0] !~ /^(name|namespace|command|container|stdin|stdout|stderr|tty|subprotocol|on_open|on_frame|on_close|on_error)$/) {
        $args{name} = shift @rest;
        %args = (%args, @rest);
    } elsif (@rest % 2 == 0) {
        %args = @rest;
    } else {
        croak "Invalid arguments to exec()";
    }

    croak "name required for exec" unless $args{name};

    my $command = delete $args{command};
    croak "command required for exec" unless defined $command;
    $command = [$command] unless ref($command) eq 'ARRAY';
    croak "command required for exec" unless @$command;
    for my $part (@$command) {
        croak "invalid command element for exec"
            unless defined($part) && !ref($part) && length $part;
    }

    my $container = delete $args{container};
    my $stdin  = delete($args{stdin})  ? 1 : 0;
    my $stdout = exists($args{stdout}) ? (delete($args{stdout}) ? 1 : 0) : 1;
    my $stderr = exists($args{stderr}) ? (delete($args{stderr}) ? 1 : 0) : 1;
    my $tty    = delete($args{tty})    ? 1 : 0;

    my $subprotocol = delete $args{subprotocol} // 'v4.channel.k8s.io';
    my $on_open  = delete $args{on_open};
    my $on_frame = delete $args{on_frame};
    my $on_close = delete $args{on_close};
    my $on_error = delete $args{on_error};

    my $class = $self->expand_class($short_class);
    my $path = $self->_build_path($class, %args) . '/exec';

    my %params = (
        command => $command,
        stdin   => $stdin  ? 'true' : 'false',
        stdout  => $stdout ? 'true' : 'false',
        stderr  => $stderr ? 'true' : 'false',
        tty     => $tty    ? 'true' : 'false',
    );
    $params{container} = $container if defined $container;

    my $req = $self->_prepare_request('GET', $path,
        parameters => \%params,
        headers    => {
            Accept                   => '*/*',
            Connection               => 'Upgrade',
            Upgrade                  => 'websocket',
            'Sec-WebSocket-Protocol' => $subprotocol,
        },
    );

    my $io = $self->io;
    unless ($io->can('call_duplex')) {
        croak "IO backend does not support exec(): missing call_duplex()";
    }

    return $io->call_duplex($req,
        on_open  => $on_open,
        on_frame => $on_frame,
        on_close => $on_close,
        on_error => $on_error,
    );
}

sub attach {
    my ($self, $short_class, @rest) = @_;


    my %args;
    if (@rest >= 1 && !ref($rest[0]) && $rest[0] !~ /^(name|namespace|container|stdin|stdout|stderr|tty|subprotocol|on_open|on_frame|on_close|on_error)$/) {
        $args{name} = shift @rest;
        %args = (%args, @rest);
    } elsif (@rest % 2 == 0) {
        %args = @rest;
    } else {
        croak "Invalid arguments to attach()";
    }

    croak "name required for attach" unless $args{name};

    my $container = delete $args{container};
    my $stdin  = delete($args{stdin})  ? 1 : 0;
    my $stdout = exists($args{stdout}) ? (delete($args{stdout}) ? 1 : 0) : 1;
    my $stderr = exists($args{stderr}) ? (delete($args{stderr}) ? 1 : 0) : 1;
    my $tty    = delete($args{tty})    ? 1 : 0;

    my $subprotocol = delete $args{subprotocol} // 'v4.channel.k8s.io';
    my $on_open  = delete $args{on_open};
    my $on_frame = delete $args{on_frame};
    my $on_close = delete $args{on_close};
    my $on_error = delete $args{on_error};

    my $class = $self->expand_class($short_class);
    my $path = $self->_build_path($class, %args) . '/attach';

    my %params = (
        stdin   => $stdin  ? 'true' : 'false',
        stdout  => $stdout ? 'true' : 'false',
        stderr  => $stderr ? 'true' : 'false',
        tty     => $tty    ? 'true' : 'false',
    );
    $params{container} = $container if defined $container;

    my $req = $self->_prepare_request('GET', $path,
        parameters => \%params,
        headers    => {
            Accept                   => '*/*',
            Connection               => 'Upgrade',
            Upgrade                  => 'websocket',
            'Sec-WebSocket-Protocol' => $subprotocol,
        },
    );

    my $io = $self->io;
    unless ($io->can('call_duplex')) {
        croak "IO backend does not support attach(): missing call_duplex()";
    }

    return $io->call_duplex($req,
        on_open  => $on_open,
        on_frame => $on_frame,
        on_close => $on_close,
        on_error => $on_error,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::REST - A Perl REST Client for the Kubernetes API

=head1 VERSION

version 1.104

=head1 SYNOPSIS

    use Kubernetes::REST;

    my $api = Kubernetes::REST->new(
        server => {
            endpoint => 'https://kubernetes.local:6443',
            ssl_verify_server => 1,
            ssl_ca_file => '/path/to/ca.crt',
        },
        credentials => { token => $token },
    );

    # List all namespaces
    my $namespaces = $api->list('Namespace');
    for my $ns (@{ $namespaces->items }) {
        say $ns->metadata->name;
    }

    # List pods in a namespace
    my $pods = $api->list('Pod', namespace => 'default');

    # Get a specific pod
    my $pod = $api->get('Pod', name => 'my-pod', namespace => 'default');

    # Create a namespace
    my $ns = $api->new_object(Namespace => {
        metadata => { name => 'my-namespace' },
    });
    my $created = $api->create($ns);

    # Create multiple namespaces
    for my $i (1..10) {
        $api->create($api->new_object(Namespace =>
            metadata => { name => "test-ns-$i" },
        ));
    }

    # Update a resource (full replacement)
    $pod->metadata->labels({ app => 'updated' });
    my $updated = $api->update($pod);

    # Patch a resource (partial update)
    my $patched = $api->patch('Pod', 'my-pod',
        namespace => 'default',
        patch     => { metadata => { labels => { env => 'staging' } } },
    );

    # Delete a resource
    $api->delete($pod);
    # or by name:
    $api->delete('Pod', name => 'my-pod', namespace => 'default');

    # Idempotent create-or-update (from a typed object or a manifest hashref)
    $api->ensure($pod);
    $api->ensure({
        apiVersion => 'v1',
        kind       => 'Secret',
        metadata   => { name => 'my-secret', namespace => 'default' },
        stringData => { password => 'hunter2' },
    });

    # Batch apply
    $api->ensure_all(@objects);

    # Apply a labeled set and prune anything with that label not in the set
    $api->ensure_only(
        label      => 'app.kubernetes.io/component=queen',
        objects    => \@rbac_objects,
        kinds      => [qw(Role RoleBinding ClusterRoleBinding)],
        namespaces => ['default', undef],
    );

=head1 DESCRIPTION

This module provides a simple REST client for the Kubernetes API using IO::K8s
resource classes. The IO::K8s classes know their own metadata (API version,
kind, whether they're namespaced), so URL building is automatic.

=head2 server

Required. L<Kubernetes::REST::Server> instance or hashref with server connection configuration.

    server => { endpoint => 'https://kubernetes.local:6443' }

Automatically coerces hashrefs to L<Kubernetes::REST::Server> objects.

=head2 credentials

Required. Authentication credentials. Can be a hashref, L<Kubernetes::REST::AuthToken>, or any object with a C<token()> method.

    credentials => { token => $bearer_token }

Automatically coerces hashrefs to L<Kubernetes::REST::AuthToken> objects.

=head2 io

HTTP backend for making requests. Must consume L<Kubernetes::REST::Role::IO>. Defaults to L<Kubernetes::REST::LWPIO> (L<LWP::UserAgent>).

To use L<HTTP::Tiny> instead:

    use Kubernetes::REST::HTTPTinyIO;
    my $api = Kubernetes::REST->new(
        ...,
        io => Kubernetes::REST::HTTPTinyIO->new(...),
    );

See L</PLUGGABLE IO ARCHITECTURE> for custom backends.

=head2 k8s

L<IO::K8s> instance configured with the same resource map. Automatically created when needed.

Provides delegated methods: C<new_object>, C<inflate>, C<json_to_object>, C<struct_to_object>, C<expand_class>.

=head2 resource_map_from_cluster

Boolean. If true, dynamically loads the resource map from the cluster's OpenAPI spec. Defaults to C<1>.

Set to C<0> to use L<IO::K8s> built-in resource map instead (faster startup, but may not match your cluster version).

=head2 cluster_version

Read-only. The Kubernetes cluster version string (e.g., C<v1.31.0>). Fetched automatically from the C</version> endpoint when first accessed.

=head2 resource_map

Hashref mapping short resource names to L<IO::K8s> class paths. By default loads dynamically from the cluster (if C<resource_map_from_cluster> is true) or uses L<IO::K8s> built-in map.

Override for custom resources:

    resource_map => {
        %{ IO::K8s->default_resource_map },
        MyResource => '+My::K8s::V1::MyResource',
    }

The C<+> prefix tells L<IO::K8s> that this is a custom class (not in the IO::K8s:: namespace).

=head2 fetch_resource_map

    my $map = $api->fetch_resource_map;

Fetch the resource map from the cluster's OpenAPI spec (C</openapi/v2> endpoint). Returns a hashref mapping short resource names (e.g., C<Pod>) to full L<IO::K8s> class paths.

Called automatically if C<resource_map_from_cluster> is enabled.

=head2 schema_for

    my $schema = $api->schema_for('Pod');

Get the OpenAPI schema definition for a resource type from the cluster. Accepts short names (C<Pod>), full class names (C<IO::K8s::Api::Core::V1::Pod>), or OpenAPI definition names (C<io.k8s.api.core.v1.Pod>).

Returns a hashref with the OpenAPI v2 schema definition.

=head2 compare_schema

    my $result = $api->compare_schema('Pod');

Compare the local L<IO::K8s> class definition against the cluster's OpenAPI schema. Useful for detecting version skew between your L<IO::K8s> installation and the cluster.

Returns the comparison result from C<< IO::K8s::Resource->compare_to_schema >>.

=head2 build_path

    my $class = $api->expand_class('Pod');
    my $path = $api->build_path($class, name => 'my-pod', namespace => 'default');
    # => /api/v1/namespaces/default/pods/my-pod

Build the REST API URL path for a resource class. Takes a fully-qualified class name (from L</expand_class>) and optional C<name>/C<namespace> arguments.

This is a public API for async wrappers like L<Net::Async::Kubernetes> that need to construct request paths independently.

=head2 prepare_request

    my $req = $api->prepare_request('GET', $path,
        parameters => \%params,
        body       => \%body,
    );

Build a L<Kubernetes::REST::HTTPRequest> with method, full URL, authorization
headers, and optional query parameters or JSON body.

Query parameter values may be scalars or arrayrefs (arrayrefs are emitted as
repeated C<key=value> pairs). Extra request headers can be provided via
C<headers =E<gt> \%headers>.

This is a public API for async wrappers that execute HTTP requests through their own event loop.

=head2 check_response

    $api->check_response($response, "get Pod");

Validate an HTTP response. Croaks with a descriptive error if the status code is >= 400. Returns the response on success.

=head2 inflate_object

    my $pod = $api->inflate_object($class, $response);

Decode the JSON response body and inflate it into a typed L<IO::K8s> object.

=head2 inflate_list

    my $list = $api->inflate_list($class, $response);

Decode the JSON response body and inflate the C<items> array into an L<IO::K8s::List> of typed objects.

=head2 process_watch_chunk

    my @results = $api->process_watch_chunk($class, \$buffer, $chunk);

Process a chunk of NDJSON watch data. Appends the chunk to the buffer, extracts complete lines, and returns a list of hashrefs with C<event> (L<Kubernetes::REST::WatchEvent>), C<resourceVersion>, C<is_error>, and C<error_code>.

This is a public API for async wrappers that handle streaming watch responses through their own event loop.

=head2 process_log_chunk

    my @events = $api->process_log_chunk(\$buffer, $chunk);

Process a chunk of plain-text log data. Appends the chunk to the buffer, extracts complete lines, and returns a list of L<Kubernetes::REST::LogEvent> objects.

This is a public API for async wrappers that handle streaming log responses through their own event loop.

=head2 list

    my $list = $api->list('Pod', namespace => 'default');
    my $list = $api->list('Namespace', labelSelector => 'app=web');

List resources. Returns an L<IO::K8s::List> object.

Accepts short class names (C<Pod>) or full class paths. For namespaced resources, pass C<namespace> parameter. Omit C<namespace> to list cluster-scoped resources.

Supports C<labelSelector> and C<fieldSelector> query parameters for server-side filtering.

=head2 get

    my $pod = $api->get('Pod', name => 'my-pod', namespace => 'default');
    # or shorthand:
    my $pod = $api->get('Pod', 'my-pod', namespace => 'default');

Get a single resource by name. Returns a typed L<IO::K8s> object.

=head2 create

    my $created = $api->create($pod);

Create a resource from an L<IO::K8s> object. Returns the created object with server-assigned fields (UID, resourceVersion, etc.).

=head2 update

    my $updated = $api->update($pod);

Update an existing resource. Replaces the entire object server-side. Returns the updated object.

For partial updates, use L</patch> instead.

=head2 patch

    my $patched = $api->patch('Pod', 'my-pod',
        namespace => 'default',
        patch     => { metadata => { labels => { env => 'staging' } } },
    );

    # Or with an object:
    my $patched = $api->patch($pod,
        patch => { metadata => { labels => { env => 'staging' } } },
    );

Partially update a resource. Unlike C<update()> which replaces the entire object, C<patch()> only modifies specified fields.

Supports three patch strategies via the C<type> parameter:

=over 4

=item C<strategic> (default) - Strategic Merge Patch (Kubernetes-native, understands array merge semantics)

=item C<merge> - JSON Merge Patch (RFC 7396, simple recursive merge)

=item C<json> - JSON Patch (RFC 6902, array of operations)

=back

See L<Kubernetes::REST/patch> for detailed examples.

=head2 delete

    $api->delete($pod);
    # or by name:
    $api->delete('Pod', name => 'my-pod', namespace => 'default');
    # or shorthand:
    $api->delete('Pod', 'my-pod', namespace => 'default');

Delete a resource. Returns true on success.

=head2 ensure

    my $obj = $api->ensure($pod);
    # or from a plain hashref (treated as a Kubernetes manifest):
    my $secret = $api->ensure({
        apiVersion => 'v1',
        kind       => 'Secret',
        metadata   => { name => 'foo', namespace => 'default' },
        stringData => { password => 'hunter2' },
    });

Idempotent create-or-update. Fetches the resource by kind/name/namespace; if it
exists, updates it (preserving C<resourceVersion>), otherwise creates it.
Returns the resulting L<IO::K8s> object.

Accepts either a typed L<IO::K8s> object or a plain hashref. A hashref must
carry a C<kind> field and is inflated to a typed object via
L<IO::K8s/struct_to_object>. Hashref keys follow the Kubernetes API convention
(camelCase, e.g. C<stringData>, not C<string_data>).

Handles common race conditions:

=over 4

=item * 404 on initial get is treated as "does not exist" and falls through to create.

=item * 409 AlreadyExists on create (resource appeared between get and create) is
retried as an update.

=item * 409 Conflict on update (resourceVersion changed server-side, e.g. a
controller wrote status) is retried by re-fetching and re-applying.

=back

Special-cases for kinds with server-side mutation constraints:

=over 4

=item * C<PersistentVolumeClaim> - spec is immutable after creation, so an existing
PVC is returned unchanged.

=item * C<Job> - spec is immutable; an existing Job that is active or has
succeeded is returned unchanged. A failed Job is deleted and recreated.

=back

=head2 ensure_all

    my @results = $api->ensure_all(@objects);

Batch version of L</ensure>. Applies create-or-update to each object in order
and returns the list of resulting objects.

=head2 ensure_only

    $api->ensure_only(
        label      => 'app.kubernetes.io/component=queen',
        objects    => \@objects,
        kinds      => [qw(Role RoleBinding ClusterRoleBinding)],
        namespaces => ['default', 'kube-system', undef],
    );

Like L</ensure_all>, but also B<deletes> any resources matching the label
selector in the given kinds and namespaces that are not present in C<objects>.
Use this for resources where stale objects must not survive (e.g. RBAC).

Pass C<undef> inside C<namespaces> to scan cluster-scoped resources. If
C<namespaces> is omitted, only cluster-scoped resources are scanned.

Returns the list of applied objects (from L</ensure_all>).

=head2 watch

    my $last_rv = $api->watch('Pod',
        namespace => 'default',
        on_event  => sub {
            my ($event) = @_;
            say $event->type . ": " . $event->object->metadata->name;
        },
        timeout         => 300,
        resourceVersion => '12345',
        labelSelector   => 'app=web',
        fieldSelector   => 'status.phase=Running',
    );

Watch for changes to resources. Uses the Kubernetes Watch API with chunked transfer encoding to stream events. The call blocks until the server-side timeout expires.

Returns the last C<resourceVersion> seen. Croaks on 410 Gone (resourceVersion too old).

See L<Kubernetes::REST/watch> for detailed documentation and resumable watch patterns.

=head2 log

    # One-shot: get full log as string
    my $text = $api->log('Pod', 'my-pod',
        namespace => 'default',
        tailLines => 100,
    );

    # Streaming: callback per log line
    $api->log('Pod', 'my-pod',
        namespace => 'default',
        follow    => 1,
        on_line   => sub {
            my ($event) = @_;  # Kubernetes::REST::LogEvent
            say $event->line;
        },
    );

Retrieve logs from a pod. Supports two modes:

B<One-shot> (without C<on_line>): Returns the full log text as a string.

B<Streaming> (with C<on_line>): Calls the callback for each log line with a L<Kubernetes::REST::LogEvent> object. Blocks until the stream ends (or the server closes the connection).

The streaming mode is designed for event-based systems like L<IO::Async> — see L<Net::Async::Kubernetes> for async integration.

=head2 port_forward

    my $session = $api->port_forward('Pod', 'my-pod',
        namespace => 'default',
        ports     => [8080, 8443],
        on_frame  => sub { my ($channel, $payload) = @_; ... },
    );

Start a full-duplex pod port-forward session.

This method requires an IO backend that implements C<call_duplex>. The default
L<Kubernetes::REST::LWPIO> and L<Kubernetes::REST::HTTPTinyIO> backends do not
currently provide duplex transport.

Returns whatever the IO backend returns for C<call_duplex> (typically a
session/handle object managed by that backend).

=head2 exec

    my $session = $api->exec('Pod', 'my-pod',
        namespace => 'default',
        command   => ['sh', '-c', 'echo hello'],
        stdin     => 0,
        stdout    => 1,
        stderr    => 1,
        tty       => 0,
        on_frame  => sub { my ($channel, $payload) = @_; ... },
    );

Start a full-duplex pod exec session via the C</exec> subresource.

This method requires an IO backend that implements C<call_duplex>. The default
L<Kubernetes::REST::LWPIO> and L<Kubernetes::REST::HTTPTinyIO> backends do not
currently provide duplex transport.

Returns whatever the IO backend returns for C<call_duplex> (typically a
session/handle object managed by that backend).

=head2 attach

    my $session = $api->attach('Pod', 'my-pod',
        namespace => 'default',
        container => 'app',
        stdin     => 1,
        stdout    => 1,
        stderr    => 1,
        tty       => 0,
        on_frame  => sub { my ($channel, $payload) = @_; ... },
    );

Start a full-duplex pod attach session via the C</attach> subresource.

This method requires an IO backend that implements C<call_duplex>. The default
L<Kubernetes::REST::LWPIO> and L<Kubernetes::REST::HTTPTinyIO> backends do not
currently provide duplex transport.

Returns whatever the IO backend returns for C<call_duplex> (typically a
session/handle object managed by that backend).

=head1 NAME

Kubernetes::REST - A Perl REST Client for the Kubernetes API

=head1 UPGRADING FROM 0.02

B<WARNING: Version 1.00 contains breaking changes!>

This version has been completely rewritten. Key changes that may affect your code:

=over 4

=item * B<New simplified API>

The old method-per-operation API (e.g., C<< $api->Core->ListNamespacedPod(...) >>)
has been replaced with a simple API: C<list>, C<get>, C<create>, C<update>,
C<patch>, C<delete>, C<ensure>, C<ensure_all>, C<ensure_only>, C<watch>,
C<log>, C<port_forward>, C<exec>, C<attach>.

=item * B<Old API still works but deprecated>

The old API is still available for backwards compatibility but will emit deprecation
warnings. Set C<$ENV{HIDE_KUBERNETES_REST_V0_API_WARNING}> to suppress warnings.

=item * B<Uses IO::K8s classes>

Results are now returned as typed L<IO::K8s> objects instead of raw hashrefs.
Lists are returned as L<IO::K8s::List> objects.

B<Note:> L<IO::K8s> has also been completely rewritten (Moose to Moo, updated
to Kubernetes v1.31 API). See L<IO::K8s/"UPGRADING FROM 0.04"> for details.

=item * B<Short resource names>

You can now use short names like C<'Pod'> instead of full class paths. The
C<resource_map> attribute controls this mapping.

=item * B<Dynamic resource map>

Use C<resource_map_from_cluster =E<gt> 1> to load the resource map from the
cluster's OpenAPI spec, ensuring compatibility with any Kubernetes version.

=back

=head1 ATTRIBUTES

=head2 server

Required. Connection details for the Kubernetes API server. Can be a hashref or
a L<Kubernetes::REST::Server> object.

    server => { endpoint => 'https://kubernetes.local:6443' }

=head2 credentials

Required. Authentication credentials. Can be a hashref or a L<Kubernetes::REST::AuthToken>
object.

    credentials => { token => $bearer_token }

=head2 io

Optional. HTTP backend for making requests. Must consume the
L<Kubernetes::REST::Role::IO> role (i.e. implement C<call($req)> and
C<call_streaming($req, $callback)>; optional C<call_duplex($req, %callbacks)> for
full-duplex subresources such as pod port-forward). Defaults to L<Kubernetes::REST::LWPIO>
(L<LWP::UserAgent>), which supports L<LWP::ConsoleLogger> for HTTP debugging.

To use the lighter L<HTTP::Tiny> backend instead:

    use Kubernetes::REST::HTTPTinyIO;
    my $api = Kubernetes::REST->new(
        server      => ...,
        credentials => ...,
        io          => Kubernetes::REST::HTTPTinyIO->new(
            ssl_verify_server => 1,
        ),
    );

To use an async event loop, provide your own IO backend:

    my $api = Kubernetes::REST->new(
        server      => ...,
        credentials => ...,
        io          => My::AsyncIO->new(loop => $loop),
    );

=head2 k8s

Optional. L<IO::K8s> instance configured with the same resource map as this client.
Automatically created when needed.

=head2 resource_map_from_cluster

Optional boolean. If true, loads the resource map dynamically from the cluster's
OpenAPI spec. Defaults to true (loads from cluster).

    resource_map_from_cluster => 1

=head2 resource_map

Optional hashref. Maps short resource names to IO::K8s class paths. By default
loads dynamically from the cluster (if C<resource_map_from_cluster> is true) or
uses L<IO::K8s> built-in map. Can be overridden for custom resources.

    resource_map => { MyResource => 'Custom::V1::MyResource' }

=head2 cluster_version

Read-only. The Kubernetes cluster version string (e.g., "v1.31.0"). Fetched
automatically from the /version endpoint when first accessed.

=head1 METHODS

=head2 new_object($class, \%attrs) or new_object($class, %attrs)

Create a new IO::K8s object. Accepts short class names (e.g., 'Pod', 'Namespace')
and either a hashref or a hash of attributes.

    # With hashref
    my $ns = $api->new_object(Namespace => { metadata => { name => 'foo' } });

    # With hash
    my $ns = $api->new_object(Namespace => metadata => { name => 'foo' });

=head2 list($class, %args)

List resources. Returns an L<IO::K8s::List>.

    my $pods = $api->list('Pod', namespace => 'default');

=head2 get($class, %args)

Get a single resource by name.

    my $pod = $api->get('Pod', name => 'my-pod', namespace => 'default');

=head2 create($object)

Create a resource from an IO::K8s object.

    my $created = $api->create($pod);

=head2 update($object)

Update an existing resource.

    my $updated = $api->update($pod);

=head2 patch($class_or_object, %args)

Partially update a resource. Unlike C<update()> which replaces the entire
object, C<patch()> only modifies the fields you specify.

    # Add a label (strategic merge patch - default)
    my $patched = $api->patch('Pod', 'my-pod',
        namespace => 'default',
        patch     => { metadata => { labels => { env => 'staging' } } },
    );

    # Same thing with an object reference
    my $patched = $api->patch($pod,
        patch => { metadata => { labels => { env => 'staging' } } },
    );

    # Explicit patch type
    my $patched = $api->patch('Deployment', 'my-app',
        namespace => 'default',
        type      => 'merge',
        patch     => { spec => { replicas => 5 } },
    );

B<Required arguments:>

=over 4

=item patch

A hashref (or arrayref for JSON Patch) describing the changes to apply.

=item name

The resource name (when using class name, not object reference).

=back

B<Optional arguments:>

=over 4

=item type

The patch strategy. One of:

=over 4

=item C<strategic> (default)

Strategic Merge Patch. The Kubernetes-native patch type that understands
array merge semantics (e.g., adding a container to a pod spec without
removing existing containers).

=item C<merge>

JSON Merge Patch (RFC 7396). Simple recursive merge where C<null> values
delete keys. Arrays are replaced entirely.

=item C<json>

JSON Patch (RFC 6902). An array of operations:

    patch => [
        { op => 'replace', path => '/spec/replicas', value => 3 },
        { op => 'add', path => '/metadata/labels/env', value => 'prod' },
    ]

=back

=item namespace

For namespaced resources, the namespace.

=back

Returns the full updated object from the server.

=head2 delete($class_or_object, %args)

Delete a resource.

    $api->delete($pod);
    $api->delete('Pod', name => 'my-pod', namespace => 'default');

=head2 watch($class, %args)

Watch for changes to resources. Uses the Kubernetes Watch API with chunked
transfer encoding to stream events. The call blocks until the server-side
timeout expires.

    my $last_rv = $api->watch('Pod',
        namespace       => 'default',
        on_event        => sub {
            my ($event) = @_;
            say $event->type;                    # ADDED, MODIFIED, DELETED
            say $event->object->metadata->name;  # inflated IO::K8s object
        },
        timeout         => 300,           # server-side timeout (default: 300)
        resourceVersion => '12345',       # resume from this version
        labelSelector   => 'app=web',     # optional label filter
        fieldSelector   => 'status.phase=Running',  # optional field filter
    );

    # $last_rv is the last resourceVersion seen - use it to resume watching

B<Required arguments:>

=over 4

=item on_event

Callback called for each watch event with a L<Kubernetes::REST::WatchEvent>
object.

=back

B<Optional arguments:>

=over 4

=item timeout

Server-side timeout in seconds (default: 300). The API server will close
the connection after this many seconds.

=item resourceVersion

Resume watching from a specific resource version. Use the return value from
a previous C<watch()> call to avoid missing events.

=item labelSelector

Filter by label selector (e.g., C<'app=web,env=prod'>).

=item fieldSelector

Filter by field selector (e.g., C<'status.phase=Running'>).

=item namespace

For namespaced resources, the namespace to watch.

=back

B<Resumable watch pattern:>

    my $rv;
    while (1) {
        $rv = eval {
            $api->watch('Pod',
                namespace       => 'default',
                resourceVersion => $rv,
                on_event        => \&handle_event,
            );
        };
        if ($@ && $@ =~ /410 Gone/) {
            # resourceVersion expired, re-list to get fresh version
            my $list = $api->list('Pod', namespace => 'default');
            $rv = undef;  # start fresh
        }
    }

Returns the last C<resourceVersion> seen. Croaks on 410 Gone with a
message to re-list.

=head2 log($class, $name, %args)

Retrieve logs from a pod. Two modes:

B<One-shot> (without C<on_line>): Returns the full log text as a string.

    my $text = $api->log('Pod', 'my-pod',
        namespace => 'default',
        tailLines => 100,
    );

B<Streaming> (with C<on_line>): Calls the callback for each log line with a
L<Kubernetes::REST::LogEvent> object. Blocks until the stream ends.

    $api->log('Pod', 'my-pod',
        namespace => 'default',
        follow    => 1,
        on_line   => sub {
            my ($event) = @_;
            say $event->line;
        },
    );

B<Optional arguments:>

=over 4

=item container - Container name (for multi-container pods)

=item follow - Stream logs (like C<kubectl logs -f>)

=item tailLines - Number of lines from the end to show

=item sinceSeconds - Logs from the last N seconds

=item sinceTime - Logs since RFC3339 timestamp

=item timestamps - Prepend timestamps to each line

=item previous - Logs from the previous container restart

=item limitBytes - Byte limit for the response

=back

=head2 port_forward($class, $name, %args)

Start a Kubernetes pod port-forward session via the C</portforward>
subresource.

    my $session = $api->port_forward('Pod', 'my-pod',
        namespace => 'default',
        ports     => [8080, 8443],
        on_frame  => sub { my ($channel, $payload) = @_; ... },
        on_close  => sub { ... },
        on_error  => sub { my ($err) = @_; ... },
    );

B<Required arguments:>

=over 4

=item name - Pod name

=item ports - Local/remote port list as arrayref or scalar (e.g. C<[8080, 8443]>)

=back

B<Optional arguments:>

=over 4

=item namespace - Namespace (for namespaced resources)

=item subprotocol - WebSocket subprotocol (default: C<v4.channel.k8s.io>)

=item on_open, on_frame, on_close, on_error - Duplex transport callbacks passed to IO backend

=back

Requires an IO backend implementing C<call_duplex>. The default sync backends
currently do not provide duplex transport.

=head2 exec($class, $name, %args)

Start a Kubernetes pod exec session via the C</exec> subresource.

    my $session = $api->exec('Pod', 'my-pod',
        namespace => 'default',
        command   => ['sh', '-c', 'echo hello'],
        on_frame  => sub { my ($channel, $payload) = @_; ... },
        on_close  => sub { ... },
        on_error  => sub { my ($err) = @_; ... },
    );

B<Required arguments:>

=over 4

=item name - Pod name

=item command - Command as arrayref or scalar (e.g. C<['sh', '-c', 'id']>)

=back

B<Optional arguments:>

=over 4

=item namespace - Namespace (for namespaced resources)

=item container - Container name (for multi-container pods)

=item stdin, stdout, stderr, tty - Stream toggles (defaults: stdin=false, stdout=true, stderr=true, tty=false)

=item subprotocol - WebSocket subprotocol (default: C<v4.channel.k8s.io>)

=item on_open, on_frame, on_close, on_error - Duplex transport callbacks passed to IO backend

=back

Requires an IO backend implementing C<call_duplex>. The default sync backends
currently do not provide duplex transport.

=head2 attach($class, $name, %args)

Start a Kubernetes pod attach session via the C</attach> subresource.

    my $session = $api->attach('Pod', 'my-pod',
        namespace => 'default',
        container => 'app',
        stdin     => 1,
        stdout    => 1,
        stderr    => 1,
        tty       => 0,
        on_frame  => sub { my ($channel, $payload) = @_; ... },
        on_close  => sub { ... },
        on_error  => sub { my ($err) = @_; ... },
    );

B<Required arguments:>

=over 4

=item name - Pod name

=back

B<Optional arguments:>

=over 4

=item namespace - Namespace (for namespaced resources)

=item container - Container name (for multi-container pods)

=item stdin, stdout, stderr, tty - Stream toggles (defaults: stdin=false, stdout=true, stderr=true, tty=false)

=item subprotocol - WebSocket subprotocol (default: C<v4.channel.k8s.io>)

=item on_open, on_frame, on_close, on_error - Duplex transport callbacks passed to IO backend

=back

Requires an IO backend implementing C<call_duplex>. The default sync backends
currently do not provide duplex transport.

=head2 fetch_resource_map()

Fetch the resource map from the cluster's OpenAPI spec (/openapi/v2 endpoint).
Returns a hashref mapping short resource names (e.g., "Pod") to full IO::K8s
class paths. This method is called automatically if C<resource_map_from_cluster>
is enabled.

=head1 BUILDING BLOCKS FOR ASYNC WRAPPERS

Async wrappers like L<Net::Async::Kubernetes> need access to the request/response
pipeline without going through the synchronous convenience methods. The following
public methods provide this:

=over 4

=item * C<expand_class($short)> - Resolve short name to full class

=item * C<build_path($class, %args)> - Build REST API URL path

=item * C<prepare_request($method, $path, %opts)> - Build HTTP request with auth

=item * C<check_response($response, $context)> - Validate HTTP status

=item * C<inflate_object($class, $response)> - JSON to typed object

=item * C<inflate_list($class, $response)> - JSON to typed list

=item * C<process_watch_chunk($class, \$buf, $chunk)> - Parse NDJSON watch stream

=item * C<process_log_chunk(\$buf, $chunk)> - Parse plain-text log stream

=back

Example async integration:

    # Build request using Kubernetes::REST
    my $class = $rest->expand_class('Pod');
    my $path = $rest->build_path($class, name => $name, namespace => $ns) . '/log';
    my $req = $rest->prepare_request('GET', $path, parameters => { follow => 'true' });

    # Execute through your own event loop
    my $buffer = '';
    $async_http->request($req->url, sub {
        my ($chunk) = @_;
        for my $event ($rest->process_log_chunk(\$buffer, $chunk)) {
            $on_line->($event);
        }
    });

=head1 PLUGGABLE IO ARCHITECTURE

The HTTP transport is decoupled from request preparation and response
processing. This makes it possible to swap the default L<LWP::UserAgent>
backend for L<HTTP::Tiny> or an async backend (e.g. L<Net::Async::HTTP>)
without changing any API logic.

The pipeline for each API call:

    1. prepare_request()    - builds HTTPRequest (method, url, headers, body)
    2. io->call()           - executes request (pluggable backend)
    3. check_response()     - validates HTTP status
    4. inflate_object/list  - decodes JSON + inflates IO::K8s objects

For watch, step 2 uses C<io-E<gt>call_streaming()> and step 4 uses
C<process_watch_chunk()> which parses NDJSON and inflates each event.

For log, step 2 uses C<io-E<gt>call_streaming()> and step 4 uses
C<process_log_chunk()> which parses plain-text lines into L<Kubernetes::REST::LogEvent> objects.

To implement a custom IO backend, consume L<Kubernetes::REST::Role::IO>
and implement C<call($req)> and C<call_streaming($req, $callback)>.
See L<Kubernetes::REST::LWPIO> and L<Kubernetes::REST::HTTPTinyIO> for
reference implementations.

=head1 SEE ALSO

=head2 Related Modules

=over

=item * L<IO::K8s> - Kubernetes resource classes (required dependency)

=item * L<Net::Async::Kubernetes> - Async Kubernetes client for L<IO::Async>

=back

=head2 Configuration and Authentication

=over

=item * L<Kubernetes::REST::Kubeconfig> - Load settings from kubeconfig

=item * L<Kubernetes::REST::Server> - Server connection configuration

=item * L<Kubernetes::REST::AuthToken> - Authentication credentials

=back

=head2 HTTP Backends

=over

=item * L<Kubernetes::REST::Role::IO> - IO interface role

=item * L<Kubernetes::REST::LWPIO> - LWP::UserAgent backend (default)

=item * L<Kubernetes::REST::HTTPTinyIO> - HTTP::Tiny backend

=item * L<LWP::ConsoleLogger> - HTTP debugging for LWPIO

=back

=head2 Data Objects

=over

=item * L<Kubernetes::REST::WatchEvent> - Watch event object

=item * L<Kubernetes::REST::LogEvent> - Log event object

=item * L<Kubernetes::REST::HTTPRequest> - HTTP request object

=item * L<Kubernetes::REST::HTTPResponse> - HTTP response object

=back

=head2 CLI Tools

=over

=item * L<Kubernetes::REST::CLI> - CLI base class

=item * L<Kubernetes::REST::CLI::Watch> - kube_watch CLI tool

=item * L<Kubernetes::REST::CLI::Role::Connection> - Shared CLI options

=back

=head2 Examples and Documentation

=over

=item * L<Kubernetes::REST::Example> - Comprehensive examples with Minikube/K3s

=item * L<https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.31/> - Kubernetes API reference

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/kubernetes-rest/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
