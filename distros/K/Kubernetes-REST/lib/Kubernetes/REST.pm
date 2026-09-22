package Kubernetes::REST;
our $VERSION = '1.108';
# ABSTRACT: A Perl REST Client for the Kubernetes API
use Moo;
use Carp qw(croak carp);
use Scalar::Util qw(blessed);
use Module::Runtime qw(require_module);
use JSON::MaybeXS ();
use Encode ();
use Kubernetes::REST::Server;
use Kubernetes::REST::AuthToken;
use Kubernetes::REST::LWPIO;
use Kubernetes::REST::HTTPRequest;
use IO::K8s;
use IO::K8s::List;
use IO::K8s::CRD;
use IO::K8s::Unstructured ();
use Time::HiRes ();
use Kubernetes::REST::WatchEvent;
use Kubernetes::REST::LogEvent;
use namespace::clean;

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


# utf8 => 1 makes encode() return UTF-8 bytes and decode() expect them, which is
# what HTTP::Request->content requires and what IO::K8s already assumes. See the
# ENCODING section below.
has _json => (
    is => 'ro',
    default => sub {
        JSON::MaybeXS->new(utf8 => 1, canonical => 1, convert_blessed => 1);
    },
);

# External IO::K8s resource-map providers, mirrored onto the inner instance.
has with => (
    is => 'ro',
    default => sub { [] },
);


# IO::K8s instance - configured with same resource_map
has k8s => (
    is => 'ro',
    lazy => 1,
    predicate => '_has_k8s',
    clearer => '_clear_k8s',
    default => sub {
        my $self = shift;
        return IO::K8s->new(
            resource_map => $self->resource_map,
            with         => [ @{ $self->with } ],
            # openapi_spec is an eager hashref on IO::K8s: handing it over here
            # only once it has actually been fetched keeps constructing/using
            # the inner instance from forcing the /openapi/v2 download (D12).
            # Until then it is absent; _openapi_spec's builder rebuilds this
            # instance once the spec exists.
            ($self->_has_openapi_spec ? (openapi_spec => $self->_openapi_spec) : ()),
        );
    },
    handles => [qw(
        new_object
        inflate
        json_to_object
        struct_to_object
        object_to_json
        object_to_struct
        load
        load_yaml
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
# The predicate is true once the map exists: passed in by the caller, or
# built (fetched) on first use. expand_class() keys its cheap path off it.
has resource_map => (
    is => 'ro',
    lazy => 1,
    predicate => '_has_resource_map',
    clearer => '_clear_resource_map',
    default => sub {
        my $self = shift;
        # A private copy, never IO::K8s's shared global map: the inner IO::K8s
        # is handed this hashref and merges any `with` providers into it with
        # add(), which mutates it in place. Returning the global ref would leak
        # provider Kinds into IO::K8s->default_resource_map process-wide.
        return { %{ IO::K8s->default_resource_map } } unless $self->resource_map_from_cluster;
        return $self->_load_resource_map_from_cluster;
    },
);


# Deliberately NOT delegated to the k8s attribute like the other IO::K8s
# methods: building that instance forces the lazy resource_map, which on the
# default resource_map_from_cluster => 1 is a full GET /openapi/v2 - paid for
# resolving a name like 'Pod' whose answer already sits in the built-in map
# (karr #15).
sub expand_class {
    my ($self, @args) = @_;


    if ($self->resource_map_from_cluster && !$self->_has_resource_map
        && defined $args[0] && !ref $args[0]) {
        # '+Full::Class::Name' names an exact class - no map consulted either
        # way, and by contract it is returned without being loaded.
        return substr($args[0], 1) if $args[0] =~ /^\+/;
        # As a class method, IO::K8s->expand_class resolves against the
        # built-in map. Its fallback for an unknown Kind is the *name*
        # 'IO::K8s::<Kind>' whether or not such a class exists, so a cheap
        # answer only counts when it names a class that actually loads.
        # Anything else falls through to the cluster-backed instance below,
        # which fetches the cluster map exactly as it always did.
        my $class = IO::K8s->expand_class(@args);
        return $class if defined $class
            && ($class->can('new') || eval { require_module($class); 1 });
    }

    # Fall through to the cluster-backed inner IO::K8s, which owns the
    # resolution order (design D13, extending the 2026-08-10 exact-GVK
    # contract):
    #   rung 1  an explicit '+Full::Class' in the caller's resource_map
    #   rung 2  provider classes merged from `with`
    #   rung 3  AutoGen from openapi_spec, once the spec has been fetched
    #   rung 5  the existing fail-closed GVK error
    # The discovery-built map (see _resource_map_from_catalog) no longer
    # short-circuits this order with invented IO::K8s::Api::<Group> names for
    # groups this distribution does not ship (D12): a foreign Kind with no
    # provider and no loaded spec now reaches rung 4/5 instead of resolving to
    # a bogus class.
    my $class = $self->k8s->expand_class(@args);

    # How IO::K8s signals "nothing resolved this Kind" depends on the argument
    # shape, and only that exact signal may be diverted to rung 4 -- every real
    # resolution (rungs 1-3: a '+Full::Class', a provider from `with`, a builtin
    # or an AutoGen class) must be returned untouched, including a '+'-class
    # that names a class not yet loaded (returned by contract without loading,
    # so a load probe would wrongly reject it -- karr t/36 subtest 3).
    #
    # For a bare Kind IO::K8s fails *open*: it fabricates the name
    # 'IO::K8s::<Kind>' whether or not such a class exists, and the fail-closed
    # error only surfaces later when require_module() cannot load it. For an
    # exact-GVK or domain-qualified request it fails *closed*, returning undef.
    # Both -- and nothing else -- mean unresolved.
    my ($kind, $api_version) = $self->_kind_from_expand_args(@args);
    my $unresolved =
        !defined $class
        || (defined $kind
            && $class eq "IO::K8s::$kind"
            && !($class->can('new') || eval { require_module($class); 1 }));

    return $class unless $unresolved && defined $kind;

    # Rung 4 (D16): the Kind resolved to nothing that ships. If the cluster
    # confirms this GVK through aggregated discovery, resolve to
    # IO::K8s::Unstructured -- its plural and scope come from the discovery
    # catalog at path-build time (_build_path), since Unstructured carries no
    # api_version()/resource_plural()/Namespaced role of its own. On by default
    # (no opt-in here, unlike bare IO::K8s): D16 gates it on discovery
    # confirmation instead. _discovery_path_meta is a no-op (undef) unless
    # resource_map_from_cluster is set, and by the time control reaches here the
    # catalog was already fetched building the cluster map, so this consults a
    # cache and never adds a round-trip. A Kind discovery does not serve stays
    # fail-closed (rung 5): the fabricated name (or undef) is returned so the
    # load error still names the Kind. A discovery *failure* (cluster
    # unreachable, expired token) is deliberately treated the same as "not
    # served" here -- rung 5, fail-closed -- with the reason kept in
    # _discovery_error; on the CRUD path the carp from
    # _load_resource_map_from_cluster has already named it while building the
    # cluster map.
    return 'IO::K8s::Unstructured'
        if $self->_discovery_path_meta($kind, $api_version);

    return $class;
}

# Extract the Kubernetes Kind (and any explicitly supplied apiVersion) from an
# expand_class() argument list, for the D16 rung-4 discovery-confirmation
# check. Only bare short names ('Widget') and domain-qualified strings
# ('example.com/v1/Widget') name a Kind that Unstructured should stand in for;
# a '+Full::Class', an 'IO::K8s::...' name or any multi-segment package name is
# an explicit class request and must never be diverted to Unstructured.
sub _kind_from_expand_args {
    my ($self, $name, $api_version) = @_;
    return () unless defined $name && !ref $name;
    return () if $name =~ /^\+/;
    return () if $name =~ /^IO::K8s::/;
    if ($name =~ m{/}) {   # 'group/version/Kind' -> ('Kind', 'group/version')
        my ($av, $kind) = $name =~ m{\A(.*)/([^/]+)\z};
        return ($kind, $av);
    }
    return () if $name =~ /::/;   # a multi-segment class name, not a Kind
    return ($name, $api_version);
}

# Path metadata (apiVersion, resource plural, namespaced) for a Kind, read from
# the cached discovery catalog. This is how a Kind resolved to
# IO::K8s::Unstructured (D16 rung 4) gets what _build_path needs: Unstructured
# has apiVersion/kind on the *instance* but no api_version()/resource_plural()
# class method and no Namespaced role, so plural and scope cannot come from the
# class the way a typed resource's do -- they come from here.
#
# Returns undef (fail-closed) unless resource_map_from_cluster is set: with no
# cluster there is no discovery to confirm a GVK, and this must never trigger a
# fetch on the fetch-free path. When it does run, the catalog is already cached
# (building the cluster resource map fetched it), so the lookup is free.
#
# A fetch that fails outright (cluster unreachable, expired token) returns the
# same undef as a healthy catalog that lacks the Kind -- deliberately
# fail-closed (D16: an unreachable cluster must not let anything pass as
# confirmed) -- but the reason is kept in _discovery_error so _build_path can
# name it instead of claiming a missing entry.
#
# $want_api_version, when given (an Unstructured object's own apiVersion),
# pins the group/version; otherwise the group's discovery-preferred version
# wins, matching _resource_map_from_catalog and D17.
sub _discovery_path_meta {
    my ($self, $kind, $want_api_version) = @_;
    return unless $self->resource_map_from_cluster;
    my $catalog = eval { $self->_discovery };
    if (my $error = $@) {
        $self->_discovery_error($error);
        return;
    }
    $self->_clear_discovery_error;
    return unless $catalog && $catalog->{groups};

    my $meta_for = sub {
        my ($group, $version, $res) = @_;
        return {
            api_version => ($group eq '' ? $version : "$group/$version"),
            resource    => $res->{resource},
            namespaced  => ($res->{scope} && $res->{scope} eq 'Namespaced' ? 1 : 0),
        };
    };

    # An explicit apiVersion pins the exact group/version first.
    if (defined $want_api_version && length $want_api_version) {
        my ($g, $v) = $want_api_version =~ m{/}
            ? split(m{/}, $want_api_version, 2)
            : ('', $want_api_version);
        my $res = $catalog->{groups}{$g}{versions}{$v}{kinds}{$kind};
        return $meta_for->($g, $v, $res) if $res;
    }

    # Otherwise the preferred version of whichever group serves the Kind.
    for my $group (sort keys %{$catalog->{groups}}) {
        my $gdata = $catalog->{groups}{$group};
        my @order = @{$gdata->{version_order} // []};
        my $pref  = $gdata->{preferred};
        @order = ($pref, grep { $_ ne $pref } @order)
            if defined $pref && grep { $_ eq $pref } @order;
        for my $version (@order) {
            my $res = $gdata->{versions}{$version}{kinds}{$kind};
            return $meta_for->($group, $version, $res) if $res;
        }
    }
    return;
}

# The extra _build_path arguments an IO::K8s::Unstructured resolution needs,
# derived from whatever identifier expand_class was given: an IO::K8s object
# (its kind/apiVersion accessors) or a name string (the Kind is its last
# '/'-delimited segment). Empty for every typed class, so typed path building
# is completely unchanged.
sub _unstructured_hint {
    my ($self, $class, $ident) = @_;
    return () unless defined $class && $class eq 'IO::K8s::Unstructured';
    if (blessed($ident)) {
        return (
            kind => $ident->kind,
            (defined $ident->apiVersion ? (api_version => $ident->apiVersion) : ()),
        );
    }
    return (kind => (split m{/}, $ident)[-1]);
}

# Kubernetes groups whose IO::K8s classes do NOT live under IO::K8s::Api::.
# Their namespace follows the upstream Go staging repository the types are
# generated from (apiextensions-apiserver, kube-aggregator), not the API group
# name, so it cannot be derived - it has to be listed here.
#
# Keyed on the full group name, because that is the only globally unique
# identifier: a cluster is free to serve a CRD group called
# apiextensions.example.com, and that group is an ordinary one.
my %NON_API_NAMESPACE = (
    'apiextensions.k8s.io'   => 'ApiextensionsApiserver::Pkg::Apis::Apiextensions',
    'apiregistration.k8s.io' => 'KubeAggregator::Pkg::Apis::Apiregistration',
);

# The same table, indexed by the IO::K8s group directory instead - the trailing
# segment of each namespace above is exactly that directory name. Derived, so
# there is still only one place to add a group.
my %NON_API_NAMESPACE_BY_GROUP_PATH =
    map { ((split /::/)[-1] => $_) } values %NON_API_NAMESPACE;

# Namespace below IO::K8s:: for a Kubernetes API group name as the cluster's
# OpenAPI spec reports it: '' for core, 'apps', 'apiextensions.k8s.io',
# 'cert-manager.io', ... The exception table is matched exactly on the full
# name - a CRD group that merely starts with 'apiextensions' is an ordinary
# group and must keep landing under Api::.
sub _io_k8s_namespace_for_group {
    my ($self, $group) = @_;
    return $NON_API_NAMESPACE{$group} if exists $NON_API_NAMESPACE{$group};
    return 'Api::' . ($group eq '' ? 'Core' : ucfirst(lc((split /\./, $group)[0])));
}

# Namespace below IO::K8s:: for an IO::K8s group directory name - 'Core',
# 'Apps', 'Apiextensions'. That is the form the v0 compatibility layer carries,
# and it is a closed set of names this distribution ships, so unlike a group
# name off the wire it needs no exact-match guard.
sub _io_k8s_namespace_for_group_path {
    my ($self, $group_path) = @_;
    return $NON_API_NAMESPACE_BY_GROUP_PATH{$group_path} // "Api::${group_path}";
}

# Public method to build the resource map from the cluster's discovery catalog
sub fetch_resource_map {
    my ($self) = @_;


    # The cluster resource map is built from aggregated discovery, not from the
    # multi-MB /openapi/v2 spec (design D11): a small GET /api + GET /apis gives
    # every group, version, plural, Kind and scope. The catalog is cached in the
    # _discovery attribute and shared by later rebuilds; /openapi/v2 stays lazy
    # for schema_for/compare_schema only. The failure keeps this method's
    # documented wording; the underlying error rides along.
    my $catalog = eval { $self->_discovery };
    croak "Could not load resource map from cluster: $@" unless $catalog;

    return $self->_resource_map_from_catalog($catalog);
}

# Turn the cached discovery catalog into the short-name -> IO::K8s class map.
# The namespace comes from _io_k8s_namespace_for_group (exception tables
# included) and List kinds are skipped. Two rules shape which entries land:
#
#   D17 preferred version: among the versions a group serves a Kind in, the
#   version the cluster marks preferred wins the bare short name (not "stable
#   beats alpha/beta" -- that heuristic is gone). A Kind served only outside
#   the preferred version still maps, to its first served version, so nothing
#   the cluster serves is dropped.
#
#   D12/D13 stop inventing: an entry is recorded only when the candidate
#   IO::K8s class actually ships. A foreign group (cilium.io, cert-manager.io)
#   has no IO::K8s::Api::<Group> class, so its Kinds are omitted here and left
#   to resolve through the inner IO::K8s pipeline (provider from `with` ->
#   AutoGen from openapi_spec -> D16 Unstructured -> fail-closed) rather than
#   short-circuiting to a bogus name. Core-API groups and the two exception
#   groups (apiextensions/apiregistration) do ship, so their Kinds map exactly
#   as before.
sub _resource_map_from_catalog {
    my ($self, $catalog) = @_;

    my %map;
    for my $group (keys %{$catalog->{groups} // {}}) {
        my $gdata = $catalog->{groups}{$group};

        # D17: try the cluster's preferred version first, then the rest in
        # discovery order; the first version to yield a shipping class for a
        # Kind keeps the short name. Where the preferred version's class does
        # not ship but another served version's does, the Kind still maps to
        # that other version rather than vanishing.
        my @order = @{$gdata->{version_order} // []};
        my $pref  = $gdata->{preferred};
        @order = ($pref, grep { $_ ne $pref } @order)
            if defined $pref && grep { $_ eq $pref } @order;

        for my $version (@order) {
            my $kinds = $gdata->{versions}{$version}{kinds};
            for my $kind (keys %$kinds) {
                next if $kind =~ /List$/;
                next if exists $map{$kind};   # a preferred/earlier version won it

                my $version_path = ucfirst($version);
                my $new_path = $self->_io_k8s_namespace_for_group($group)
                    . "::${version_path}::${kind}";

                # D12/D13: only record a class name this distribution ships.
                next unless $self->_io_k8s_class_ships($new_path);

                $map{$kind} = $new_path;
            }
        }
    }

    return \%map;
}

# Process-wide cache for the D12/D13 "stop inventing" loadability probe: a
# relative class path is either shipped (a real IO::K8s class that loads) or it
# is not, and that never changes within a run. Keyed by the relative path, so
# it is shared across instances.
my %_CLASS_SHIPS;

# True when 'IO::K8s::<rel_path>' is a real, loadable class. The discovery map
# is built from group/version/Kind triples off the wire; without this probe
# every foreign CRD group would map to an IO::K8s::Api::<Group>::... name that
# has no class behind it (design D12). require the candidate once -- already
# loaded classes short-circuit on ->can('new') -- and remember the answer.
sub _io_k8s_class_ships {
    my ($self, $rel_path) = @_;
    return $_CLASS_SHIPS{$rel_path} //= do {
        my $full = "IO::K8s::$rel_path";
        ($full->can('new') || eval { require_module($full); 1 }) ? 1 : 0;
    };
}

# Per-instance discovery catalog, keyed by group. Shape:
#   { groups => { <group> => {
#       preferred     => <version>,            # first version the cluster serves
#       version_order => [ <version>, ... ],   # discovery order, preferred first
#       versions      => { <version> => { kinds => {
#           <Kind> => { resource => <plural>, scope => 'Namespaced'|'Cluster' },
#       } } },
#   } } }
# Built lazily on first use and invalidated by invalidate_discovery.
has _discovery => (
    is => 'lazy',
    predicate => '_has_discovery',
    clearer => '_clear_discovery',
    builder => sub { $_[0]->_fetch_discovery },
);

# The reason ($@ text) the last discovery fetch attempted from
# _discovery_path_meta failed, kept so the croak in _build_path can name it: a
# failed fetch and a healthy catalog without the Kind both come back from
# _discovery_path_meta as undef (fail-closed, D16), and only this tells them
# apart. Cleared by the next successful fetch and by invalidate_discovery.
has _discovery_error => (
    is => 'rw',
    clearer => '_clear_discovery_error',
);

# Aggregated discovery v2 (Kubernetes >= 1.27): GET /api and GET /apis with an
# Accept header selecting APIGroupDiscoveryList answer every group, version,
# resource plural, Kind and scope in one small response each. A server that does
# not understand the header ignores the as= parameter and returns the legacy
# document (APIVersions / APIGroupList) - detected by the kind - and the
# per-group APIResourceList fallback fills the catalog instead.
my $DISCOVERY_ACCEPT =
    'application/json;g=apidiscovery.k8s.io;v=v2;as=APIGroupDiscoveryList';

sub _fetch_discovery {
    my ($self) = @_;

    my $catalog = { groups => {} };

    for my $root ('/api', '/apis') {
        my $response = $self->_request('GET', $root, undef,
            headers => { Accept => $DISCOVERY_ACCEPT });
        croak "discovery GET $root failed: " . $response->status
            if $response->status >= 400;

        my $body = $self->_json->decode($response->content);
        my $kind = ref $body eq 'HASH' ? ($body->{kind} // '') : '';

        if ($kind eq 'APIGroupDiscoveryList') {
            $self->_absorb_discovery_list($catalog, $body);
        } elsif ($root eq '/api') {
            $self->_fetch_discovery_legacy_core($catalog, $body);
        } else {
            $self->_fetch_discovery_legacy_groups($catalog, $body);
        }
    }

    return $catalog;
}

# APIGroupDiscoveryList (aggregated discovery v2). Each item is one group; the
# order of its versions is the cluster's preference, so the first is preferred.
sub _absorb_discovery_list {
    my ($self, $catalog, $body) = @_;

    for my $group_item (@{$body->{items} // []}) {
        my $group = $group_item->{metadata}{name} // '';
        my @versions = @{$group_item->{versions} // []};
        for my $i (0 .. $#versions) {
            my $vd = $versions[$i];
            my $version = $vd->{version};
            next unless defined $version && length $version;
            for my $res (@{$vd->{resources} // []}) {
                my $plural = $res->{resource};
                my $rkind  = $res->{responseKind}{kind};
                next unless defined $plural && defined $rkind;
                $self->_catalog_add($catalog, $group, $version, $rkind,
                    $plural, $res->{scope} // '');
            }
            # First version served = preferred version for the group.
            $catalog->{groups}{$group}{preferred} = $version
                if $i == 0 && exists $catalog->{groups}{$group};
        }
    }
}

# Legacy fallback for GET /api: an APIVersions document. Each version's
# APIResourceList is fetched from /api/<version>.
sub _fetch_discovery_legacy_core {
    my ($self, $catalog, $body) = @_;

    my @versions = @{$body->{versions} // []};
    for my $version (@versions) {
        my $response = $self->_request('GET', "/api/$version");
        next if $response->status >= 400;
        my $list = $self->_json->decode($response->content);
        $self->_absorb_api_resource_list($catalog, '', $version, $list);
    }
    $catalog->{groups}{''}{preferred} = $versions[0]
        if @versions && exists $catalog->{groups}{''};
}

# Legacy fallback for GET /apis: an APIGroupList document. Each group/version's
# APIResourceList is fetched from /apis/<group>/<version>.
sub _fetch_discovery_legacy_groups {
    my ($self, $catalog, $body) = @_;

    for my $group (@{$body->{groups} // []}) {
        my $gname = $group->{name};
        next unless defined $gname && length $gname;
        for my $v (@{$group->{versions} // []}) {
            my $version = $v->{version};
            next unless defined $version && length $version;
            my $response = $self->_request('GET', "/apis/$gname/$version");
            next if $response->status >= 400;
            my $list = $self->_json->decode($response->content);
            $self->_absorb_api_resource_list($catalog, $gname, $version, $list);
        }
        my $pref = $group->{preferredVersion}{version};
        $catalog->{groups}{$gname}{preferred} = $pref
            if defined $pref && exists $catalog->{groups}{$gname};
    }
}

# APIResourceList (legacy per-group discovery). Subresource entries carry a
# slash in their name (pods/status) and are skipped; scope comes from the
# namespaced boolean.
sub _absorb_api_resource_list {
    my ($self, $catalog, $group, $version, $list) = @_;

    for my $res (@{$list->{resources} // []}) {
        my $name = $res->{name};
        next unless defined $name && length $name;
        next if $name =~ m{/};
        my $kind = $res->{kind};
        next unless defined $kind;
        my $scope = $res->{namespaced} ? 'Namespaced' : 'Cluster';
        $self->_catalog_add($catalog, $group, $version, $kind, $name, $scope);
    }
}

# Register one Kind (plural, scope) under a group/version in the catalog,
# tracking version discovery order.
sub _catalog_add {
    my ($self, $catalog, $group, $version, $kind, $plural, $scope) = @_;

    my $gdata = $catalog->{groups}{$group} ||= {
        preferred => undef, version_order => [], versions => {},
    };
    unless (exists $gdata->{versions}{$version}) {
        $gdata->{versions}{$version} = { kinds => {} };
        push @{$gdata->{version_order}}, $version;
    }
    $gdata->{versions}{$version}{kinds}{$kind} = {
        resource => $plural,
        scope    => $scope,
    };
}

sub invalidate_discovery {
    my ($self) = @_;


    $self->_clear_discovery;
    $self->_clear_discovery_error;
    $self->_clear_resource_map if $self->_has_resource_map;
    # The inner IO::K8s captured the old map at build time; drop it too so it is
    # rebuilt from the refreshed map on next use.
    $self->_clear_k8s if $self->_has_k8s;
    return 1;
}

# Fetch full OpenAPI spec from cluster (cached). Kept lazy on purpose: the
# only /openapi/v2 download in the client, paid for by schema_for/compare_schema
# and (once resolution needs it) AutoGen, never by construction.
has _openapi_spec => (
    is => 'lazy',
    predicate => '_has_openapi_spec',
    builder => sub {
        my $self = shift;
        my $response = $self->_request('GET', '/openapi/v2');
        croak "Could not fetch OpenAPI spec: " . $response->status if $response->status >= 400;
        my $spec = $self->_json->decode($response->content);
        # D12: the inner IO::K8s was built without a spec (so building it never
        # forced this fetch). Now that the spec exists, drop the cached instance
        # so its next build passes it through as openapi_spec for AutoGen -- the
        # same rebuild-on-next-use pattern invalidate_discovery uses. The clear
        # only marks it for rebuild; nothing here re-reads k8s, so the rebuild
        # happens after Moo has stored this spec, not during the builder.
        $self->_clear_k8s if $self->_has_k8s;
        return $spec;
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
# Returns comparison result from IO::K8s::Role::Resource->compare_to_schema
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
        carp "Falling back to the built-in resource map: $@";
        return IO::K8s->default_resource_map;
    }
    return $map;
}

# V0 API compatibility - returns group wrapper objects
#
# Called as a plain function, not a method: each accessor below shares its name
# with the group module it wraps, so once this package is loaded Perl resolves
# a bareword like Kubernetes::REST::Core->new(...) against the sub instead of
# the class and calls it as Kubernetes::REST::Core()->new(...) - with no
# invocant. Returning the class name in that case puts the ->new(...) back on
# the class the caller was aiming at.
sub _v0_group {
    my ($group, $self) = @_;
    my $class = "Kubernetes::REST::$group";
    require_module($class);
    return $class unless defined $self;
    return $class->new(api => $self);
}

sub Core { _v0_group('Core', @_) }
sub Apps { _v0_group('Apps', @_) }
sub Batch { _v0_group('Batch', @_) }
sub Networking { _v0_group('Networking', @_) }
sub Storage { _v0_group('Storage', @_) }
sub Policy { _v0_group('Policy', @_) }
sub Autoscaling { _v0_group('Autoscaling', @_) }
sub RbacAuthorization { _v0_group('RbacAuthorization', @_) }
sub Certificates { _v0_group('Certificates', @_) }
sub Coordination { _v0_group('Coordination', @_) }
sub Events { _v0_group('Events', @_) }
sub Scheduling { _v0_group('Scheduling', @_) }
sub Authentication { _v0_group('Authentication', @_) }
sub Authorization { _v0_group('Authorization', @_) }
sub Admissionregistration { _v0_group('Admissionregistration', @_) }
sub Apiextensions { _v0_group('Apiextensions', @_) }
sub Apiregistration { _v0_group('Apiregistration', @_) }

# Build URL path from class metadata
sub _build_path {
    my ($self, $class, %args) = @_;

    require_module($class);

    # An Unstructured resolution (D16 rung 4) carries no api_version()/
    # resource_plural()/Namespaced role -- its Kind is data on the instance,
    # not a class identity -- so the path metadata comes from the discovery
    # catalog instead of the class. The caller (a CRUD method, or a seam
    # consumer) passes the Kind (and an object's own apiVersion) via
    # _unstructured_hint; api_version/resource/namespaced overrides are honoured
    # directly when given, which keeps build_path usable by async wrappers.
    my ($api_version, $resource, $is_namespaced);
    my ($kind_hint, $av_hint) = (delete $args{kind}, delete $args{api_version});
    my $override_resource   = delete $args{resource};
    my $override_namespaced = delete $args{namespaced};
    if ($class eq 'IO::K8s::Unstructured') {
        if (defined $override_resource && defined $override_namespaced
            && defined $av_hint) {
            ($api_version, $resource, $is_namespaced) =
                ($av_hint, $override_resource, $override_namespaced);
        } else {
            defined $kind_hint
                or croak "IO::K8s::Unstructured needs a Kind to build a path"
                    . " (pass kind => 'Kind')";
            my $meta = $self->_discovery_path_meta($kind_hint, $av_hint);
            unless ($meta) {
                # A failed fetch and a catalog without the Kind both come back
                # undef (fail-closed, see _discovery_path_meta); only the
                # recorded reason tells them apart, and a catalog that was
                # never read must not be reported as one lacking an entry.
                my $reason = $self->_discovery_error;
                croak defined $reason
                    ? "discovery failed, so Kind '$kind_hint' is unconfirmed"
                        . " - cannot build a path for IO::K8s::Unstructured:"
                        . " $reason"
                    : "no discovery entry for Kind '$kind_hint' - cannot"
                        . " build a path for IO::K8s::Unstructured";
            }
            ($api_version, $resource, $is_namespaced) =
                @{$meta}{qw(api_version resource namespaced)};
        }
    } else {
        # Get metadata from class
        $api_version = $class->can('api_version') ? $class->api_version : undef;
        croak "Cannot determine api_version for $class - override api_version() in your CRD class"
            unless defined $api_version;
        my $kind = $class->can('kind') ? $class->kind : (split('::', $class))[-1];
        $is_namespaced = $class->does('IO::K8s::Role::Namespaced');

        # Use explicit resource_plural if available, otherwise auto-pluralize
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

    # Subresource suffix: /status, /log, /exec, /attach, /portforward.
    # Every subresource addresses one named resource - without a name the
    # suffix would silently land on the collection endpoint instead.
    if (defined $args{subresource} && length $args{subresource}) {
        croak "subresource '$args{subresource}' requires a name for $class"
            unless $args{name};
        $path .= "/$args{subresource}";
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
        # Response bodies are bytes; the error message is read by humans, so
        # decode it (leniently - a truncated or non-UTF-8 body must not turn a
        # useful API error into an encoding croak).
        my $body = Encode::decode('UTF-8', $response->content // '', Encode::FB_DEFAULT);
        croak "Kubernetes API error ($context): "
            . $response->status . " " . $body;
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
    my $items = $struct->{items} // [];
    my (@objects, @dropped);
    for my $i (0 .. $#$items) {
        my $item = $items->[$i];
        my $obj = eval { $self->k8s->struct_to_object($class, $item) };
        if (defined $obj) {
            push @objects, $obj;
            next;
        }
        # An item the object model rejects must not disappear without a
        # trace: the caller would read a cluster with N unreadable Pods as a
        # cluster with N fewer Pods (karr #16). Say which items were dropped
        # and why - typically the installed IO::K8s not knowing a field the
        # cluster version serves.
        my $err = $@ || 'inflated to undef';
        $err =~ s/\s+\z//;
        my $name = ref $item eq 'HASH' && ref $item->{metadata} eq 'HASH'
            ? $item->{metadata}{name}
            : undef;
        push @dropped,
            "item $i" . (defined $name ? " (name '$name')" : '') . ": $err";
    }
    if (@dropped) {
        carp sprintf
            "inflate_list: dropped %d of %d %s items - the returned list is"
            . " INCOMPLETE (often IO::K8s version drift against the cluster):\n  %s",
            scalar @dropped, scalar @$items, $class, join("\n  ", @dropped);
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
    my $path = $self->_build_path($class, %args,
        $self->_unstructured_hint($class, $short_class));

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

    my $path = $self->_build_path($class, %args,
        $self->_unstructured_hint($class, $short_class));
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

    my $path = $self->_build_path($class, namespace => $namespace,
        $self->_unstructured_hint($class, $object));
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

    my $path = $self->_build_path($class, name => $name, namespace => $namespace,
        $self->_unstructured_hint($class, $object));
    my $response = $self->_request('PUT', $path, $object->TO_JSON);
    $self->_check_response($response, "update " . ref($object));

    return $self->_inflate_object($class, $response);
}

my %PATCH_TYPES = (
    strategic => 'application/strategic-merge-patch+json',
    merge     => 'application/merge-patch+json',
    json      => 'application/json-patch+json',
);

# Shared argument unpacking for patch() and patch_status(): accepts either a
# blessed object or a class plus name, in both the shorthand
# (patch('Pod', 'name', ...)) and the fully keyed (patch('Pod', name => ...))
# call form. $label only appears in croak messages, $default_type is the patch
# strategy used when the caller does not pass one.
sub _unpack_patch_args {
    my ($self, $label, $default_type, $class_or_object, @rest) = @_;

    my ($class, $name, $namespace, $patch, $patch_type);

    if (ref($class_or_object) && blessed($class_or_object)) {
        # Object passed: patch($object, patch => {...})
        my $object = $class_or_object;
        $class = ref($object);
        my $metadata = $object->metadata or croak "object must have metadata";
        $name = $metadata->name or croak "object must have metadata.name";
        $namespace = $metadata->namespace;
        my %args = @rest;
        $patch = $args{patch} // croak "$label requires 'patch' parameter";
        $patch_type = $args{type} // $default_type;
    } else {
        # Class + name: patch('Pod', 'name', namespace => 'ns', patch => {...})
        my %args;
        if (@rest >= 1 && !ref($rest[0]) && $rest[0] !~ /^(name|namespace|patch|type)$/) {
            $args{name} = shift @rest;
            %args = (%args, @rest);
        } elsif (@rest % 2 == 0) {
            %args = @rest;
        } else {
            croak "Invalid arguments to $label()";
        }

        $class = $self->expand_class($class_or_object);
        $name = $args{name} or croak "name required for $label";
        $namespace = $args{namespace};
        $patch = $args{patch} // croak "$label requires 'patch' parameter";
        $patch_type = $args{type} // $default_type;
    }

    my $content_type = $PATCH_TYPES{$patch_type}
        // croak "Unknown patch type '$patch_type' (use: strategic, merge, json)";

    return ($class, $name, $namespace, $patch, $content_type);
}

sub patch {
    my ($self, $class_or_object, @rest) = @_;


    my ($class, $name, $namespace, $patch, $content_type)
        = $self->_unpack_patch_args('patch', 'strategic', $class_or_object, @rest);

    my $path = $self->_build_path($class, name => $name, namespace => $namespace,
        $self->_unstructured_hint($class, $class_or_object));
    my $response = $self->_request('PATCH', $path, $patch,
        content_type => $content_type);
    $self->_check_response($response, "patch $class");

    return $self->_inflate_object($class, $response);
}

sub patch_status {
    my ($self, $class_or_object, @rest) = @_;


    my ($class, $name, $namespace, $patch, $content_type)
        = $self->_unpack_patch_args('patch_status', 'merge', $class_or_object, @rest);

    my $path = $self->_build_path($class,
        name        => $name,
        namespace   => $namespace,
        subresource => 'status',
        $self->_unstructured_hint($class, $class_or_object),
    );
    my $response = $self->_request('PATCH', $path, $patch,
        content_type => $content_type);
    $self->_check_response($response, "patch_status $class");

    return $self->_inflate_object($class, $response);
}

sub update_status {
    my ($self, $object) = @_;


    my $class = ref($object);
    my $metadata = $object->metadata or croak "object must have metadata";
    my $name = $metadata->name or croak "object must have metadata.name";
    my $namespace = $metadata->namespace;

    my $path = $self->_build_path($class,
        name        => $name,
        namespace   => $namespace,
        subresource => 'status',
        $self->_unstructured_hint($class, $object),
    );
    my $response = $self->_request('PUT', $path, $object->TO_JSON);
    $self->_check_response($response, "update_status " . ref($object));

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

    my $path = $self->_build_path($class, name => $name, namespace => $namespace,
        $self->_unstructured_hint($class, $class_or_object));
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

    my @unstructured_hint = $self->_unstructured_hint($class, $object);
    my $path = $self->_build_path($class, name => $name, namespace => $namespace,
        @unstructured_hint);

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

sub ensure_crd {
    my $self = shift;


    my (@classes, %opts);
    if (@_ && ref $_[0] eq 'ARRAY') {
        @classes = @{ shift() };
        %opts    = @_;
    } else {
        @classes = @_;
    }
    croak "ensure_crd requires at least one CRD class" unless @classes;

    my $storage = $opts{storage};

    # Group the classes by the CRD they name (metadata.name = "$plural.$group"),
    # preserving first-seen order so the applied order is predictable.
    my (@order, %group);
    for my $class (@classes) {
        my $single   = $class->to_crd;
        my $crd_name = $single->metadata->name;
        push @order, $crd_name unless exists $group{$crd_name};
        push @{ $group{$crd_name} }, { class => $class, single => $single };
    }

    my @crds;
    for my $crd_name (@order) {
        my $members = $group{$crd_name};
        if (@$members == 1) {
            push @crds, $members->[0]{single};
            next;
        }
        # Two or more classes are versions of the SAME CRD: assemble one
        # multi-version CRD rather than apply competing single-version ones.
        my @version_classes = map { $_->{class} } @$members;
        my @versions        = map { $_->{single}->spec->versions->[0]->name } @$members;
        my $storage_version =
              !defined $storage      ? undef
            : ref $storage eq 'HASH' ? $storage->{$crd_name}
            :                          $storage;
        croak "ensure_crd: '$crd_name' is defined by multiple classes ("
            . join(', ', @version_classes) . ") naming versions ("
            . join(', ', @versions) . "); pass storage => '<version>' (or "
            . "storage => { '$crd_name' => '<version>' }) to name the storage version"
            unless defined $storage_version && length $storage_version;
        push @crds,
            IO::K8s::CRD->new(classes => \@version_classes, storage => $storage_version);
    }

    # Apply every CRD first, then wait for each to establish (so establishment
    # happens in parallel), then invalidate discovery exactly once.
    $self->ensure($_) for @crds;
    my @established = map { $self->_wait_crd_established($_, %opts) } @crds;
    $self->invalidate_discovery;
    return @established;
}

# Poll GET on a CustomResourceDefinition by name until its Established condition
# is True, or croak on timeout. A 404 during polling means "not registered yet"
# and is treated as not-established, not an error.
sub _wait_crd_established {
    my ($self, $crd, %opts) = @_;

    my $class    = ref $crd;
    my $name     = $crd->metadata->name;
    my $path     = $self->_build_path($class, name => $name);
    my $timeout  = defined $opts{timeout}       ? $opts{timeout}       : 30;
    my $interval = defined $opts{poll_interval} ? $opts{poll_interval} : 1;
    my $deadline = Time::HiRes::time() + $timeout;

    while (1) {
        my $current = eval {
            my $response = $self->_request('GET', $path);
            return undef if $response->status == 404;
            $self->_check_response($response, "ensure_crd wait $name");
            $self->_inflate_object($class, $response);
        };
        my $err = $@;
        die $err if $err && $err !~ /\b404\b/;

        return $current if $current && $self->_crd_established($current);
        last if Time::HiRes::time() >= $deadline;
        Time::HiRes::sleep($interval);
    }

    croak "ensure_crd: CustomResourceDefinition '$name' did not reach the "
        . "Established condition within ${timeout}s";
}

# True when a CustomResourceDefinition object carries an Established=True
# condition in status.conditions.
sub _crd_established {
    my ($self, $crd) = @_;
    my $status     = $crd->status     or return 0;
    my $conditions = $status->conditions or return 0;
    for my $cond (@$conditions) {
        return 1
            if ($cond->type // '') eq 'Established'
            && ($cond->status // '') eq 'True';
    }
    return 0;
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
    my $path = $self->_build_path($class, %args,
        $self->_unstructured_hint($class, $short_class));

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
    my $path = $self->_build_path($class, %args, subresource => 'log',
        $self->_unstructured_hint($class, $short_class));

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
    my $path = $self->_build_path($class, %args, subresource => 'portforward',
        $self->_unstructured_hint($class, $short_class));

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
    my $path = $self->_build_path($class, %args, subresource => 'exec',
        $self->_unstructured_hint($class, $short_class));

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
    my $path = $self->_build_path($class, %args, subresource => 'attach',
        $self->_unstructured_hint($class, $short_class));

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

version 1.108

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

=head2 with

Arrayref of external L<IO::K8s> resource-map providers (CRD bundles), passed
straight through to the inner L<IO::K8s/with>. Each entry is a provider class
name (or object, or plain hashref) whose typed classes are merged into the
resource map, so the cluster's CRD Kinds resolve to real classes:

    my $api = Kubernetes::REST->new(
        server      => { endpoint => 'https://k8s.local:6443' },
        credentials => { token => $token },
        with        => ['IO::K8s::GatewayAPI'],
    );

    my $gw = $api->new_object(Gateway => { metadata => { name => 'gw' } });
    # => IO::K8s::GatewayAPI::V1::Gateway

Defaults to C<[]>. See L<IO::K8s/with> for the accepted provider forms.

=head2 k8s

L<IO::K8s> instance configured with the same resource map. Automatically created when needed.

Provides delegated methods: C<new_object>, C<inflate>, C<json_to_object>, C<struct_to_object>, C<object_to_json>, C<object_to_struct>, C<load>, C<load_yaml>. (C<expand_class> is implemented here rather than delegated, so that pure name resolution does not force the cluster resource-map fetch - see L</expand_class>.)

Delegation is a convenience only, every one of them behaves exactly as it does on L<IO::K8s>, including its argument contract:

=over

=item *

C<new_object> takes a short or full class name and either a hashref or a flat hash of attributes:

    my $ns = $api->new_object(Namespace => { metadata => { name => 'foo' } });
    my $ns = $api->new_object(Namespace => metadata => { name => 'foo' });

=item *

C<inflate> takes a hashref, or JSON as B<UTF-8 bytes> - its decoder is C<utf8 =E<gt> 1>.

=item *

C<json_to_object> and C<struct_to_object> auto-detect the class from the decoded C<kind> field when called with a single argument (JSON or hashref, respectively) - a leading class name is only needed to override that detection:

    my $pod = $api->json_to_object($json_with_kind);
    my $pod = $api->json_to_object('Pod', $json_string);

C<object_to_json> and C<object_to_struct> are their inverses, serialising a typed object back to JSON or to a plain hashref.

=item *

C<load_yaml> takes a file name or YAML as B<characters>. Handing it bytes turns every non-ASCII value into mojibake, so decode first (C<Encode::decode('UTF-8', $yaml)>). A newline-free argument is taken as a file name. C<--->-separated multi-document YAML is supported - the common case for Kubernetes manifests - so this always returns an arrayref, even for a single document:

    for my $obj (@{ $api->load_yaml('deployment.yaml') }) {
        $api->create($obj);
    }

=item *

C<load> reads a C<.pk8s> manifest, which is Perl code and is C<eval>ed in-process:

    my $objects = $api->load('myapp.pk8s');

Only load C<.pk8s> files you trust; for data-only manifests use C<load_yaml>.

=back

Not delegated: C<add>, which registers extra classes in the L<IO::K8s> resource map. That map is mirrored by this client's own L</resource_map> attribute, and mutating one behind the other's back makes the two disagree - reach through C<< $api->k8s->add(...) >> if you really mean to.

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

=head2 expand_class

    my $class = $api->expand_class('Pod');
    # => IO::K8s::Api::Core::V1::Pod

Resolve a short resource name (C<'Pod'>), a domain-qualified name
(C<'cilium.io/v2/NetworkPolicy'>), a C<+>-prefixed or an already
fully-qualified class name to its L<IO::K8s> class - the same contract as
L<IO::K8s/expand_class>, against this client's L</resource_map>.

Pure name resolution does not cost a cluster roundtrip: as long as the
resource map has not been fetched yet (and none was passed to the
constructor), a name the built-in L<IO::K8s> map resolves to a loadable
class is answered from that map directly. Only a name the built-in map
cannot answer falls through to the cluster-backed map, fetching it on first
use exactly as before.

=head2 fetch_resource_map

    my $map = $api->fetch_resource_map;

Build the resource map from the cluster's aggregated discovery documents
(C<GET /api> and C<GET /apis>). Returns a hashref mapping short resource names
(e.g., C<Pod>) to full L<IO::K8s> class paths.

Called automatically if C<resource_map_from_cluster> is enabled.

Discovery is fetched and cached once per instance (see L</invalidate_discovery>);
calling this again rebuilds the map from the cached catalog rather than
re-querying the cluster. It does B<not> download C</openapi/v2> - that spec is
fetched lazily only when L</schema_for> or L</compare_schema> need it.

B<Version selection (D17).> When a group serves a Kind in more than one
version, the bare short name (C<Pod>, C<ServiceCIDR>) resolves to the version
the B<cluster marks preferred> for that group - not to a fixed "stable beats
alpha/beta" preference. A Kind served only outside the preferred version still
maps, to its first served version.

Only Kinds whose L<IO::K8s> class this distribution actually ships are recorded
in the map. A CRD group with no bundled class (C<cilium.io>,
C<cert-manager.io>, ...) is deliberately omitted here, so that its Kinds
resolve through the inner L<IO::K8s> - a provider merged via L</with>, then
AutoGen from the fetched C</openapi/v2>, and finally a fail-closed error -
rather than being mapped to a class name that does not exist.

=head2 invalidate_discovery

    $api->invalidate_discovery;

Discard the cached discovery catalog and the resource map built from it, so the
next resolution re-queries the cluster. Use it after a CustomResourceDefinition
is installed or changed, to make the new Kind visible to this client instance.

=head2 schema_for

    my $schema = $api->schema_for('Pod');

Get the OpenAPI schema definition for a resource type from the cluster. Accepts short names (C<Pod>), full class names (C<IO::K8s::Api::Core::V1::Pod>), or OpenAPI definition names (C<io.k8s.api.core.v1.Pod>).

Returns a hashref with the OpenAPI v2 schema definition.

=head2 compare_schema

    my $result = $api->compare_schema('Pod');

Compare the local L<IO::K8s> class definition against the cluster's OpenAPI schema. Useful for detecting version skew between your L<IO::K8s> installation and the cluster.

Returns the comparison result from C<< $class->compare_to_schema >>, the method L<IO::K8s::Role::Resource> provides on every resource class.

=head2 build_path

    my $class = $api->expand_class('Pod');
    my $path = $api->build_path($class, name => 'my-pod', namespace => 'default');
    # => /api/v1/namespaces/default/pods/my-pod

    my $status = $api->build_path($class,
        name        => 'my-pod',
        namespace   => 'default',
        subresource => 'status',
    );
    # => /api/v1/namespaces/default/pods/my-pod/status

Build the REST API URL path for a resource class. Takes a fully-qualified class name (from C<expand_class>) and optional C<name>/C<namespace> arguments.

The optional C<subresource> argument appends a subresource segment (C<status>, C<log>, C<exec>, C<attach>, C<portforward>) to the resource path. A subresource always addresses one named resource, so C<subresource> without C<name> croaks rather than returning a path pointing at the collection endpoint.

C<build_path> also accepts C<kind>, C<api_version>, C<resource> and C<namespaced> arguments, but they matter only for L<IO::K8s::Unstructured>. For any other class they are ignored: C<api_version>, pluralisation and namespaced-ness always come from the class itself. Unstructured has no such class identity - its Kind is data on the instance - so the path metadata has to come from somewhere else:

    my $path = $api->build_path('IO::K8s::Unstructured',
        kind        => 'MyCRD',
        api_version => 'example.com/v1',
        resource    => 'mycrds',
        namespaced  => 1,
        name        => 'my-instance',
        namespace   => 'default',
    );
    # => /apis/example.com/v1/namespaces/default/mycrds/my-instance

Passing C<api_version>, C<resource> and C<namespaced> together, as above, resolves the path directly with no discovery lookup - the case for a caller (such as an async wrapper) that already knows the resource's metadata. Otherwise C<kind> is required (C<build_path> croaks without it), and resource/namespaced/apiVersion are looked up in the client's cached discovery catalog instead, preferring the cluster's preferred version unless C<api_version> pins a specific group/version; C<build_path> croaks if discovery has no entry for the Kind, and equally if the catalog could not be fetched at all (cluster unreachable, expired token) - in that case the message names that failure rather than claiming a missing entry, and the fallback stays fail-closed either way.

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

An item the object model rejects - typically because the installed L<IO::K8s>
does not know a field the cluster version serves - is dropped from the list,
and a warning names every dropped item (index, C<metadata.name>, the
inflation error) so an incomplete list is never silent. Promote it to a fatal
error with C<< local $SIG{__WARN__} = sub { die @_ } >> if partial results
are unacceptable to you.

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

    # JSON Patch (RFC 6902) instead: an array of operations, not a hashref
    my $patched = $api->patch('Deployment', 'my-app',
        namespace => 'default',
        type      => 'json',
        patch     => [
            { op => 'replace', path => '/spec/replicas', value => 3 },
            { op => 'add', path => '/metadata/labels/env', value => 'prod' },
        ],
    );

Partially update a resource. Unlike C<update()> which replaces the entire object, C<patch()> only modifies specified fields.

Required: C<patch> (a hashref, or an arrayref of operations when C<type> is
C<json>) and, when passing a class rather than an object, C<name>.

Optional: C<namespace> (for namespaced resources) and C<type>, the patch
strategy:

=over 4

=item C<strategic> (default)

Strategic Merge Patch. The Kubernetes-native patch type, which understands
array merge semantics (e.g. adding a container to a pod spec without removing
the existing ones).

=item C<merge>

JSON Merge Patch (RFC 7396). Simple recursive merge where C<null> values
delete keys; arrays are replaced entirely.

=item C<json>

JSON Patch (RFC 6902): an array of operations, as in the third example above.

=back

Returns the full updated object from the server.

=head2 patch_status

    my $node = $api->patch_status('OCPNode', 'cp-1',
        namespace => 'ocp',
        patch     => { status => { phase => 'Ready', ip => '10.0.0.7' } },
    );

    # Or with an object:
    my $node = $api->patch_status($node,
        patch => { status => { phase => 'Ready' } },
    );

Partially update a resource's B<status> through the C</status> subresource.

Once a CustomResourceDefinition declares C<subresources: {status: {}}>, the API
server strips the C<status> stanza from every write to the main endpoint -
C<create>, C<update>, C<patch> and server-side apply alike - and still answers
2xx. The write appears to succeed and nothing is stored. Status has to go to
C</status>, which is what this method addresses.

Takes the same arguments as L</patch> (object or class plus name, both call
forms, the same C<type> values) and returns the full object from the server.
The patch document is passed through unchanged, so it carries its own
C<status> key.

The default patch type is C<merge>, not C<strategic> as in L</patch>: custom
resources do not support strategic merge patch and the API server rejects it
with 415, and C<merge> works for built-in kinds as well. Pass
C<type =E<gt> 'strategic'> explicitly when patching the status of a built-in
resource and you need array merge semantics.

=head2 update_status

    my $node = $api->update_status($node);

Replace a resource's B<status> through the C</status> subresource. The whole
object is sent, as with L</update>, but the server only takes its C<status>
and leaves C<spec> and C<metadata> untouched. Returns the updated object.

This is the read-modify-write counterpart to L</patch_status>: it needs a
current C<resourceVersion> and fails with a 409 conflict when the object
changed in the meantime. Prefer L</patch_status> when you are setting
individual status fields.

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

=head2 ensure_crd

    # one class == one single-version CRD
    $api->ensure_crd('My::K8s::StaticWebSite');

    # several distinct CRDs at once
    $api->ensure_crd(@crd_classes);

    # with options (pass the classes as an arrayref):
    $api->ensure_crd(\@crd_classes, timeout => 60, poll_interval => 2);

    # several classes that are versions of the SAME CRD -> one multi-version CRD
    $api->ensure_crd(
        [ 'My::K8s::V1beta1::Widget', 'My::K8s::V1::Widget' ],
        storage => 'v1',
    );

Install (create-or-update) one or more CustomResourceDefinitions from typed
L<IO::K8s> classes, wait for each to reach the C<Established> condition, then
L</invalidate_discovery> so the new Kinds resolve on this client instance.

Each class's CRD manifest comes from C<< $class->to_crd >> (L<IO::K8s::CRD>).
The assembled CRD is applied with L</ensure>, so re-running is idempotent.
After every CRD is applied, each is polled with L</get> by name until its
C<status.conditions> carries C<< type => 'Established', status => 'True' >>,
subject to a timeout. Only then is the discovery cache invalidated, so the
next C<create>/C<list> of a custom resource does not race the apiserver
registering the Kind (the reason plain C<ensure> of the CRD is not enough:
the following call almost always creates a CR, which 404s until Established).

Returns the list of established CustomResourceDefinition objects (the objects
read back from the final poll, carrying their C<Established> status).

Arguments: the CRD classes, either as a plain list (C<ensure_crd(@classes)>)
or, when options are needed, as an arrayref followed by named options
(C<ensure_crd(\@classes, %opts)>).

=over 4

=item timeout

Seconds to wait for the C<Established> condition per CRD (default 30). On
expiry the call croaks, naming the CRD and that C<Established> was not
reached.

=item poll_interval

Seconds between polls (default 1). The current state is always checked once
before the timeout is consulted, so C<timeout =E<gt> 0> performs exactly one
poll.

=item storage

Only consulted when two or more passed classes name the SAME CRD (same group,
plural, kind and scope but different versions). Those are assembled into ONE
multi-version CustomResourceDefinition via
C<< IO::K8s::CRD->new(classes => [...], storage => ...) >> rather than applied
as competing single-version CRDs. Because a class carries no marker for which
version is authoritative, the storage version is not guessed: pass it as a
bare version string (applies to the multi-version group) or as a hashref
keyed by CRD name (C<< { 'widgets.example.com' => 'v1' } >>). A multi-version
group with no storage version croaks, naming the CRD and the candidate
versions.

=back

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

Required: C<on_event>, a callback invoked with a L<Kubernetes::REST::WatchEvent> for each event.

Optional:

=over 4

=item timeout

Server-side timeout in seconds (default: 300). The API server closes the
connection after this many seconds.

=item resourceVersion

Resume watching from a specific resource version - pass the return value of a
previous C<watch()> call to avoid missing events.

=item labelSelector

Filter by label selector (e.g. C<'app=web,env=prod'>).

=item fieldSelector

Filter by field selector (e.g. C<'status.phase=Running'>).

=item namespace

For namespaced resources, the namespace to watch.

=back

Returns the last C<resourceVersion> seen. Croaks on 410 Gone once the given
C<resourceVersion> has expired - re-list to get a fresh one and resume from
there:

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

Log output is returned as raw bytes in both modes - container output is not
guaranteed to be UTF-8, or even text. Decode it yourself when you know it is:
C<< Encode::decode('UTF-8', $text) >>. See L</ENCODING>.

The streaming mode is designed for event-based systems like L<IO::Async> — see L<Net::Async::Kubernetes> for async integration.

Also accepts, for namespaced resources, C<namespace>; and as further optional
arguments: C<container> (name, for multi-container pods), C<sinceSeconds> /
C<sinceTime> (show only recent output), C<timestamps> (prepend a timestamp to
each line), C<previous> (logs from the container's previous run, after a
restart), and C<limitBytes> (byte cap on the response).

=head2 port_forward

    my $session = $api->port_forward('Pod', 'my-pod',
        namespace => 'default',
        ports     => [8080, 8443],
        on_frame  => sub { my ($channel, $payload) = @_; ... },
    );

Start a full-duplex pod port-forward session.

Required: C<name> and C<ports> - one port number or an arrayref of them (e.g.
C<[8080, 8443]>).

Optional: C<namespace> (for namespaced resources), C<subprotocol> (WebSocket
subprotocol, default C<v4.channel.k8s.io>), and the duplex transport callbacks
C<on_open>, C<on_frame>, C<on_close>, C<on_error>, passed through to the IO
backend.

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

Required: C<name> and C<command> - a single string or an arrayref (e.g.
C<['sh', '-c', 'id']>).

Optional: C<namespace>, C<container> (for multi-container pods), the stream
toggles C<stdin>/C<stdout>/C<stderr>/C<tty> shown above (defaults: stdin and
tty off, stdout and stderr on), C<subprotocol> (WebSocket subprotocol, default
C<v4.channel.k8s.io>), and the duplex transport callbacks C<on_open>,
C<on_frame>, C<on_close>, C<on_error>, passed through to the IO backend.

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

Required: C<name>.

Optional: C<namespace>, C<container> (for multi-container pods), the stream
toggles C<stdin>/C<stdout>/C<stderr>/C<tty> shown above (defaults: stdin and
tty off, stdout and stderr on), C<subprotocol> (WebSocket subprotocol, default
C<v4.channel.k8s.io>), and the duplex transport callbacks C<on_open>,
C<on_frame>, C<on_close>, C<on_error>, passed through to the IO backend.

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
C<patch>, C<patch_status>, C<update_status>, C<delete>, C<ensure>,
C<ensure_all>, C<ensure_only>, C<watch>, C<log>, C<port_forward>, C<exec>,
C<attach>.

=item * B<Old API still works but deprecated>

The old API is still available for backwards compatibility but will emit deprecation
warnings. Set C<$ENV{HIDE_KUBERNETES_REST_V0_API_WARNING}> to suppress warnings.

=item * B<Uses IO::K8s classes>

Results are now returned as typed L<IO::K8s> objects instead of raw hashrefs.
Lists are returned as L<IO::K8s::List> objects.

B<Note:> L<IO::K8s> has also been completely rewritten (Moose to Moo, API
objects updated to a current Kubernetes release). See
L<IO::K8s/"UPGRADING FROM PREVIOUS VERSIONS"> for details.

=item * B<Short resource names>

You can now use short names like C<'Pod'> instead of full class paths. The
C<resource_map> attribute controls this mapping.

=item * B<Dynamic resource map>

Use C<resource_map_from_cluster =E<gt> 1> to load the resource map from the
cluster's OpenAPI spec, ensuring compatibility with any Kubernetes version.

=back

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

=item * C<inflate_list($class, $response)> - JSON to typed list (an item the
object model rejects is dropped and carped about, not silently lost - see
L</inflate_list>)

=item * C<process_watch_chunk($class, \$buf, $chunk)> - Parse NDJSON watch stream

=item * C<process_log_chunk(\$buf, $chunk)> - Parse plain-text log stream

=back

Example async integration:

    # Build request using Kubernetes::REST
    my $class = $rest->expand_class('Pod');
    my $path = $rest->build_path($class,
        name        => $name,
        namespace   => $ns,
        subresource => 'log',
    );
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

=head1 ENCODING

On the wire everything is bytes; in your program everything is characters.
The boundary sits in this module, and you do not have to do anything for it:

=over

=item *

Objects you pass to C<create>, C<update>, C<patch> and friends hold ordinary
Perl character strings. They are UTF-8 encoded on the way into the request
body, so C<< data => { note => "Caf\x{e9} \x{a7}" } >> is applied to the
cluster unchanged.

=item *

Objects you get back from C<get>, C<list>, C<watch> and friends hold decoded
characters, so C<length> counts characters and regexes match as expected.

=item *

Exception messages from failed API calls are decoded too.

=back

Two things stay bytes on purpose:

=over

=item *

C<log> - container output is an arbitrary byte stream, not necessarily UTF-8,
and decoding it would corrupt anything binary. Decode it yourself if you know
it is text: C<< Encode::decode('UTF-8', $api->log('Pod', $name)) >>. The same
applies to C<< $event->line >> in streaming mode.

=item *

The C<content> of L<Kubernetes::REST::HTTPRequest> and
L<Kubernetes::REST::HTTPResponse> - these are the raw HTTP layer. Custom IO
backends must honour that; see L<Kubernetes::REST::Role::IO/Encoding contract>.

=back

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

=item * L<https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.36/> - Kubernetes API reference

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

Torsten Raudssus <getty@cpan.org>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
