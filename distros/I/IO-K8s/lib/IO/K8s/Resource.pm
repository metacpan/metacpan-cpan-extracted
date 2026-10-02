package IO::K8s::Resource;
# ABSTRACT: Base class for all Kubernetes resources
our $VERSION = '1.110';
use v5.10;
use strict;
use warnings;
use Moo ();
use Moo::Role ();
use Import::Into;
use Package::Stash;
use Types::Standard qw( ArrayRef Bool HashRef InstanceOf Int Maybe Num Str );
use IO::K8s::Types qw( IntOrStr Quantity Time );
use IO::K8s::Role::Resource ();
use namespace::clean ();
use Scalar::Util qw( blessed reftype looks_like_number );
use Carp qw( croak );
use Sub::Util qw( subname );

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

# Value types for the hash-of-scalar-type DSL form { TypeName => 1 } (k63),
# and for HashRef[TypeName], which means the same (k191). Everything here
# constrains each VALUE against the scalar type, so a map upstream declares
# as map[X]Quantity finally rejects cpu => 'banana' at construction instead
# of at the API server.
#
# 'Str' is NOT here: since k191 it is the string map (is_hash_of_str, every
# scalar value a JSON string on the wire), and its two spellings validate
# differently. HashRef[Str] is strict, a reference value is refused.
# { Str => 1 } keeps the bare HashRef it always had and is marked
# is_hash_of_str_lenient: it was the opaque map until k191, so a reference
# value still passes and TO_JSON warns about it once per class and field.
# The free map is Opaque (or a bare HashRef), flag is_hash_opaque.
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
# nullable also keeps an explicit JSON null on the way in and out (k158).
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
    $class->_import_map_types($caller);
}

# HashRef and Opaque for map declarations (k191): `k8s data => HashRef[Str]`,
# `k8s raw => Opaque`. Only here, where a class is compiled from source --
# _setup_class also serves inline structs and IO::K8s::AutoGen, which build
# their fields at runtime and never name a type in code. Both names are
# swept from the package again once the scope that said `use` has finished
# compiling (namespace::clean, the explicit-list form): the declarations
# compiled against them keep working, but neither becomes a method of every
# shipped class, which is what k118 took HashRef off (t/27_no_import_leak.t).
sub _import_map_types {
    my ($class, $target) = @_;
    Types::Standard->import::into($target, qw( HashRef ));
    IO::K8s::Types->import::into($target, qw( Opaque ));
    namespace::clean->import(-cleanee => $target, qw( HashRef Opaque ));
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
# is a plain `has` -- the role composes before any k8s declaration runs, and
# metadata is then only registered through _k8s_adopt, which never calls
# has(), so a coercer installed here would never reach it (k115). The role
# therefore declares metadata with this coercion from the start.
#
# $class_name is captured; IO::K8s::Role::Resource::_default_k8s() is
# touched at COERCION time only, never while the attribute is installed --
# _k8s runs at compile time of every one of the ~850 classes, and
# _default_k8s requires IO::K8s, which loads this file.
sub _object_coercer {
    my ($class_name) = @_;
    my $builds = _object_builds($class_name);
    return sub {
        return $_[0] unless $builds->($_[0]);
        return IO::K8s::Role::Resource::_default_k8s()
            ->_struct_to_object_expanded($class_name, $_[0]);
    };
}

# Whether a value handed to an object-bearing field of $class_name is built
# into that class by the object coercers, as a predicate the three of them
# share -- the single field above and, element by element, the array and
# hash forms in _declare_field.
#
# A plain hashref always is. A class with FROM_STRUCT -- the apiextensions
# union classes, which serialize as the bare value they hold -- takes every
# defined value (k179): inflation hands it anything, so values => [1, 2]
# or enum => ['a'] inflated fine while ->new, the setter and spec_set died
# on the InstanceOf check for the very same values. An object already of
# the class is left alone, and undef stays "no value". Every other class
# keeps the k146 rule: anything but a hashref goes on to `isa`, which
# refuses it.
#
# FROM_STRUCT is only known once the class is loaded, and the coercer is
# installed long before (see _object_coercer). It is asked the first time
# a value is not a hashref, and the answer is kept; a class that does not
# load is asked again next time and meanwhile counts as an ordinary class,
# so such a value still meets the type check it met before.
sub _object_builds {
    my ($class_name) = @_;
    my $from_struct;
    return sub {
        my ($value) = @_;
        return 0 unless defined $value;
        return 1 if ref $value eq 'HASH';
        $from_struct //= _takes_any_value($class_name);
        return 0 unless $from_struct;
        return blessed($value) && $value->isa($class_name) ? 0 : 1;
    };
}

# True when $class_name inflates through FROM_STRUCT (k179), false when it
# does not, nothing when it cannot be loaded.
sub _takes_any_value {
    my ($class_name) = @_;
    return unless eval {
        IO::K8s::Role::Resource::_default_k8s()->load_class($class_name);
        1;
    };
    return $class_name->can('FROM_STRUCT') ? 1 : 0;
}

# A map whose values have a type (k191): HashRef[X], and the { X => 1 } form
# that means the same for every X but Str. Sets the registry flag in $info
# and returns the field's type. X is a Type::Tiny value type: a scalar kind
# by its name -- Str (the strict string map), Int, Num, Bool, IntOrStr,
# Quantity, Time -- or InstanceOf[Class], the map of objects. The value
# constraint is X itself, so HashRef[Time] checks what { Time => 1 } checks
# and a lenient Str-based Time (IO::K8s::AutoGen's) stays lenient.
sub _typed_map {
    my ($info, $value_type, $opts, $where) = @_;
    my $kind = $value_type->name;
    if ($kind eq 'Str') {
        $info->{is_hash_of_str} = 1;
        return HashRef[ _constrain($value_type, 'Str', $opts, $where) ];
    }
    if (my $vt = $HASH_VALUE_TYPES{$kind}) {
        $info->{ $vt->{flag} } = 1;
        return HashRef[ _constrain($value_type, $kind, $opts, $where) ];
    }
    return _object_map($info, $value_type->class, $opts, $where)
        if $value_type->isa('Type::Tiny::Class');
    croak "k8s: cannot interpret the value type of $where: HashRef["
        . $value_type->display_name . '] (a scalar type, or InstanceOf[Class])';
}

# The map of objects: { Class => 1 } and HashRef[InstanceOf[Class]].
sub _object_map {
    my ($info, $full_class, $opts, $where) = @_;
    $info->{is_hash_of_objects} = 1;
    $info->{class} = $full_class;
    _reject_value_options($opts, $where);
    return HashRef[InstanceOf[$full_class]];
}

sub _generate_inline_struct {
    my ($class_name, $fields) = @_;
    __PACKAGE__->_setup_class($class_name);
    for my $field_name (keys %$fields) {
        __PACKAGE__->_k8s($class_name, $field_name, $fields->{$field_name});
    }
}

# The nearest registry entry for a Perl attribute name: $class's own, else
# the first one found walking @ISA depth-first, left to right -- the order
# IO::K8s::Role::Resource::_merged_attr_info resolves in, so this answers
# for the same view TO_JSON and FROM_HASH read. Returns the declaring class
# and its entry, or nothing. Uncached: it runs while classes are still
# being declared, and populating the role's merged-view cache from here
# would be a side effect of a declaration that may yet be rejected.
sub _nearest_registration {
    my ($class, $attr_name) = @_;
    my $own = $_attr_registry{$class};
    return ($class, $own->{$attr_name}) if $own && $own->{$attr_name};
    no strict 'refs';
    for my $parent (@{"${class}::ISA"}) {
        my @found = _nearest_registration($parent, $attr_name);
        return @found if @found;
    }
    return;
}

# The role that $class's method $attr_name comes from, when that role lists
# the name in its %YIELDS_TO_K8S_FIELD -- a role helper meant to give way to
# a declared wire field of the same name (IO::K8s::Role::APIObject's
# conditions, for ComponentStatus). Found through the method's own name
# rather than a list of classes, and checked against the role itself: the
# code must be the role's sub, and $class must do the role. Anything else --
# a method the class wrote, one a role does not declare as yielding, a
# modifier-wrapped helper -- returns nothing and stays a collision.
sub _yielding_role_helper {
    my ($class, $attr_name) = @_;
    my $code = $class->can($attr_name) or return;
    my ($role, $sub) = subname($code) =~ /\A(.+)::([^:]+)\z/ or return;
    return unless $sub eq $attr_name && Moo::Role->is_role($role);
    no strict 'refs';
    return unless ${"${role}::YIELDS_TO_K8S_FIELD"}{$attr_name};
    return unless defined &{"${role}::${attr_name}"}
        && \&{"${role}::${attr_name}"} == $code;
    return unless $class->can('does') && $class->does($role);
    return $role;
}

# The `k8s` DSL entry point. A thin wrapper so that every argument a caller
# of `k8s` can pass has a meaning; the adopt switch below is not one of them.
sub _k8s {
    my ($class, $caller, $name, $type_spec, $marker) = @_;
    return $class->_declare_field($caller, $name, $type_spec, $marker, 0);
}

# Register a wire field for a Moo attribute the class already has, without
# calling has() -- the one field this exists for is metadata, which
# IO::K8s::Role::APIObject declares itself (with the ObjectMeta coercion)
# and which IO::K8s::APIObject::import and IO::K8s::AutoGen then register
# for the registry readers. Private on purpose: the public `k8s` never
# adopts, so a field can no longer end up registered over an attribute
# nobody declared for it (k144). Refused unless an attribute of that name
# is in effect and its init_arg is the field's JSON key.
sub _k8s_adopt {
    my ($class, $caller, $name, $type_spec, $marker) = @_;
    return $class->_declare_field($caller, $name, $type_spec, $marker, 1);
}

sub _declare_field {
    my ($class, $caller, $name, $type_spec, $marker, $adopt) = @_;

    my $json_key  = $name;
    my $attr_name = _sanitize_attr_name($name);
    my $where     = "field '$name' of $caller";

    # Declaration preflight (k144). Every conflict is refused here, before
    # anything below builds an inline-struct class, calls has() or writes
    # the registry, the attribute list or the merged-view cache -- a
    # rejected declaration leaves the class exactly as it was.
    #
    # Two JSON keys, one accessor: _sanitize_attr_name is not injective
    # (x-value and x_value both become x_value), so a second key reaching
    # an attribute name another key already holds -- in this class or,
    # nearest wins, in an ancestor -- would silently retarget that field.
    my ($declarer, $registered) = _nearest_registration($caller, $attr_name);
    if ($registered) {
        my $other_key = $registered->{json_key} // $attr_name;
        croak "k8s: $where collides with field '$other_key' of $declarer: "
            . "both map to the Perl attribute '$attr_name'"
            if $other_key ne $json_key;
    }
    # The same JSON key declared a second time in this very class (k151).
    # Moo keeps the first attribute, so a second declaration is only ever
    # compared with the first one, below, once its type is interpreted --
    # identical is a no-op, anything else is refused.
    my $redeclared = $registered && $declarer eq $caller;
    # A method that is not a Moo attribute -- an IO::K8s::Role::APIObject
    # helper such as get_condition, a Moo keyword -- used to make the old
    # `return if $caller->can($attr_name)` register the field and skip
    # has(), leaving the wire field served by that method. What counts is
    # the effective Moo spec; a registry entry proves nothing. The one way
    # past this is a role helper its role declares as yielding to a wire
    # field of the same name (see _yielding_role_helper): the field is then
    # installed over it.
    my ($spec, $local, $yielding);
    if ($caller->can($attr_name)) {
        $spec = IO::K8s::Role::Resource::_effective_attribute_specs($caller)->{$attr_name};
        $yielding = _yielding_role_helper($caller, $attr_name) unless $spec;
        croak "k8s: $where collides with the method '$attr_name' of $caller, "
            . 'which is not an attribute'
            unless $spec || $yielding;
        no strict 'refs';
        $local = defined &{"${caller}::${attr_name}"};
    }
    # Moo refuses has() for an accessor this very package already defines,
    # so a fresh declaration can replace an inherited attribute (nearest
    # wins, below) but never one of the class's own. That leaves three
    # cases where has() is not called at all:
    #   * adopt -- the explicit path above; the attribute must exist and
    #     take the JSON key as its constructor argument;
    #   * a field this class already declared (or adopted), declared again
    #     with the same JSON key -- compared with the first declaration
    #     further down, and a no-op when identical (k151). It used to
    #     overwrite the registry entry while Moo kept the first spec, so
    #     the two described different fields;
    #   * anything else the class defines itself (a role's attribute, a
    #     plain has) -- refused, since the field would be registered over
    #     an attribute that does not follow its declaration.
    my $install = 1;
    if ($adopt) {
        my $init = $spec && exists $spec->{init_arg} ? $spec->{init_arg} : $attr_name;
        croak "k8s: cannot adopt $where: $caller has no attribute '$attr_name' "
            . "taking '$json_key' as its constructor argument"
            unless $spec && defined $init && $init eq $json_key;
        $install = 0;
    } elsif ($yielding) {
        # Installed below; a helper composed into this very package is
        # removed right before has(), which refuses to overwrite it.
    } elsif ($local) {
        croak "k8s: $where would take over the attribute '$attr_name' that "
            . "$caller defines outside the k8s DSL"
            unless $redeclared;
        $install = 0;
    }

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
    # A nullable field keeps an explicit JSON null (k158) and brings two
    # methods of its own: has_<accessor>, true while the key exists (null
    # included), and clear_<accessor>, which makes the field absent again.
    # Both names are part of the declaration preflight: taken by anything
    # but this very field's own predicate and clearer -- declared before in
    # this class, or inherited from the field an ancestor declares -- they
    # are refused like a colliding field name, before anything is built.
    my @nullable_methods = $opts{nullable} ? _nullable_methods($attr_name) : ();
    if (@nullable_methods) {
        my $own = IO::K8s::Role::Resource::_effective_attribute_specs($caller)->{$attr_name} // {};
        my %own = map { defined $_ ? ($_ => 1) : () } @{$own}{qw( predicate clearer )};
        for my $method (@nullable_methods) {
            croak "k8s: $where needs the method '$method' as a nullable field, "
                . "but $caller already has a method of that name"
                if $caller->can($method) && !$own{$method};
        }
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

    # Every branch below sets $inner, the type of a present value; the
    # Maybe wrapping for an optional field happens once at the end.
    my %info;
    my $inner;

    # Handle Type::Tiny objects directly (Str, Int, Bool, IntOrStr, Quantity,
    # Time) -- and, since k191, the map types: Opaque or a bare HashRef is
    # the free map, HashRef[X] a map whose values are X.
    if (_is_type_tiny($type_spec)) {
        my $kind  = $type_spec->name;
        my $flags = $TYPE_FLAGS{$kind};
        if ($flags) {
            %info  = %$flags;
            $inner = _constrain($type_spec, $kind, \%opts, $where);
        } elsif ($kind eq 'Opaque' || $kind eq 'HashRef') {
            # Values untyped and copied through as they are; there is no
            # scalar to put a value option on.
            $info{is_hash_opaque} = 1;
            _reject_value_options(\%opts, $where);
            $inner = HashRef;
        } elsif ($type_spec->is_parameterized
            && $type_spec->parameterized_from->name eq 'HashRef') {
            $inner = _typed_map(\%info, $type_spec->type_parameter, \%opts, $where);
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
        # Purely additive when introduced (k96 task-2): TO_JSON and
        # _inflate_struct had no branch keyed on any of these four flags, so
        # they fell through to the same generic ArrayRef copy an unflagged
        # entry already used. _inflate_struct still does today -- inflation
        # is unchanged. TO_JSON no longer does: it now reads is_array_of_num
        # for JSON-number elements (k155), is_array_of_quantity and
        # is_array_of_time to stringify elements (k180), and
        # is_array_of_int_or_string for the per-element int-or-string rule
        # (k167, k181).
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
                # The string map, lenient (k191): TO_JSON puts every scalar
                # value out as a JSON string, but the check stays the bare
                # HashRef it was while { Str => 1 } meant the opaque map, so
                # a declaration still relying on that keeps loading and
                # serializing -- its reference values pass through, with a
                # one-time warning. HashRef[Str] is the strict spelling.
                $info{is_hash_of_str} = 1;
                $info{is_hash_of_str_lenient} = 1;
                _reject_value_options(\%opts, $where);
                $inner = HashRef;
            } elsif (my $vt = $HASH_VALUE_TYPES{$vkind}) {
                # { Quantity => 1 } and friends: a typed value map. Each value
                # is validated against the scalar type (k63).
                $inner = _typed_map(\%info, $vt->{isa}, \%opts, $where);
            } else {
                $inner = _object_map(\%info, _expand_class($vkind), \%opts, $where);
            }
        } else {
            # Inline struct: { field => TypeSpec, ... }
            my $inner_class = $caller . '::_' . ucfirst($attr_name);
            if ($redeclared) {
                _redeclare_inline_struct($caller, $where, $registered, $inner_class, $type_spec);
            } else {
                _generate_inline_struct($inner_class, $type_spec);
            }
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

    # A nullable field takes undef even when required: required means the
    # key must exist, and null is a value it may exist with (k158).
    my $isa = $required && !@nullable_methods ? $inner : Maybe[$inner];

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

    # Declared in this very class before (k151): nothing is installed or
    # registered a second time. The registry entry covers type, nested
    # class, options, recorded required-ness and JSON key; the Moo spec
    # adds whether required is enforced (1 and 'schema' record the same).
    # An identical declaration changes nothing, not even the attribute list.
    if ($redeclared) {
        _croak_redeclared($where, $caller)
            unless _same_value(\%info, $registered)
            && $required == ($spec && $spec->{required} ? 1 : 0);
        return;
    }

    # Adopted (a redeclaration has returned above): see the preflight above
    # for why there is nothing to install.
    return _register_field($caller, $attr_name, \%info) unless $install;

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
    #   * one predicate, _object_builds, decides what is built: a plain
    #     hashref -- `ref eq 'HASH'` is false for a blessed one -- or, for a
    #     union class with FROM_STRUCT, any defined value that is not
    #     already of the class (k179). An object of the class is passed
    #     through, which is also what keeps IO::K8s::_inflate_struct from
    #     doing the work twice: it hands $class->new fully built objects and
    #     every one of them lands here.
    #   * anything else goes on unchanged and lets `isa` write the message
    #     -- a coercer never invents a type error of its own.
    elsif ($info{is_object}) {
        @coerce = (coerce => _object_coercer($info{class}));
    }
    # Array of named nested classes: element-wise, and a failing element
    # gets its index appended the same way the [Bool] coercer above does,
    # so the culprit can be found. Scanned first and returned untouched
    # when no element needs building -- the inflate path arrives here with
    # an array of ready objects and should pay one check per element, not
    # a fresh arrayref.
    #
    # An element is built by the rule _object_builds states for the single
    # field: a hashref, or any defined value for a union class (k179).
    elsif ($info{is_array_of_objects}) {
        my $oc = $info{class};
        my $builds = _object_builds($oc);
        @coerce = (coerce => sub {
            return $_[0] unless ref $_[0] eq 'ARRAY';
            my $in = $_[0];
            my $needed = 0;
            for my $elem (@$in) {
                next unless $builds->($elem);
                $needed = 1;
                last;
            }
            return $in unless $needed;
            my @out;
            for my $i (0 .. $#$in) {
                if ($builds->($in->[$i])) {
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
    # failure. Same scan-first shortcut and element rule as the array form;
    # `sort keys` in the building pass so several bad values still name a
    # deterministic one, matching the unknown-field walk in
    # IO::K8s::Role::Resource.
    elsif ($info{is_hash_of_objects}) {
        my $oc = $info{class};
        my $builds = _object_builds($oc);
        @coerce = (coerce => sub {
            return $_[0] unless ref $_[0] eq 'HASH';
            my $in = $_[0];
            my $needed = 0;
            for my $key (keys %$in) {
                next unless $builds->($in->{$key});
                $needed = 1;
                last;
            }
            return $in unless $needed;
            my %out;
            for my $key (sort keys %$in) {
                if ($builds->($in->{$key})) {
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
    # Map of Bool (k191): a JSON boolean value -- what a decoded document
    # carries -- becomes the 0/1 the value check accepts, through the same
    # normalization the Bool field uses. Only reference values are touched:
    # a plain scalar goes to `isa` as it is, so 'maybe' is still refused
    # rather than read as true. A map whose values are all plain scalars is
    # returned untouched.
    elsif ($info{is_hash_of_bool}) {
        @coerce = (coerce => sub {
            return $_[0] unless ref $_[0] eq 'HASH';
            my $in = $_[0];
            return $in unless grep { ref } values %$in;
            my %out;
            for my $key (keys %$in) {
                my $v = $in->{$key};
                my $n = ref $v ? eval { _normalize_bool($v) } : undef;
                $out{$key} = defined $n ? $n : $v;
            }
            return \%out;
        });
    }
    # A yielding role helper composed into this package goes first, so the
    # accessor can take its name -- after every check above, so a rejected
    # declaration never gets this far.
    Package::Stash->new($caller)->remove_symbol('&'.$attr_name)
        if $yielding && $local;

    # A complete spec, never has('+name'). For a field redeclared under the
    # same JSON key in a subclass this is what makes nearest-wins real
    # (k144): the subclass's spec replaces the inherited one outright, so
    # the parent's coercion, required flag and init_arg go with it --
    # has('+name') would merge them back in, and refuses coerce => undef.
    # The parent class is left untouched.
    $has->($attr_name, is => 'rw', isa => $isa, @coerce,
        ($required ? (required => 1) : ()),
        ($attr_name ne $json_key ? (init_arg => $json_key) : ()),
        (@nullable_methods
            ? (predicate => $nullable_methods[0], clearer => $nullable_methods[1])
            : ()),
    );
    return _register_field($caller, $attr_name, \%info);
}

# The predicate and clearer a nullable field gets (k158), in that order:
# has_<accessor> and clear_<accessor>, named after the Perl attribute, the
# same name the accessor itself has. IO::K8s::Role::Resource's TO_JSON and
# IO::K8s::Role::SpecBuilder's spec_delete call them through this too, so
# the names are spelled in one place.
sub _nullable_methods {
    my ($attr_name) = @_;
    return ('has_'.$attr_name, 'clear_'.$attr_name);
}

# An inline struct declared again in the class that declared it (k151). Its
# inner class exists already, and building it a second time would add a new
# field to it, keep a dropped one and set the class up twice -- so it is
# compared instead: the same field names, and every field again an
# identical declaration in the inner class, which the same rule makes a
# no-op or refuses. Refused before any field is looked at when the first
# declaration was not this inline struct or the names differ, so a refusal
# leaves the inner class as it was.
sub _redeclare_inline_struct {
    my ($caller, $where, $registered, $inner_class, $fields) = @_;
    my $had = $_attr_registry{$inner_class} // {};
    my @had = sort map { $had->{$_}{json_key} // $_ } keys %$had;
    _croak_redeclared($where, $caller)
        unless $registered->{is_inline_struct}
        && $registered->{class} eq $inner_class
        && join("\0", @had) eq join("\0", sort keys %$fields);
    __PACKAGE__->_k8s($inner_class, $_, $fields->{$_}) for sort keys %$fields;
    return;
}

sub _croak_redeclared {
    my ($where, $caller) = @_;
    croak "k8s: $where is already declared in $caller with a different type, "
        . 'options or required-ness; declare each field once per class';
}

# Deep equality of two registry entries (k151): arrays and hashes element
# by element, everything else by what it stringifies to within the same
# ref type -- a plain scalar as itself, a Regexp as its pattern with its
# flags, a JSON boolean default as 0 or 1.
sub _same_value {
    my ($x, $y) = @_;
    return !defined $y unless defined $x;
    return 0 unless defined $y && ref $x eq ref $y;
    my $type = reftype($x) // '';
    if ($type eq 'ARRAY') {
        return 0 unless @$x == @$y;
        for my $i (0 .. $#$x) {
            return 0 unless _same_value($x->[$i], $y->[$i]);
        }
        return 1;
    }
    if ($type eq 'HASH') {
        return 0 unless keys %$x == keys %$y;
        for my $key (keys %$x) {
            return 0 unless exists $y->{$key} && _same_value($x->{$key}, $y->{$key});
        }
        return 1;
    }
    return "$x" eq "$y" ? 1 : 0;
}

# Record a declared field, only once its attribute is in place (k144): a
# has() that dies must not leave a registry entry behind that no attribute
# backs, nor a name in the attribute list or a merged view already rebuilt
# around it.
sub _register_field {
    my ($caller, $attr_name, $info) = @_;
    # Copy the values, not the reference
    $_attr_registry{$caller}{$attr_name} = { %$info };
    no strict 'refs';
    push @{"${caller}::_k8s_attributes"}, $attr_name;

    # The merged @ISA views in IO::K8s::Role::Resource are cached; a new
    # registration must not leave a stale merged view behind.
    IO::K8s::Role::Resource::_invalidate_k8s_attr_cache($caller);
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Resource - Base class for all Kubernetes resources

=head1 VERSION

version 1.110

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
    k8s labels => { Str => 1 };                # String map (lenient legacy spelling)
    k8s data => HashRef[Str];                  # String map, strict
    k8s raw => Opaque;                         # Free map, values untyped (also bare HashRef)
    k8s limits => { Quantity => 1 };           # Typed value map (also Int/Num/Bool/Time/IntOrStr)
    k8s ports => HashRef[Int];                 # The same, as HashRef[X]
    k8s rows => [ {} ];                         # Array of opaque hashes
    k8s matrix => [ [] ];                       # Array of opaque arrays
    k8s spec => {                              # Inline struct
        replicas => Int,
        selector => Str,
        template => { Str => 1 },
    };

C<< { Str => 1 } >> and C<HashRef[Str]> declare a B<string map> -- labels,
annotations, ConfigMap C<data>, a C<map[string]string> upstream: C<TO_JSON>
puts every scalar value out as a JSON string, so C<< labels => { v => 5 } >>
goes out as C<{"v":"5"}>. C<HashRef[Str]> refuses a reference value at
construction. C<< { Str => 1 } >> keeps accepting any value, since it was
the opaque map before 1.109: a reference value passes through unchanged and
warns once per class and field (category C<deprecated>). C<Opaque>, or a
bare C<HashRef>, is the B<free map> for genuinely free-form values such as
C<fieldsV1> or a C<RawExtension>: any value, copied through as it is.
C<Opaque> takes no parameters -- C<Opaque[...]> dies at declaration.
Declare a free field as C<Opaque>: C<< { Str => 1 } >> was the opaque map up
to 1.108, but is a string map now, so C<to_crd> emits C<additionalProperties:
string> for it instead of C<x-kubernetes-preserve-unknown-fields>, and a
reference value warns.
C<< { Quantity => 1 } >> (and C<Int>, C<Num>, C<Bool>, C<Time>,
C<IntOrStr>) instead validates every value against that scalar type, so a
map upstream declares as C<map[X]Quantity> rejects a bad value at
construction rather than at the API server; C<HashRef[Quantity]> and the
other C<HashRef[X]>, including C<HashRef[InstanceOf['Some::Class']]> for a
map of objects, are the same declarations spelled the other way.

Inline structs auto-generate an inner class (e.g. C<MyClass::_Spec>) with
the declared fields. Hashrefs are auto-coerced to the inner class on
construction, through the very same coercion a named nested class gets --
so a plain container inside the hashref is copied one level rather than
stored by reference. Before 1.108, C<< ->new >> was the one route
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

The one exception is a class that inflates through C<FROM_STRUCT> -- the
apiextensions union classes C<V1::JSON> and C<JSONSchemaPropsOr*>, which
serialize as the bare value they hold. Such a field takes every defined
value, not only a hashref, exactly as inflation does:

    IO::K8s::K3s::V1::HelmChartSpec->new(values => [ 1, 2 ]);   # values: [1,2]
    $schema->enum([ 'small', 'large' ]);                         # enum: ["small","large"]

The value goes to the class's C<FROM_STRUCT> through the same call
inflation makes, in the constructor, the setter and every C<spec_*> write,
element by element for an array or map of such objects. An object already
of the class is passed through, C<undef> is still no value, and a value
the union itself refuses (a plain scalar for the schema arm of C<items>)
fails with the same inflation error L<IO::K8s/inflate> gives for it.

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
directly after the type spec (C<< k8s name => Type, { ... } >>), or as the
second element of a two-element arrayref in place of the type spec
(C<< name => [ Type, { ... } ] >>) for a field inside an inline struct, which
has no third-argument slot of its own. The legacy C<'required'> string
marker and the C<Type!> suffix (C<< k8s x => 'Str!' >>) still work and are
equivalent to C<< { required => 1 } >>.

The nine recognised option keys are C<required>, C<default>, C<enum>,
C<minimum>, C<maximum>, C<pattern>, C<description>, C<nullable> and
C<preserve_unknown>. All nine are recorded in the attribute registry for
the CRD schema a C<to_crd> emitter builds from it.

C<required> itself takes two meaningful values. C<< required => 1 >> (like the
legacy marker and the C<!> suffix) both makes the field a Moo-required
constructor argument and records C<< required => 1 >> in the registry.
C<< required => 'schema' >> records the same registry fact without the Moo
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
Declaring one of them on an object, inline-struct or container field
(C<Opaque>, a bare C<HashRef>, C<< { Str => 1 } >>, C<[ {} ]>, C<[ [] ]>, a nested class) is a
class-load error, since there is no scalar value to check. C<HashRef[Str]>
takes them, per value. A failing value dies with
one of:

    Value "x" is not one of: a, b
    Value "-1" is below the minimum 0
    Value "11" is above the maximum 10
    Value "x" does not match the pattern ...

On an optional field the message is prefixed with Type::Tiny's own generic
"did not pass type constraint" line; the rule text above follows in the
explanation.

C<default>, C<description> and C<preserve_unknown> are schema-only: they
are recorded for C<to_crd> and never change anything at construction or
serialization. In particular, C<default> is B<not> applied client-side --
defaulting is the API server's job, and a client-side default would change
the wire output, so a field with no value given still serializes as
absent.

C<nullable> is recorded for C<to_crd> as well, and since 1.109 it also
makes an explicit JSON C<null> a value of its own:

    k8s upstream => { Str => 1 }, { nullable => 1 };

    my $spec = My::Spec->new(upstream => undef);
    $spec->has_upstream;      # true: the key exists
    $spec->to_json;           # {"upstream":null}
    $spec->clear_upstream;    # absent again
    $spec->to_json;           # {}

The field accepts C<undef> at construction and in its setter -- its type
is C<Maybe>-wrapped even when it is C<required> -- and every inflation
route (L<IO::K8s/inflate>, L<IO::K8s/new_object>,
L<IO::K8s/struct_to_object>, L<IO::K8s/json_to_object>,
L<IO::K8s::Role::Resource/FROM_HASH>, C<from_json> and the nested coercion
of a constructor, at any depth) keeps a C<null> for it where every other
field drops it. C<TO_JSON> writes a nullable field that is present with
C<undef> as C<null>; an absent one stays omitted. Only a nullable field
gets the two methods that tell those apart: C<< has_<accessor> >>, true
while the key exists, C<null> included, and C<< clear_<accessor> >>,
which makes the field absent again. C<< required => 1 >> together with
C<nullable> means the key has to exist, and C<null> satisfies it. For every
field without C<nullable>, C<undef> and C<null> still mean "absent".

Class load fails, naming the class and field, on: an unrecognised option
key (C<< k8s: unknown field option '<key>' for field '<name>' of <class>
(known: ...) >>); any option given an explicit C<undef> value, since that is
a declaration error rather than "no option" (C<< k8s: field option '<key>'
for ... must not be undef >>); a third argument that is neither
C<'required'> nor a hashref; an empty or duplicate C<enum>, or C<enum> on a
C<Bool> field; C<minimum>/C<maximum> on a non-numeric field, a non-numeric
bound, or a C<minimum> exceeding C<maximum>; a C<pattern> on a non-string
field or one that does not compile as a Perl regex; and a C<default> that
fails the field's own type (C<< k8s: 'default' for ... fails the field's own
type: <message> >>), checked once at class-load time rather than discovered
later when C<to_crd> emits it. An object-bearing field -- a referenced
class, an inline struct, or an array or map of objects -- is exempt from
that last check: no plain hash or array default can ever satisfy an
C<InstanceOf> constraint, so there is nothing useful to check, and the
default is recorded as given.

Class load also fails, before any field option above is even considered,
on a declaration that collides with something already in place:

=over 4

=item * Two different JSON keys that sanitize to the same Perl attribute
name (C<x-value> and C<x_value> both become C<x_value>), in this class or,
nearest wins, in an ancestor: C<< k8s: field '<name>' of <class> collides
with field '<other key>' of <declaring class>: both map to the Perl
attribute '<attr>' >>.

=item * A field name that is already a method on the class but not a Moo
attribute -- a role helper such as L<IO::K8s::Role::APIObject/is_ready> --
unless the role that provides it has declared the helper as yielding to a
wire field of the same name, which today only C<conditions> is:
C<< k8s: field '<name>' of <class> collides with the method '<attr>' of
<class>, which is not an attribute >>.

=item * A field that would take over an attribute the class defines
itself outside the C<k8s> DSL (a plain C<has>): C<< k8s: field '<name>' of
<class> would take over the attribute '<attr>' that <class> defines
outside the k8s DSL >>.

=item * A C<nullable> field whose predicate or clearer name
(C<< has_<accessor> >>, C<< clear_<accessor> >>) the class already
answers to -- a method, or the accessor of another field -- other than as
this very field's own, declared before or inherited: C<< k8s: field
'<name>' of <class> needs the method '<method>' as a nullable field, but
<class> already has a method of that name >>. The other way round, a field
whose accessor would take a nullable field's predicate or clearer name is
refused by the method check above.

=item * A field the same class has already declared under the same JSON
key, declared again with a different type, nested class, option,
C<required> (including C<1> against C<'schema'>) or inline-struct field
set: C<< k8s: field '<name>' of <class> is already declared in
<class> with a different type, options or required-ness; declare each
field once per class >>. Moo keeps the first attribute of a class, so a
second, different declaration could never take effect; it used to
overwrite the C<_k8s_attr_info> entry anyway, leaving serialization and
construction to follow two different declarations of one field. An
inline struct is compared field by field, and a changed field inside it is
reported against the generated inner class (C<< <class>::_<Name> >>).

=back

A rejected declaration leaves the class exactly as it was -- nothing is
installed, registered in C<_k8s_attr_info>, or added to the attribute
list. A subclass that redeclares an inherited C<k8s> field under the same
JSON key replaces it outright, in the subclass only: nearest wins, so the
new declaration's type, coercion, C<required> and C<init_arg> take over
there, while the ancestor's own declaration is left completely untouched.
Within the very same class, an identical second declaration of a field
is tolerated and changes nothing -- not the registry, not the attribute
list; that includes declaring C<metadata> as C<Meta::V1::ObjectMeta> in a
class whose C<use IO::K8s::APIObject> already adopted it. Declare each
field once per class.

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
