package IO::K8s::AutoGen;
# ABSTRACT: Dynamically generate IO::K8s classes from OpenAPI schema
our $VERSION = '1.109';
use v5.10;
use strict;
use warnings;
use Carp qw(croak);
use Digest::SHA qw( sha1_hex );
use Module::Runtime qw( use_module );
use Package::Stash;
use Scalar::Util qw(blessed reftype refaddr looks_like_number);
use Types::Standard qw( Bool HashRef Int Num Str );
# Type::Tiny object for the [IntOrStr] array items (k167); see the array
# branch of _schema_to_type_spec for why a bareword does not do. [Time]
# items go through $GENERATED_TIME instead (k178), so Time is not imported.
# Opaque is the free map a schemaless object becomes (k191).
use IO::K8s::Types qw( IntOrStr Opaque );
# The empty list matters: IO::K8s::APIObject's import would make this
# package a Moo class. Loaded for its subresources check (k158).
use IO::K8s::APIObject ();
our @CARP_NOT = ('IO::K8s');  # errors via an openapi_spec instance name its caller (k175)

# Cache of generated classes -- only classes whose generation run completed
# (see "Generation runs" below). generated_classes() lists exactly these.
my %_generated;

# ---------------------------------------------------------------------------
# Generation runs (k149)
#
# A root get_or_generate call is one small transaction, a "run". Every class
# first begun during it -- the root, each $ref'd definition generated on the
# way, each nested class -- stays pending until the whole run, identity
# methods and roles included, has succeeded; only then do they all become
# complete together. A class is marked begun early, before its own fields
# exist, because a recursive type (A.child => A, A => B => A) must be able to
# name it; a pending class is only ever handed back to that same run's
# recursion, never as a public cache hit.
#
# If the run dies, every class it began is recorded as failed, keyed by
# class name (so per namespace), with the run's original error -- including
# a dependency whose own fields finished cleanly, since it may well point
# back at the class that died. Nothing is rolled back: the packages, the Moo
# internals and the attribute registry keep whatever the run built. Any
# later request that would hand out one of those classes, directly or as a
# dependency, rethrows that original error instead. Classes that were
# already complete before the run are untouched. The failure record is never
# cleared, not even by clear_cache(), which would otherwise revive a
# half-built package; a repaired schema is generated into a fresh namespace
# (a fresh IO::K8s instance gets one).
# ---------------------------------------------------------------------------

# class name -> the original error of the run that began it and died
my %_failed;

# The classes begun by the generation run in progress, as a { $class => 1 }
# hashref; undef between runs. Only _in_generation_run sets or clears it.
my $_run;

# Perl's own limit on a fully qualified identifier is 251 characters. A
# path-derived nested class name (see _nested_class below) is kept while it
# fits under this, lower threshold -- the headroom accounts for a
# '::_Spec'-style segment a caller might append to an already-long name, and
# for the shortened '::_<hash>' form itself, which must never in turn need
# shortening.
my $MAX_CLASS_NAME = 200;

# Class-level schema description, keyed by generated class name. AutoGen
# itself never reads this -- it exists for IO::K8s::CRD::Emitter, which has
# no other way to recover a schema's `description` once the class is built
# (the k8s DSL only records per-field descriptions, not one for the class
# as a whole).
my %_descriptions;

# Default namespace for auto-generated classes
our $DEFAULT_NAMESPACE = 'IO::K8s::_AUTOGEN';

# Sanitize one or more strings into safe Perl package-name segments: every
# character outside [A-Za-z0-9_] becomes '_', and a segment that would
# start with a digit gets a leading '_' (a bareword identifier can't start
# with one). Each argument becomes exactly one output segment -- splitting
# a def_name or an api_version into segments is the caller's job (see
# def_to_class and _class_name_for below); _class_segment passes a whole
# JSON key through as a single segment on purpose, since a key containing
# '.' or '/' is one field name, not a request for sub-packages.
#
# A hyphenated API group ('cert-manager.io') is the case this exists for:
# left alone, 'acme.cert-manager.io' becomes the package segment
# 'cert-manager', which Perl parses as a subtraction ('cert' MINUS
# 'manager'), not an identifier -- def_to_class died building the package,
# not on anything IO::K8s::CRD did wrong.
sub _class_segments {
    return map {
        my $s = $_;
        $s =~ s/[^A-Za-z0-9_]/_/g;
        $s = "_$s" if $s =~ /^[0-9]/;
        $s;
    } @_;
}

# Convert OpenAPI definition name to Perl class name
# With namespace 'MyProject::K8s':
#   helm.cattle.io.v1.HelmChart -> MyProject::K8s::helm::cattle::io::v1::HelmChart
sub def_to_class {
    my ($def_name, $namespace) = @_;
    $namespace //= $DEFAULT_NAMESPACE;
    return join('::', $namespace, _class_segments(split /\./, $def_name));
}

# Convert Perl class name back to OpenAPI definition name. Lossy on
# purpose: def_to_class/_class_segments sanitize each package segment (a
# hyphen becomes '_', among other substitutions), and that cannot be
# undone here. Used only for diagnostics and to build a nested class's
# synthetic def_name (_nested_class) -- never to look a definition back up
# in $all_defs.
sub class_to_def {
    my ($class) = @_;
    # Strip any _AUTOGEN namespace prefix
    $class =~ s/^IO::K8s::_AUTOGEN_[^:]+:://;
    $class =~ s/^IO::K8s::_AUTOGEN:://;
    $class =~ s/::/./g;
    return $class;
}

# Check if a class was auto-generated
sub is_autogen {
    my ($class) = @_;
    return $class =~ /^IO::K8s::_AUTOGEN/;
}

# Get or generate a class from schema
# Options hash can include:
#   api_version      => 'stable.example.com/v1'
#   kind             => 'StaticWebSite'
#   resource_plural  => 'staticwebsites'
#   is_namespaced    => 1
#   subresources     => { status => {}, scale => {...} } -- a CRD
#                      version's subresources, installed as the fixed
#                      identity method `subresources` on a top-level class
#                      (k158); checked like the IO::K8s::APIObject import
#                      parameter, before the class is begun.
#   reuse_core       => 0|1 (default 1) -- type a nested object/items/
#                      additionalProperties schema as a shipped core class
#                      instead of a nested class when its shape matches
#                      one (D5); see _core_class_for.
#   reuse_core_except => { 'Spec::Foo' => 1, ... } -- with reuse_core on,
#                      the logical nested-class paths (root-relative,
#                      class_path's key space) at which reuse is suppressed
#                      so a provider's own named type is generated even
#                      though its shape matches a core class (k120).
sub get_or_generate {
    my ($def_name, $schema, $all_defs, $namespace, %opts) = @_;

    my $class = _class_name_for($def_name, $schema, $namespace, $opts{api_version});
    return $class if _class_usable($class);

    _in_generation_run(sub {
        _generate_class($class, $def_name, $schema, $all_defs, $namespace, %opts);
    });
    return $class;
}

# Run $code as a generation run (see "Generation runs" above). A request made
# while a run is already in progress -- a $ref reached from inside the
# property loop -- joins that run instead of opening its own, so the root
# call's run is the one unit that commits or fails.
sub _in_generation_run {
    my ($code) = @_;
    return $code->() if $_run;

    $_run = {};
    my $ok  = eval { $code->(); 1 };
    my $err = $@ || 'IO::K8s::AutoGen: class generation died without an error message';
    my @begun = keys %$_run;
    undef $_run;

    if ($ok) {
        $_generated{$_} = 1 for @begun;
        return;
    }
    $_failed{$_} = $err for @begun;
    die $err;  # rethrow unchanged: croak would restamp it with our caller
}

# Rethrow the original error of the failed run that began $class, if any.
# The first failure reaches the caller unchanged (_in_generation_run); a
# later request gets it again behind a prefix saying it is a remembered
# failure -- otherwise a dependency asked for directly would die naming
# another class's field and the first call's line. The original message is
# kept whole. An exception object is rethrown as it is, never stringified.
sub _rethrow_failed {
    my ($class) = @_;
    return unless exists $_failed{$class};
    my $err = $_failed{$class};
    die $err if ref $err;
    chomp $err;
    croak 'IO::K8s::AutoGen: '.$class.' failed to generate earlier in this namespace '
        .'and stays failed; load a repaired schema into a fresh IO::K8s instance. '
        .'Original error: '.$err;
}

# True when $class can be handed out as it is: complete, or begun earlier in
# the run in progress (recursion). Rethrows instead when its run failed.
sub _class_usable {
    my ($class) = @_;
    _rethrow_failed($class);
    return $_generated{$class} || ($_run && $_run->{$class});
}

# Class identity for a definition. A definition whose
# x-kubernetes-group-version-kind lists several entries serves more than
# one apiVersion from one schema; requesting one of them must produce a
# package specific to that GVK, otherwise the second version would silently
# reuse the first version's class (and its api_version method). The
# versionless generation keeps the plain def_to_class name as the
# deterministic compatibility default.
sub _class_name_for {
    my ($def_name, $schema, $namespace, $api_version) = @_;
    my $class = def_to_class($def_name, $namespace);
    return $class unless defined $api_version;

    my $gvk = $schema->{'x-kubernetes-group-version-kind'};
    return $class unless ref($gvk) eq 'ARRAY' && @$gvk > 1;

    # / and . are not valid in a package name, and every segment must be a
    # bare identifier; map group/version to sanitized ::-separated segments
    # the same way def_to_class maps def_names (see _class_segments) -- a
    # hyphenated group in the api_version needs the same treatment here.
    my @segments = _class_segments(split m{[./]}, $api_version);
    return "${class}::" . join('::', @segments);
}

# Wire apiVersion a GVK entry represents: group/version, or bare version
# when the group is empty (core group).
sub _gvk_api_version {
    my ($entry) = @_;
    my $group = $entry->{group} // '';
    my $version = $entry->{version} // '';
    return $group ? "$group/$version" : $version;
}

# Deterministic ordering key for a GVK entry.
sub _gvk_sort_key {
    my ($entry) = @_;
    return join '/',
        ($entry->{group} // ''),
        ($entry->{version} // ''),
        ($entry->{kind} // '');
}

# Pick the GVK entry a class should be built from.
#
# With an $api_version the request is exact: the entry whose group/version
# matches is returned; several matches are an ambiguity error, none is a
# fail-closed error. It never silently takes the first entry.
#
# Without an $api_version the entries are sorted and the first is returned
# -- deterministic regardless of array order.
sub _select_gvk_entry {
    my ($gvk, $api_version, $def_name) = @_;

    return $gvk unless ref($gvk) eq 'ARRAY';

    if (defined $api_version) {
        my @matches = grep { _gvk_api_version($_) eq $api_version } @$gvk;
        if (@matches > 1) {
            croak "GVK ambiguity in definition '$def_name': "
                . scalar(@matches)
                . " x-kubernetes-group-version-kind entries match api_version '$api_version'";
        }
        if (@matches == 1) {
            return $matches[0];
        }
        croak "No x-kubernetes-group-version-kind entry in definition '$def_name' "
            . "matches api_version '$api_version'";
    }

    return (sort { _gvk_sort_key($a) cmp _gvk_sort_key($b) } @$gvk)[0];
}

# Generate a class from OpenAPI schema using IO::K8s::Resource
sub _generate_class {
    my ($class, $def_name, $schema, $all_defs, $namespace, %opts) = @_;

    # Determine api_version/kind from schema or explicit options. This has
    # to happen before the class is marked begun: a fail-closed error here
    # (ambiguous or non-matching api_version) builds nothing, so it must not
    # record the class as failed either -- a retry with a matching
    # api_version resolves to the same class name and has to work.
    my ($api_ver, $kind_val, $res_plural, $is_namespaced);
    if (my $gvk = $schema->{'x-kubernetes-group-version-kind'}) {
        my $entry = _select_gvk_entry($gvk, $opts{api_version}, $def_name);
        my $group = $entry->{group} // '';
        my $version = $entry->{version} // '';
        $kind_val = $entry->{kind} // '';
        $api_ver = $group ? "$group/$version" : $version;
    }

    # Explicit options override schema-derived values. Hoisted above the
    # property loop because whether this class ends up with GVK class
    # methods decides which properties must not become attributes.
    $api_ver       = $opts{api_version}     if exists $opts{api_version};
    $kind_val      = $opts{kind}            if exists $opts{kind};
    $res_plural    = $opts{resource_plural} if exists $opts{resource_plural};
    $is_namespaced = $opts{is_namespaced}   if exists $opts{is_namespaced};

    # A CRD version's subresources (k158), checked here for the same reason
    # as the GVK selection above: a malformed section builds nothing and
    # marks nothing failed, so the repaired manifest works on a retry.
    my $subresources;
    $subresources = IO::K8s::APIObject::_checked_subresources($class, $opts{subresources})
        if exists $opts{subresources};

    return if _class_usable($class);
    croak "IO::K8s::AutoGen: $class generated outside a generation run" unless $_run;
    $_run->{$class} = 1;  # Mark begun early to allow recursion; pending until the run commits
    $_descriptions{$class} = $schema->{description} if defined $schema->{description};

    # Ensure parent packages exist
    _ensure_package_exists($class);

    # Set up the class using IO::K8s::Resource's shared setup method
    {
        no strict 'refs';
        @{"${class}::ISA"} = ();
    }

    require IO::K8s::Resource;
    IO::K8s::Resource->_setup_class($class);

    # Get the k8s function for this class
    my $k8s = $class->can('k8s')
        or croak "Failed to set up k8s DSL for $class";

    # A top-level class -- one with a GVK -- gets its identity methods and
    # IO::K8s::Role::APIObject (and with it IO::K8s::Role::SpecBuilder)
    # BEFORE any property is declared: the order `use IO::K8s::APIObject`
    # gives a hand-written class (k150). The other way round, Role::Tiny's
    # "class wins" let a property whose accessor has the name of a role
    # method (label, save, is_ready, spec_get, ...) silently replace that
    # method. Now the k144 declaration preflight in IO::K8s::Resource sees
    # the role method and refuses the property, naming the class, the
    # property and the method, which fails the whole generation run (k149).
    # There is no renaming: the property would have to change its accessor
    # name, and with it what the class looks like, to get past a clash its
    # schema cannot know about. conditions keeps its k144 exception -- the
    # role helper yields to a declared field of that name.
    #
    # The identity methods still go in before the role, so the role sees
    # them and does not install its own class-name-derived api_version, kind
    # and resource_plural -- the same reason IO::K8s::APIObject::import
    # installs a CRD's before it composes the role.
    my $is_top = defined $api_ver && defined $kind_val;
    if ($is_top) {
        my $stash = Package::Stash->new($class);

        # These are fixed identity methods, not writable fields. A caller
        # passing an argument believes they retargeted the object; fail closed
        # rather than swallow the write (k67, the house line of k37/k39).
        $stash->add_symbol('&api_version', sub {
            croak 'api_version is fixed for this class and cannot be set' if @_ > 1;
            $api_ver;
        });
        $stash->add_symbol('&kind', sub {
            croak 'kind is fixed for this class and cannot be set' if @_ > 1;
            $kind_val;
        });
        $stash->add_symbol('&resource_plural', sub {
            croak 'resource_plural is fixed for this class and cannot be set' if @_ > 1;
            $res_plural;
        });
        # The same identity method `use IO::K8s::APIObject subresources =>`
        # installs, so to_crd writes them back (k112 symmetry, k158).
        IO::K8s::APIObject::_install_subresources($class, $subresources)
            if $subresources;

        # Apply Role::APIObject for metadata, to_yaml, save, etc.
        require Moo::Role;
        require IO::K8s::Role::APIObject;
        Moo::Role->apply_roles_to_package($class, 'IO::K8s::Role::APIObject');

        # Register the role's metadata attribute so _inflate_struct knows the
        # type -- adopted, the same way IO::K8s::APIObject::import does it
        # for hand-written classes (k144)
        IO::K8s::Resource->_k8s_adopt($class, 'metadata', 'Meta::V1::ObjectMeta');

        # Apply Namespaced role if requested or schema suggests it
        if ($is_namespaced) {
            require IO::K8s::Role::Namespaced;
            Moo::Role->apply_roles_to_package($class, 'IO::K8s::Role::Namespaced');
        }
    }

    my $properties = $schema->{properties} // {};

    # The block above gave a top-level class apiVersion, kind and metadata
    # -- exactly the three properties IO::K8s::Role::Resource::compare_to_schema
    # already excuses a top-level object for not declaring, and the line
    # k45 drew for the hand-written template classes. A schema that lists
    # them as properties as well is skipped for each of them:
    #
    #   kind:       the fixed identity method is already there, so the k144
    #               preflight would refuse the property as a collision. Back
    #               when properties came first, the identity method was
    #               installed over the generated accessor afterwards and
    #               $obj->kind('Other') was a silent no-op (k60).
    #   apiVersion: no method of that name, which is worse -- it would become
    #               a writable attribute and TO_JSON would emit it over the
    #               apiVersion the class actually is.
    #   metadata:   the role's own attribute, adopted above; declaring it
    #               again from the schema could only conflict with that, and
    #               would generate a throwaway ObjectMeta class on the way. It is
    #               skipped here so that a schema referencing the standard
    #               ObjectMeta without carrying its definition (a very common
    #               way to hand in a single CRD schema) does not trip the
    #               unresolved-$ref refusal below over a field the role
    #               supplies anyway.
    my %role_supplied = $is_top ? (apiVersion => 1, kind => 1, metadata => 1) : ();

    # D5: reuse a shipped core class for a nested object/items/
    # additionalProperties schema of exactly its shape, default on.
    my $reuse_core = exists $opts{reuse_core} ? ($opts{reuse_core} ? 1 : 0) : 1;

    # k120: a set of logical nested-class paths (root-relative,
    # '::'-joined -- the same key space class_path/the render overlay use)
    # at which core reuse is suppressed even with reuse_core on, so a
    # provider's own named type is generated where its shape happens to
    # match a core class (PrometheusOperator's Argument matches
    # Core::V1::HTTPHeader). Empty/absent -> reuse behaves exactly as before.
    my $reuse_core_except = $opts{reuse_core_except} || {};

    # Generate attributes using k8s DSL
    # Property names with special characters ($ref, x-kubernetes-*) are
    # automatically sanitized to valid Perl identifiers by _k8s(), with
    # init_arg mapping so constructors still accept the original JSON keys.
    my %required = map { $_ => 1 } @{ $schema->{required} // [] };
    for my $prop (sort keys %$properties) {
        next if $role_supplied{$prop};
        my $prop_schema = $properties->{$prop};
        my $type_spec = _schema_to_type_spec($prop_schema, $all_defs, $namespace, $prop, $class, $reuse_core, $reuse_core_except);
        next unless defined $type_spec;  # Skip unsupported types

        my $opts = _field_options($prop_schema, $type_spec, $required{$prop});
        $k8s->($prop, $type_spec, ($opts ? $opts : ()));
    }

    return $class;
}

# Opaque type definitions that should be the free map (Opaque), not object
# references
my %OPAQUE_TYPES = map { $_ => 1 } qw(
    io.k8s.apimachinery.pkg.apis.meta.v1.FieldsV1
    io.k8s.apimachinery.pkg.runtime.RawExtension
);

# The apiextensions union types (k152). Upstream's swagger.json describes
# each of them with a description and nothing else, since none is a JSON
# object: v1.JSON is any JSON value, JSONSchemaPropsOrArray a schema or an
# array of schemas, JSONSchemaPropsOrBool a schema or a boolean,
# JSONSchemaPropsOrStringArray a schema or a string array. Generated from
# such a definition, a class has no fields and no FROM_STRUCT and cannot
# hold `default: "foo"`. IO::K8s ships a hand-written class for each of the
# four, inflated through FROM_STRUCT, and a $ref to one of the names is
# typed as that class -- by name, whether the spec carries the definition
# or not, like the apimachinery scalars and %OPAQUE_TYPES above. reuse_core
# has no say: this is the type itself, not a shape that happens to match.
#
# IO::K8s ships no v1beta1 apiextensions classes. The v1beta1 names -- in a
# spec from a cluster older than 1.22, which removed that API -- are carried
# by the v1 JSON class instead, which holds any JSON value as it came and
# writes it back unchanged: opaque, never a field-less class that loses the
# value.
my $APIEXT_DEF   = 'io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.';
my $APIEXT_CLASS = 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::';
my %UNION_TYPES  = map {
    ( $APIEXT_DEF.'v1.'.$_      => $APIEXT_CLASS.$_,
      $APIEXT_DEF.'v1beta1.'.$_ => $APIEXT_CLASS.'JSON' )
} qw( JSON JSONSchemaPropsOrArray JSONSchemaPropsOrBool JSONSchemaPropsOrStringArray );

# The shipped class a union $ref stands for, loaded, or nothing.
sub _union_class {
    my ($ref) = @_;
    my $class = $UNION_TYPES{$ref} or return;
    return use_module($class);
}

# A $ref pointing at a definition the caller never supplied.
#
# Refusing is the fail-closed choice (k56). The property used to be
# skipped outright: the generated class simply had no such attribute, Moo
# dropped the constructor argument for it without a word, and TO_JSON never
# emitted the data again -- an inflate/serialize round-trip that quietly
# lost whatever sat under that key.
#
# The alternative considered was an opaque { Str => 1 } attribute. It was
# rejected for two reasons. It cannot be applied at all three call sites:
# the k8s DSL has no array-of-hash form, so `items: { $ref: <missing> }`
# would have to become ArrayRef[Str] and then reject the very hashrefs the
# field carries -- the k57 failure, reintroduced. And it guesses a
# shape: a missing definition may just as well be a string or array alias,
# in which case the Maybe[HashRef] attribute fails its type constraint
# without ever naming the unresolved $ref that caused it. %OPAQUE_TYPES
# above is a decision taken per named type, not a default for anything
# unresolvable.
sub _croak_unresolved_ref {
    my ($ref, $where) = @_;
    croak "Cannot resolve the \$ref '$ref' for $where: no such definition in "
        . "the OpenAPI spec. Supply the definition or drop the property -- "
        . "generating the class without it would silently drop that field on "
        . "every round-trip";
}

# The class segment for a nested class: the whole JSON key sanitized into
# one package-identifier segment (see _class_segments above), then
# ucfirst'd. `x-extra` -> `X_extra`, `$ref` -> `_ref`, `x.y/z` -> `X_y_z`
# -- unlike def_to_class/_class_name_for the key is never split on '.' or
# '/' first: it is one field name, not a request for sub-packages, and a
# key containing either used to reach package creation unsanitized and die
# there with a message that named neither the field nor the class.
sub _class_segment {
    my ($json_key) = @_;
    return ucfirst((_class_segments($json_key))[0]);
}

# The field name that generated a given nested class name. Needed to fail
# closed on a name collision: two schema keys can sanitize + ucfirst to the
# same class segment -- an array-of-objects field `routes` (its items get
# an `Item` suffix) and a sibling plain-object field `routesItem` both
# produce `...::RoutesItem`; so would a `weights` map (`Value` suffix)
# alongside a sibling `weightsValue`, or `x-extra` next to `x_extra`, or
# `Foo` next to `foo`. The class name already encodes the suffix, so the
# bare field name is enough to tell two different owners apart -- and it
# has to be the bare name, not "$field_name$suffix", because that compound
# form is itself ambiguous: `routes` + the `Item` suffix and the plain
# field `routesItem` concatenate to the identical string, which would defeat
# the very check meant to catch that exact pair. Without this, the `unless
# ($_generated{$class})` guard below would silently keep the FIRST field's
# class for the SECOND -- the second field ends up typed as the first
# field's class, and inflating real data for it drops the field on every
# round-trip in the default non-strict mode. Never generate a class that
# silently drops a field -- the same rule _croak_unresolved_ref enforces for
# an unresolved $ref (k56), reached here from a name collision instead.
#
# Keyed on the FULL logical name (root + the whole '::'-joined path below
# it), never on a class's own (possibly hash-shortened) Perl name: two
# different long paths must never be treated as "the same nested class"
# just because a name collision detector happened to look at the shortened
# form, which -- being a 40-bit truncated hash -- is a much smaller space
# than the paths it stands in for.
my %_nested_origin;

# Every nested class AutoGen has generated, keyed by its actual (possibly
# shortened) Perl class name:
#   %_root_of   -> the top-level generated class (the Kind class) the
#                  nesting started from. A root has no entry here;
#                  class_root() falls back to the class itself.
#   %_class_path -> the '::'-joined path below that root
#                  ('Spec::Acme::SolversItem::...'), recorded regardless of
#                  whether the class name itself had to be shortened. A
#                  root, or a class AutoGen did not generate as nested, has
#                  no entry; class_path() returns undef for those.
my %_root_of;
my %_class_path;

# The Perl class name for a nested class at logical path $path below $root:
# the path-derived name (identical to what pre-1.109 AutoGen always used)
# while it fits under $MAX_CLASS_NAME, otherwise <root>::_<10 hex chars>
# from a SHA-1 of the full logical name -- deterministic, so the same
# (root, path) always yields the same class, and short enough that it can
# never itself need shortening (root plus a fixed 13-character suffix).
sub _class_for_path {
    my ($root, $path) = @_;
    my $logical_name = "$root\::$path";
    return $logical_name if length($logical_name) <= $MAX_CLASS_NAME;
    return $root . '::_' . substr(sha1_hex($logical_name), 0, 10);
}

# An inline `type: object` with its own properties becomes a nested class
# named after its place in the parent -- <Parent>::<Prop>, plus an Item /
# Value suffix for array items and map values -- generated in the parent's
# namespace and cached like every other generated class. Before 1.108 such
# an object was an opaque hash, so a CRD's spec, which every CRD schema
# inlines, carried no typing below the top level (k94). Hash-style access on
# the result keeps working: a Moo object is a blessed hash keyed by
# attribute name. Property-less objects and additionalProperties-only maps
# are not touched here; they stay opaque (k55).
#
# A schema nested deep enough (cert-manager's CRDs inline a full
# PodTemplateSpec under a solver, itself several levels into a Challenge)
# makes the path-derived name run past Perl's 251-character identifier
# limit; see $MAX_CLASS_NAME and _class_for_path above.
#
# $reuse_core carries forward unchanged (D5): a schema only reaches here
# because its own shape did NOT match a shipped core class, but its
# properties still get the same reuse_core treatment when this new class's
# own fields are, in turn, typed.
sub _nested_class {
    my ($parent_class, $field_name, $suffix, $schema, $all_defs, $namespace, $reuse_core, $reuse_core_except) = @_;
    $reuse_core = 1 unless defined $reuse_core;

    my $root = $_root_of{$parent_class} // $parent_class;
    my $parent_path = $_class_path{$parent_class};
    my $segment = _class_segment($field_name) . ($suffix // '');
    my $path = defined($parent_path) ? "$parent_path\::$segment" : $segment;
    my $logical_name = "$root\::$path";

    if (exists $_nested_origin{$logical_name}) {
        my $existing = $_nested_origin{$logical_name};
        if ($existing ne $field_name) {
            croak "Cannot generate a nested class for field '$field_name' of $parent_class: "
                . "its class name $logical_name is already taken by field '$existing' "
                . "-- two schema keys collapse to the same class segment; rename one of them";
        }
        my $existing_class = _class_for_path($root, $path);
        _rethrow_failed($existing_class);
        return $existing_class;
    }
    $_nested_origin{$logical_name} = $field_name;

    my $class = _class_for_path($root, $path);
    $_root_of{$class} = $root;
    $_class_path{$class} = $path;

    my $def_name = class_to_def($parent_class) . '.' . $segment;
    _generate_class($class, $def_name, $schema, $all_defs, $namespace,
        reuse_core => $reuse_core, reuse_core_except => $reuse_core_except);
    return $class;
}

# The logical path a nested class for ($parent_class, $field_name, $suffix)
# WOULD be generated at, computed the same way _nested_class does above --
# but without generating anything, so the reuse decision in
# _schema_to_type_spec can consult reuse_core_except before it calls
# _core_class_for (k120).
sub _prospective_nested_path {
    my ($parent_class, $field_name, $suffix) = @_;
    my $parent_path = $_class_path{$parent_class};
    my $segment = _class_segment($field_name) . ($suffix // '');
    return defined($parent_path) ? "$parent_path\::$segment" : $segment;
}

sub _has_properties {
    my ($schema) = @_;
    return ref $schema eq 'HASH'
        && ($schema->{type} // '') eq 'object'
        && ref $schema->{properties} eq 'HASH'
        && %{ $schema->{properties} };
}

# ---------------------------------------------------------------------------
# reuse_core (D5): a nested object whose property set is exactly the key set
# of a shipped core / apimachinery class is typed as that class. CRD schemas
# inline the types they embed (a LabelSelector, a PodTemplateSpec), and
# modeling them again would give every provider its own copy of PodSpec.
#
# The index is built once from the shipped class files, keyed by JSON key
# NAME only -- core_class_for_shape lists every candidate a key set could
# mean, without regard to type. _core_class_for below is the actual reuse
# decision, and needs more than a name match to be safe:
#
#   1. A schema shape under two keys is never reused. A single shared key
#      name ({value}, {name}, ...) is common enough by accident that
#      requiring at least two narrows out most of it for free.
#
#   2. Every remaining candidate must be TYPE-compatible with the schema,
#      key by key (see %_TYPE_COMPAT below) -- a schema string field can't
#      reuse a class that declares the same-named field as an array, for
#      instance. This is checked before anything else, since a name match
#      alone says nothing about the wire shape. It is coarse for arrays and
#      maps (any array, any map); step 4 settles what they hold.
#
#   3. Every remaining candidate must not OVER-CONSTRAIN the schema (k136,
#      see _overrequires): a candidate that marks some shared key
#      `required` (plain Moo-enforced or registry-only `required =>
#      'schema'`) which the schema's own `required` list leaves optional is
#      dropped. Reusing it would reject or silently drop a real cluster
#      object that (validly, per the CRD) omits that key -- the metav1.
#      Condition shape reused for a CRD condition that requires only
#      [type,status] is the case this exists for (k135/k137): message,
#      reason and lastTransitionTime are required on Condition but not on
#      the CRD, so a message-less live condition failed to inflate. Only
#      this direction is checked -- a schema requiring MORE than the
#      candidate leaves the reused class merely looser than the schema
#      promises, never lossy.
#
#   4. Every remaining candidate must hold the schema all the way down
#      (k148, see _field_compatible): an array's elements, a map's values
#      and every nested object's fields, recursively. A candidate that does
#      not -- an array of objects against a class whose same-named field is
#      an array of strings, which is what LabelSelectorRequirement was reused
#      for before -- is dropped here. k148 first ran this as a gate on the
#      class steps 5/6 had already picked, so it could only WITHDRAW a reuse;
#      k156 moved it ahead of the tie-break, where dropping the
#      recursively-incompatible candidates can leave a single survivor and so
#      DECIDE a reuse that a name/type match alone left ambiguous: a
#      {metadata,spec} matches every *TemplateSpec by name and type, but only
#      PodTemplateSpec's spec holds a PodSpec and only
#      PersistentVolumeClaimTemplate's a PVC spec, so the mismatched
#      candidates fall away and the one that fits is reused (AgentSandbox's
#      podTemplate and volumeClaimTemplates, PrometheusOperator's ephemeral
#      volumeClaimTemplate). Wire-identical candidates share their verdict
#      here (same flags, same classes per key), so they survive or fall
#      together and step 6 still sees the same wire-identical set.
#
#   5. Exactly one candidate survives every filter -> reuse it.
#
#   6. Several do -- reused only when they are wire-identical: the same
#      type flags (NOT required-ness -- a field being optional on one
#      shipped class and mandatory on another doesn't change what value it
#      holds) and the same referenced class per key, where a key has one.
#      {name,value} matches HTTPHeader, PodDNSConfigOption and Sysctl --
#      three unrelated Core::V1 leaf structs, wire-identical (two required
#      Str fields on two of them, two optional Str fields on the third, but
#      Str either way) -- reused as the preferred one (Meta::V1, then
#      Core::V1, then alphabetical: HTTPHeader). {key,operator,values}
#      matches LabelSelectorRequirement, FieldSelectorRequirement (both
#      Meta::V1) and NodeSelectorRequirement (Core::V1) -- also
#      wire-identical despite spanning two API areas -- reused as
#      LabelSelectorRequirement, by a wide margin the most common shape a
#      provider CRD's inline schema turns out to match (138 LabelSelector
#      copies, 162 of this bare triple, per the step-4 drift measurement).
#      A shape still matched by several NON-wire-identical candidates after
#      the step-4 filter (an optional field naming a different type, a
#      different value type under the same key that both nonetheless hold the
#      schema) stays a nested class rather than guess.
#
# A class's own `metadata` is part of its shape only for an embedded type
# (PodTemplateSpec: {metadata,spec}, a real schema-visible field) -- never
# for a top-level Kind (Pod: {spec,status}), whose `metadata` is supplied
# by IO::K8s::Role::APIObject outside the schema's own properties (see
# _generate_class's %role_supplied) and so never appears in a CRD's own
# inline schema for that Kind.
# ---------------------------------------------------------------------------

my %_core_shapes;       # "k1,k2,..." -> [ classes, preference-ordered ]
my %_core_shape_loaded; # shape -> 1 once that shape's candidates are loaded
my $_core_indexed = 0;

# The checked-in, precomputed form of %_core_shapes (k104). Building the
# index live costs ~6.5s in a fresh process -- >99% of it Module::Runtime
# loading all 839 classes under the two trees, the File::Find walk and the
# registry reads being ~15ms together -- and reuse_core is default on, so
# every first add_crd / generate / CRD inflate paid it. The precomputed
# module carries the finished shape -> classes map (no DSL semantics: the
# type-aware half of the reuse decision in _core_class_for loads the few
# candidate classes it actually looks at, see core_class_for_shape) and
# loads in ~2ms.
#
# It is a maint-maintained artifact in the sense of
# maint/spec-drift-exceptions.yaml, NOT a codegen step -- nothing under
# lib/IO/K8s/Api* is generated. maint/core-shape-index-gen.pl writes it by
# calling _scan_core_shapes below, and t/85_core_shape_index.t fails when
# the checked-in copy no longer matches what that same function produces,
# which is what keeps adding, removing or renaming a class honest.
our $CORE_SHAPE_INDEX = 'IO::K8s::AutoGen::CoreShapes';

# Preference order for core_class_for_shape's listing and for picking among
# several wire-identical candidates: LabelSelector / LabelSelectorRequirement
# first (see above), then the rest of apimachinery's Meta::V1, then
# core/v1, then everything else alphabetically.
my @CORE_PREFERENCE = (
    'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector',
    'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::',
    'IO::K8s::Api::Core::V1::',
);

sub _core_rank {
    my ($class) = @_;
    for my $i (0 .. $#CORE_PREFERENCE) {
        return $i if index($class, $CORE_PREFERENCE[$i]) == 0;
    }
    return scalar @CORE_PREFERENCE;
}

sub _index_core_shapes {
    return if $_core_indexed++;
    my $precomputed = eval { use_module($CORE_SHAPE_INDEX)->shapes };
    # A copy of the top level only: the arrayrefs stay shared with the
    # index module, so core_class_for_shape replaces a shape's entry
    # rather than sorting or splicing one in place.
    %_core_shapes = %{ $precomputed || _scan_core_shapes() };
}

# Build the shape index by loading every shipped class under the two trees
# and reading its attribute registry -- the slow path the precomputed
# index above exists to avoid. Called as the fallback when that module is
# missing, and, deliberately, as the ONE implementation both
# maint/core-shape-index-gen.pl and t/85_core_shape_index.t call: the
# artifact cannot encode a different metadata rule or a different
# preference order than the live path produces, because it IS this
# function's output. Returns a fresh hashref and touches no module state,
# so the drift test can scan without disturbing a lookup already served.
sub _scan_core_shapes {
    require File::Find;
    require IO::K8s::Role::Resource;
    (my $lib = $INC{'IO/K8s/AutoGen.pm'}) =~ s{/IO/K8s/AutoGen\.pm\z}{};
    my @files;
    File::Find::find(sub { push @files, $File::Find::name if /\.pm\z/ },
        "$lib/IO/K8s/Api", "$lib/IO/K8s/Apimachinery");
    my %shapes;
    for my $file (sort @files) {
        (my $class = $file) =~ s{^\Q$lib\E/}{};
        $class =~ s{/}{::}g;
        $class =~ s/\.pm\z//;
        eval { use_module($class); 1 } or next;
        my $info = IO::K8s::Role::Resource::_k8s_attr_info($class);
        # See the block comment above: metadata is part of the shape for an
        # embedded type, not for a top-level Kind (Role::APIObject supplies
        # it outside the schema there).
        my @attrs = $class->can('_is_resource') ? grep { $_ ne 'metadata' } keys %$info : keys %$info;
        my @keys = sort map { $info->{$_}{json_key} // $_ } @attrs;
        next unless @keys;
        push @{ $shapes{ join ',', @keys } }, $class;
    }
    for my $shape (keys %shapes) {
        @{ $shapes{$shape} } = sort { _core_rank($a) <=> _core_rank($b) || $a cmp $b } @{ $shapes{$shape} };
    }
    return \%shapes;
}

# Every shipped class whose key set is exactly \@json_keys, preference
# ordered. Diagnostic / listing use as well as the reuse decision below;
# building the class-name-only class from a plain ARRAY (JSON key names,
# not schema fragments) keeps it usable without a schema in hand. Name
# match only -- see _core_class_for for the type-aware reuse decision.
sub core_class_for_shape {
    my ($keys) = @_;
    _index_core_shapes();
    my $shape = join ',', sort @$keys;
    my $classes = $_core_shapes{$shape} or return ();
    # The precomputed index names classes without loading them, while
    # every caller -- _core_class_for's type check first among them --
    # reads the candidate's attribute registry, which is empty until the
    # class is loaded. Handing out an unloaded name would not raise: the
    # type filter would simply find no compatible candidate and silently
    # stop reusing anything, which is the worst shape this optimisation
    # could fail in. So a shape's candidates are loaded the first time
    # that shape is asked for: a handful of classes per lookup instead of
    # all 839 up front. A class that will not load is dropped and stays
    # dropped, matching the live scan, which never indexes one.
    unless ($_core_shape_loaded{$shape}++) {
        $classes = [ grep { eval { use_module($_); 1 } } @$classes ];
        $_core_shapes{$shape} = $classes;
    }
    return @$classes;
}

# The JSON-schema "kind" a property's type dispatches on for reuse-safety
# purposes -- string / int-or-string / time / quantity / integer / number /
# boolean / array / object. Mirrors _schema_to_type_spec's own dispatch
# (including its x-kubernetes-int-or-string, `format: int-or-string` and
# `format: date-time` checks and its Str fallback for anything unmodeled)
# without generating anything, since _core_class_for needs this for a schema
# fragment it may end up NOT typing as an object at all.
#
# The string family splits into four kinds (k181, k185), not one, because a
# reused class imposes its own wire type on the field and the wrong one
# corrupts the value:
#   * int-or-string (k181) -- x-kubernetes-int-or-string, or `type: string`
#     with `format: int-or-string`, or a $ref to intstr.IntOrString
#     (_scalar_ref_kind). Matches an IntOrStr field and a Quantity one:
#     controller-gen renders a resource.Quantity as x-kubernetes-int-or-string
#     with the quantity pattern (the emitter reads that back as Quantity,
#     k125), so a CRD embedding a pod template or a ResourceList still reuses
#     the core class that holds it.
#   * time -- `format: date-time`, or a $ref to meta.v1.(Micro)Time
#     (_scalar_ref_kind). Matches a Time field: the value IS an RFC 3339
#     timestamp, which is exactly what a Time field holds and emits.
#   * quantity -- a $ref to resource.Quantity (_scalar_ref_kind). Matches a
#     Quantity field: the value IS a quantity.
#   * string -- a plain `type: string` (no format, no scalar $ref), '', and
#     anything unmodeled. Matches a Str field only (k185). It must NOT reuse
#     an IntOrStr, Quantity or Time class: an IntOrStr turns the schema's
#     "8080" into the number 8080 (a Str goes out quoted since k145), a strict
#     Quantity rejects a "big", a strict Time rejects any non-RFC 3339 string.
#     Reading a plain string as any of those was the k185 bug -- the mirror of
#     the k181 one that read int-or-string as 'string'.
# time and quantity also match a Str field: a timestamp or quantity string is
# a lossless fit for one, the same direction the reuse check accepts elsewhere.
sub _schema_type_kind {
    my ($schema) = @_;
    return 'int-or-string' if eval { IO::K8s::Resource::_normalize_bool($schema->{'x-kubernetes-int-or-string'}) };
    my $type = $schema->{type} // '';
    return 'int-or-string' if $type eq 'string' && ($schema->{format} // '') eq 'int-or-string';
    return 'time'    if $type eq 'string' && ($schema->{format} // '') eq 'date-time';
    return 'integer' if $type eq 'integer';
    return 'number'  if $type eq 'number';
    return 'boolean' if $type eq 'boolean';
    return 'array'   if $type eq 'array';
    return 'object'  if $type eq 'object';
    return 'string';  # 'string', '', and anything unmodeled alike (k42's own Str fallback)
}

# The value type of a map whose additionalProperties is a scalar schema
# (k191) -- the DSL kind name Str, Int, Num, Bool, IntOrStr or Time -- or
# undef when the generator types the map as the free Opaque instead: an
# object or array value, or a value schema that names no type at all.
# Unlike _schema_type_kind, a missing type is not read as a string here: a
# string map stringifies every value on the wire, and `{}` promises no
# strings. Shared by _schema_to_type_spec and the reuse check
# (_object_compatible), so both read a map the same way.
sub _map_value_kind {
    my ($addl) = @_;
    return 'IntOrStr' if eval { IO::K8s::Resource::_normalize_bool($addl->{'x-kubernetes-int-or-string'}) };
    my $type = $addl->{type} // '';
    if ($type eq 'string') {
        my $format = $addl->{format} // '';
        return 'IntOrStr' if $format eq 'int-or-string';
        return 'Time'     if $format eq 'date-time';
        return 'Str';
    }
    return 'Int'  if $type eq 'integer';
    return 'Num'  if $type eq 'number';
    return 'Bool' if $type eq 'boolean';
    return undef;
}

# Registry type flags compatible with each schema kind (rule 2 above). The
# string family (string / int-or-string / time / quantity) and why each is a
# kind of its own is explained on _schema_type_kind above.
# 'array'/'object' match by prefix/membership rather than an exhaustive
# list -- see _flag_compatible. That coarse array/object match is only the
# pre-selection the tie-break works on; what the array holds and what the
# map's values are is decided by _field_compatible below (k148), which asks
# _flag_compatible about scalar kinds only.
my %_TYPE_COMPAT = (
    string          => { is_str => 1 },
    quantity        => { map { $_ => 1 } qw( is_quantity is_str ) },
    time            => { map { $_ => 1 } qw( is_time is_str ) },
    'int-or-string' => { map { $_ => 1 } qw( is_int_or_string is_quantity ) },
    integer         => { map { $_ => 1 } qw( is_int is_int_or_string ) },
    number          => { map { $_ => 1 } qw( is_num ) },
    boolean         => { map { $_ => 1 } qw( is_bool ) },
);

sub _flag_compatible {
    my ($kind, $flag) = @_;
    return 1 if $kind eq 'array'  && $flag =~ /^is_array_of_/;
    return 1 if $kind eq 'object' && ($flag eq 'is_object' || $flag eq 'is_inline_struct'
        || $flag eq 'is_hash_opaque' || $flag =~ /^is_hash_of_/);
    return $_TYPE_COMPAT{$kind} ? !!$_TYPE_COMPAT{$kind}{$flag} : 0;
}

# Does $registry_entry (one candidate's _k8s_attr_info entry for a key)
# hold a type flag compatible with $kind? Every k8s()-registered attribute
# carries exactly one "is_*" classifying flag (is_object plus
# is_inline_struct together for an inline struct -- either one matches
# 'object'), so one match is enough.
sub _entry_compatible {
    my ($entry, $kind) = @_;
    return !!grep { /^is_/ && $entry->{$_} && _flag_compatible($kind, $_) } keys %$entry;
}

# ---------------------------------------------------------------------------
# Container compatibility (k148)
#
# A flag alone cannot tell whether a candidate's array or map field holds
# what the schema says: "an array" matched every is_array_of_* and "an
# object" every is_object / is_hash_of_*, so LabelSelectorRequirement
# ({key,operator,values}, values [Str]) was reused for a schema whose values
# are an array of objects, and the schema's own valid data then failed to
# inflate. _field_compatible instead compares the candidate's field with
# the type _schema_to_type_spec WOULD give the schema fragment -- read off
# the schema the same way that function dispatches on it, without
# generating anything -- and recurses into element, value and nested
# object shapes:
#
#   scalar          -> the scalar rules above, unchanged
#   array           -> items decide: a scalar item kind needs the matching
#                      is_array_of_<scalar> (the scalar rules one level
#                      down); items with properties need is_array_of_objects
#                      whose class matches them (_class_compatible); bare
#                      `type: object` / `type: array` items need
#                      is_array_of_hash / is_array_of_array, what the
#                      generator types them as
#   object + props  -> is_object whose class matches them
#   object + map    -> additionalProperties with properties needs
#                      is_hash_of_objects whose class matches it; a scalar
#                      value kind a typed scalar map (is_hash_of_quantity,
#                      ...) by the scalar rules -- the string map
#                      (is_hash_of_str, labels, annotations) among them, a
#                      `type: string` value needing is_hash_of_str (k191)
#   opaque object   -> see below
#
# The opaque map, Opaque / is_hash_opaque (arbitrary JSON, fieldsV1,
# RawExtension), is its own case: it matches exactly the schema fragments
# the generator itself types as Opaque -- an object with neither properties
# nor a scalar-valued additionalProperties (an object, array or typeless
# value schema, a boolean one, or none; a $ref to %OPAQUE_TYPES; see
# _map_value_kind). Reusing it there changes nothing about the field. It
# does not match a map of structured objects, a string or typed map, a
# structured object, an array or a scalar, however permissive a plain
# HashRef is: that would reuse a class that loses the schema's typing, and
# a match that cannot be shown is not one. Nor does an opaque schema match
# a string map, a typed map or a structured class -- the schema allows
# values those reject or would rewrite (a string map puts a number out as
# a string) -- with the one exception of ObjectMeta ($OBJECT_META below).
# Until k191 the opaque map was spelled { Str => 1 }, and is_hash_of_str
# was matched here in its place.
#
# A $ref is resolved read-only against the definitions _core_class_for was
# handed, the way _schema_to_type_spec resolves it: the apimachinery scalars
# are values -- IntOrString the int-or-string kind (k181), Quantity the
# quantity kind and Time the time kind (k185) -- as a property, as items and
# as map values alike (k178, see _scalar_ref_kind), %OPAQUE_TYPES is the
# opaque map, an apiextensions union name is its shipped class
# (%UNION_TYPES), anything else is the object its definition describes. A
# $ref that does not resolve cannot be shown compatible.
#
# Nested classes: every schema property must be declared by the class and
# hold a compatible value (an undeclared one would end in the unknown-field
# bag, or die under strict), the class must not require a key the schema
# lacks, and _overrequires applies as it does one level up -- a nested
# class the nested decision would refuse must not come in through its
# parent. Keys only the class declares are fine otherwise: the reused class
# is looser than the schema there, never lossy (the same direction
# _overrequires accepts).
#
# Recursion: a (class, schema) pair met again while it is still being
# checked further up (a recursive $ref'd definition against a recursive
# class) counts as compatible at the repeat -- that pair's every other field
# is being checked by the frame that entered it, so nothing unchecked is
# waved through, and any finite value of the schema is held by the class.
# The set is path-scoped, like IO::K8s::CRD's own, so a pair that recurs as
# an unrelated sibling is checked again rather than taken on trust.
# ---------------------------------------------------------------------------

# The one structured class an unstructured object schema stands for. Below
# the root, controller-gen renders an embedded metav1.ObjectMeta as a bare
# `type: object` (the apiserver owns its shape) -- a PVC template's metadata
# inside core Volume's ephemeral source, for one -- so there the schema IS
# ObjectMeta, not some other opaque value, and ObjectMeta holds it, with any
# key it does not declare kept in the unknown-field bag. Refusing it would
# refuse the whole core Volume for every pod template a CRD embeds.
my $OBJECT_META = 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta';

sub _field_compatible {
    my ($entry, $schema, $ctx) = @_;
    return 0 unless ref $entry eq 'HASH' && ref $schema eq 'HASH';
    if (defined(my $ref = $schema->{'$ref'})) {
        $ref =~ s{^#/definitions/}{};
        if (my $kind = _scalar_ref_kind($ref)) {
            return _entry_compatible($entry, $kind);
        }
        return !!$entry->{is_hash_opaque} if $OPAQUE_TYPES{$ref};
        if (my $union = _union_class($ref)) {
            return $entry->{is_object} && ($entry->{class} // '') eq $union;
        }
        my $def = _ref_definition($ref, $ctx) or return 0;
        return $entry->{is_object} && _class_compatible($entry->{class}, $def, $ctx);
    }
    my $kind = _schema_type_kind($schema);
    return _array_compatible($entry, $schema, $ctx)  if $kind eq 'array';
    return _object_compatible($entry, $schema, $ctx) if $kind eq 'object';
    return _entry_compatible($entry, $kind);
}

sub _array_compatible {
    my ($entry, $schema, $ctx) = @_;
    my $items = $schema->{items} // {};
    return 0 unless ref $items eq 'HASH';
    # items with a $ref: an array of the scalar an apimachinery $ref stands
    # for, as the generator's items branch types it (k178), else an array of
    # the definition's class
    if (defined(my $ref = $items->{'$ref'})) {
        $ref =~ s{^#/definitions/}{};
        if (my $kind = _scalar_ref_kind($ref)) {
            return _element_compatible($entry, 'is_array_of_', $kind);
        }
        if (my $union = _union_class($ref)) {
            return $entry->{is_array_of_objects} && ($entry->{class} // '') eq $union;
        }
        my $def = _ref_definition($ref, $ctx) or return 0;
        return $entry->{is_array_of_objects} && _class_compatible($entry->{class}, $def, $ctx);
    }
    return $entry->{is_array_of_objects} && _class_compatible($entry->{class}, $items, $ctx)
        if _has_properties($items);
    my $kind = _schema_type_kind($items);
    return !!$entry->{is_array_of_hash}  if $kind eq 'object';
    return !!$entry->{is_array_of_array} if $kind eq 'array';
    return _element_compatible($entry, 'is_array_of_', $kind);
}

sub _object_compatible {
    my ($entry, $schema, $ctx) = @_;
    return $entry->{is_object} && _class_compatible($entry->{class}, $schema, $ctx)
        if _has_properties($schema);
    my $addl = $schema->{additionalProperties};
    # a boolean additionalProperties, or none: the opaque map -- or an
    # embedded ObjectMeta (see $OBJECT_META)
    unless (ref $addl eq 'HASH') {
        return 1 if $entry->{is_hash_opaque};
        return $entry->{is_object} && ($entry->{class} // '') eq $OBJECT_META;
    }
    if (defined(my $ref = $addl->{'$ref'})) {
        $ref =~ s{^#/definitions/}{};
        # the typed map the generator makes of an apimachinery scalar (k178)
        if (my $kind = _scalar_ref_kind($ref)) {
            return _element_compatible($entry, 'is_hash_of_', $kind);
        }
        if (my $union = _union_class($ref)) {
            return $entry->{is_hash_of_objects} && ($entry->{class} // '') eq $union;
        }
        my $def = _ref_definition($ref, $ctx) or return 0;
        return $entry->{is_hash_of_objects} && _class_compatible($entry->{class}, $def, $ctx);
    }
    return $entry->{is_hash_of_objects} && _class_compatible($entry->{class}, $addl, $ctx)
        if _has_properties($addl);
    # a scalar value schema is the string or typed map the generator makes
    # of it, by the scalar rules; anything else it types as the opaque map
    return !!$entry->{is_hash_opaque} unless _map_value_kind($addl);
    return _element_compatible($entry, 'is_hash_of_', _schema_type_kind($addl));
}

# Does $entry carry a scalar-element container flag ($prefix plus a scalar
# name: is_array_of_int, is_hash_of_quantity, ...) whose scalar is
# compatible with $kind under the scalar rules? Since k191 is_hash_of_str
# is the string map and counts like is_array_of_str; the opaque map has a
# flag of its own (is_hash_opaque) that never matches a prefix here.
sub _element_compatible {
    my ($entry, $prefix, $kind) = @_;
    for my $flag (grep { $entry->{$_} } keys %$entry) {
        next unless $flag =~ /^\Q$prefix\E(.+)\z/;
        return 1 if _flag_compatible($kind, 'is_' . $1);
    }
    return 0;
}

# Does $class hold every value the object schema $schema describes? See
# the block comment above for the rules and the recursion guard.
sub _class_compatible {
    my ($class, $schema, $ctx) = @_;
    return 0 unless defined $class && _has_properties($schema);
    my $pair = $class . '|' . refaddr($schema);
    return 1 if $ctx->{active}{$pair};
    return 0 unless $class->can('_k8s_attr_info') || eval { use_module($class); 1 };
    local $ctx->{active}{$pair} = 1;

    my $by_json = _attrs_by_json_key($class);
    my $props   = $schema->{properties};
    for my $key (keys %$props) {
        return 0 unless _field_compatible($by_json->{$key}, $props->{$key}, $ctx);
    }
    for my $key (keys %$by_json) {
        return 0 if $by_json->{$key}{required} && !exists $props->{$key};
    }
    if (defined $schema->{required}) {
        my %schema_required = map { $_ => 1 } @{ $schema->{required} };
        return 0 if _overrequires([ keys %$props ], \%schema_required, $class);
    }
    return 1;
}

# The definition a $ref names, from the definitions handed to
# _core_class_for, or undef.
sub _ref_definition {
    my ($ref, $ctx) = @_;
    my $def = $ctx->{defs} && $ctx->{defs}{$ref};
    return ref $def eq 'HASH' ? $def : undef;
}

# $class's registry entries keyed by JSON key rather than attribute name.
sub _attrs_by_json_key {
    my ($class) = @_;
    my $info = IO::K8s::Role::Resource::_k8s_attr_info($class);
    my %by_json;
    $by_json{ $info->{$_}{json_key} // $_ } = $info->{$_} for keys %$info;
    return \%by_json;
}

# Do every one of @candidates agree, key by key, on type flags (ignoring
# required-ness) and on the referenced class where a key has one? Assumes
# @candidates already share the identical JSON key set (core_class_for_shape
# guarantees that) -- compared by JSON key, not by each candidate's own
# (possibly differently-sanitized) Perl attribute name.
sub _wire_identical {
    my ($keys, @candidates) = @_;
    return 1 if @candidates <= 1;
    my @by_json = map {
        my $info = IO::K8s::Role::Resource::_k8s_attr_info($_);
        my %j; $j{ $info->{$_}{json_key} // $_ } = $info->{$_} for keys %$info;
        \%j;
    } @candidates;
    for my $key (@$keys) {
        my %sig;
        for my $j (@by_json) {
            my $e = $j->{$key} // {};
            my @flags = sort grep { /^is_/ && $e->{$_} } keys %$e;
            $sig{ join('|', @flags) . '#' . ($e->{class} // '') } = 1;
        }
        return 0 if keys %sig > 1;
    }
    return 1;
}

# Does $candidate mark some shared key `required` (Moo-enforced plain
# `required => 1`, or registry-only `required => 'schema'` -- both are
# recorded as `required => 1` in _k8s_attr_info, see IO::K8s::Resource's
# k8s()) that $schema_required does NOT list? One direction only (k136): a
# candidate requiring MORE than the schema is unsafe to reuse -- a real
# cluster object that omits that key would fail ->new() (plain required) or
# be silently dropped on inflate (required => 'schema'), even though the
# schema never promised the field. A schema requiring MORE than the
# candidate is the opposite, harmless direction -- the reused class is
# merely looser than the schema, never lossy -- and is not checked here.
#
# Only called (see _core_class_for) when $schema itself carries a `required`
# key at all -- a schema fragment that omits `required` entirely is treated
# as making no required-ness claim one way or the other, not as an explicit
# "nothing required" (which, strictly, is what JSON Schema says an absent
# `required` means). Every upstream CRD schema actually seen to embed one of
# these reused shapes (LabelSelector's {key,operator,values}, {name,value},
# ...) does carry an explicit `required` list matching the reused class, so
# this distinction changes nothing for real schemas; what it avoids is
# treating a schema fragment that simply never bothered to state `required`
# (as this function's own test fixtures do, and as a hand-written or
# less careful third-party CRD might) as if it had positively declared every
# field optional, which would fall back dozens of well-established, safe
# reuses (LabelSelectorRequirement, HTTPHeader, ...) to nested classes for no
# safety gain.
sub _overrequires {
    my ($keys, $schema_required, $candidate) = @_;
    my $info = IO::K8s::Role::Resource::_k8s_attr_info($candidate);
    my %by_json; $by_json{ $info->{$_}{json_key} // $_ } = $info->{$_} for keys %$info;
    for my $key (@$keys) {
        return 1 if $by_json{$key}{required} && !$schema_required->{$key};
    }
    return 0;
}

# The class to reuse for a nested object schema, or undef. $all_defs, the
# definitions the schema's $refs resolve against, is only read (k148).
sub _core_class_for {
    my ($schema, $all_defs) = @_;
    return undef unless _has_properties($schema);
    my @keys = sort keys %{ $schema->{properties} };
    return undef if @keys < 2;  # a single shared key name is too common to trust
    my @candidates = core_class_for_shape(\@keys);
    return undef unless @candidates;

    # Type-compatibility filter: drop any candidate that types some key
    # incompatibly with what the schema itself says that key is.
    @candidates = grep {
        my $info = IO::K8s::Role::Resource::_k8s_attr_info($_);
        my %by_json; $by_json{ $info->{$_}{json_key} // $_ } = $info->{$_} for keys %$info;
        !grep { !_entry_compatible($by_json{$_}, _schema_type_kind($schema->{properties}{$_})) } @keys;
    } @candidates;
    return undef unless @candidates;

    # Required-compatibility filter (k136): drop any candidate that
    # over-constrains the schema -- see _overrequires. Only applied when the
    # schema itself declares a `required` list (see that function's comment
    # for why an absent one is not treated as an explicit "nothing
    # required"). Checked before the single-candidate shortcut and the
    # wire-identical tie-break alike, so an over-constrained candidate can
    # never be "the one" reuse picks, whether it was alone or one of several
    # wire-identical options.
    if (defined $schema->{required}) {
        my %schema_required = map { $_ => 1 } @{ $schema->{required} };

        # k139: remember the shared-vocab candidates (Meta::V1 / Core::V1,
        # _core_rank below @CORE_PREFERENCE) that ENTER the required filter,
        # to catch the specific fallback the check just below rejects.
        my @shared_vocab_before = grep { _core_rank($_) < scalar @CORE_PREFERENCE } @candidates;

        @candidates = grep { !_overrequires(\@keys, \%schema_required, $_) } @candidates;
        return undef unless @candidates;

        # k139: a shared-vocab candidate matched this shape but the required
        # filter above eliminated every one of them, leaving only a
        # domain-foreign candidate (_core_rank == @CORE_PREFERENCE) to reuse.
        # That is the k135/k137 condition case: metav1.Condition matches a
        # CRD condition's {lastTransitionTime,message,observedGeneration,
        # reason,status,type} shape but over-requires (message/reason/
        # lastTransitionTime) relative to a CRD that requires only
        # [status,type], so k136 drops it -- and reuse would otherwise fall
        # back to an unrelated class that merely shares the shape and the
        # narrower required set (Autoscaling::V2::HorizontalPodAutoscaler-
        # Condition for a cert-manager IssuerCondition). Return undef so the
        # provider's own nested class is generated instead of reusing a
        # foreign one. This fires ONLY once a shared-vocab candidate has been
        # removed HERE: a shape whose candidates were always domain-specific
        # (no Meta/Core member ever) is a genuine sole-family reuse of the
        # one real embedded upstream type (NetworkPolicyPort,
        # CrossVersionObjectReference, ParamKind, ...) and is left untouched,
        # as is a shape where a shared-vocab candidate still survives the
        # required filter (Core::V1::NamespaceCondition for the 5-key
        # CertificateRequest condition, which requires only [status,type]).
        return undef
            if @shared_vocab_before
            && !grep { _core_rank($_) < scalar @CORE_PREFERENCE } @candidates;
    }
    # Recursive-compatibility filter (k148 check, k156 placement): every
    # remaining candidate must hold what the schema describes all the way
    # down -- array elements, map values, nested objects (see
    # _field_compatible / _class_compatible) -- or it is dropped here, ahead
    # of the tie-break below. k148 first ran this as a gate on the
    # already-picked class (it could only WITHDRAW a reuse); k156 moves it
    # ahead of the tie-break so it can also DECIDE one: a shape several
    # candidates match by name and type alone (a {metadata,spec} that fits
    # every *TemplateSpec) narrows to the single candidate whose deep shape
    # holds the schema (only PodTemplateSpec's spec holds a PodSpec, only
    # PersistentVolumeClaimTemplate's a PVC spec), and that one is reused
    # where before the non-wire-identical tie-break refused them all.
    # Wire-identical candidates share their verdict here (same flags, same
    # classes per key), so they survive or fall together and the tie-break
    # below still sees the same wire-identical set.
    @candidates = grep {
        _class_compatible($_, $schema, { defs => $all_defs, active => {} })
    } @candidates;
    return undef unless @candidates;

    # Several type-, required- and recursively-compatible candidates: reuse
    # the preferred one only if they are wire-identical (already
    # preference-sorted by core_class_for_shape, and every filter above
    # preserves that order). A single survivor is reused outright.
    return @candidates == 1                     ? $candidates[0]
         : _wire_identical(\@keys, @candidates) ? $candidates[0]
         :                                        undef;
}

# The scalar type a $ref to one of the special apimachinery types stands for
# (they are values, not object references), or undef -- as a property, as
# an array's items and as a map's additionalProperties alike (k178).
# Shared by _schema_to_type_spec and the reuse check (_field_compatible), so
# the two read a $ref the same way.
sub _scalar_ref_type {
    my ($ref) = @_;
    return 'IntOrStr' if $ref =~ /intstr\.IntOrString$/;
    return 'Quantity' if $ref =~ /resource\.Quantity$/;
    return 'Time'     if $ref =~ /meta\.v1\.(Micro)?Time$/;
    return undef;
}

# The reuse-check kind (see _schema_type_kind) of such a $ref, or undef:
# IntOrString is the int-or-string kind (k181), Quantity the quantity kind
# and Time the time kind (k185) -- each distinct from a plain string, which a
# scalar $ref never is.
sub _scalar_ref_kind {
    my ($ref) = @_;
    my $scalar = _scalar_ref_type($ref) or return undef;
    return 'int-or-string' if $scalar eq 'IntOrStr';
    return 'quantity'      if $scalar eq 'Quantity';
    return 'time';  # Time / MicroTime
}

# The element types of a generated class's scalar arrays (k178). The scalar
# fields of a generated class are the barewords 'Quantity' and 'Time', which
# the DSL builds on Str: any string, so a value the API server stores as
# written -- a custom resource's date-time with a lowercase 't' or 'z' is
# valid RFC 3339 -- never fails to inflate. An array element has to follow
# the same rule, but inside an arrayref the DSL reads a bareword as a class
# name, and the library's Time and Quantity carry the strict regexes a
# hand-written class keeps. So each is Str under the kind's name: the DSL
# and _scalar_kind classify a Type::Tiny element by its name, which is what
# gives it the is_array_of_time / is_array_of_quantity registry flag and
# with that its TO_JSON rule, its to_crd schema and its emitter spelling. A
# Type::Library cannot hold a second Time, so these stay private here
# rather than becoming an export of IO::K8s::Types. IntOrStr is Str in the
# library already.
my $GENERATED_TIME     = Str->create_child_type(name => 'Time');
my $GENERATED_QUANTITY = Str->create_child_type(name => 'Quantity');
my %GENERATED_ITEM_TYPE = (
    IntOrStr => IntOrStr,
    Quantity => $GENERATED_QUANTITY,
    Time     => $GENERATED_TIME,
);

# The value types of a generated scalar map, HashRef[X] (k191), by the kind
# _map_value_kind reads off additionalProperties. Time is the lenient
# $GENERATED_TIME for the reason the array element above is.
my %GENERATED_MAP_VALUE_TYPE = (
    Str      => Str,
    Int      => Int,
    Num      => Num,
    Bool     => Bool,
    IntOrStr => IntOrStr,
    Time     => $GENERATED_TIME,
);

# Convert OpenAPI schema to k8s() type spec
#
# $field_name and $class are diagnostic context only: everything this
# function refuses has to name the class being generated and the field it
# choked on, because the caller sees neither (the k42 diagnostic line).
#
# $reuse_core (D5, default 1) turns the object / array-items /
# additionalProperties reuse check on or off (see _core_class_for).
sub _schema_to_type_spec {
    my ($schema, $all_defs, $namespace, $field_name, $class, $reuse_core, $reuse_core_except) = @_;
    $reuse_core = 1 unless defined $reuse_core;
    $reuse_core_except ||= {};

    # k120: reuse core here unless this field's would-be nested class sits
    # at a path the caller marked for suppression (see reuse_core_except in
    # _generate_class). $suffix matches the _nested_class call in the same
    # branch: 'Item' for array items, undef for a plain object, 'Value' for
    # additionalProperties.
    my $may_reuse = sub {
        my ($suffix) = @_;
        return 0 unless $reuse_core;
        return !$reuse_core_except->{ _prospective_nested_path($class, $field_name, $suffix) };
    };

    my $where = "field '" . $field_name . "' of " . $class;

    # Handle $ref
    if (my $ref = $schema->{'$ref'}) {
        $ref =~ s{^#/definitions/}{};

        # Special apimachinery types - not object references
        if (my $scalar = _scalar_ref_type($ref)) {
            return $scalar;
        }

        # apiextensions union types: the shipped FROM_STRUCT class (k152)
        if (my $union = _union_class($ref)) {
            return "+$union";
        }

        # Opaque types should be the free map, not object references
        if ($OPAQUE_TYPES{$ref}) {
            return Opaque;
        }

        # Generate referenced class if needed
        if ($all_defs && $all_defs->{$ref}) {
            my $ref_class = get_or_generate($ref, $all_defs->{$ref}, $all_defs, $namespace);
            return "+$ref_class";  # + prefix for full class name
        }
        _croak_unresolved_ref($ref, $where);
    }

    # A structural CRD schema marks Kubernetes' IntOrString union type with
    # this extension, almost always instead of `type` rather than alongside
    # it (the pruning rules for x-kubernetes-int-or-string require either no
    # `type` or an `anyOf`) -- checked before the type dispatch below, which
    # would otherwise read the type-less shape as "unknown type" and fall
    # back to Str. Found via IO::K8s::CRD::Emitter's stronger assertion on
    # the registry type flag (t/74_crd_emitter.t): t/73_add_crd.t's own
    # same-named subtest passed regardless, since a Str-typed attribute
    # holds a plain IntOrString value like '10Gi' exactly as well as an
    # IntOrStr-typed one does. The swagger v2 `format: int-or-string`
    # convention below still works for a schema that keeps `type: string`.
    #
    # Unlike the nullable/preserve_unknown checks in _field_options (Minor 6
    # of the k93 review, deliberately left unwrapped: a schema property is
    # always a plain scalar or JSON boolean there), this call sits ahead of
    # the type dispatch below rather than after it -- a malformed value here
    # must not abort class generation outright, so it is wrapped in eval and
    # treated as false, falling through to the ordinary `type`-based
    # dispatch instead.
    return 'IntOrStr'
        if eval { IO::K8s::Resource::_normalize_bool($schema->{'x-kubernetes-int-or-string'}) };

    my $type = $schema->{type} // '';

    if ($type eq 'string') {
        my $format = $schema->{format} // '';
        return 'IntOrStr' if $format eq 'int-or-string';
        return 'Time'     if $format eq 'date-time';
        return 'Str';
    }
    elsif ($type eq 'integer') {
        return 'Int';
    }
    elsif ($type eq 'number') {
        return 'Num';  # A genuine JSON number -- unquoted on the wire (k68)
    }
    elsif ($type eq 'boolean') {
        return 'Bool';
    }
    elsif ($type eq 'array') {
        my $items = $schema->{items} // {};
        if (my $ref = $items->{'$ref'}) {
            $ref =~ s{^#/definitions/}{};
            # The apimachinery scalars are values here too (k178): generated
            # from their definitions -- a bare `type: string` -- they used to
            # become an empty class no element could inflate into.
            if (my $scalar = _scalar_ref_type($ref)) {
                return [ $GENERATED_ITEM_TYPE{$scalar} ];
            }
            if (my $union = _union_class($ref)) {
                return ["+$union"];
            }
            if ($all_defs && $all_defs->{$ref}) {
                my $ref_class = get_or_generate($ref, $all_defs->{$ref}, $all_defs, $namespace);
                return ["+$ref_class"];
            }
            _croak_unresolved_ref($ref, "the items of $where");
        }
        if ($may_reuse->('Item') and my $core = _core_class_for($items, $all_defs)) {
            return [ "+$core" ];
        }
        if (_has_properties($items)) {
            return [ '+' . _nested_class($class, $field_name, 'Item', $items, $all_defs, $namespace, $reuse_core, $reuse_core_except) ];
        }
        # Type::Tiny objects rather than the barewords: inside an arrayref
        # the DSL reads a plain string as a class name for everything except
        # 'Str' and 'Int', so ['Bool'] would ask for an array of
        # IO::K8s::Api::Bool objects. [Bool] is the form that reaches the
        # is_array_of_bool branch and its per-element normalization, which is
        # what an array of schema-true JSON booleans needs (k57). Number
        # items get [Num], the array form of the scalar number case (k68):
        # they used to fall through to [ Str ] below, and a [Str] element
        # goes out as a JSON string since k145 (k155). int-or-string and
        # date-time items are the same gap for the scalar IntOrStr / Time
        # cases above (k167), read off the items exactly as those read the
        # property: the extension first, a format only with `type: string`.
        # [IntOrStr] keeps an element 8080 a number on the wire; a [Time]
        # element accepts what the scalar Time of a generated class accepts
        # (k178, see %GENERATED_ITEM_TYPE).
        return [ IntOrStr ]
            if eval { IO::K8s::Resource::_normalize_bool($items->{'x-kubernetes-int-or-string'}) };
        if (($items->{type} // '') eq 'string') {
            my $format = $items->{format} // '';
            return [ IntOrStr ]        if $format eq 'int-or-string';
            return [ $GENERATED_TIME ] if $format eq 'date-time';
        }
        my $item_type = $items->{type} // 'string';
        return [ Int ]  if $item_type eq 'integer';
        return [ Num ]  if $item_type eq 'number';
        return [ Bool ] if $item_type eq 'boolean';
        # items: object / array with no further structure -> an array of
        # opaque hashes / opaque arrays. Before k66 both fell through to
        # [ Str ] below and rejected the very hashrefs/arrayrefs the schema
        # describes.
        return [ {} ] if $item_type eq 'object';
        return [ [] ] if $item_type eq 'array';
        return [ Str ];  # string, and the default for anything unmodelled
    }
    elsif ($type eq 'object') {
        if (_has_properties($schema)) {
            if ($may_reuse->(undef) and my $core = _core_class_for($schema, $all_defs)) {
                return "+$core";
            }
            return '+' . _nested_class($class, $field_name, undef, $schema, $all_defs, $namespace, $reuse_core, $reuse_core_except);
        }
        my $addl = $schema->{additionalProperties};
        if (ref $addl eq 'HASH') {
            if (my $ref = $addl->{'$ref'}) {
                $ref =~ s{^#/definitions/}{};
                # The DSL's typed map of the scalar (k178), as for items
                # above: { Quantity => 1 } is what a ResourceList is. It is
                # the DSL's one typed map, so its values are checked against
                # the library types -- for Quantity and Time the strict
                # form a hand-written map carries. A $ref only comes from a
                # swagger definition (a CRD schema has none), and the API
                # server writes both of those scalars in canonical form.
                if (my $scalar = _scalar_ref_type($ref)) {
                    return { $scalar => 1 };
                }
                if (my $union = _union_class($ref)) {
                    return { "+$union" => 1 };
                }
                if ($all_defs && $all_defs->{$ref}) {
                    my $ref_class = get_or_generate($ref, $all_defs->{$ref}, $all_defs, $namespace);
                    return { "+$ref_class" => 1 };
                }
                _croak_unresolved_ref($ref, "the additionalProperties of $where");
            }
            if ($may_reuse->('Value') and my $core = _core_class_for($addl, $all_defs)) {
                return { "+$core" => 1 };
            }
            if (_has_properties($addl)) {
                return { '+' . _nested_class($class, $field_name, 'Value', $addl, $all_defs, $namespace, $reuse_core, $reuse_core_except) => 1 };
            }
            # A scalar value schema is the string map HashRef[Str] or the
            # typed map of its kind; anything else -- object or array
            # values, a value schema without a type -- the free map (k191).
            # Before k191 every one of them became the then-opaque
            # { Str => 1 }.
            my $value_kind = _map_value_kind($addl);
            return $value_kind ? HashRef[ $GENERATED_MAP_VALUE_TYPE{$value_kind} ] : Opaque;
        }
        # additionalProperties is allowed to be a JSON boolean instead of a
        # schema -- true: any extra property, false: none. A JSON::PP::Boolean
        # is a blessed scalar ref, so the $ref lookup above used to die "Not a
        # HASH reference" naming neither class nor field (k55). Neither
        # boolean says anything about the value types, so the field stays the
        # same free map (Opaque) a schemaless object gets.
        if (defined $addl) {
            my $reftype = reftype($addl);
            croak "additionalProperties of $where is a " . $reftype
                . " reference; expected a schema object or a boolean"
                if defined $reftype && $reftype ne 'SCALAR';
        }
        return Opaque;  # Generic object -> the free map (k191)
    }

    # Unknown type
    return 'Str';
}

# The scalar type a DSL type spec is built on -- Str, Int, Num, Bool,
# IntOrStr, Quantity, Time -- or undef for objects, structs and the opaque
# container forms. Value constraints (enum, minimum, maximum, pattern) only
# make sense on the former; passing one to the DSL for the latter would
# croak at class generation.
my %SCALAR_KIND = map { $_ => 1 } qw( Str Int Num Bool IntOrStr Quantity Time );

sub _scalar_kind {
    my ($type_spec) = @_;
    if (!ref $type_spec) {
        return $SCALAR_KIND{$type_spec} ? $type_spec : undef;
    }
    if (ref $type_spec eq 'ARRAY') {
        my $elem = $type_spec->[0];
        return undef if ref $elem eq 'HASH' || ref $elem eq 'ARRAY';
        # Mirror _k8s's own array-element handling exactly (Important 4 of
        # the k93 review): a Type::Tiny element is a scalar kind only when
        # its name is one of the seven the DSL knows, and a bareword
        # string element is a scalar kind only for 'Str' and 'Int' -- _k8s
        # treats every other bareword (including the kind names 'Num',
        # 'Bool', 'Quantity', 'Time', 'IntOrStr' spelled as plain strings)
        # as a class name and hands it to _expand_class.
        if (blessed($elem) && $elem->isa('Type::Tiny')) {
            return $SCALAR_KIND{$elem->name} ? $elem->name : undef;
        }
        return undef if ref $elem;
        return ($elem eq 'Str' || $elem eq 'Int') ? $elem : undef;
    }
    if (ref $type_spec eq 'HASH') {
        my ($k) = keys %$type_spec;
        # { Str => 1 } is the lenient string map, which takes no value
        # option (IO::K8s::Resource); typed maps carry their value kind.
        return undef if $k eq 'Str';
        return $SCALAR_KIND{$k} ? $k : undef;
    }
    # HashRef[X] (k191): the value type's kind, Str included -- the strict
    # string map takes value options; Opaque none.
    if (my $value_type = _map_value_type($type_spec)) {
        return $SCALAR_KIND{ $value_type->name } ? $value_type->name : undef;
    }
    return undef;
}

# The value type of a HashRef[X] type spec, or undef for anything else.
sub _map_value_type {
    my ($type_spec) = @_;
    return undef unless blessed($type_spec) && $type_spec->isa('Type::Tiny')
        && $type_spec->is_parameterized
        && $type_spec->parameterized_from->name eq 'HashRef';
    return $type_spec->type_parameter;
}

# A typed map of either spelling: { X => 1 } or HashRef[X].
sub _is_map_spec {
    my ($type_spec) = @_;
    return ref $type_spec eq 'HASH' || _map_value_type($type_spec) ? 1 : 0;
}

# Field options for one property (D3). Schema-only facts (description,
# default, nullable, x-kubernetes-preserve-unknown-fields) travel for every
# field; the value constraints only where the DSL can enforce them. For an
# array the constraints sit on `items` and apply per element.
#
# required => 'schema' (not 1): the schema's required list is a fact for
# to_crd, not a client-side guarantee. A cluster document can validly omit
# a field the schema requires -- a server-side default, or an object still
# short of that field (an empty status right after creation) -- and
# rejecting inflate over that would reject real cluster data. required =>
# 1 would enforce it at construction; see IO::K8s::Resource/k8s (Critical
# 1 of the k93 review).
#
# A pattern is an ECMA 262 regex on the wire. Perl compiles nearly all of
# them; one it cannot is dropped rather than failing the whole class -- the
# client-side check is a convenience, the API server validates regardless,
# and no data is lost (the k56 line is about data, not about checks). An
# empty enum, a duplicate enum, or an enum containing a JSON null is
# dropped the same way; minimum/maximum are dropped (individually, if only
# one bound is bad, or both together when minimum exceeds maximum) when
# either fails to parse as a number; and a default the field cannot hold --
# wrong type, or outside its own enum/range -- is dropped rather than
# refused at generation time the way a hand-written k8s declaration would
# refuse it (Important 2 of the k93 review).
#
# `default: null` in a schema (common on a `nullable: true` field) decodes
# to undef; that is treated as no default at all, not as a default of
# undef, since the DSL's own field-option check refuses an undef value for
# any option, and a null default carries no information for the
# client-side check anyway.
sub _field_options {
    my ($prop_schema, $type_spec, $is_required) = @_;
    my %opts;
    $opts{required}    = 'schema' if $is_required;
    $opts{description} = $prop_schema->{description} if defined $prop_schema->{description};
    $opts{default}     = $prop_schema->{default}     if defined $prop_schema->{default};
    # nullable and x-kubernetes-preserve-unknown-fields are JSON booleans on
    # the wire and so need the same normalization every other Bool value in
    # the distribution gets (plain Perl truthiness would treat the string
    # 'false' as true). _normalize_bool only dies on a value that cannot
    # mean true or false at all (a non-scalar reference); a schema property
    # is always a plain scalar or JSON boolean here, so there is nothing for
    # an eval to usefully swallow (Minor 6 of the k93 review).
    $opts{nullable} = 1
        if IO::K8s::Resource::_normalize_bool($prop_schema->{nullable});
    $opts{preserve_unknown} = 1
        if IO::K8s::Resource::_normalize_bool($prop_schema->{'x-kubernetes-preserve-unknown-fields'});

    my $kind = _scalar_kind($type_spec);
    # A schema decoded from JSON carries a boolean default as a
    # JSON::PP::Boolean (or similar) blessed scalar ref, which fails the
    # field's own Bool constraint at class-generation time (_k8s's own
    # default-vs-type check). Normalize it the one way the distribution
    # normalizes every other Bool value rather than duplicating that rule
    # here (IO::K8s::Resource::_normalize_bool's own comment: "The one
    # boolean normalization in the distribution"). $kind is 'Bool' for both
    # the scalar Bool field and the [Bool] array field (_scalar_kind reads
    # through the array wrapper), but the default's own shape differs: a
    # [Bool] default is itself an arrayref of JSON booleans, and
    # _normalize_bool only accepts a scalar or scalar ref -- handing it the
    # arrayref whole would die and kill class generation over an entirely
    # legal default. Normalize per element instead, and drop the default
    # (rather than refuse generation) if any element cannot mean true/false,
    # the same "malformed default is dropped" rule every other option here
    # follows (carried over from the step-2 final re-review).
    if ($kind && $kind eq 'Bool' && exists $opts{default}) {
        if (_is_map_spec($type_spec)) {
            # A map of Bool (k191): the default is a hash, normalized value
            # by value and dropped when a value cannot mean true/false, as
            # the array case below does per element.
            my %normalized;
            if (ref $opts{default} eq 'HASH') {
                for my $key (keys %{ $opts{default} }) {
                    my $n = eval { IO::K8s::Resource::_normalize_bool($opts{default}{$key}) };
                    last if $@;
                    $normalized{$key} = $n;
                }
            }
            if (ref $opts{default} eq 'HASH' && keys %normalized == keys %{ $opts{default} }) {
                $opts{default} = \%normalized;
            } else {
                delete $opts{default};
            }
        } elsif (ref $type_spec eq 'ARRAY') {
            my @normalized;
            if (ref $opts{default} eq 'ARRAY') {
                for my $elem (@{ $opts{default} }) {
                    my $n = eval { IO::K8s::Resource::_normalize_bool($elem) };
                    last if $@;
                    push @normalized, $n;
                }
            }
            if (ref $opts{default} eq 'ARRAY' && @normalized == @{ $opts{default} }) {
                $opts{default} = \@normalized;
            } else {
                delete $opts{default};
            }
        } else {
            $opts{default} = IO::K8s::Resource::_normalize_bool($opts{default});
        }
    }
    if ($kind && $kind ne 'Bool') {
        # A typed map (k178) constrains each value, as an array each
        # element: its constraints sit on additionalProperties.
        my $src = ($prop_schema->{type} // '') eq 'array' ? ($prop_schema->{items} // {})
                : _is_map_spec($type_spec)                ? $prop_schema->{additionalProperties}
                :                                           $prop_schema;
        if (ref $src->{enum} eq 'ARRAY' && @{ $src->{enum} } && !grep { !defined } @{ $src->{enum} }) {
            my %seen;
            $seen{$_}++ for @{ $src->{enum} };
            $opts{enum} = $src->{enum} if keys %seen == @{ $src->{enum} };
        }
        if ($kind eq 'Int' || $kind eq 'Num') {
            my ($min, $max) = @{$src}{qw(minimum maximum)};
            $min = undef if defined $min && !looks_like_number($min);
            $max = undef if defined $max && !looks_like_number($max);
            if (defined $min && defined $max && $min > $max) {
                $min = $max = undef;
            }
            $opts{minimum} = $min if defined $min;
            $opts{maximum} = $max if defined $max;
        } elsif (defined $src->{pattern}) {
            my $re = eval { my $p = $src->{pattern}; qr/$p/ };
            $opts{pattern} = $re if $re;
        }
    }

    # A default the field cannot hold kills class generation via _k8s's own
    # default-vs-type check unless it is dropped here first. Built from the
    # same (already-filtered) enum/minimum/maximum/pattern collected above
    # so the check matches what _k8s itself would enforce. Object-bearing
    # and opaque fields ($kind undef) keep the default as given -- there is
    # no scalar Type::Tiny check to run there, and to_crd validates it
    # against the schema instead (Important 3 of the k93 review; _k8s's own
    # default check now skips those fields too).
    if (exists $opts{default} && $kind) {
        # An array's element type is the Type::Tiny object in the spec (k167);
        # a typed map's value type is the library type of that name, the one
        # IO::K8s::Resource's { X => 1 } form checks each value against --
        # the strict Quantity and Time among them (k178). A default that is
        # a hash, for a map, is checked value by value.
        my $base = ref $type_spec eq 'ARRAY' && blessed($type_spec->[0]) ? $type_spec->[0]
                 : _map_value_type($type_spec)                          ? _map_value_type($type_spec)
                 : ref $type_spec eq 'HASH'                             ? IO::K8s::Types->get_type($kind)
                 :                                                        IO::K8s::Resource::_scalar_base_for($kind);
        my %check_opts = map { $_ => $opts{$_} } grep { exists $opts{$_} } qw(enum minimum maximum pattern);
        my $constrained = IO::K8s::Resource::_constrain($base, $kind, \%check_opts, 'AutoGen default check');
        my $default_ok = ref $type_spec eq 'ARRAY'
            ? (ref $opts{default} eq 'ARRAY' && !grep { !$constrained->check($_) } @{ $opts{default} })
            : _is_map_spec($type_spec)
            ? (ref $opts{default} eq 'HASH' && !grep { !$constrained->check($_) } values %{ $opts{default} })
            : $constrained->check($opts{default});
        delete $opts{default} unless $default_ok;
    }

    return %opts ? \%opts : undef;
}

# Ensure parent packages exist
sub _ensure_package_exists {
    my ($class) = @_;
    my @parts = split /::/, $class;
    pop @parts;  # Remove the final class name

    my $current = '';
    for my $part (@parts) {
        $current .= '::' if $current;
        $current .= $part;
        no strict 'refs';
        unless (%{"${current}::"}) {
            # Create empty package
            eval "package $current; 1;" or warn "Could not create package $current: $@";
        }
    }
}

# Clear generated class cache (mainly for testing). %_failed is left alone on
# purpose: forgetting a failure would let the next request return the
# half-built package that failed run left behind (k149).
sub clear_cache {
    %_generated = ();
    %_nested_origin = ();
    %_descriptions = ();
    %_root_of = ();
    %_class_path = ();
}

# The schema `description` a generated class was built from, or undef when
# the schema had none. See IO::K8s::CRD::Emitter, the only consumer.
sub class_description {
    my ($class) = @_;
    return $_descriptions{$class};
}

# The top-level generated class (the Kind class) a nested class's naming
# started from, or $class itself when it already is one -- a root is never
# recorded in %_root_of, so this always falls back correctly. See
# IO::K8s::CRD::Emitter, which needs the true root to decide whether a
# reachable class belongs to the tree it is currently rendering.
sub class_root {
    my ($class) = @_;
    return $_root_of{$class} // $class;
}

# The '::'-joined path a nested class sits at below its root
# ('Spec::Acme::SolversItem::...'), recorded even when the class's own Perl
# name had to be shortened (see $MAX_CLASS_NAME). undef for a root class, or
# for any class AutoGen did not generate through _nested_class.
sub class_path {
    my ($class) = @_;
    return $_class_path{$class};
}

# List all generated classes -- complete ones only; a class begun by a run
# that failed is never listed (k149)
sub generated_classes {
    return keys %_generated;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::AutoGen - Dynamically generate IO::K8s classes from OpenAPI schema

=head1 VERSION

version 1.109

=head1 SYNOPSIS

    use IO::K8s::AutoGen;

    # Generate a class from OpenAPI schema
    my $class = IO::K8s::AutoGen::get_or_generate(
        'helm.cattle.io.v1.HelmChart',
        $schema_definition,
        $all_definitions,
        'IO::K8s::_AUTOGEN_abc123',  # namespace
    );

    # The class is now available and works like any IO::K8s class
    my $obj = $class->new(metadata => $meta, spec => $spec);
    my $json = $obj->TO_JSON;

=head1 DESCRIPTION

This module dynamically generates Moo classes for Kubernetes custom resources
that don't have pre-generated IO::K8s classes.

Generated classes use C<IO::K8s::Resource> as their base, so they have:

=over 4

=item * The C<k8s> DSL for attribute definitions

=item * C<TO_JSON> / C<to_json> serialization

=item * C<_k8s_attr_info> for inflate support

=item * All standard IO::K8s behavior

=back

Generated classes are placed in a unique namespace per IO::K8s instance
to avoid collisions:

    IO::K8s::_AUTOGEN_abc123::helm::cattle::io::v1::HelmChart

Each OpenAPI property also carries its field options (D3 of the CRD
design) into the generated class, through the same C<k8s> option hash a
hand-written class would use (see L<IO::K8s::Resource/k8s>): the schema's
C<required> list becomes the field's C<< required => 'schema' >> option, so a
generated class records which fields the schema demands -- available to
C<to_crd> and to L<IO::K8s::Resource/_k8s_attr_info> -- without enforcing
them at construction. An OpenAPI-required field can still be absent from a
real cluster document (a server-side default, a status object not yet
populated), and rejecting it at C<inflate> would reject valid data; use
C<< required => 1 >> for a field that must always be enforced (see
L<IO::K8s::Resource/k8s>). C<enum>, C<minimum>, C<maximum>, C<pattern>,
C<default>, C<description>, C<nullable> and
C<x-kubernetes-preserve-unknown-fields> are carried the same way, so a
generated class enforces enum, range and pattern values exactly like a
hand-written one that declares the same options. For an array property,
C<enum>/C<minimum>/C<maximum>/C<pattern> are read off C<items> and lifted
onto the field's own options, since it is each element that is
constrained, not the array itself. C<nullable> and
C<x-kubernetes-preserve-unknown-fields> are read as JSON booleans, not
Perl truthiness, so the wire string C<"false"> is false; a C<default> of
JSON C<null> -- common on a C<nullable: true> field -- is treated as no
default at all, not as a default of C<undef>, which the DSL's own
field-option check would otherwise refuse. A C<nullable: true> property
behaves as C<nullable> does on a hand-written field: an explicit
C<null> in a document is kept and written back, and the property gets
C<< has_<accessor> >> and C<< clear_<accessor> >>. A property whose
predicate or clearer name the class already answers to fails the generation
run, like any other declaration collision (see L<IO::K8s::Resource/k8s>).

A malformed schema option is dropped rather than failing the whole class:
the client-side check is a convenience, the API server validates every
value regardless, and dropping it loses no data. This covers an C<enum>
that is empty, has duplicate entries, or contains a JSON C<null>; a
C<pattern> that does not compile as a Perl regex; a C<minimum>/C<maximum>
where either bound is not a number or C<minimum> exceeds C<maximum>; and a
C<default> the field cannot hold -- the wrong type, or a value outside its
own enum or range.

OpenAPI C<type: number> becomes C<Num>, for a scalar property and for an
array's C<items> alike, so those values stay JSON numbers on the
wire rather than turning into strings; C<type: integer> likewise becomes
C<Int> and C<[Int]>. C<x-kubernetes-int-or-string: true> (or C<type:
string> with C<format: int-or-string>) becomes C<IntOrStr> and, on
C<items>, C<[IntOrStr]>, so an element C<8080> stays a JSON number and
C<'25%'> a string; C<type: string> with C<format: date-time> becomes
C<Time> and C<[Time]>. A map whose C<additionalProperties> is one
of these scalar schemas becomes a typed map: C<type: string> gives
C<HashRef[Str]>, and C<integer>, C<number>, C<boolean>, int-or-string and
C<date-time> give C<HashRef[Int]>, C<HashRef[Num]>, C<HashRef[Bool]>,
C<HashRef[IntOrStr]> and C<HashRef[Time]>.

A C<$ref> to one of the apimachinery scalar definitions --
C<resource.Quantity>, C<intstr.IntOrString>, C<meta.v1.Time> and
C<meta.v1.MicroTime> -- is typed as that scalar wherever it sits: a
property becomes C<Quantity>, C<IntOrStr> or C<Time>, an array's C<items>
C<[Quantity]>, C<[IntOrStr]> or C<[Time]>, and a map's
C<additionalProperties> C<HashRef[Quantity]>, C<HashRef[IntOrStr]>
or C<HashRef[Time]>, whether or not the spec carries the definition.
Before, the C<items> and C<additionalProperties> forms were generated from
the definition, a bare C<type: string>, as an empty class that no quantity
or timestamp could inflate into.

The C<Time> and C<Quantity> of a generated class accept any string, as a
scalar field and as an array element alike: a custom resource's
C<date-time> is stored as written, and RFC 3339 allows a lowercase C<t> and
C<z> the strict check of a hand-written C<Time> field refuses, so a
generated class never fails to inflate what the API server returned. The
API server validates the format regardless. A hand-written or emitted
class keeps the strict checks, and so does the typed map above -- the DSL
has only the one C<HashRef[Quantity]> and C<HashRef[Time]> -- which
only a swagger C<$ref> reaches, whose values the API server writes in
canonical form.

An inline C<type: object> schema with its own non-empty C<properties> also
becomes a typed class now (D10), named after its place in the parent --
C<< <Parent>::<Prop> >>, with an C<Item> / C<Value> suffix for array items
and map values shaped the same way -- so its properties get field options
exactly like a class built from a C<$ref>. A property-less C<type:
object> (or one with C<x-kubernetes-preserve-unknown-fields>) becomes
C<Opaque>, and an C<additionalProperties>-only map (no C<properties> of
their own) a C<HashRef[X]>, with nothing underneath to attach options to. Scalar properties carry their options at every level
regardless.

A path-derived nested class name that would run past Perl's 251-character
limit on a fully qualified identifier (cert-manager's CRDs inline a full
C<PodTemplateSpec> several levels into a C<Challenge>'s C<spec>, and the
namespace prefix an AutoGen instance generates under adds still more) is
shortened instead of failing class generation: C<< <root>::_<10 hex chars>
>>, the root being the top-level generated class (the Kind) the nesting
started from and the hex digits a C<Digest::SHA::sha1_hex> of the full,
unshortened logical name. The logical path is not lost -- L</"class_path($class)">
and L</"class_root($class)"> recover it -- and a name collision between two
different schema keys is still detected against that full logical name,
never against the (much smaller) space of possibly-shortened names.

A nested object -- or an array's C<items>, or a map's
C<additionalProperties> -- whose property set exactly matches a shipped
core or apimachinery class's own key set is typed as that class instead of
a new nested one (D5, C<reuse_core>, default on): a CRD's inline
C<LabelSelector> or C<HTTPHeader>-shaped struct becomes the real IO::K8s
class rather than a per-provider copy. C<get_or_generate>'s C<< reuse_core
=> 0 >> option turns this off and restores the pre-D5 behavior (every
inline object becomes its own nested class, per D10 above).

A name match alone is not enough to reuse a class -- it only decides which
classes L</"core_class_for_shape(\@json_keys)"> lists as candidates. The reuse decision
applies three further checks: a shape under two keys is never reused (a
single shared key name -- C<{value}>, C<{name}>, ... -- is common enough by
accident that this alone rules out most of it); every remaining candidate
must be type-compatible with the schema, key by key (a schema C<string>
field can't reuse a class that declares the same-named field as an array,
for instance -- see L</"core_class_for_shape(\@json_keys)"> below for the full
compatibility table); and where several candidates survive that filter,
they are reused as the preferred one (apimachinery's C<LabelSelector>
family first, then the rest of C<Meta::V1>, then C<Core::V1>, then
alphabetically) only when they are wire-identical -- the same type per key
(ignoring required-ness: a field being optional on one shipped class and
mandatory on another doesn't change what value it holds) and the same
referenced class per key, where a key has one. C<{name,value}> matches
three unrelated Core::V1 leaf structs -- C<HTTPHeader>, C<PodDNSConfigOption>,
C<Sysctl> -- wire-identical despite one of the three having two optional
fields where the other two have two required ones, so it reuses the
preferred one, C<HTTPHeader>. C<{key,operator,values}> matches
C<LabelSelectorRequirement> and C<FieldSelectorRequirement> (C<Meta::V1>)
as well as C<NodeSelectorRequirement> (C<Core::V1>) -- also wire-identical
despite spanning two API areas -- so it reuses C<LabelSelectorRequirement>.
A shape shared by candidates that are NOT wire-identical -- an optional
field naming a different referenced class, e.g. C<{metadata,spec}>
matching C<PodTemplateSpec>, C<JobTemplateSpec>,
C<ResourceClaimTemplateSpec> and others, each with C<spec> typed
differently -- stays a nested class rather than guess which one is meant.

Surviving all of that is still not enough: the chosen class must also
hold what the schema describes all the way down, not merely match it key by
key at the top level -- an array field's C<items>, a map's
C<additionalProperties> values, and any nested object field are checked the
same way, recursively. A C<$ref> met along the way is resolved read-only
against the same definitions the schema's own C<$ref>s resolve against; one
that does not resolve counts as not held, never as a pass. An
C<Opaque> field on the candidate matches only a schema fragment that
would itself become an C<Opaque> map -- no C<properties>, no scalar or structured
C<additionalProperties> -- with one exception: a bare C<{type: object}>
field matches a candidate field typed as C<ObjectMeta>, since that is how
C<controller-gen> renders an embedded C<metav1.ObjectMeta> below a CRD's
root. A nested schema fragment that never states its own C<required> list
makes no requiredness claim at that level either, the same rule the
top-level check above follows. This is a final gate on the pick above, not a
sharper filter ahead of it: it can only withdraw a reuse the checks above
already chose, never manufacture a new one -- C<LabelSelectorRequirement>'s
C<{key,operator,values}> shape stops being reused the moment a schema's own
C<values> turns out to hold an array of objects rather than scalars; that
schema gets its own nested class instead.

A C<$ref> to one of the apiextensions union types --
C<io.k8s.apiextensions-apiserver.pkg.apis.apiextensions.v1.JSON>,
C<...v1.JSONSchemaPropsOrArray>, C<...v1.JSONSchemaPropsOrBool> and
C<...v1.JSONSchemaPropsOrStringArray> -- is typed as the class IO::K8s
ships for it (C<Apiextensions::V1::JSON> and so on), as a property, as an
array's C<items> or as a map's values. Upstream describes these
definitions without any properties, because none of them is a JSON object
(any JSON value; a schema or an array of schemas; a schema or a boolean; a
schema or a string array); the shipped classes inflate through
C<FROM_STRUCT> and write the value back exactly as it came, where a class
generated from the empty definition could not hold C<default: "foo"> at
all. This holds whatever C<reuse_core> says, and whether or not the spec
carries the definitions -- the names are resolved like the apimachinery
C<IntOrString>, C<Quantity> and C<Time>. IO::K8s ships no v1beta1
apiextensions classes: the same four names under C<v1beta1> are carried
opaquely by the v1 C<JSON> class, which keeps any value unchanged but does
not type a schema inside it.

=head1 NAME

IO::K8s::AutoGen - Dynamically generate IO::K8s classes from OpenAPI schema

=head1 FUNCTIONS

=head2 get_or_generate($def_name, $schema, $all_defs, $namespace)

Generate (or return cached) class for the given OpenAPI definition.

Extra positional options after C<$namespace> pin the identity of a
top-level object (C<< api_version => ..., kind => ..., resource_plural =>
..., is_namespaced => ... >>); the generated class then also composes
L<IO::K8s::Role::APIObject>. C<< reuse_core => 0|1 >> (default 1) controls
D5's core-class reuse; see above.

When C<api_version> (or C<kind> / C<resource_plural>) is supplied, the
generated class installs fixed-value methods for each. These are fixed
identity, not writable fields: passing an argument croaks rather than
silently retargeting the object -- the same contract the
hand-written CRD template installs via L<IO::K8s::APIObject>.

C<< subresources => { ... } >>, which L<IO::K8s::CRD/generate> passes
for a CRD version that has any, installs the C<subresources> identity method
the C<use IO::K8s::APIObject> parameter of that name installs, on a
top-level class, so its C<to_crd> writes them back. It is checked the same
way and croaks naming the class and the key; like a failed GVK selection,
that happens before the class is marked as begun, so it builds and poisons
nothing.

This function fails closed on input it cannot generate a faithful class
from, rather than dropping fields or inventing a wrong type. It C<croak>s
when:

=over 4

=item *

a property, an array's C<items>, or an C<additionalProperties> schema
carries a C<$ref> to a definition not present in C<$all_defs> -- other than
the apimachinery scalars and the apiextensions union types, which are
resolved by name (see L</DESCRIPTION>). A partial
spec that references definitions it does not ship used to generate the
class anyway, minus those fields -- losing their data on every round-trip.
It now dies naming the C<$ref> and where it appeared.

=item *

C<additionalProperties> is a reference that is neither a schema object nor
a JSON boolean; the message names the class and field.

=item *

the schema's C<x-kubernetes-group-version-kind> metadata is ambiguous for
the requested C<api_version>, or names no entry matching it -- the GVK
selection fails closed rather than pick a version.

=item *

a top-level class -- one with an C<api_version> and a C<kind> -- has a
property whose accessor would take the name of a method of
L<IO::K8s::Role::APIObject> (C<label>, C<save>, C<is_ready>, ..., and the
C<spec_*> methods of L<IO::K8s::Role::SpecBuilder>, which it composes) or of
the identity methods C<api_version> and C<resource_plural>. The
identity methods and the role are in place before the first property is
declared, the order C<use IO::K8s::APIObject> gives a hand-written class,
so the declaration check of L<IO::K8s::Resource/k8s> refuses the property
with C<< k8s: field 'label' of <class> collides with the method 'label' of
<class>, which is not an attribute >>. Before, such a property silently
replaced the role method on the generated class. The exceptions are that
check's own: a C<conditions> property takes over the role's condition
helper, and C<apiVersion>, C<kind> and C<metadata> are not declared from
the schema at all, since the class already supplies them. A nested class
composes no role, so these names are ordinary fields there. Nothing is
renamed.

=back

A failure anywhere in this process is a failure of the whole generation run,
not just of the one class being built: the root class, every
C<$ref>'d definition generated on the way, and every nested class -- the
"run" -- succeed or fail together. The one exception is the GVK-selection
failure above (the third bullet): it happens before the class is marked as
begun, so it builds, and poisons, nothing -- a retry with a matching
C<api_version> resolves to the same class name and works normally. Any other
failure during the run -- an unresolved C<$ref> surfacing from a nested
class several levels down, a bad C<additionalProperties>, or anything else
the run's own code raises -- marks every class the run began, in this call's
C<$namespace>, as permanently failed with that run's original error, even a
dependency whose own fields had already finished cleanly (it may well point
back at the class that died). Nothing already built is rolled back -- the
packages and their Moo internals stay exactly as the run left them -- but a
later request for any of those classes, whether asked for directly or
reached again as another class's dependency, re-raises the original error
behind a prefix explaining that the class failed earlier and stays failed,
rather than handing back a half-typed package or silently rebuilding it.
This failure record survives L</clear_cache()>; the only way to retry is to
load a repaired schema into a fresh C<IO::K8s> instance, which gets its own
AutoGen namespace and so a class name the earlier failure never touched.
C<add_crd> in L<IO::K8s::CRD>, which calls this function, inherits the same
contract: a CRD that fails to generate stays failed for that C<IO::K8s>
instance.

One partial-spec shape still generates successfully by design: a top-level
CRD schema whose C<metadata> C<$ref>s the standard C<ObjectMeta> without
shipping its definition. C<metadata> is supplied by the role and is skipped
before its C<$ref> is looked at, so this common single-schema
hand-in does not trip the unresolved-C<$ref> refusal. A side effect of that
skip: when C<$all_defs> does carry C<ObjectMeta> and nothing else
references it, it no longer appears in L</generated_classes()>.

=head2 def_to_class($def_name, $namespace)

Convert OpenAPI definition name to Perl class name.

=head2 class_to_def($class)

Convert Perl class name back to OpenAPI definition name.

=head2 is_autogen($class)

Returns true if the class was auto-generated.

=head2 clear_cache()

Clear the generated class cache. Classes generated before the call keep
working -- their packages already exist and nothing here touches them --
but regenerating the same names into the same namespace afterward is
unsupported: Moo cannot rebuild an existing package, and L</"class_path($class)"> /
L</"class_root($class)"> forget what they knew about the classes this cleared.

A class that failed to generate (see
L</get_or_generate($def_name, $schema, $all_defs, $namespace)>) is not reset
by this call -- its failure record is kept on purpose, so a later request
for it still re-raises the run's original error instead of handing back the
half-built package the failed run left behind. The only way to retry
that class is to generate it into a fresh C<IO::K8s> instance's namespace.

=head2 generated_classes()

List the class names whose generation run completed successfully. A class
begun by a run that later failed is never listed here, even though its
package may still exist in memory and even though it can never be generated
again in this namespace (see
L</get_or_generate($def_name, $schema, $all_defs, $namespace)>).

=head2 class_description($class)

The schema C<description> a generated class was built from, or C<undef>
when the schema carried none. Used by L<IO::K8s::CRD::Emitter> to fill in
a rendered class's C<# ABSTRACT> line.

=head2 class_root($class)

The top-level generated class (the Kind class) C<$class>'s nesting started
from, or C<$class> itself when it already is a root -- including when
C<$class> is not something AutoGen generated at all. Never C<undef>.

=head2 class_path($class)

The C<::>-joined field path C<$class> sits at below its L</"class_root($class)">
(C<Spec::Acme::SolversItem::...>), recorded even when C<$class>'s own Perl
name had to be shortened past Perl's identifier limit. C<undef> for a root
class or for a class AutoGen did not generate through nested-object
handling.

=head2 core_class_for_shape(\@json_keys)

    my @classes = IO::K8s::AutoGen::core_class_for_shape([qw(key operator values)]);

Every shipped core / apimachinery class (under C<IO::K8s::Api> and
C<IO::K8s::Apimachinery>) whose own key set is exactly C<@json_keys>, most
preferred first (apimachinery's C<LabelSelector>, then the rest of
C<Meta::V1>, then C<Core::V1>, then alphabetically). Empty when no shipped
class has that exact shape. A class's own C<metadata> counts as part of
its shape only when the class is an embedded type (C<PodTemplateSpec>:
C<{metadata,spec}>, a real schema-visible field); a top-level Kind's
C<metadata> is supplied by L<IO::K8s::Role::APIObject> outside the
schema's own properties and is dropped, so e.g. C<Pod>'s indexed shape is
C<{spec,status}>. This is a name match only, by key set alone -- it says
nothing about whether reusing any listed class is actually safe for a
given schema; that is D5's C<reuse_core> reuse decision (see above), which
consults this same index but additionally requires a type-compatible
candidate (a per-key check against the schema: C<string> -- including
C<format: date-time> -- matches
C<is_str>/C<is_int_or_string>/C<is_quantity>/C<is_time>; int-or-string --
C<x-kubernetes-int-or-string>, or C<type: string> with C<format:
int-or-string> -- matches C<is_int_or_string> or C<is_quantity> (the form
C<controller-gen> gives a C<resource.Quantity>), never a C<Str> field that
would write C<8080> back as C<"8080"> nor a C<Time>; C<integer>
matches C<is_int> or C<is_int_or_string>; C<number> matches C<is_num>;
C<boolean> matches C<is_bool>; C<array> matches any C<is_array_of_*>;
C<object>, whether the schema property has C<properties> of its own or is
a map, matches C<is_object>, C<is_inline_struct> or any C<is_hash_of_*>),
and -- when several type-compatible candidates remain -- requires them to
be wire-identical before picking the preferred one. Picking a class this way
is still not the final word: it must also hold the schema all the way down
-- array items, map values, nested object fields, checked recursively -- or
nothing is reused after all (see above for the full rule, including
the C<$ref>, opaque-map and C<ObjectMeta> special cases).

The index itself is precomputed and shipped as
L<IO::K8s::AutoGen::CoreShapes>, regenerated by
F<maint/core-shape-index-gen.pl> and checked against the shipped classes
by F<t/85_core_shape_index.t>; where that module is missing it is rebuilt
on first call by loading every class under the two trees instead, which
costs seconds rather than milliseconds but produces the same index. Either
way, only the classes a looked-up shape actually names are loaded -- the
returned names are always loadable, loaded classes, since the reuse
decision reads their attribute registries.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

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

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
