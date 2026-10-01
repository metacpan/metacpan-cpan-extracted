package Kubernetes::REST;
our $VERSION = '1.109';
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
use Kubernetes::REST::APIError;
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
            # Until then it is absent; _fetch_openapi_spec rebuilds this
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
    # Always a hash of our own: the inner IO::K8s merges the `with` providers
    # into this hashref in place (IO::K8s::add). A map passed to the
    # constructor is the caller's, and the fallback of a failed cluster fetch
    # is IO::K8s's process-wide built-in map - neither may grow by the
    # provider Kinds (karr k57). Moo coerces the default's value too.
    coerce => sub { ref $_[0] eq 'HASH' ? { %{ $_[0] } } : $_[0] },
    default => sub {
        my $self = shift;
        # Built here, not passed in: absorb_discovery may rebuild it.
        $self->_resource_map_built(1);
        # A private copy, never IO::K8s's shared global map: the inner IO::K8s
        # is handed this hashref and merges any `with` providers into it with
        # add(), which mutates it in place. Returning the global ref would leak
        # provider Kinds into IO::K8s->default_resource_map process-wide.
        return { %{ IO::K8s->default_resource_map } } unless $self->resource_map_from_cluster;
        return $self->_load_resource_map_from_cluster;
    },
);


# Whether the resource map in place was built by the default above rather
# than passed to the constructor. absorb_discovery rebuilds a built map from
# the catalog it takes; a map the caller passed is theirs and stays (karr k51).
has _resource_map_built => (is => 'rw', init_arg => undef);

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
    # Both -- and nothing else -- mean unresolved (_is_unresolved).
    my ($kind, $api_version) = $self->_kind_from_expand_args(@args);
    return $class unless defined $kind && $self->_is_unresolved($class, $kind);

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
    # load error still names the Kind. A qualified name, or a Kind plus
    # apiVersion, is confirmed only in exactly its group/version: another
    # group or version serving the Kind leaves it at rung 5 too (karr k43).
    # A discovery *failure* (cluster unreachable, expired token) is
    # deliberately treated the same as "not served" here -- rung 5,
    # fail-closed -- with the reason kept in
    # _discovery_error; on the CRUD path the carp from
    # _load_resource_map_from_cluster has already named it while building the
    # cluster map.
    return 'IO::K8s::Unstructured'
        if $self->_discovery_path_meta($kind, $api_version);

    return $class;
}

# Whether $class, what expand_class() made of a name whose Kind is $kind (from
# _kind_from_expand_args), is the signal that nothing resolved it: undef, or
# the 'IO::K8s::<Kind>' IO::K8s fabricates for a bare Kind when that class does
# not load (see expand_class). Every real resolution is resolved, including a
# '+'-class that is not loaded yet.
sub _is_unresolved {
    my ($self, $class, $kind) = @_;
    return 1 unless defined $class;
    return defined $kind
        && $class eq "IO::K8s::$kind"
        && !($class->can('new') || eval { require_module($class); 1 });
}

# expand_class() for the methods that take a resource name and build a request
# path from its class (list, get, patch, patch_status, delete, watch, log,
# port_forward, exec, attach) or load it (compare_schema). A name nothing
# resolves croaks here, naming it the way Net::Async::Kubernetes does, before
# any request (karr k46) - instead of in _build_path, where require_module saw
# only expand_class's answer: undef for a qualified name ("argument is not a
# module name"), or a bare Kind's fabricated class ("Can't locate
# IO/K8s/<Kind>.pm", naming a module that does not exist). A discovery
# failure is named with it: an unreachable cluster could not confirm the name,
# which is not the same as a cluster that does not serve it (karr k28). Only
# for a name with a Kind - expand_class consulted discovery for exactly that
# one, so the recorded failure is this call's. expand_class itself keeps
# returning undef or the fabricated name: that is its public contract, and
# _manifest_to_object reads the undef.
sub _expand_class_or_croak {
    my ($self, $name) = @_;
    my $class = $self->expand_class($name);
    my ($kind) = $self->_kind_from_expand_args($name);
    return $class unless $self->_is_unresolved($class, $kind);
    my $discovery_error = defined $kind ? $self->_discovery_error : undef;
    $discovery_error = $self->_error_reason($discovery_error) if defined $discovery_error;
    croak "unknown resource '" . ($name // '(undef)') . "': no IO::K8s class"
        . " for this apiVersion/kind (add it to resource_map if it is a CRD)"
        . (defined $discovery_error
            ? "; discovery failed, so the cluster could not confirm it: $discovery_error"
            : '');
}

# A caught error - a croak's string, or an APIError - as the reason another
# message embeds: its text without the location it ends with. That location
# names a line in here, or whatever frame a lazy builder left; the message it
# goes into names the caller's line itself (karr k59). Once a file handle has
# been read, Carp's location ends ', <$fh> line N.' (or 'chunk N').
sub _error_reason {
    my ($self, $error) = @_;
    my $reason = "$error";
    $reason =~ s/(?: at \S+ line \d+(?:, <[^>]*> (?:line|chunk) \d+)?\.)?\s*\z//;
    return $reason;
}

# carp, for a warning raised while a lazy attribute is built - the discovery
# catalog, the resource map built from it. Carp skips the frames of Moo's
# generated accessors (Moo marks them internal), but not the frame where this
# package calls into one, so a plain carp named the line in here that first
# asked for the attribute (karr k63, k64). Trusting the generated accessors
# for this one warning lets it name the caller's line, as a warning from a
# plain method does. Not package-wide: that would move every other croak.
sub _carp_past_builders {
    my ($self, $message) = @_;
    local our @CARP_NOT = ('Method::Generate::Accessor::_Generated');
    carp $message;
    return;
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
# $want_api_version, when given (a qualified name's group/version, or an
# Unstructured object's own apiVersion), pins the group/version, and nothing
# else will do; without it the group's discovery-preferred version wins,
# matching _resource_map_from_catalog and D17.
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

    # An explicit apiVersion pins the exact group/version, and only that one.
    # It names one GVK, and a cluster that does not serve that GVK has not
    # confirmed it (D16) - not even when another group, or another version of
    # the same group, serves a Kind of that name. Falling back there would
    # address that other resource: list, delete and ensure_only's prune would
    # land in it (karr k43). The same rule as IO::K8s's exact-GVK resolution,
    # where an explicit version never falls back to the bare Kind's.
    if (defined $want_api_version && length $want_api_version) {
        my ($g, $v) = $want_api_version =~ m{/}
            ? split(m{/}, $want_api_version, 2)
            : ('', $want_api_version);
        my $res = $catalog->{groups}{$g}{versions}{$v}{kinds}{$kind};
        return unless $res;
        return $meta_for->($g, $v, $res);
    }

    # A bare Kind: the preferred version of whichever group serves it (D17).
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
# (its kind/apiVersion accessors) or a name string. A string is split the way
# expand_class split it to confirm the GVK, so a qualified
# 'example.org/v1/Widget' keeps its group/version and does not land in
# whichever other group serving a Widget discovery lists first. Empty for
# every typed class, so typed path building is completely unchanged.
sub _unstructured_hint {
    my ($self, $class, $ident) = @_;
    return () unless defined $class && $class eq 'IO::K8s::Unstructured';
    if (blessed($ident)) {
        return (
            kind => $ident->kind,
            (defined $ident->apiVersion ? (api_version => $ident->apiVersion) : ()),
        );
    }
    my ($kind, $api_version) = $self->_kind_from_expand_args($ident);
    return (
        (defined $kind        ? (kind        => $kind)        : ()),
        (defined $api_version ? (api_version => $api_version) : ()),
    );
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
    croak 'Could not load resource map from cluster: ' . $self->_error_reason($@)
        unless $catalog;

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
# Built lazily on first use - or handed over by absorb_discovery - and
# invalidated by invalidate_discovery.
has _discovery => (
    is => 'lazy',
    predicate => '_has_discovery',
    clearer => '_clear_discovery',
    writer => '_set_discovery',   # absorb_discovery
    builder => sub { $_[0]->_fetch_discovery },
);

# The reason the last discovery fetch attempted from _discovery_path_meta
# failed - its $@, for an HTTP error status an APIError (karr k59), rendered
# with _error_reason - kept so the croak in _build_path can name it: a
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

# The two discovery documents, in the order they are read.
my @DISCOVERY_ROOTS = ('/api', '/apis');

sub _fetch_discovery {
    my ($self) = @_;

    my $catalog = { groups => {} };

    for my $root (@DISCOVERY_ROOTS) {
        my ($body, $aggregated) = $self->_discovery_document($root,
            $self->io->call($self->_discovery_request($root)));

        if ($aggregated) {
            $self->_absorb_discovery_list($catalog, $body);
        } elsif ($root eq '/api') {
            $self->_fetch_discovery_legacy_core($catalog, $body);
        } else {
            $self->_fetch_discovery_legacy_groups($catalog, $body);
        }
    }

    return $catalog;
}

# The request for one discovery root: what _fetch_discovery sends, and what
# prepare_discovery_requests hands an async client to send.
sub _discovery_request {
    my ($self, $root) = @_;
    return $self->_prepare_request('GET', $root,
        headers => { Accept => $DISCOVERY_ACCEPT });
}

# One discovery root's response, checked and decoded - for the synchronous
# fetch and absorb_discovery alike. An HTTP error dies as an APIError like
# any other checked response, carrying the body that says why (karr k59);
# the second value says whether the document is aggregated discovery
# (APIGroupDiscoveryList) rather than the legacy one.
sub _discovery_document {
    my ($self, $root, $response) = @_;
    $self->_check_response($response, "discovery GET $root");
    my $body = $self->_json->decode($response->content);
    my $kind = ref $body eq 'HASH' ? ($body->{kind} // '') : '';
    return ($body, $kind eq 'APIGroupDiscoveryList');
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
        my $path = "/api/$version";
        my $response = $self->_request('GET', $path);
        next unless $self->_legacy_resource_list_ok($response, $version, $path);
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
            my $path = "/apis/$gname/$version";
            my $response = $self->_request('GET', $path);
            next unless $self->_legacy_resource_list_ok($response, "$gname/$version", $path);
            my $list = $self->_json->decode($response->content);
            $self->_absorb_api_resource_list($catalog, $gname, $version, $list);
        }
        my $pref = $group->{preferredVersion}{version};
        $catalog->{groups}{$gname}{preferred} = $pref
            if defined $pref && exists $catalog->{groups}{$gname};
    }
}

# Whether the legacy APIResourceList response for one group/version
# ($api_version, fetched from $path) can be read into the catalog. An error
# status leaves that group/version's Kinds out of the catalog, and so out of
# the resource map: any other status than 404 warns, naming it and the reason
# the APIError gives, and the other groups are read on (karr k63). A 404 is
# silent - the group/version went away between the group list and this
# request.
sub _legacy_resource_list_ok {
    my ($self, $response, $api_version, $path) = @_;
    return 1 if $response->status < 400;
    return 0 if $response->status == 404;
    eval { $self->_check_response($response, "discovery GET $path") };
    $self->_carp_past_builders("discovery: cannot read apiVersion '$api_version',"
        . ' its Kinds are missing from the resource map: ' . $self->_error_reason($@));
    return 0;
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
    # Only a map built from the catalog goes, and with it the inner IO::K8s
    # that captured it at build time, so both are rebuilt on next use. A map
    # passed to the constructor is the caller's: rebuilding it would drop
    # their '+My::Class' entries (karr k52), as absorb_discovery knows too.
    if ($self->_has_resource_map && $self->_resource_map_built) {
        $self->_clear_resource_map;
        $self->_clear_k8s if $self->_has_k8s;
    }
    return 1;
}

sub prepare_discovery_requests {
    my ($self) = @_;


    return map { ($_ => $self->_discovery_request($_)) } @DISCOVERY_ROOTS;
}

sub absorb_discovery {
    my ($self, %responses) = @_;


    $self->_croak_unknown_args('absorb_discovery', \%responses, @DISCOVERY_ROOTS);
    my @lists;
    for my $root (@DISCOVERY_ROOTS) {
        my $response = $responses{$root}
            or croak "absorb_discovery requires the response for $root";
        my ($body, $aggregated) = $self->_discovery_document($root, $response);
        push @lists, $aggregated ? $body : undef;
    }
    # Legacy discovery needs a request per group/version on top, which only
    # the synchronous path makes: nothing is cached, and the caller falls
    # back to that path.
    return if grep { !defined } @lists;

    my $catalog = { groups => {} };
    $self->_absorb_discovery_list($catalog, $_) for @lists;

    # What an earlier catalog built goes, so this one counts: a resource map
    # built from it, and the inner IO::K8s holding that map. A map passed to
    # the constructor stays - a caller's '+My::Class' entries must survive.
    if ($self->_has_resource_map && $self->_resource_map_built) {
        $self->_clear_resource_map;
        $self->_clear_k8s if $self->_has_k8s;
    }
    $self->_clear_discovery_error;
    $self->_set_discovery($catalog);
    return 1;
}

# The full OpenAPI spec from the cluster, once _fetch_openapi_spec has fetched
# it (cached). The only /openapi/v2 download in the client, paid for by
# schema_for/compare_schema and (once resolution needs it) AutoGen, never by
# construction.
has _openapi_spec => (
    is => 'ro',
    predicate => '_has_openapi_spec',
    writer => '_set_openapi_spec',
);

# Fetch /openapi/v2 and keep it. Not a lazy builder: an error status dies as
# an APIError like any other checked response, naming the caller's line (karr
# k55) - and a Moo-generated accessor between the caller and the check breaks
# Carp's trust chain, so from a builder it named a line in here. A failed
# fetch keeps nothing, and the next use fetches again.
sub _fetch_openapi_spec {
    my ($self) = @_;
    my $response = $self->_request('GET', '/openapi/v2');
    $self->_check_response($response, 'fetch OpenAPI spec');
    my $spec = $self->_json->decode($response->content);
    $self->_set_openapi_spec($spec);
    # D12: the inner IO::K8s was built without a spec (so building it never
    # forced this fetch). Now that the spec exists, drop the cached instance
    # so its next build passes it through as openapi_spec for AutoGen -- the
    # same rebuild-on-next-use pattern invalidate_discovery uses.
    $self->_clear_k8s if $self->_has_k8s;
    return $spec;
}

# Get schema definition for a specific type
# $kind can be: 'Pod', 'IO::K8s::Api::Core::V1::Pod', or OpenAPI name like 'io.k8s.api.core.v1.Pod'
sub schema_for {
    my ($self, $kind) = @_;


    my $spec = $self->_has_openapi_spec ? $self->_openapi_spec : $self->_fetch_openapi_spec;
    my $defs = $spec->{definitions} // {};

    # If it's already an OpenAPI definition name
    if (exists $defs->{$kind}) {
        return $defs->{$kind};
    }

    # Convert class name to OpenAPI definition name. A name nothing resolves
    # (expand_class answers undef for a qualified one) has no definition to
    # look up: the same undef a missing definition gets, without turning undef
    # into a definition name first (karr k47).
    my $class = $self->expand_class($kind);
    return unless defined $class;
    # IO::K8s::Api::Core::V1::Pod -> io.k8s.api.core.v1.Pod
    my $def_name = $class;
    $def_name =~ s/^IO::K8s:://;
    $def_name =~ s/::/./g;
    $def_name = 'io.k8s.' . $def_name;
    # Lowercase all path components except the final type name
    my @parts = split /\./, $def_name;
    $parts[$_] = lc($parts[$_]) for 0 .. $#parts - 1;
    $def_name = join '.', @parts;
    return $defs->{$def_name} if exists $defs->{$def_name};

    # That holds for the IO::K8s::Api:: classes only. Upstream names
    # apiextensions and apiregistration after their staging repositories
    # (io.k8s.apiextensions-apiserver..., io.k8s.kube-aggregator...), a CRD's
    # definition after its group (com.example.v1.Widget), and Unstructured or
    # a '+My::Class' map onto nothing. Every Kind's definition carries
    # x-kubernetes-group-version-kind, so the class's GVK finds it; no match
    # stays undef (karr k54).
    my ($api_version, $gvk_kind) = $self->_schema_gvk($class, $kind);
    return unless defined $api_version;
    my ($group, $version) = $api_version =~ m{/}
        ? split(m{/}, $api_version, 2)
        : ('', $api_version);
    for my $name (sort keys %$defs) {
        my $gvks = ref $defs->{$name} eq 'HASH'
            ? $defs->{$name}{'x-kubernetes-group-version-kind'} : undef;
        next unless ref $gvks eq 'ARRAY';
        for my $gvk (grep { ref $_ eq 'HASH' } @$gvks) {
            return $defs->{$name}
                if ($gvk->{group} // '') eq $group
                && ($gvk->{version} // '') eq $version
                && ($gvk->{kind} // '') eq $gvk_kind;
        }
    }
    return;
}

# The apiVersion and Kind schema_for looks a definition up by, for $class as
# expand_class resolved $name: the class's own api_version() and kind(), or -
# for IO::K8s::Unstructured, whose class has neither - the Kind of the name
# and the apiVersion discovery confirmed for it, exactly as expand_class and
# _build_path read it (_discovery_path_meta). Empty when there is none.
sub _schema_gvk {
    my ($self, $class, $name) = @_;
    if ($class eq 'IO::K8s::Unstructured') {
        my ($kind, $api_version) = $self->_kind_from_expand_args($name);
        return unless defined $kind;
        my $meta = $self->_discovery_path_meta($kind, $api_version) or return;
        return ($meta->{api_version}, $kind);
    }
    return unless eval { require_module($class); 1 } && $class->can('api_version');
    # Asked as class methods, and only an answer without error counts - a
    # class of your own may have them as instance attributes.
    my $api_version = eval { $class->api_version };
    return unless defined $api_version && length $api_version;
    my $kind = $class->can('kind') ? eval { $class->kind } : undef;
    ($kind = $class) =~ s/.*::// unless defined $kind && length $kind;
    return ($api_version, $kind);
}

# Compare local class against cluster schema
# Returns comparison result from IO::K8s::Role::Resource->compare_to_schema
sub compare_schema {
    my ($self, $kind) = @_;


    my $class = $self->_expand_class_or_croak($kind);
    # Unstructured declares only the envelope; held against a definition it
    # would report every other field as missing locally, which says nothing
    # about skew (karr k60). Before the /openapi/v2 download, which it would
    # waste.
    croak "compare_schema: '$kind' resolves to IO::K8s::Unstructured, which has"
        . " no local schema to compare (add a typed class for it to resource_map"
        . " or with)"
        if $class eq 'IO::K8s::Unstructured';
    require_module($class);

    my $schema = $self->schema_for($kind);
    croak "Schema not found for $kind" unless $schema;

    return $class->compare_to_schema($schema);
}

# Internal wrapper with fallback for lazy loading. It runs in the
# resource_map builder, most often reached through the k8s one: the warning
# goes through _carp_past_builders to name the caller's line, not the line of
# the k8s builder that asked for the map (karr k64).
sub _load_resource_map_from_cluster {
    my ($self) = @_;
    my $map = eval { $self->fetch_resource_map };
    if ($@) {
        $self->_carp_past_builders('Falling back to the built-in resource map: '
            . $self->_error_reason($@));
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
                # never read must not be reported as one lacking an entry. A
                # pinned apiVersion is named: the Kind may well be served in
                # another group or version, just not in this one (karr k43).
                my $reason = $self->_discovery_error;
                $reason = $self->_error_reason($reason) if defined $reason;
                my $gvk = "Kind '$kind_hint'"
                    . (defined $av_hint && length $av_hint
                        ? " in apiVersion '$av_hint'" : '');
                croak defined $reason
                    ? "discovery failed, so $gvk is unconfirmed"
                        . " - cannot build a path for IO::K8s::Unstructured:"
                        . " $reason"
                    : "no discovery entry for $gvk - cannot"
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

    # Append query parameters to URL, keys and values through _query_escape
    if ($parameters && %$parameters) {
        my @pairs;
        for my $key (sort keys %$parameters) {
            my $val = $parameters->{$key};
            next unless defined $val;
            my $k = $self->_query_escape($key);
            if (ref($val) eq 'ARRAY') {
                push @pairs, map { "$k=" . $self->_query_escape($_) } grep { defined } @$val;
            } else {
                push @pairs, "$k=" . $self->_query_escape($val);
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

# Percent-encode a query key or value - but only what would otherwise change
# what the API server reads (karr k35). The server splits a query with Go's
# net/url ParseQuery: into pairs at '&', dropping a pair that holds a ';'
# whole, then key from value at the FIRST '=', reading '+' as a space and
# '%XX' as a byte, and dropping a pair with a malformed '%'. A '#' ends the
# URL before it is sent (URI and HTTP::Tiny take the rest for a fragment), and
# a space, a control character or a non-ASCII byte has no place in a request
# target. Those are encoded - characters as their UTF-8 bytes, the contract
# the JSON body follows too. Everything else stays as it is, above all '=',
# ',', '!', '/', '(', ')' and ':': the server reads them the same either way
# (a value's '=' is past the first one), a selector stays readable in the URL,
# and whoever compares the rendered query - this distribution's mock harness,
# Net::Async::Kubernetes's - sees the string it always did. Keys go the same
# way; they are the API's parameter names, none of which holds an '='.
sub _query_escape {
    my ($self, $string) = @_;
    my $bytes = Encode::encode('UTF-8', "$string");
    $bytes =~ s/([\x00-\x20\x7F-\xFF%&+#;])/sprintf('%%%02X', ord $1)/ge;
    return $bytes;
}

sub _check_response {
    my ($self, $response, $context) = @_;
    if ($response->status >= 400) {
        # Response bodies are bytes; the error message is read by humans, so
        # decode it (leniently - a truncated or non-UTF-8 body must not turn a
        # useful API error into an encoding croak).
        my $body = Encode::decode('UTF-8', $response->content // '', Encode::FB_DEFAULT);
        # An object, so a caller can branch on the status instead of parsing
        # the text; it stringifies to the message this croaked with before,
        # at the same caller line (karr k50).
        Kubernetes::REST::APIError->throw(
            code     => 0 + $response->status,
            body     => $body,
            context  => $context,
            response => $response,
        );
    }
    return $response;
}

# The name to hand IO::K8s's json_to_object()/struct_to_object() for $class.
# Both resolve a name again, and a single-segment class of your own - '+Gizmo'
# in the resource_map, which expand_class returns as 'Gizmo' - reads to them
# as a Kind: IO::K8s::Gizmo, or whatever class the map gives the Kind Gizmo
# (karr k42). A name that already is a loaded IO::K8s class, which is what
# expand_class resolved and _build_path loaded, therefore goes over as
# '+Class', which IO::K8s takes exactly. Any other name - a short or qualified
# one a seam caller passed - is left for IO::K8s to resolve. The role check
# keeps an unrelated package that merely shares a Kind's name from being
# taken for the class.
sub _exact_class {
    my ($self, $class) = @_;
    return "+$class"
        if defined $class && !ref $class && length $class && $class !~ /\A\+/
            && $class->can('does') && $class->does('IO::K8s::Role::Resource');
    return $class;
}

sub _inflate_object {
    my ($self, $class, $response) = @_;
    return $self->k8s->json_to_object($self->_exact_class($class), $response->content);
}

sub _inflate_list {
    my ($self, $class, $response) = @_;
    my $struct = $self->_json->decode($response->content);
    my $items = $struct->{items} // [];
    my $exact_class = $self->_exact_class($class);
    my (@objects, @dropped);
    for my $i (0 .. $#$items) {
        my $item = $items->[$i];
        my $obj = eval { $self->k8s->struct_to_object($exact_class, $item) };
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

    my $exact_class = $self->_exact_class($class);
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
            $object = eval { $self->k8s->struct_to_object($exact_class, $raw_object) }
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


    # A misspelt option is not ignored (karr k58): label_selector listed
    # unfiltered, namespce across the cluster. name and subresource are out
    # too: they made the request a GET of one object, read as an empty list.
    $self->_croak_unknown_args('list', \%args, qw(namespace labelSelector fieldSelector));
    my ($class, $response) = $self->_list_request($short_class, %args);
    $self->_check_response($response, "list $short_class");

    return $self->_inflate_list($class, $response);
}

# list() up to the response, unchecked: returns the resolved class and the raw
# response. ensure_only() needs the status itself - a 404 there means the Kind
# is not served, not a failure - and must not read it back out of the text
# _check_response croaks with.
sub _list_request {
    my ($self, $short_class, %args) = @_;

    # Extract query parameters before building path
    my $label_selector = delete $args{labelSelector};
    my $field_selector = delete $args{fieldSelector};

    my $class = $self->_expand_class_or_croak($short_class);
    my $path = $self->_build_path($class, %args,
        $self->_unstructured_hint($class, $short_class));

    my %params;
    $params{labelSelector} = $label_selector if defined $label_selector;
    $params{fieldSelector} = $field_selector if defined $field_selector;

    my $response = %params
        ? $self->_request('GET', $path, undef, parameters => \%params)
        : $self->_request('GET', $path);
    return ($class, $response);
}

sub get {
    my ($self, $short_class, @rest) = @_;


    # Support: get('Kind', 'name'), get('Kind', 'name', namespace => 'ns'),
    #          get('Kind', name => 'name'), get('Kind', name => 'name', namespace => 'ns'),
    #          each with subresource => ... as well
    my %args;
    if (@rest == 1) {
        $args{name} = $rest[0];
    } elsif (@rest >= 2 && $rest[0] !~ /^(name|namespace|subresource)$/) {
        # First arg is name, rest are key=value pairs
        $args{name} = shift @rest;
        %args = (%args, @rest);
    } elsif (@rest % 2 == 0) {
        %args = @rest;
    } else {
        croak "Invalid arguments to get()";
    }
    # A misspelt option is not ignored (karr k58). subresource is build_path's
    # and works: status answers with the object.
    $self->_croak_unknown_args('get', \%args, qw(name namespace subresource));

    my $class = $self->_expand_class_or_croak($short_class);
    croak "name required for get" unless $args{name};

    my $path = $self->_build_path($class, %args,
        $self->_unstructured_hint($class, $short_class));
    my $response = $self->_request('GET', $path);
    $self->_check_response($response, "get $short_class");

    return $self->_inflate_object($class, $response);
}

sub create {
    my ($self, $object) = @_;


    my ($class, $response) = $self->_create_request($object);
    $self->_check_response($response, "create $class");

    return $self->_inflate_object($class, $response);
}

# create() up to the response, unchecked, for the same reason as
# _list_request: ensure() takes a 409 as its cue that the object appeared
# since its GET, and must read that off the status, not out of the text
# _check_response croaks with (karr k44).
sub _create_request {
    my ($self, $object) = @_;

    my $class = ref($object);
    my $namespace = $object->can('metadata') && $object->metadata
        ? $object->metadata->namespace
        : undef;

    my $path = $self->_build_path($class, namespace => $namespace,
        $self->_unstructured_hint($class, $object));
    return ($class, $self->_request('POST', $path, $object->TO_JSON));
}

sub update {
    my ($self, $object) = @_;


    my ($class, $response) = $self->_update_request($object);
    $self->_check_response($response, "update $class");

    return $self->_inflate_object($class, $response);
}

# update() up to the response, unchecked, like _create_request: ensure()
# re-fetches and retries on a 409 Conflict and must tell it apart by status.
sub _update_request {
    my ($self, $object) = @_;

    my $class = ref($object);
    my $metadata = $object->metadata or croak "object must have metadata";
    my $name = $metadata->name or croak "object must have metadata.name";
    my $namespace = $metadata->namespace;

    my $path = $self->_build_path($class, name => $name, namespace => $namespace,
        $self->_unstructured_hint($class, $object));
    return ($class, $self->_request('PUT', $path, $object->TO_JSON));
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
#
# Any argument it does not read croaks before anything is sent (karr k61): a
# misspelt namespce patched the object of that name at cluster scope, a
# patch_type => 'merge' went out as a strategic merge patch. An object names
# itself, so with one only the patch and its type are taken.
sub _unpack_patch_args {
    my ($self, $label, $default_type, $class_or_object, @rest) = @_;

    my ($class, $name, $namespace, $patch, $patch_type);

    if (ref($class_or_object) && blessed($class_or_object)) {
        # Object passed: patch($object, patch => {...})
        my $object = $class_or_object;
        my %args = @rest;
        $self->_croak_unknown_args($label, \%args, qw(patch type));
        $class = ref($object);
        my $metadata = $object->metadata or croak "object must have metadata";
        $name = $metadata->name or croak "object must have metadata.name";
        $namespace = $metadata->namespace;
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
        $self->_croak_unknown_args($label, \%args, qw(name namespace patch type));

        $class = $self->_expand_class_or_croak($class_or_object);
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


    my ($class, $response) = $self->_delete_request($class_or_object, @rest);
    $self->_check_response($response, "delete $class");

    return 1;
}

# delete() up to the response, unchecked: returns the resolved class and the
# raw response, for the same reason as _list_request - ensure_only() treats a
# 404 (already gone) differently from a failure.
#
# propagationPolicy goes out as the query parameter the API server reads
# DeleteOptions from. Any other argument croaks before anything is sent: a
# misspelt propagationPolicy that was silently dropped would leave a Job's
# Pods orphaned (karr k49).
sub _delete_request {
    my ($self, $class_or_object, @rest) = @_;

    my ($class, $name, $namespace, %args);

    if (ref($class_or_object)) {
        # Object passed: delete($object), delete($object, propagationPolicy => ...)
        my $object = $class_or_object;
        croak "Invalid arguments to delete()" if @rest % 2;
        %args = @rest;
        $self->_croak_unknown_args('delete', \%args, 'propagationPolicy');
        $self->_propagation_policy_or_croak('delete', $args{propagationPolicy});
        $class = ref($object);
        my $metadata = $object->metadata or croak "object must have metadata";
        $name = $metadata->name or croak "object must have metadata.name";
        $namespace = $metadata->namespace;
    } else {
        # Support: delete('Kind', 'name'), delete('Kind', 'name', namespace => 'ns'),
        #          delete('Kind', name => 'name'), delete('Kind', name => 'name', namespace => 'ns'),
        #          each with propagationPolicy => ... as well
        if (@rest == 1) {
            $args{name} = $rest[0];
        } elsif (@rest >= 2 && $rest[0] !~ /^(name|namespace|propagationPolicy)$/) {
            # First arg is name, rest are key=value pairs
            $args{name} = shift @rest;
            %args = (%args, @rest);
        } elsif (@rest % 2 == 0) {
            %args = @rest;
        } else {
            croak "Invalid arguments to delete()";
        }
        $self->_croak_unknown_args('delete', \%args,
            qw(name namespace propagationPolicy));
        $self->_propagation_policy_or_croak('delete', $args{propagationPolicy});

        $class = $self->_expand_class_or_croak($class_or_object);
        $name = $args{name} or croak "name required for delete";
        $namespace = $args{namespace};
    }

    my $path = $self->_build_path($class, name => $name, namespace => $namespace,
        $self->_unstructured_hint($class, $class_or_object));
    my $policy = $args{propagationPolicy};
    return ($class, defined $policy
        ? $self->_request('DELETE', $path, undef,
            parameters => { propagationPolicy => $policy })
        : $self->_request('DELETE', $path));
}

# The propagationPolicy values DeleteOptions takes.
my @PROPAGATION_POLICIES = qw(Background Foreground Orphan);

# Croak unless $policy is undef (none given) or one of @PROPAGATION_POLICIES.
# $label only appears in the message.
sub _propagation_policy_or_croak {
    my ($self, $label, $policy) = @_;
    return $policy if !defined $policy || grep { $_ eq $policy } @PROPAGATION_POLICIES;
    croak "Unknown propagationPolicy '$policy' for $label() (use: "
        . join(', ', @PROPAGATION_POLICIES) . ")";
}

# Croak on the first key of %$args that is not in @allowed, naming it and
# what is allowed, instead of ignoring it. $label only appears in the message.
sub _croak_unknown_args {
    my ($self, $label, $args, @allowed) = @_;
    my %allowed = map { $_ => 1 } @allowed;
    my ($unknown) = sort grep { !$allowed{$_} } keys %$args;
    return unless defined $unknown;
    croak "Unknown argument '$unknown' to $label() (allowed: "
        . join(', ', @allowed) . ")";
}

# Shared hashref handling for ensure() and ensure_only(): turns a manifest into
# a typed object. A manifest's apiVersion is authoritative - with one, the
# class is resolved as that exact group/version/Kind, and an apiVersion no
# class serves croaks instead of falling back to the version the bare Kind
# happens to map to (HorizontalPodAutoscaler alone means autoscaling/v2, a
# different endpoint and schema than an autoscaling/v1 manifest). Without an
# apiVersion the bare Kind resolves as it always did, and a Kind nothing
# resolves croaks naming it, as for every method taking a resource name -
# not with the module loader's "Can't locate IO/K8s/<Kind>.pm" (karr k48).
# Either way the class is resolved here, so it goes to struct_to_object with
# its '+': IO::K8s takes it as that exact class instead of resolving the name
# again (see _exact_class; the class need not be loaded yet, so this does not
# ask it). $label only appears in croak messages.
sub _manifest_to_object {
    my ($self, $label, $manifest) = @_;
    my $kind = $manifest->{kind} or croak "$label: hashref must have 'kind'";
    my $api_version = $manifest->{apiVersion};

    return $self->k8s->struct_to_object('+' . $self->_expand_class_or_croak($kind), $manifest)
        unless defined $api_version && length $api_version;

    my $class = $self->expand_class($kind, $api_version)
        // croak "$label: no IO::K8s class for apiVersion '$api_version', kind '$kind'"
            . " (add it to resource_map if it is a CRD)";
    return $self->k8s->struct_to_object("+$class", $manifest);
}

# The apiVersion and Kind an object is an instance of, for ensure() and
# ensure_only() to tell resources apart by. A typed object answers from its
# class (api_version(), kind()); IO::K8s::Unstructured from its instance data,
# since its class name says nothing about what it holds. The last segment of a
# class name is not enough on its own: a CRD is free to reuse a built-in Kind
# name in its own group.
sub _api_version_and_kind {
    my ($self, $object) = @_;
    my $api_version = ref($object) eq 'IO::K8s::Unstructured' ? $object->apiVersion
                    : $object->can('api_version')           ? $object->api_version
                    : undef;
    my $kind = $object->can('kind') ? $object->kind : undef;
    ($kind = ref $object) =~ s/.*::// unless defined $kind;
    return ($api_version // '', $kind);
}

sub ensure {
    my ($self, $object, @extra) = @_;


    # Nothing after the object is read (karr k58): namespace => ... would not
    # move it, a second object would not be applied.
    croak 'Invalid arguments to ensure(): it takes one object or hashref'
        . ' (ensure_all takes several)'
        if @extra;
    $object = $self->_manifest_to_object('ensure', $object) if ref($object) eq 'HASH';

    my $class = ref($object);
    croak "ensure requires an IO::K8s object or hashref" unless blessed($object);
    my ($api_version, $kind) = $self->_api_version_and_kind($object);
    # The special cases below are the built-in core v1 PersistentVolumeClaim
    # and batch/v1 Job only. The apiVersion is compared exactly, not just its
    # group: the Job branch reads batch/v1's status fields and deletes what it
    # takes for a failed Job, so an apiVersion it was not written for falls
    # through to the plain update, where a mismatch fails loudly instead.
    my $is_pvc = $api_version eq 'v1'       && $kind eq 'PersistentVolumeClaim';
    my $is_job = $api_version eq 'batch/v1' && $kind eq 'Job';
    my $metadata = $object->metadata or croak "object must have metadata";
    my $name = $metadata->name or croak "object must have metadata.name";
    my $namespace = $metadata->namespace;

    my @unstructured_hint = $self->_unstructured_hint($class, $object);
    my $path = $self->_build_path($class, name => $name, namespace => $namespace,
        @unstructured_hint);

    # Every branch below is taken on the status of the response, never on the
    # text of an error: a 500 or 422 whose message merely contains "404" or
    # "409" is a failure, not a missing object or a conflict (karr k44).
    my $existing;
    my $response = $self->_request('GET', $path);
    unless ($response->status == 404) {
        $self->_check_response($response, "ensure get $kind/$name");
        $existing = $self->_inflate_object($class, $response);
    }

    unless ($existing) {
        (undef, $response) = $self->_create_request($object);
        unless ($response->status == 409) {
            $self->_check_response($response, "create $class");
            return $self->_inflate_object($class, $response);
        }
        # 409 AlreadyExists: it appeared between the GET and the POST. From
        # here on it is an existing object like any other, special cases
        # included - a Job must not get a PUT onto its immutable Pod template.
        $response = $self->_request('GET', $path);
        $self->_check_response($response, "ensure post-409 get $kind/$name");
        $existing = $self->_inflate_object($class, $response);
    }

    return $existing if $is_pvc;
    if ($is_job) {
        # Read from TO_JSON, not status(): an IO::K8s::Unstructured Job has
        # no status accessor, its status rides in the unknown-fields bag.
        my $status = $existing->TO_JSON->{status} || {};
        return $existing if $status->{succeeded} || $status->{active};
        # Background, or the failed Job's Pods would be orphaned - the API
        # default for a Job (karr k49) - and the old Job is gone at once, so
        # the create does not run into it.
        eval { $self->delete($existing, propagationPolicy => 'Background') };
        return $self->create($object);
    }
    $object->metadata->resourceVersion($existing->metadata->resourceVersion);
    (undef, $response) = $self->_update_request($object);
    unless ($response->status == 409) {
        $self->_check_response($response, "update $class");
        return $self->_inflate_object($class, $response);
    }
    # 409 Conflict: the resourceVersion moved on server-side. Re-fetch it and
    # retry once; a second conflict croaks.
    $response = $self->_request('GET', $path);
    $self->_check_response($response, "ensure refetch $kind/$name");
    $existing = $self->_inflate_object($class, $response);
    $object->metadata->resourceVersion($existing->metadata->resourceVersion);
    return $self->update($object);
}

sub ensure_all {
    my ($self, @objects) = @_;


    return map { $self->ensure($_) } @objects;
}

sub ensure_only {
    my ($self, %args) = @_;


    # A misspelt option is not ignored, before anything is applied: a
    # propagation_policy typo would prune with Background, a namespace typo
    # scan cluster scope only (karr k53).
    $self->_croak_unknown_args('ensure_only', \%args,
        qw(label objects kinds namespaces propagationPolicy));
    my $label      = $args{label} or croak "ensure_only requires 'label'";
    my @objects    = @{$args{objects} || []};
    my @kinds      = @{$args{kinds} || []};
    my @namespaces = @{$args{namespaces} || [undef]};
    # Background by default, as kubectl delete does: a pruned Job would
    # otherwise orphan its Pods (karr k49). Checked before anything is applied.
    my $propagation = $self->_propagation_policy_or_croak('ensure_only',
        $args{propagationPolicy} // 'Background');

    for my $obj (@objects) {
        $obj = $self->_manifest_to_object('ensure_only', $obj) if ref($obj) eq 'HASH';
    }

    my @results = $self->ensure_all(@objects);

    # (group, Kind, namespace, name), taken from the object on both sides -
    # never from the kinds entry, which may be qualified ('autoscaling/v1/...')
    # and would then match nothing, deleting the objects just applied. Group
    # and Kind come from _api_version_and_kind: class-derived for a typed
    # object, instance data for IO::K8s::Unstructured. The group keeps the same
    # Kind name in two groups apart (Istio's and the Gateway API's Gateway);
    # the core group is ''. No version in the key: the same resource listed
    # through another version's class is still the same resource.
    my $key_of = sub {
        my ($obj) = @_;
        my ($api_version, $kind) = $self->_api_version_and_kind($obj);
        my ($group) = $api_version =~ m{\A(.*)/[^/]*\z};
        my $metadata = $obj->metadata;
        return join("\0", $group // '', $kind, $metadata->namespace // '', $metadata->name);
    };
    my %expected = map { $key_of->($_) => 1 } @objects;

    # A failed list or delete leaves stale objects behind, so it is reported
    # rather than swallowed - but only a real failure: a 404 on the list means
    # the cluster does not serve the Kind, a 404 on the delete that the object
    # is already gone. The status comes from the response, never from the text
    # of an error. The caught croak already names the caller's line, which
    # carp adds again, so the reason drops it.
    my $where = sub {
        my ($ns) = @_;
        return defined $ns ? "in namespace '$ns'" : 'at cluster scope';
    };
    my $reason_of = sub {
        my ($error) = @_;
        $error =~ s/\s+\z//;
        $error =~ s/ at \S+ line \d+\.\z//;
        return $error;
    };

    for my $kind (@kinds) {
        for my $ns (@namespaces) {
            my %list_args = (labelSelector => $label);
            $list_args{namespace} = $ns if defined $ns;
            my $list = eval {
                my ($class, $response) = $self->_list_request($kind, %list_args);
                return if $response->status == 404;
                $self->_check_response($response, "list $kind");
                $self->_inflate_list($class, $response);
            };
            unless ($list) {
                carp "ensure_only: cannot list $kind " . $where->($ns)
                    . ', nothing pruned there: ' . $reason_of->($@)
                    if $@;
                next;
            }
            for my $item (@{$list->items}) {
                next if $expected{ $key_of->($item) };
                next if eval {
                    my ($class, $response) = $self->_delete_request($item,
                        propagationPolicy => $propagation);
                    $response->status == 404
                        || $self->_check_response($response, "delete $class");
                };
                my (undef, $item_kind) = $self->_api_version_and_kind($item);
                carp "ensure_only: cannot delete $item_kind '" . $item->metadata->name
                    . "' " . $where->($item->metadata->namespace)
                    . ': ' . $reason_of->($@);
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
    # A misspelt option is not ignored, before any class is asked for its CRD
    # (karr k61): tiemout => 5 waited the default 30 seconds.
    $self->_croak_unknown_args('ensure_crd', \%opts, qw(timeout poll_interval storage));
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
# and is treated as not-established, not an error. That is read off the status
# of the response, never out of the text of an error: any other failure - a
# 500 whose message merely contains "404" too - ends the wait with that error
# instead of being polled away into a timeout (karr k45).
sub _wait_crd_established {
    my ($self, $crd, %opts) = @_;

    my $class    = ref $crd;
    my $name     = $crd->metadata->name;
    my $path     = $self->_build_path($class, name => $name);
    my $timeout  = defined $opts{timeout}       ? $opts{timeout}       : 30;
    my $interval = defined $opts{poll_interval} ? $opts{poll_interval} : 1;
    my $deadline = Time::HiRes::time() + $timeout;

    while (1) {
        my $response = $self->_request('GET', $path);
        unless ($response->status == 404) {
            $self->_check_response($response, "ensure_crd wait $name");
            my $current = $self->_inflate_object($class, $response);
            return $current if $current && $self->_crd_established($current);
        }
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


    # A misspelt option is not ignored (karr k58): timeoutSeconds ran for the
    # default 300. name is out too: it made the request a GET of one object,
    # which the server answers with the object, not a watch.
    $self->_croak_unknown_args('watch', \%args, qw(on_event timeout
        resourceVersion labelSelector fieldSelector namespace));
    my $on_event = delete $args{on_event}
        or croak "watch requires 'on_event' callback";
    my $timeout          = delete $args{timeout} // 300;
    my $resource_version = delete $args{resourceVersion};
    my $label_selector   = delete $args{labelSelector};
    my $field_selector   = delete $args{fieldSelector};

    my $class = $self->_expand_class_or_croak($short_class);
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
    # A misspelt option is not ignored (karr k53): tail_lines => 10 would
    # fetch the whole log.
    $self->_croak_unknown_args('log', \%args, qw(name namespace container
        follow tailLines sinceSeconds sinceTime timestamps previous limitBytes
        on_line));

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

    my $class = $self->_expand_class_or_croak($short_class);
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
    # A misspelt option is not ignored (karr k61): whatever was not read went
    # on to build_path, which dropped it - on_message never saw a frame.
    $self->_croak_unknown_args('port_forward', \%args, qw(name namespace ports
        subprotocol on_open on_frame on_close on_error));

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

    my $class = $self->_expand_class_or_croak($short_class);
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
    # A misspelt option is not ignored (karr k61): containr => 'app' ran the
    # command in the default container.
    $self->_croak_unknown_args('exec', \%args, qw(name namespace command
        container stdin stdout stderr tty subprotocol on_open on_frame on_close
        on_error));

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

    my $class = $self->_expand_class_or_croak($short_class);
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
    # A misspelt option is not ignored (karr k61): stdn => 1 attached without
    # stdin.
    $self->_croak_unknown_args('attach', \%args, qw(name namespace container
        stdin stdout stderr tty subprotocol on_open on_frame on_close on_error));

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

    my $class = $self->_expand_class_or_croak($short_class);
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

version 1.109

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

When the cluster's discovery cannot be read, the built-in map is used
instead, with a warning that names the reason - at the line of the call that
first needed the map, whether that read C<resource_map> or resolved a name.

Override for custom resources:

    resource_map => {
        %{ IO::K8s->default_resource_map },
        MyResource => '+My::K8s::V1::MyResource',
    }

The C<+> prefix tells L<IO::K8s> that this is a custom class (not in the IO::K8s:: namespace).

The client keeps a copy of the hashref it is given: the Kinds of the L</with>
providers are merged into that copy, never into your hash, and a change you
make to your hash after construction is not seen. Change
C<< $api->resource_map >> itself instead:

    $api->resource_map->{StaticWebSite} = '+My::StaticWebSite';

=head2 expand_class

    my $class = $api->expand_class('Pod');
    # => IO::K8s::Api::Core::V1::Pod

Resolve a short resource name (C<'Pod'>), a domain-qualified name
(C<'cilium.io/v2/NetworkPolicy'>), a C<+>-prefixed or an already
fully-qualified class name to its L<IO::K8s> class - the same contract as
L<IO::K8s/expand_class>, against this client's L</resource_map>.

With L</resource_map_from_cluster> on (the default), a Kind no shipped class,
L</with> provider or AutoGen class resolves becomes L<IO::K8s::Unstructured>
when the cluster's discovery serves it. A bare Kind is looked up in whichever
group serves it, at that group's preferred version. A qualified name
(C<'example.org/v1/Widget'>, or C<('Widget', 'example.org/v1')>) counts only
in exactly that group and version: when the cluster does not serve those, it
stays unresolved (C<undef>), even if another group or another version serves
a Kind of the same name - nothing is ever sent there instead.

The methods that take a resource name - L</list>, L</get>, L</patch>,
L</patch_status>, L</delete>, L</watch>, L</log>, L</port_forward>,
L</exec>, L</attach> and L</compare_schema> - croak on a name that stays
unresolved, before sending anything, and name it:

    unknown resource 'other.org/v1/Widget': no IO::K8s class for this
    apiVersion/kind (add it to resource_map if it is a CRD)

A bare Kind nothing resolves (C<expand_class> answers with the class name
C<IO::K8s::E<lt>KindE<gt>>, which does not exist) is reported the same way.
When the cluster's discovery could not be read, the message goes on to say so
and why - the cluster could not confirm the name, which is not the same as not
serving it.

Pure name resolution does not cost a cluster roundtrip: as long as the
resource map has not been fetched yet (and none was passed to the
constructor), a name the built-in L<IO::K8s> map resolves to a loadable
class is answered from that map directly. Only a name the built-in map
cannot answer falls through to the cluster-backed map, fetching it on first
use exactly as before.

The result is a plain class name, without a C<+>. Handed back to a method
that resolves names again - L<IO::K8s/struct_to_object>,
L<IO::K8s/json_to_object> - a single-segment class of your own (C<'+Gizmo'>
in the resource map, returned as C<'Gizmo'>) reads as the Kind C<Gizmo>
there. Prefix it with C<+> when you do that yourself; this client's own
inflation already does.

=head2 fetch_resource_map

    my $map = $api->fetch_resource_map;

Build the resource map from the cluster's aggregated discovery documents
(C<GET /api> and C<GET /apis>). Returns a hashref mapping short resource names
(e.g., C<Pod>) to full L<IO::K8s> class paths.

Called automatically if C<resource_map_from_cluster> is enabled.

Discovery is fetched and cached once per instance (see L</invalidate_discovery>;
an async client can supply it instead, see L</absorb_discovery>);
calling this again rebuilds the map from the cached catalog rather than
re-querying the cluster. It does B<not> download C</openapi/v2> - that spec is
fetched lazily only when L</schema_for> or L</compare_schema> need it.

When discovery cannot be read, it croaks C<Could not load resource map from
cluster:> followed by the reason - for an HTTP error status the message of
the L<Kubernetes::REST::APIError>,
C<Kubernetes API error (discovery GET /api): 401 ...>.

A cluster older than Kubernetes 1.27 answers with legacy discovery, which
takes one more request per group and version. When one of those answers with
an HTTP error status, that group/version's Kinds are missing from the map,
and a warning names its apiVersion and the error - C<discovery: cannot read
apiVersion 'metrics.k8s.io/v1beta1', its Kinds are missing from the resource
map: Kubernetes API error (discovery GET /apis/metrics.k8s.io/v1beta1): 503
...>; the other groups are read on. A 404 there is silent: the group/version
went away after the list of groups was read.

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

A resource map passed to the constructor is not built from the catalog and
stays as it is, entries such as C<'+My::Class'> included.

=head2 prepare_discovery_requests

    my %requests = $api->prepare_discovery_requests;
    # ('/api' => $request, '/apis' => $request)

Build the two discovery requests - C<GET /api> and C<GET /apis>, with the
C<Accept> header that asks for aggregated discovery (C<APIGroupDiscoveryList>,
C<apidiscovery.k8s.io/v2>) - without sending them. Returns them as path/request
pairs, C</api> first, each a L<Kubernetes::REST::HTTPRequest> as
L</prepare_request> builds it: exactly what the client sends when it reads
discovery through its own L</io>.

This and L</absorb_discovery> are for async wrappers such as
L<Net::Async::Kubernetes>. With L</resource_map_from_cluster> on, the first
name resolution otherwise reads discovery through the synchronous L</io>,
blocking the wrapper's event loop.

=head2 absorb_discovery

    my $absorbed = $api->absorb_discovery(
        '/api'  => $api_response,
        '/apis' => $apis_response,
    );

Take the responses to the requests from L</prepare_discovery_requests> - any
objects with C<status> and C<content> (the undecoded body), such as
L<Kubernetes::REST::HTTPResponse>.

When both are aggregated discovery documents they become this client's
discovery catalog, replacing any it had cached, as if the client had read them
itself, and the method returns true. From then on L</expand_class>,
L</fetch_resource_map>, L</build_path> and the lazily built L</resource_map>
answer from that catalog without sending a request. A resource map built from
an earlier catalog is rebuilt from this one; a map passed to the constructor
stays as it is.

When either is a legacy discovery document - a cluster older than Kubernetes
1.27 ignores the C<Accept> header - it returns false and caches nothing:
reading legacy discovery takes a request per group and version, which only the
synchronous path makes. The client then reads discovery itself when it first
needs it, as it always did.

An HTTP error status dies with a L<Kubernetes::REST::APIError>, as the
client's own discovery read does, its C<context> naming the document:
C<Kubernetes API error (discovery GET /apis): 503 ...>. A missing response,
or any key other than C</api> and C</apis>, croaks.

An async client hands the requests to its own transport and the responses
back - here C<< $send->($request) >> stands for whatever runs a
L<Kubernetes::REST::HTTPRequest> through the event loop and returns a
L<Future> of the response:

    my %requests = $rest->prepare_discovery_requests;
    my @roots    = sort keys %requests;
    my $ready = Future->needs_all(map { $send->($requests{$_}) } @roots)
        ->then(sub {
            my %responses;
            @responses{@roots} = @_;
            # false: legacy discovery, read synchronously on first use
            $rest->absorb_discovery(%responses);
            return Future->done;
        });

=head2 schema_for

    my $schema = $api->schema_for('Pod');

Get the OpenAPI schema definition for a resource type from the cluster. Accepts short names (C<Pod>), full class names (C<IO::K8s::Api::Core::V1::Pod>), or OpenAPI definition names (C<io.k8s.api.core.v1.Pod>).

A name resolves as in L</expand_class>, and the definition is looked up by
the name its class maps onto (C<IO::K8s::Api::Core::V1::Pod> becomes
C<io.k8s.api.core.v1.Pod>), which holds for the C<IO::K8s::Api::> classes.
Where no definition has that name - apiextensions and apiregistration, whose
definitions upstream names after their staging repositories, a CRD class of
your own or from a L</with> provider, L<IO::K8s::Unstructured> - it is the
definition whose C<x-kubernetes-group-version-kind> names the class's API
group, version and Kind: its C<api_version> and C<kind>, or for
L<IO::K8s::Unstructured> the Kind and the group/version the cluster's
discovery confirmed for it.

Returns a hashref with the OpenAPI v2 schema definition, or C<undef> when
there is none - also for a name that resolves to no class at all.

The spec is fetched from C</openapi/v2> on first use and kept. An HTTP error
status there dies with a L<Kubernetes::REST::APIError> whose C<context> is
C<fetch OpenAPI spec>, as does L</compare_schema>; nothing is kept, and the
next call fetches again.

=head2 compare_schema

    my $result = $api->compare_schema('Pod');

Compare the local L<IO::K8s> class definition against the cluster's OpenAPI schema. Useful for detecting version skew between your L<IO::K8s> installation and the cluster.

Returns the comparison result from C<< $class->compare_to_schema >>, the method L<IO::K8s::Role::Resource> provides on every resource class.

A name that resolves to L<IO::K8s::Unstructured> (see L</expand_class>)
croaks, before the spec is fetched: that class declares only C<apiVersion>,
C<kind> and C<metadata> and keeps every other field untyped, so it has no
local schema to compare. L</schema_for> still answers the cluster's
definition for such a name.

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

Passing C<api_version>, C<resource> and C<namespaced> together, as above, resolves the path directly with no discovery lookup - the case for a caller (such as an async wrapper) that already knows the resource's metadata. Otherwise C<kind> is required (C<build_path> croaks without it), and resource/namespaced/apiVersion are looked up in the client's cached discovery catalog instead, preferring the cluster's preferred version unless C<api_version> pins a specific group/version - then only that group/version counts, never another group or version that serves a Kind of the same name; C<build_path> croaks if discovery has no entry for the Kind (in the pinned group/version, which the message then names), and equally if the catalog could not be fetched at all (cluster unreachable, expired token) - in that case the message names that failure rather than claiming a missing entry, and the fallback stays fail-closed either way.

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

Keys and values are percent-encoded where they would otherwise split or
change the query on its way to the API server: C<%>, C<&>, C<+>, C<#>, C<;>,
space, control characters, and non-ASCII characters (as their UTF-8 bytes).
Everything else is sent as written, so a selector such as
C<app.kubernetes.io/name=web,tier!=db> appears in the URL exactly as it was
passed. Pass characters, not bytes - a value that already holds UTF-8 bytes
is encoded twice. A query string that is already part of C<$path> is left
untouched.

This is a public API for async wrappers that execute HTTP requests through their own event loop.

=head2 check_response

    $api->check_response($response, "get Pod");

Validate an HTTP response. Returns the response on success. On a status code
>= 400 it dies with a L<Kubernetes::REST::APIError>, which carries the status
(C<code>, C<is_not_found>, C<is_conflict>), the C<reason>, C<message> and
C<details> of a Kubernetes C<Status> body, the decoded C<body>, the
C<context> and the C<response>. It stringifies to the message this method
croaked with as a plain string before, C<Kubernetes API error (get Pod): 404
...>, naming the line that called C<check_response>. See L</ERROR HANDLING>.

=head2 inflate_object

    my $pod = $api->inflate_object($class, $response);

Decode the JSON response body and inflate it into a typed L<IO::K8s> object.

C<$class> is normally what L</expand_class> resolved and L</build_path>
loaded. A loaded L<IO::K8s> class is inflated as exactly that class - also a
single-segment class of your own, registered as C<'+Gizmo'>, which
L<IO::K8s> would otherwise read as the Kind C<Gizmo>. Any other name, short
or qualified, is resolved first. L</inflate_list> and
L</process_watch_chunk> treat C<$class> the same way.

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

Any other argument croaks before a request is sent, naming it: a misspelt
option is not ignored. That includes C<name>: the list endpoint selects one
object with C<< fieldSelector => 'metadata.name=NAME' >>, and L</get>
fetches it.

=head2 get

    my $pod = $api->get('Pod', name => 'my-pod', namespace => 'default');
    # or shorthand:
    my $pod = $api->get('Pod', 'my-pod', namespace => 'default');

Get a single resource by name. Returns a typed L<IO::K8s> object.

    my $pod = $api->get('Pod', 'my-pod', namespace => 'default',
        subresource => 'status');
    # GET /api/v1/namespaces/default/pods/my-pod/status

Takes C<name>, C<namespace> for namespaced resources, and C<subresource>,
which reads the named subresource of the object instead of the object. The
response is inflated as the resource's own class, which fits a subresource
that answers with the object itself, as C<status> does. Any other argument
croaks before a request is sent, naming it: a misspelt option is not
ignored.

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

Any other argument croaks before a request is sent, naming it: a misspelt
option is not ignored. With an object, which names the resource itself, only
C<patch> and C<type> are taken - C<name> and C<namespace> croak too.

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
forms, the same C<type> values), croaks on any other as L</patch> does, and
returns the full object from the server.
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

    # a Job, and the Pods it created with it:
    $api->delete($job, propagationPolicy => 'Background');
    $api->delete('Job', 'nightly', namespace => 'default',
        propagationPolicy => 'Foreground');

Delete a resource. Returns true on success.

The optional C<propagationPolicy> decides what happens to the objects the
deleted one owns, and is sent as the C<propagationPolicy> query parameter
(a C<DeleteOptions> field):

=over 4

=item C<Background>

The object is deleted at once; the garbage collector deletes its dependents
afterwards.

=item C<Foreground>

The object stays, with a C<deletionTimestamp>, until its dependents are
deleted.

=item C<Orphan>

The dependents are kept and lose their owner reference.

=back

Without it the server applies the resource's default - for a C<batch/v1>
C<Job> that is C<Orphan>, which leaves its Pods behind. Any other value
croaks, listing the three.

Any argument other than C<name>, C<namespace> and C<propagationPolicy> -
with an object, other than C<propagationPolicy> - croaks before anything is
sent, naming it: a misspelt option is not ignored.

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

A hashref's C<apiVersion>, when present, selects the class: an
C<autoscaling/v1> HorizontalPodAutoscaler stays C<autoscaling/v1> and goes to
that endpoint, although the bare Kind resolves to C<autoscaling/v2>. An
C<apiVersion> that resolves to no known class croaks, naming the Kind and the
C<apiVersion>, instead of falling back to the Kind's default version. A
hashref without C<apiVersion> resolves by its Kind alone, as L</expand_class>
does; a Kind that resolves to nothing croaks naming it
(C<unknown resource 'Kind'>, as described under L</expand_class>) before any
request is sent.

Handles common race conditions:

=over 4

=item * 404 on initial get is treated as "does not exist" and falls through to create.

=item * 409 AlreadyExists on create (resource appeared between get and create) is
re-fetched and handled like a resource that existed from the start: updated,
or - for the special cases below - returned unchanged or recreated.

=item * 409 Conflict on update (resourceVersion changed server-side, e.g. a
controller wrote status) is retried by re-fetching and re-applying.

=back

Each case is recognised by the response status. Any other error status
croaks with the API error, whatever its message happens to say.

Special-cases for kinds with server-side mutation constraints:

=over 4

=item * C<PersistentVolumeClaim> (core C<v1>) - spec is immutable after
creation, so an existing PVC is returned unchanged.

=item * C<Job> (C<batch/v1>) - spec is immutable; an existing Job that is
active or has succeeded is returned unchanged. A failed Job is deleted with
C<propagationPolicy> C<Background>, so its Pods go with it, and recreated.

=back

Both are recognised by apiVersion and Kind together: a typed object's
C<api_version> and C<kind>, or an L<IO::K8s::Unstructured> object's
C<apiVersion> and C<kind> fields - never by the class name. A custom resource
that reuses one of these Kind names in its own group is ensured like any other
object, and so is a C<Job> under any apiVersion other than C<batch/v1>.

It takes exactly one object or hashref. Anything after it croaks before a
request is sent - an option is not ignored, and a second object is not
applied silently or dropped; L</ensure_all> takes several.

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

C<objects> takes typed objects or hashrefs, resolved as in L</ensure>. A
C<kinds> entry may be a bare Kind or a qualified C<group/version/Kind> (see
L</expand_class>). A listed resource counts as present when its API group,
Kind, namespace and name match an object in C<objects> - group and Kind come
from a typed object's C<api_version> and C<kind>, or from an
L<IO::K8s::Unstructured> object's C<apiVersion> and C<kind> fields. The
same Kind name in another group is another resource: with Istio's
C<networking.istio.io> Gateway in C<objects>, a labelled Gateway API
C<gateway.networking.k8s.io> Gateway of the same name is deleted. The version
is not compared, so an object applied as C<autoscaling/v1> is kept when the
listing goes through C<autoscaling/v2>.

Pruning goes on past a failure, and says so. When a C<kinds> entry cannot be
listed in one namespace - an HTTP error, or an entry that resolves to no
class - that combination is skipped with a warning naming the entry, the
namespace (or cluster scope) and the reason; anything stale there survives
this run. A 404 is silent: the cluster does not serve that Kind, so there is
nothing to prune. A delete that fails warns with the Kind, name, namespace and
reason, and the next object is tried; a 404 there means the object is already
gone and is silent too. Promote the warnings to a fatal error with
C<< local $SIG{__WARN__} = sub { die @_ } >> if a partial prune is
unacceptable to you.

Pruned objects are deleted with C<propagationPolicy> C<Background> (see
L</delete>), as C<kubectl delete> does, so a pruned Job takes its Pods with
it. Pass C<< propagationPolicy => 'Foreground' >> or C<'Orphan'> to change
that; any other value croaks before anything is applied.

Returns the list of applied objects (from L</ensure_all>), whether or not the
pruning was complete.

Any argument other than C<label>, C<objects>, C<kinds>, C<namespaces> and
C<propagationPolicy> croaks before anything is applied, naming it: a
misspelt option is not ignored.

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
A 404 while polling counts as not registered yet and is polled again; any
other error status ends the wait at once and croaks with that API error.

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

Any other option croaks before anything is applied, naming it: a misspelt
option is not ignored.

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

Any other argument croaks before a request is sent, naming it: a misspelt
option is not ignored. That includes C<name>: to watch one object, pass
C<< fieldSelector => 'metadata.name=NAME' >>.

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

That croak is a plain string, not a L<Kubernetes::REST::APIError>: the watch
request itself was answered with C<200>, and the C<410> arrived inside the
stream as an C<ERROR> event, which C<on_event> has already been given. It
calls for a re-list, not error handling. An HTTP error status on the watch
request itself dies with an L<Kubernetes::REST::APIError> as usual.

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
restart), and C<limitBytes> (byte cap on the response). Any other argument
croaks before the request is sent, naming it: a misspelt option is not
ignored.

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
backend. Any other argument croaks before a request is sent, naming it: a
misspelt option is not ignored.

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
C<on_frame>, C<on_close>, C<on_error>, passed through to the IO backend. Any
other argument croaks before a request is sent, naming it: a misspelt option
is not ignored.

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
C<on_frame>, C<on_close>, C<on_error>, passed through to the IO backend. Any
other argument croaks before a request is sent, naming it: a misspelt option
is not ignored.

This method requires an IO backend that implements C<call_duplex>. The default
L<Kubernetes::REST::LWPIO> and L<Kubernetes::REST::HTTPTinyIO> backends do not
currently provide duplex transport.

Returns whatever the IO backend returns for C<call_duplex> (typically a
session/handle object managed by that backend).

=head1 ERROR HANDLING

When the API server answers with an HTTP error status (400 and up), the call
dies with a L<Kubernetes::REST::APIError>. It stringifies to the familiar
message - C<Kubernetes API error (get Pod): 404 {...} at app.pl line 12.> -
so printing C<$@> or matching it against a regex works as it always did, and
it carries the status for code that has to tell cases apart:

    my $ok = eval { $api->delete('Pod', 'web', namespace => 'default'); 1 };
    unless ($ok) {
        my $err = $@;
        die $err unless ref $err && $err->isa('Kubernetes::REST::APIError')
            && $err->is_not_found;    # already gone is fine
    }

Besides C<code>, C<is_not_found> and C<is_conflict> it has the C<reason>,
C<message> and C<details> of the Kubernetes C<Status> body, the decoded
C<body>, the C<context> and the C<response>.

That includes the C</openapi/v2> fetch behind C<schema_for> and
C<compare_schema>, and the discovery documents (C<GET /api>, C<GET /apis>,
context C<discovery GET /api>), which L</absorb_discovery> dies with
directly. Where the client reads discovery for itself, a failure shows
inside another message instead - the warning that the resource map falls
back to the built-in one, the croak of L</fetch_resource_map>, the croak for
a name discovery could not confirm, the warning for a legacy group/version
it could not read (see L</fetch_resource_map>) - which embeds the error's
text.

Everything else croaks with a plain string: invalid arguments, a resource
name nothing resolves, and an expired watch - its C<410> arrives as an
C<ERROR> event in a stream the server answered with C<200>, not as an HTTP
status (see L</watch>).

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

=item * C<check_response($response, $context)> - Validate HTTP status (dies
with a L<Kubernetes::REST::APIError> on 400 and up)

=item * C<inflate_object($class, $response)> - JSON to typed object

=item * C<inflate_list($class, $response)> - JSON to typed list (an item the
object model rejects is dropped and carped about, not silently lost - see
L</inflate_list>)

=item * C<process_watch_chunk($class, \$buf, $chunk)> - Parse NDJSON watch stream

=item * C<process_log_chunk(\$buf, $chunk)> - Parse plain-text log stream

=item * C<prepare_discovery_requests> and C<absorb_discovery(%responses)> -
Read the cluster's discovery through your own event loop, so that resolving
names needs no request of the client's own (see L</absorb_discovery>)

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

=item * L<Kubernetes::REST::APIError> - Error thrown for an HTTP error status

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
