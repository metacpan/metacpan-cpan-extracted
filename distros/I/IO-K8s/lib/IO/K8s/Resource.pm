package IO::K8s::Resource;
# ABSTRACT: Base class for all Kubernetes resources
our $VERSION = '1.108';
use v5.10;
use Moo ();
use Moo::Role ();
use Import::Into;
use Package::Stash;
use Types::Standard qw( ArrayRef Bool HashRef InstanceOf Int Maybe Num Str );
use IO::K8s::Types qw( IntOrStr Quantity Time );
use IO::K8s::Role::Resource ();
use Scalar::Util qw( blessed reftype looks_like_number );
use Carp qw( croak );

# Registry: class -> attr -> { type, class, is_array, is_hash, is_bool, is_int }
# Use 'our' to make it a proper package variable accessible via symbol table
our %_attr_registry;

# Unknown-field policy (D1). Off: a constructor key no attribute claims is
# kept in the object's _unknown_fields bag and emitted again by TO_JSON, so
# a document from a newer upstream than the class still round-trips. On: it
# dies naming the class and the field. IO::K8s localizes this around its own
# entry points when built with strict => 1 (see IO::K8s/strict); nothing
# else writes it. A package variable rather than a constructor argument so
# that it reaches the inline-struct coercers, which call ->new directly and
# never pass through IO::K8s::_inflate_struct.
our $STRICT = 0;

# Class name expansion map
my %_class_prefix = (
    'Core'           => 'IO::K8s::Api::Core',
    'Apps'           => 'IO::K8s::Api::Apps',
    'Batch'          => 'IO::K8s::Api::Batch',
    'Networking'     => 'IO::K8s::Api::Networking',
    'Rbac'           => 'IO::K8s::Api::Rbac',
    'Storage'        => 'IO::K8s::Api::Storage',
    'Policy'         => 'IO::K8s::Api::Policy',
    'Autoscaling'    => 'IO::K8s::Api::Autoscaling',
    'Admissionregistration' => 'IO::K8s::Api::Admissionregistration',
    'Coordination'   => 'IO::K8s::Api::Coordination',
    'Discovery'      => 'IO::K8s::Api::Discovery',
    'Events'         => 'IO::K8s::Api::Events',
    'Flowcontrol'    => 'IO::K8s::Api::Flowcontrol',
    'Node'           => 'IO::K8s::Api::Node',
    'Scheduling'     => 'IO::K8s::Api::Scheduling',
    'Certificates'   => 'IO::K8s::Api::Certificates',
    'Authentication' => 'IO::K8s::Api::Authentication',
    'Authorization'  => 'IO::K8s::Api::Authorization',
    'Resource'       => 'IO::K8s::Api::Resource',
    'Storagemigration' => 'IO::K8s::Api::Storagemigration',
    'Lifecycle'      => 'IO::K8s::Api::Lifecycle',
    'Meta'           => 'IO::K8s::Apimachinery::Pkg::Apis::Meta',
    'Apiextensions'  => 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions',
    'KubeAggregator' => 'IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration',
    # Bundled CRD providers (step 4, k95/D6): a provider class is written
    # the same short way a core class is ('Traefik::V1alpha1::Middleware'
    # like 'Core::V1::Pod'), not '+IO::K8s::Traefik::V1alpha1::Middleware'.
    # PrometheusOperator, VolumeSnapshot and ExternalSecrets have no shipped
    # classes yet -- the prefixes are reserved ahead of their provider tasks
    # so the emitter can start rendering short names for them immediately.
    'Cilium'             => 'IO::K8s::Cilium',
    'Traefik'            => 'IO::K8s::Traefik',
    'CertManager'        => 'IO::K8s::CertManager',
    'GatewayAPI'         => 'IO::K8s::GatewayAPI',
    'K3s'                => 'IO::K8s::K3s',
    'AgentSandbox'       => 'IO::K8s::AgentSandbox',
    'PrometheusOperator' => 'IO::K8s::PrometheusOperator',
    'VolumeSnapshot'     => 'IO::K8s::VolumeSnapshot',
    'ExternalSecrets'    => 'IO::K8s::ExternalSecrets',
);

# Type flag lookup table
my %TYPE_FLAGS = (
    Str      => { is_str => 1 },
    Int      => { is_int => 1 },
    Num      => { is_num => 1 },
    Bool     => { is_bool => 1 },
    IntOrStr => { is_int_or_string => 1 },
    Quantity => { is_quantity => 1 },
    Time     => { is_time => 1 },
);

# For string path: map type name to base Type::Tiny constraint
# Custom K8s types (IntOrStr, Quantity, Time) fall back to Str
my %STR_ISA_MAP = (
    Str  => Str,
    Int  => Int,
    Num  => Num,
    Bool => Bool,
);

# The Type::Tiny base type for a scalar kind name -- Str, Int, Num, Bool
# keep their own Types::Standard constraint; IntOrStr, Quantity and Time
# fall back to Str, the same way the bareword type-spec branch of _k8s
# does via %STR_ISA_MAP above. Exposed so AutoGen's own default-vs-kind
# guard (_field_options) can build the same constrained type _k8s would
# without duplicating this map.
sub _scalar_base_for {
    my ($kind) = @_;
    return $STR_ISA_MAP{$kind} // Str;
}

# Value types for the hash-of-scalar-type DSL form { TypeName => 1 } (k63).
# 'Str' is deliberately NOT here: it keeps its historical bare-HashRef meaning,
# the genuinely opaque string map that labels, annotations and fieldsV1 need.
# Everything here constrains each VALUE against the scalar type, so a map
# upstream declares as map[X]Quantity finally rejects cpu => 'banana' at
# construction instead of at the API server.
my %HASH_VALUE_TYPES = (
    Int      => { isa => Int,      flag => 'is_hash_of_int' },
    Num      => { isa => Num,      flag => 'is_hash_of_num' },
    Bool     => { isa => Bool,     flag => 'is_hash_of_bool' },
    Quantity => { isa => Quantity, flag => 'is_hash_of_quantity' },
    Time     => { isa => Time,     flag => 'is_hash_of_time' },
    IntOrStr => { isa => IntOrStr, flag => 'is_hash_of_int_or_string' },
);

# Field options a declaration may carry (D3): the third argument
# (`k8s name => Type, { ... }`) or, inside an inline struct, the two-element
# form `name => [ Type, { ... } ]`. The legacy 'required' marker and the
# `Type!` suffix still work and mean { required => 1 }. Everything here is
# recorded in the registry for to_crd; enum, minimum, maximum and pattern
# are also enforced at construction, the way { Quantity => 1 } validates
# its values -- a bad value fails here instead of at the API server.
# default is deliberately NOT applied client-side: defaulting is the API
# server's job, and a client default would change the wire output.
my %FIELD_OPTIONS = map { $_ => 1 } qw(
    required default enum minimum maximum pattern description nullable
    preserve_unknown
);
my %NUMERIC_KIND = (Int => 1, Num => 1);
my %STRING_KIND  = (Str => 1, IntOrStr => 1, Quantity => 1, Time => 1);

# The value constraints as child types of the field's base type, so a
# failure names the rule ("is not one of", "is below the minimum") rather
# than an anonymous intersection. $kind is the scalar type name the field
# is built on (Str, Int, Num, Bool, IntOrStr, Quantity, Time).
sub _constrain {
    my ($base, $kind, $opts, $where) = @_;
    my $type = $base;

    if (exists $opts->{enum}) {
        croak "k8s: 'enum' for $where must be a non-empty arrayref"
            unless ref $opts->{enum} eq 'ARRAY' && @{ $opts->{enum} };
        croak "k8s: 'enum' is not allowed on a Bool field ($where)" if $kind eq 'Bool';
        my %allowed = map { $_ => 1 } @{ $opts->{enum} };
        croak "k8s: 'enum' for $where has duplicate entries"
            unless @{ $opts->{enum} } == keys %allowed;
        my $list = join ', ', @{ $opts->{enum} };
        $type = $type->create_child_type(
            display_name => $type->display_name . '[enum]',
            constraint   => sub { defined $_ && exists $allowed{$_} },
            message      => sub { "Value \"$_\" is not one of: $list" },
        );
    }

    if (exists $opts->{minimum} || exists $opts->{maximum}) {
        croak "k8s: 'minimum' and 'maximum' need an Int or Num field, not $kind ($where)"
            unless $NUMERIC_KIND{$kind};
        my ($min, $max) = @{$opts}{qw(minimum maximum)};
        for my $bound ($min, $max) {
            croak "k8s: 'minimum' and 'maximum' for $where must be numbers"
                if defined $bound && !looks_like_number($bound);
        }
        croak "k8s: 'minimum' ($min) must not exceed 'maximum' ($max) for $where"
            if defined $min && defined $max && $min > $max;
        $type = $type->create_child_type(
            display_name => $type->display_name . '[range]',
            constraint   => sub {
                (!defined $min || $_ >= $min) && (!defined $max || $_ <= $max)
            },
            message      => sub {
                defined $min && $_ < $min
                    ? "Value \"$_\" is below the minimum $min"
                    : "Value \"$_\" is above the maximum $max";
            },
        );
    }

    if (exists $opts->{pattern}) {
        croak "k8s: 'pattern' needs a string field, not $kind ($where)"
            unless $STRING_KIND{$kind};
        my $re = ref $opts->{pattern} eq 'Regexp'
            ? $opts->{pattern}
            : eval { my $p = $opts->{pattern}; qr/$p/ };
        croak "k8s: 'pattern' for $where does not compile: $@" unless $re;
        $type = $type->create_child_type(
            display_name => $type->display_name . '[pattern]',
            constraint   => sub { defined $_ && $_ =~ $re },
            message      => sub { "Value \"$_\" does not match the pattern $re" },
        );
    }

    return $type;
}

# Options that only make sense on a scalar-bearing field. Object, struct
# and opaque container fields reject them at class load.
sub _reject_value_options {
    my ($opts, $where) = @_;
    croak "k8s: 'enum' needs a scalar field ($where)" if exists $opts->{enum};
    croak "k8s: 'minimum' and 'maximum' need a scalar field ($where)"
        if exists $opts->{minimum} || exists $opts->{maximum};
    croak "k8s: 'pattern' needs a scalar field ($where)" if exists $opts->{pattern};
}

sub import {
    my $class = shift;
    my $caller = caller;
    $class->_setup_class($caller);
}

sub _setup_class {
    my ($class, $target) = @_;
    Moo->import::into($target);
    Types::Standard->import::into($target, qw( Str Int Bool Num ));
    IO::K8s::Types->import::into($target, qw( IntOrStr Quantity Time ));
    Moo::Role->apply_roles_to_package($target, 'IO::K8s::Role::Resource');
    my $stash = Package::Stash->new($target);
    $stash->add_symbol('&k8s', sub { $class->_k8s($target, @_) });
}

sub _expand_class {
    my ($short) = @_;

    # +FullClassName - strip + and use as-is
    return substr($short, 1) if $short =~ /^\+/;

    # Already fully qualified?
    return $short if $short =~ /^IO::K8s::/;

    # Prefix match against %_class_prefix: try the longest key first so that
    # CamelCase prefixes like KubeAggregator win over a hypothetical shorter
    # substring. Anything in the map is canonical — the lookup IS the source
    # of truth, the regex is not. Unknown short names still fall through to
    # the IO::K8s::Api default so this stays backwards compatible.
    if ($short =~ /^([A-Z]\w*)::/) {
        for my $prefix (sort { length($b) <=> length($a) } keys %_class_prefix) {
            next unless $short =~ /^\Q$prefix\E::/;
            $short =~ s/^\Q$prefix\E:://;
            return $_class_prefix{$prefix} . '::' . $short;
        }
    }

    # Default: assume it's under IO::K8s::Api
    return "IO::K8s::Api::$short";
}

# A read-only view of %_class_prefix (short prefix -> full namespace),
# keyed the same as the map _expand_class walks above. This started as a
# lexical 'my' with a single reader inside this file; IO::K8s::CRD::Emitter
# is the first outside consumer, building the REVERSE map (full namespace
# -> short prefix) from it so a rendered class reference uses the short
# form a hand-written class would ('Traefik::V1alpha1::Middleware',
# 'Core::V1::PodTemplateSpec') instead of always spelling out '+Full::Name'.
sub class_prefixes { \%_class_prefix }

sub _is_type_tiny {
    my ($obj) = @_;
    return blessed($obj) && $obj->isa('Type::Tiny');
}

# Sanitize JSON field names into valid Perl identifiers for Moo attributes:
# every character outside [A-Za-z0-9_] becomes '_' -- $ref -> _ref,
# $schema -> _schema, x-kubernetes-foo -> x_kubernetes_foo, x.y/z -> x_y_z,
# and the same for any other character a schema's property key happens to
# carry, not only the '-', '.' and '/' realistic CRD schemas mostly produce.
# This matters beyond cosmetics: `has` is always called with an `isa` type
# constraint here (see _k8s below), which routes through Sub::Quote's
# inlined accessor generation, and that dies naming the attribute as an
# invalid sub name for any of these characters -- the same failure
# IO::K8s::AutoGen::_class_segments exists to avoid for package segments,
# just one call site over (the attribute name here, not a class name; the
# two use the same blanket rule). A CRD schema is free to use any of these
# characters in a property key; the original is preserved on the wire via
# the caller's existing json_key/init_arg mapping below whenever this
# changes the name.
sub _sanitize_attr_name {
    my ($name) = @_;
    return $name unless $name =~ /[^a-zA-Z0-9_]/;
    (my $safe = $name) =~ s/[^A-Za-z0-9_]/_/g;
    return $safe;
}

# The one boolean normalization in the distribution: everything that can
# arrive on a Bool attribute, reduced to a plain 0/1 -- or undef, meaning
# "leave the field unset". Used by the Bool and [Bool] coercers below and,
# before the constructor even runs, by the is_bool branch of
# IO::K8s::_inflate_struct -- those two used to disagree (k37).
#
# Two traps, both of which silently flip false into true:
#   * every reference is true in Perl, so \0 (the bare false idiom) and a
#     JSON::PP::Boolean (a blessed ref to 0) must be dereferenced, not tested;
#   * 'false' is a non-empty string and therefore true, so the strings have to
#     be spelled out rather than left to truthiness.
#
# Anything that cannot mean true or false dies (k42): a non-scalar
# reference, and a scalar ref that dereferences to yet another reference
# (\\0 used to come out silently true). reftype, not ref, so that blessed
# scalar refs -- JSON::PP::Boolean, boolean.pm, Types::Serialiser, any
# bless \(my $x = 0) -- keep working. Messages end in \n deliberately:
# they are diagnostics, and the callers (Moo's coercion wrapper, the
# eval/rethrow in _inflate_struct) attach the attribute context.
sub _normalize_bool {
    my ($value) = @_;
    if (ref $value) {
        my $reftype = reftype($value);
        die "Bool value must be a scalar or scalar ref, got $reftype\n"
            unless $reftype eq 'SCALAR' || $reftype eq 'REF';
        $value = $$value;
        die 'Bool scalar ref dereferenced to another reference ('
            . ref($value) . "), not a boolean\n" if ref $value;
    }
    # Explicit undef stays undef: the attribute is Maybe[Bool], TO_JSON
    # omits undef, and "no value" must not turn into an explicit false on
    # the wire (k48). `return undef`, not bare `return` -- in the
    # [Bool] coercer's list context a bare return would drop the element.
    return undef unless defined $value;
    return 0 if lc($value) eq 'false';
    return $value ? 1 : 0;
}

# The coercion a single object-bearing field gets (k100): a plain hashref
# becomes an instance of $class_name, built by the very call FROM_HASH
# makes, so bool normalization and the D1 unknown-field policy are the ones
# the inflate path already uses instead of a second, subtly different way of
# building the same object. See the is_object branch of _k8s below for why
# one `ref eq 'HASH'` test is the whole guard.
#
# Named rather than written inline in that branch for the same reason
# _normalize_bool above is: a second caller needs exactly this, and the two
# must not drift. That caller is IO::K8s::Role::APIObject, whose `metadata`
# is a plain `has` -- the role composes before any k8s declaration runs, so
# _k8s's "don't overwrite a role's attribute" guard means it registers
# metadata but never creates it, and a coercer installed here would never
# reach it (k115). The role therefore declares metadata with this coercion
# from the start.
#
# $class_name is captured; IO::K8s::Role::Resource::_default_k8s() is
# touched at COERCION time only, never while the attribute is installed --
# _k8s runs at compile time of every one of the ~850 classes, and
# _default_k8s requires IO::K8s, which loads this file.
sub _object_coercer {
    my ($class_name) = @_;
    return sub {
        return $_[0] unless ref $_[0] eq 'HASH';
        return IO::K8s::Role::Resource::_default_k8s()
            ->_struct_to_object_expanded($class_name, $_[0]);
    };
}

sub _generate_inline_struct {
    my ($class_name, $fields) = @_;
    __PACKAGE__->_setup_class($class_name);
    for my $field_name (keys %$fields) {
        __PACKAGE__->_k8s($class_name, $field_name, $fields->{$field_name});
    }
}

sub _k8s {
    my ($class, $caller, $name, $type_spec, $marker) = @_;

    my $json_key  = $name;
    my $attr_name = _sanitize_attr_name($name);
    my $where     = "field '$name' of $caller";

    # Inline-struct form: name => [ Type, { options } ]. Exactly two elements
    # with a hashref second is unambiguous -- every array type spec ([Str],
    # ['Core::V1::Container'], [ {} ], [ [] ]) has one element.
    if (ref $type_spec eq 'ARRAY' && @$type_spec == 2 && ref $type_spec->[1] eq 'HASH') {
        ($type_spec, $marker) = @$type_spec;
    }

    my %opts;
    if (ref $marker eq 'HASH') {
        %opts = %$marker;
    } elsif (defined $marker && $marker eq 'required') {
        $opts{required} = 1;
    } elsif (defined $marker) {
        croak "k8s: third argument for $where must be 'required' or a hashref of field options, got '$marker'";
    }
    for my $key (sort keys %opts) {
        croak "k8s: unknown field option '$key' for $where (known: "
            . join(', ', sort keys %FIELD_OPTIONS) . ')'
            unless $FIELD_OPTIONS{$key};
    }
    # An option present with an undef value is a declaration error, not a
    # no-op: `pattern => $schema->{pattern}` on an upstream schema with no
    # pattern would otherwise compile to a match-everything regex instead
    # of simply not declaring the option, and the same silent trap applies
    # to every other option (an undef default is not a JSON null we model).
    for my $key (sort keys %opts) {
        croak "k8s: field option '$key' for $where must not be undef"
            unless defined $opts{$key};
    }
    # required => 1 (or the legacy 'required' marker / '!' suffix) both
    # enforces the field at construction and records required => 1 in the
    # registry. required => 'schema' does the second half only: AutoGen
    # uses it for an OpenAPI schema's required list, since a real cluster
    # document can omit a field the schema requires -- a server-side
    # default, or an object still short of that field (an empty status
    # right after creation) -- and Moo enforcement would reject a
    # perfectly valid document for it (Critical 1 of the k93 review). Any
    # other true value is treated the same as 1.
    my $required_opt = delete $opts{required};
    my $required_recorded = $required_opt ? 1 : 0;
    my $required = ($required_opt && $required_opt ne 'schema') ? 1 : 0;

    # `!` suffix on strings (legacy/alternative required syntax)
    if (!ref $type_spec && !_is_type_tiny($type_spec) && $type_spec =~ s/!$//) {
        $required = $required_recorded = 1;
    } elsif (ref $type_spec eq 'ARRAY' && !ref($type_spec->[0]) && $type_spec->[0] =~ s/!$//) {
        $required = $required_recorded = 1;
    }

    # Ensure the registry entry exists
    $_attr_registry{$caller} = {} unless exists $_attr_registry{$caller};

    # Every branch below sets $inner, the type of a present value; the
    # Maybe wrapping for an optional field happens once at the end.
    my %info;
    my $inner;

    # Handle Type::Tiny objects directly (Str, Int, Bool, IntOrStr, Quantity, Time)
    if (_is_type_tiny($type_spec)) {
        my $kind  = $type_spec->name;
        my $flags = $TYPE_FLAGS{$kind};
        if ($flags) {
            %info  = %$flags;
            $inner = _constrain($type_spec, $kind, \%opts, $where);
        }
    } elsif (!ref $type_spec) {
        if (my $flags = $TYPE_FLAGS{$type_spec}) {
            %info = %$flags;
            my $base = $STR_ISA_MAP{$type_spec} // Str;
            $inner = _constrain($base, $type_spec, \%opts, $where);
        } else {
            my $full_class = _expand_class($type_spec);
            $info{is_object} = 1;
            $info{class} = $full_class;
            _reject_value_options(\%opts, $where);
            $inner = InstanceOf[$full_class];
        }
    } elsif (ref $type_spec eq 'ARRAY') {
        my $elem = $type_spec->[0];
        # [ {} ] / [ [] ] -- an array of opaque hashes or opaque arrays, for a
        # schema whose items are `type: object` / `type: array` with no further
        # structure (k66). Validated as arrays of the right container
        # shape; the contents pass through untyped, the same one-level-copy
        # opaque handling a free-form HashRef gets in TO_JSON / _inflate_struct.
        if (ref $elem eq 'HASH') {
            $info{is_array_of_hash} = 1;
            _reject_value_options(\%opts, $where);
            $inner = ArrayRef[HashRef];
        } elsif (ref $elem eq 'ARRAY') {
            $info{is_array_of_array} = 1;
            _reject_value_options(\%opts, $where);
            $inner = ArrayRef[ArrayRef];
        # Handle [Str] with Type::Tiny object -- and, since 1.108's to_crd
        # (D9), every other scalar kind the DSL knows too. Before, only
        # Str/Int/Bool recorded an is_array_of_* flag here; [Num]/[Quantity]/
        # [Time]/[IntOrStr] still built and validated a working ArrayRef
        # attribute (Moo's own isa/coerce below is unaffected either way),
        # but left the registry entry with NO classifying flag at all --
        # invisible to anything that reads the registry instead of the Moo
        # attribute, which is exactly what to_crd's _schema_for_class does
        # (found via IO::K8s::Api::Resource::V1::ResourceSlice, whose
        # DeviceCapacity.validValues is [Quantity]; k96 task-2 review).
        # Purely additive: TO_JSON/_inflate_struct have no branch keyed on
        # any of these four new flags either, so they fall through to the
        # same generic ArrayRef copy an unflagged entry already used --
        # serialization and inflation are unchanged, only the registry gets
        # more precise.
        } elsif (_is_type_tiny($elem)) {
            my $kind = $elem->name;
            if ($kind eq 'Str') {
                $info{is_array_of_str} = 1;
            } elsif ($kind eq 'Int') {
                $info{is_array_of_int} = 1;
            } elsif ($kind eq 'Bool') {
                $info{is_array_of_bool} = 1;
            } elsif ($kind eq 'Num') {
                $info{is_array_of_num} = 1;
            } elsif ($kind eq 'IntOrStr') {
                $info{is_array_of_int_or_string} = 1;
            } elsif ($kind eq 'Quantity') {
                $info{is_array_of_quantity} = 1;
            } elsif ($kind eq 'Time') {
                $info{is_array_of_time} = 1;
            }
            $inner = ArrayRef[ _constrain($elem, $kind, \%opts, $where) ];
        } elsif ($elem eq 'Str') {
            $info{is_array_of_str} = 1;
            $inner = ArrayRef[ _constrain(Str, 'Str', \%opts, $where) ];
        } elsif ($elem eq 'Int') {
            $info{is_array_of_int} = 1;
            $inner = ArrayRef[ _constrain(Int, 'Int', \%opts, $where) ];
        } else {
            my $full_class = _expand_class($elem);
            $info{is_array_of_objects} = 1;
            $info{class} = $full_class;
            _reject_value_options(\%opts, $where);
            $inner = ArrayRef[InstanceOf[$full_class]];
        }
    } elsif (ref $type_spec eq 'HASH') {
        my @keys = keys %$type_spec;
        if (@keys == 1 && !ref($type_spec->{$keys[0]}) && $type_spec->{$keys[0]} eq '1') {
            # Hash-of-X pattern: { TypeName => 1 }
            my $vkind = $keys[0];
            if ($vkind eq 'Str') {
                $info{is_hash_of_str} = 1;
                # Use plain HashRef without inner constraint - K8s has nested hashes
                # in fields like fieldsV1, annotations, labels which can have any structure
                _reject_value_options(\%opts, $where);
                $inner = HashRef;
            } elsif (my $vt = $HASH_VALUE_TYPES{$vkind}) {
                # { Quantity => 1 } and friends: a typed value map. Each value
                # is validated against the scalar type (k63).
                $info{$vt->{flag}} = 1;
                $inner = HashRef[ _constrain($vt->{isa}, $vkind, \%opts, $where) ];
            } else {
                my $full_class = _expand_class($vkind);
                $info{is_hash_of_objects} = 1;
                $info{class} = $full_class;
                _reject_value_options(\%opts, $where);
                $inner = HashRef[InstanceOf[$full_class]];
            }
        } else {
            # Inline struct: { field => TypeSpec, ... }
            my $inner_class = $caller . '::_' . ucfirst($attr_name);
            _generate_inline_struct($inner_class, $type_spec);
            $info{is_object} = 1;
            $info{is_inline_struct} = 1;
            $info{class} = $inner_class;
            _reject_value_options(\%opts, $where);
            $inner = InstanceOf[$inner_class];
        }
    }

    croak "k8s: cannot interpret the type of $where" unless defined $inner;

    # A default that the field's own type rejects is a declaration error,
    # not something to discover when to_crd emits it -- except on an
    # object-bearing field (a referenced class, an inline struct, an array
    # or hash of objects), where $inner is InstanceOf[...] or wraps it: no
    # plain hash/array default can ever satisfy that, so there is nothing
    # useful to check here. The default is recorded as given; to_crd
    # validates it against the schema instead (Important 3 of the k93
    # review).
    if (exists $opts{default} && !$info{is_object} && !$info{is_array_of_objects}
        && !$info{is_hash_of_objects} && !$inner->check($opts{default})) {
        croak "k8s: 'default' for $where fails the field's own type: "
            . $inner->get_message($opts{default});
    }

    my $isa = $required ? $inner : Maybe[$inner];

    $info{required} = 1 if $required_recorded;
    if (%opts) {
        # A one-level copy: the registry must not alias a caller's arrayref
        # (the common `enum => $schema->{enum}` idiom reads straight off a
        # shared upstream structure) and later see it mutated out from under
        # the constraint that was already built from it. A Regexp is
        # immutable, so 'pattern' needs no copy.
        my %stored = %opts;
        $stored{enum} = [ @{ $stored{enum} } ] if exists $stored{enum};
        $info{options} = \%stored;
    }

    # Store json_key when it differs from the Perl attribute name
    $info{json_key} = $json_key if $attr_name ne $json_key;

    # Register - use hash slice to copy values, not reference
    $_attr_registry{$caller}{$attr_name} = { %info };
    no strict 'refs';
    push @{"${caller}::_k8s_attributes"}, $attr_name;

    # The merged @ISA views in IO::K8s::Role::Resource are cached; a new
    # registration must not leave a stale merged view behind.
    IO::K8s::Role::Resource::_invalidate_k8s_attr_cache($caller);

    # Only create the attribute if it doesn't already exist (e.g., from a role)
    return if $caller->can($attr_name);

    # Call Moo's has — use init_arg to map JSON key to Perl-safe attribute name
    my $has = $caller->can('has');
    my @coerce;
    # Bool attributes: coerce \0/\1 refs, JSON booleans and 'true'/'false'
    # strings to plain 0/1
    if ($info{is_bool}) {
        @coerce = (coerce => \&_normalize_bool);
    }
    # Array of bool: the same normalization, per element. A bad element's
    # message gets the index appended so it can be found in the array.
    elsif ($info{is_array_of_bool}) {
        @coerce = (coerce => sub {
            return $_[0] unless ref $_[0] eq 'ARRAY';
            my $in = $_[0];
            my @out;
            for my $i (0 .. $#$in) {
                push @out, eval { _normalize_bool($in->[$i]) };
                if (my $err = $@) {
                    $err =~ s/\n\z//;
                    die "$err at element $i\n";
                }
            }
            return \@out;
        });
    }
    # Named nested class, single (k100) -- body in _object_coercer above,
    # because IO::K8s::Role::APIObject's `metadata` needs the same one.
    #
    # An inline struct takes this branch too, since is_inline_struct always
    # sets is_object as well (k116). It used to have a branch of its own
    # doing `$ic->new(%{$_[0]})`, which differs in exactly one visible way:
    # `->new` stored the caller's inner containers by reference, while every
    # other route into the same field -- inflate, struct_to_object,
    # FROM_HASH -- copies them one level (k54). The same field of the same
    # class therefore had both semantics depending on how it was built,
    # which is not something a design chooses: the inline coercer landed
    # with the inline-struct DSL in 2c0c6d02, k54 arrived five months later
    # in 5ab95ca3 and touched _inflate_struct and TO_JSON without ever
    # reaching it. Unified on the copying side, the newer and the tested
    # one; t/29_inline_struct.t pins it, since nothing did before.
    #
    # The other differences the k100 review listed turned out not to be
    # differences worth keeping either. load_class is not a blocker: Moo
    # registers a generated inline-struct package in %INC (as '(eval NNN)'),
    # so require_module finds it and returns. The opaque names
    # fieldsV1/rawExtension/raw that _inflate_struct special-cases are
    # theoretical here -- ManagedFieldsEntry is the only class shipping one
    # and it already declares the opaque form. FROM_STRUCT never exists on a
    # generated class. What is left is the Bool error wrapper, whose text
    # now matches the one every other object-bearing field produces.
    #
    # Two things the three object branches here share:
    #   * `ref $_[0] eq 'HASH'` is false for a blessed hashref, so one test
    #     covers both "already an object, pass it through" and "not a hash,
    #     pass it through". That short-circuit is also what keeps
    #     IO::K8s::_inflate_struct from doing the work twice: it hands
    #     $class->new fully built objects and every one of them lands here.
    #   * anything that is neither goes on unchanged and lets `isa` write
    #     the message -- a coercer never invents a type error of its own.
    elsif ($info{is_object}) {
        @coerce = (coerce => _object_coercer($info{class}));
    }
    # Array of named nested classes: element-wise, and a failing element
    # gets its index appended the same way the [Bool] coercer above does,
    # so the culprit can be found. Scanned first and returned untouched
    # when no element needs building -- the inflate path arrives here with
    # an array of ready objects and should pay one `ref` per element, not
    # a fresh arrayref.
    elsif ($info{is_array_of_objects}) {
        my $oc = $info{class};
        @coerce = (coerce => sub {
            return $_[0] unless ref $_[0] eq 'ARRAY';
            my $in = $_[0];
            my $needed = 0;
            for my $elem (@$in) {
                next unless ref $elem eq 'HASH';
                $needed = 1;
                last;
            }
            return $in unless $needed;
            my @out;
            for my $i (0 .. $#$in) {
                if (ref $in->[$i] eq 'HASH') {
                    push @out, eval {
                        IO::K8s::Role::Resource::_default_k8s()
                            ->_struct_to_object_expanded($oc, $in->[$i])
                    };
                    if (my $err = $@) {
                        $err =~ s/\n\z//;
                        die "$err at element $i\n";
                    }
                } else {
                    push @out, $in->[$i];
                }
            }
            return \@out;
        });
    }
    # Hash of named nested classes: value-wise, with the key named on a
    # failure. Same scan-first shortcut as the array form; `sort keys` in
    # the building pass so several bad values still name a deterministic
    # one, matching the unknown-field walk in IO::K8s::Role::Resource.
    elsif ($info{is_hash_of_objects}) {
        my $oc = $info{class};
        @coerce = (coerce => sub {
            return $_[0] unless ref $_[0] eq 'HASH';
            my $in = $_[0];
            my $needed = 0;
            for my $key (keys %$in) {
                next unless ref $in->{$key} eq 'HASH';
                $needed = 1;
                last;
            }
            return $in unless $needed;
            my %out;
            for my $key (sort keys %$in) {
                if (ref $in->{$key} eq 'HASH') {
                    $out{$key} = eval {
                        IO::K8s::Role::Resource::_default_k8s()
                            ->_struct_to_object_expanded($oc, $in->{$key})
                    };
                    if (my $err = $@) {
                        $err =~ s/\n\z//;
                        die "$err at key '$key'\n";
                    }
                } else {
                    $out{$key} = $in->{$key};
                }
            }
            return \%out;
        });
    }
    $has->($attr_name, is => 'rw', isa => $isa, @coerce,
        ($required ? (required => 1) : ()),
        ($attr_name ne $json_key ? (init_arg => $json_key) : ()),
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Resource - Base class for all Kubernetes resources

=head1 VERSION

version 1.108

=head1 SYNOPSIS

    package IO::K8s::Api::Core::V1::Pod;
    use IO::K8s::Resource;

    k8s apiVersion => 'Str';
    k8s kind => 'Str';
    k8s metadata => 'Meta::V1::ObjectMeta';
    k8s spec => 'Core::V1::PodSpec';

    1;

=head1 DESCRIPTION

Base class that sets up Moo, inheritance, and provides the C<k8s> DSL.
Just C<use IO::K8s::Resource;> - no need for C<use Moo> or C<extends>.

=head1 NAME

IO::K8s::Resource - Base class for Kubernetes resources

=head1 EXPORTED FUNCTIONS

=head2 k8s

    k8s name => 'Str';
    k8s replicas => 'Int';
    k8s ratio => 'Num';                        # JSON number, unquoted on the wire
    k8s suspend => 'Bool';
    k8s spec => 'Core::V1::PodSpec';           # Short class name
    k8s containers => ['Core::V1::Container']; # Array of objects
    k8s labels => { Str => 1 };                # Opaque hash of strings
    k8s limits => { Quantity => 1 };           # Typed value map (also Int/Num/Bool/Time/IntOrStr)
    k8s rows => [ {} ];                         # Array of opaque hashes
    k8s matrix => [ [] ];                       # Array of opaque arrays
    k8s spec => {                              # Inline struct
        replicas => Int,
        selector => Str,
        template => { Str => 1 },
    };

The C<< { Str => 1 } >> form is a deliberately B<opaque> hash: any value is
accepted, for genuinely free-form maps such as labels, annotations and
C<fieldsV1>. C<< { Quantity => 1 } >> (and C<Int>, C<Num>, C<Bool>, C<Time>,
C<IntOrStr>) instead validates every value against that scalar type, so a
map upstream declares as C<map[X]Quantity> rejects a bad value at
construction rather than at the API server.

Inline structs auto-generate an inner class (e.g. C<MyClass::_Spec>) with
the declared fields. Hashrefs are auto-coerced to the inner class on
construction, through the very same coercion a named nested class gets --
so a plain container inside the hashref is copied one level rather than
stored by reference (k116). Before that, C<< ->new >> was the one route
into an inline-struct field that aliased the caller's structure while
C<inflate>, C<struct_to_object> and C<FROM_HASH> already copied it; the
four now agree.

A named nested class coerces the same way (since 1.108): a plain hashref
passed to C<< ->new >> or to the setter of an C<is_object>,
C<is_array_of_objects> or C<is_hash_of_objects> field is built into that
class -- element-wise for an array, value-wise for a map -- so

    IO::K8s::Traefik::V1alpha1::Middleware->new(
        spec => { rateLimit => { average => 100 } });

no longer has to pre-build C<MiddlewareSpec> and C<RateLimit> by hand. It
goes through the same inflation L<IO::K8s::Role::Resource/FROM_HASH> uses,
so boolean spellings and the unknown-field policy behave identically on both
routes. A value that is already an object is passed through untouched, and
anything that is neither a hashref nor an object is left to the type
constraint to reject.

Short class names are auto-expanded:

    Core::V1::Pod      -> IO::K8s::Api::Core::V1::Pod
    Meta::V1::ObjectMeta -> IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta

Field names that are not valid Perl identifiers are automatically sanitized:
C<$ref> becomes C<_ref>, C<$schema> becomes C<_schema>, and hyphens are
replaced with underscores (C<x-kubernetes-foo> becomes C<x_kubernetes_foo>).
The original JSON key is preserved via C<init_arg> so constructors and
C<FROM_HASH> still accept the original names, and C<TO_JSON> outputs the
original keys.

    k8s '$ref' => Str;                          # Moo attr: _ref
    k8s 'x-kubernetes-list-type' => Str;        # Moo attr: x_kubernetes_list_type

=head3 Field options

    k8s replicas => Int, { minimum => 0, maximum => 10, default => 1 };
    k8s policy   => Str, { enum => [qw(Retain Delete)], required => 1 };
    k8s name     => Str, { pattern => qr/\A[a-z0-9-]+\z/, description => '...' };
    k8s spec     => {
        mode  => [ Str, { enum => [qw(fast safe)] } ],   # inside an inline struct
        hosts => [ [Str], { pattern => '^[a-z.]+$' } ],
    };

A field declaration takes an optional third argument: a hashref of options,
directly after the type spec (C<k8s name => Type, { ... }>), or as the
second element of a two-element arrayref in place of the type spec
(C<name => [ Type, { ... } ]>) for a field inside an inline struct, which
has no third-argument slot of its own. The legacy C<'required'> string
marker and the C<Type!> suffix (C<k8s x => 'Str!'>) still work and are
equivalent to C<{ required => 1 }>.

The nine recognised option keys are C<required>, C<default>, C<enum>,
C<minimum>, C<maximum>, C<pattern>, C<description>, C<nullable> and
C<preserve_unknown>. All nine are recorded in the attribute registry for
the CRD schema a C<to_crd> emitter builds from it.

C<required> itself takes two meaningful values. C<required => 1> (like the
legacy marker and the C<!> suffix) both makes the field a Moo-required
constructor argument and records C<required => 1> in the registry.
C<required => 'schema'> records the same registry fact without the Moo
enforcement, leaving the field optional at construction -- this is what
L<IO::K8s::AutoGen> uses for an OpenAPI C<required> list, since a document
a real cluster returns can still omit such a field (a server-side default,
or a status object not yet populated), and C<inflate> must not fail on
data the cluster actually sent. Any other true value is treated the same
as C<1>.

C<enum>, C<minimum>, C<maximum> and C<pattern> are additionally enforced as
Type::Tiny constraints at construction, the same way C<< { Quantity => 1 }
>> validates a typed value map -- a bad value fails here instead of at the
API server. They apply to a scalar field, to each element of an array of
scalars (C<< k8s tags => [Str], { enum => [...] } >>), and to each value of
a typed value map (C<< k8s weights => { Int => 1 }, { maximum => 100 } >>).
Declaring one of them on an object, inline-struct or opaque-container field
(C<{ Str => 1 }>, C<[ {} ]>, C<[ [] ]>, a nested class) is a class-load
error, since there is no scalar value to check. A failing value dies with
one of:

    Value "x" is not one of: a, b
    Value "-1" is below the minimum 0
    Value "11" is above the maximum 10
    Value "x" does not match the pattern ...

On an optional field the message is prefixed with Type::Tiny's own generic
"did not pass type constraint" line; the rule text above follows in the
explanation.

C<default>, C<description>, C<nullable> and C<preserve_unknown> are
schema-only: they are recorded for C<to_crd> and never change anything at
construction or serialization. In particular, C<default> is B<not> applied
client-side -- defaulting is the API server's job, and a client-side
default would change the wire output, so a field with no value given still
serializes as absent. C<nullable> likewise does not make C<TO_JSON> emit
C<null>: an unset field is still omitted from the JSON either way.

Class load fails, naming the class and field, on: an unrecognised option
key (C<k8s: unknown field option '<key>' for field '<name>' of <class>
(known: ...)>); any option given an explicit C<undef> value, since that is
a declaration error rather than "no option" (C<k8s: field option '<key>'
for ... must not be undef>); a third argument that is neither
C<'required'> nor a hashref; an empty or duplicate C<enum>, or C<enum> on a
C<Bool> field; C<minimum>/C<maximum> on a non-numeric field, a non-numeric
bound, or a C<minimum> exceeding C<maximum>; a C<pattern> on a non-string
field or one that does not compile as a Perl regex; and a C<default> that
fails the field's own type (C<k8s: 'default' for ... fails the field's own
type: <message>>), checked once at class-load time rather than discovered
later when C<to_crd> emits it. An object-bearing field -- a referenced
class, an inline struct, or an array or map of objects -- is exempt from
that last check: no plain hash or array default can ever satisfy an
C<InstanceOf> constraint, so there is nothing useful to check, and the
default is recorded as given.

The registry (C<_k8s_attr_info>) keeps C<required> as a plain C<1> (absent
when not required, matching the pre-D3 shape) and every other given option,
one level deep, under C<options>.

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
