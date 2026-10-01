package IO::K8s::Role::Resource;
# ABSTRACT: Role providing Kubernetes resource instance behavior
our $VERSION = '1.109';
use v5.10;
use Moo ();
use mro ();
use Types::Standard qw(HashRef);
use JSON::MaybeXS ();
use Scalar::Util qw(blessed);
# Imports above `use Moo::Role` on purpose: Role::Tiny treats subs already in
# the package as not-methods, so their names stay off every consumer. A `use`
# below that line composes its exports onto all shipped classes (k118).
use Moo::Role;
our @CARP_NOT = ('IO::K8s');  # FROM_HASH/from_json errors name their caller (k175)

has _json_encoder => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build__json_encoder',
);

sub _build__json_encoder {
    return JSON::MaybeXS->new(utf8 => 1, canonical => 1);
}

# Constructor arguments no attribute claims (D1). Kept so a document from a
# newer upstream than the class round-trips instead of losing fields; TO_JSON
# emits them again, declared attributes winning on a name clash. Filled by
# the BUILD below; SpecBuilder writes undeclared keys here too.
# Not a k8s-registered attribute, so TO_JSON's attribute walk never sees the
# bag as a field of its own.
has _unknown_fields => (
    is       => 'rw',
    isa      => HashRef,
    init_arg => '_unknown_fields',
    default  => sub { {} },
);

# The registry lookup is the hot path (every inflate / TO_JSON), so the
# merged views are cached per class. IO::K8s::Resource::_k8s() invalidates
# the affected entries whenever it registers a new attribute.
my %_attr_info_cache;
my %_attributes_cache;
my %_known_init_args_cache;

# Every constructor key a class accepts: the JSON key of each k8s-registered
# attribute (json_key when the Perl name was sanitized), the init_arg of every
# Moo attribute declared with a plain `has` anywhere in the class's ancestry
# (metadata from Role::APIObject, json, _unknown_fields itself), and
# apiVersion/kind on a top-level object, which Role::APIObject supplies as
# methods rather than attributes. The Moo side is read from each ancestor's
# own constructor maker -- the same view MooX::StrictConstructor uses; Moo
# has no public accessor for it -- because all_attribute_specs only ever
# returns a class's *own* specs, never its parents'. A subclass created
# without `use Moo` (e.g. `use parent -norequire, 'IO::K8s::Api::...::Pod'`)
# has no constructor maker of its own at all, so the walk covers the whole
# linear ISA via mro::get_linear_isa rather than looking at $class alone.
sub _known_init_args {
    my ($class) = @_;
    return $_known_init_args_cache{$class} //= _collect_known_init_args($class);
}

sub _collect_known_init_args {
    my ($class) = @_;
    my %known;
    my $info = _k8s_attr_info($class);
    for my $attr (keys %$info) {
        $known{ $info->{$attr}{json_key} // $attr } = 1;
    }
    my $specs = _effective_attribute_specs($class);
    for my $name (keys %$specs) {
        my $spec = $specs->{$name};
        my $init = exists $spec->{init_arg} ? $spec->{init_arg} : $name;
        $known{$init} = 1 if defined $init;
    }
    if ($class->can('_is_resource')) {
        $known{apiVersion} = 1;
        $known{kind}       = 1;
    }
    return \%known;
}

# The Moo attribute specs that are in effect for $class: attribute name ->
# spec, nearest first over mro::get_linear_isa, so a subclass's own `has`
# for a name hides every ancestor's spec of that name. Read from each
# ancestor's constructor maker for the reasons given above
# _known_init_args. Private, uncached and free of side effects on the
# registry: _collect_known_init_args uses it for the constructor keys,
# IO::K8s::Resource's declaration preflight (k144) to tell a real Moo
# attribute from a same-named method -- the registry alone never proves an
# attribute exists.
sub _effective_attribute_specs {
    my ($class) = @_;
    my %specs;
    for my $ancestor (@{ mro::get_linear_isa($class) }) {
        my $maker = Moo->_constructor_maker_for($ancestor) or next;
        my $own = $maker->all_attribute_specs;
        for my $name (keys %$own) {
            $specs{$name} = $own->{$name} unless exists $specs{$name};
        }
    }
    return \%specs;
}

# One level of copying for a plain container -- the same depth TO_JSON and
# IO::K8s::_inflate_struct use (k54), duplicated here because IO::K8s.pm is
# loaded after this role and must not be required from it.
sub _copy_one_level {
    my ($value) = @_;
    return [ @$value ] if ref $value eq 'ARRAY';
    return { %$value } if ref $value eq 'HASH';
    return $value;
}

# BUILD, not `around BUILDARGS` (k102). The walk, its order and everything
# it decides are unchanged; only the plumbing Moo has to generate around it
# differs, and the two are not priced alike. Measured on a quiet box, a
# three-attribute Moo class: 4.85 us/construction plain, 6.51 us with an
# `around BUILDARGS` whose body is empty, 5.31 us with an empty `sub BUILD`
# -- 1.66 us of pure plumbing against 0.46 us, on every one of the ~850
# classes and every nested object of every inflated document. Against the
# t/25 Dashboard Deployment (22 objects) that is -2.6% [IQR -4.5..+4.1],
# i.e. inside the run-to-run spread; on a small direct ->new it is
# -9.8%/-8.5% with a tight interval, and that is the honest claim.
#
# Two things the move does NOT change, both checked before it was made:
#   * an unknown key is no longer deleted from the argument hash, because
#     BUILD runs after the constructor -- Moo ignores a constructor key no
#     attribute claims, so it lands nowhere either way;
#   * the field STRICT names first is still the innermost one, since
#     _inflate_struct builds children before their parent and each child's
#     BUILD therefore runs first. (Classifying the keys up in
#     _inflate_struct instead would invert that, which is why it is a
#     separate decision and not part of this change.)
#
# The bag is written through its own writer rather than the object slot: the
# common case writes nothing at all, so the accessor's cost is paid only by
# a document that actually carries an undeclared field, and the role stays
# clear of assumptions about Moo's storage layout.
sub BUILD {
    my ($self, $args) = @_;
    my $class = ref $self;
    my $known = _known_init_args($class);
    my %unknown;
    # sort: with several unknown keys, STRICT's die names a deterministic
    # one instead of whichever `keys` happened to hash first.
    for my $key (sort keys %$args) {
        next if $known->{$key};
        die "Unknown field '$key' for $class\n" if $IO::K8s::Resource::STRICT;
        my $value = $args->{$key};
        next unless defined $value;
        $unknown{$key} = _copy_one_level($value);
    }
    if (%unknown) {
        # A caller-supplied _unknown_fields hashref must not be aliased --
        # the merge below builds a new hash, which is the same one-level
        # copy every other value crossing this boundary gets.
        my $bag = $self->_unknown_fields;
        $self->_unknown_fields({ %$bag, %unknown });
    }
    elsif (exists $args->{_unknown_fields}) {
        # Nothing collected here, but the caller handed one in: copy it one
        # level so later edits to their hashref do not reach the object.
        $self->_unknown_fields(_copy_one_level($args->{_unknown_fields}));
    }
    return;
}

# Get merged attribute info from the global registry in IO::K8s::Resource,
# walking @ISA so a consumer subclass registered via class_namespaces sees
# its parents' attributes. Nearest wins: a class's own entry for a name
# beats any inherited one; @ISA order (depth-first, left to right) is
# deterministic, so diamond shapes resolve to the first declarer.
sub _k8s_attr_info {
    my ($class) = @_;
    $class = ref($class) if ref($class);
    return $_attr_info_cache{$class} //= _merged_attr_info($class);
}

sub _merged_attr_info {
    my ($class) = @_;
    my %info = %{ $IO::K8s::Resource::_attr_registry{$class} // {} };
    no strict 'refs';
    for my $parent (@{"${class}::ISA"}) {
        my $parent_info = _merged_attr_info($parent);
        for my $attr (keys %$parent_info) {
            $info{$attr} //= $parent_info->{$attr};
        }
    }
    return \%info;
}

# Get attribute list (stored as per-class package variables), merged with
# ancestors as a UNION: a class's own declarations first, then each parent's
# in @ISA order, deduplicated so an overridden name appears once.
sub _k8s_attributes {
    my ($self) = @_;
    my $class = ref($self) || $self;
    return $_attributes_cache{$class} //= _collect_attributes($class);
}

sub _collect_attributes {
    my ($class) = @_;
    my (@attrs, %seen);
    _append_attributes($class, \@attrs, \%seen);
    return \@attrs;
}

sub _append_attributes {
    my ($class, $attrs, $seen) = @_;
    no strict 'refs';
    for my $attr (@{"${class}::_k8s_attributes"}) {
        next if $seen->{$attr}++;
        push @$attrs, $attr;
    }
    for my $parent (@{"${class}::ISA"}) {
        _append_attributes($parent, $attrs, $seen);
    }
}

# Invalidate the merged-view caches for a class and every cached descendant
# after IO::K8s::Resource::_k8s() registers a new attribute. The direct hit
# covers the registering class; the descendant sweep covers a class whose
# merged view was already computed before its parent gained the attribute
# (the same subclass drift this module exists to fix).
sub _invalidate_k8s_attr_cache {
    my ($class) = @_;
    delete $_attr_info_cache{$class};
    delete $_attributes_cache{$class};
    delete $_known_init_args_cache{$class};
    my %sweep;
    @sweep{keys %_attr_info_cache, keys %_attributes_cache, keys %_known_init_args_cache} = ();
    for my $cached_class (keys %sweep) {
        next if $cached_class eq $class;
        next unless $cached_class->isa($class);
        delete $_attr_info_cache{$cached_class};
        delete $_attributes_cache{$cached_class};
        delete $_known_init_args_cache{$cached_class};
    }
}


sub TO_JSON {
    my $self = shift;
    my %data;
    my $attrs = $self->_k8s_attributes;
    my $info = _k8s_attr_info($self);

    # Add apiVersion, kind, and metadata for APIObjects (those with the role)
    if ($self->can('_is_resource') && $self->_is_resource) {
        $data{apiVersion} = $self->api_version if $self->api_version;
        $data{kind} = $self->kind if $self->kind;
        # metadata comes from the Role, not from k8s DSL
        if ($self->can('metadata') && $self->metadata) {
            $data{metadata} = $self->metadata->TO_JSON;
        }
    }

    for my $attr (@$attrs) {
        my $value = $self->$attr;
        unless (defined $value) {
            # A nullable field present with undef is an explicit JSON null
            # (k158); has_<accessor> tells it from an absent one. Every
            # other undefined field is omitted, as it always was.
            my $opts = $info->{$attr} && $info->{$attr}{options};
            next unless $opts && $opts->{nullable};
            my ($has) = IO::K8s::Resource::_nullable_methods($attr);
            $data{ $info->{$attr}{json_key} // $attr } = undef if $self->$has;
            next;
        }

        my $attr_info = $info->{$attr} // {};
        # Use json_key for output when attr name differs from JSON field name
        my $key = $attr_info->{json_key} // $attr;

        if ($attr_info->{is_bool}) {
            $data{$key} = $value ? JSON::MaybeXS::true : JSON::MaybeXS::false;
        } elsif ($attr_info->{is_int}) {
            $data{$key} = int($value);
        } elsif ($attr_info->{is_num}) {
            # A genuine JSON number (OpenAPI type: number). Numify so it
            # serializes unquoted -- the fractional counterpart to is_int's
            # int() (k68). Quantity stays a string; this is only for
            # schemas that declare type: number.
            $data{$key} = $value + 0;
        } elsif ($attr_info->{is_int_or_string}) {
            $data{$key} = ($value =~ /\A-?\d+\z/) ? int($value) : $value;
        } elsif ($attr_info->{is_str}) {
            # A JSON string on the wire whatever Perl scalar it holds (k145):
            # JSON::MaybeXS encodes a numeric scalar as a JSON number, so
            # EnvVar value => 8080 used to go out as 8080 where Kubernetes
            # expects "8080". Interpolating builds a fresh string, so the
            # object's own value is left as it was. A ref cannot pass the
            # Str constraint; the guard only keeps one that got into the
            # slot some other way on the old pass-through.
            $data{$key} = ref $value ? $value : "$value";
        } elsif ($attr_info->{is_quantity} || $attr_info->{is_time}) {
            # A JSON string, the form Kubernetes writes both in (k180): a
            # numeric Perl value -- sizeLimit => 1 -- used to go out as a
            # JSON number, while the same value in a [Quantity] array went
            # out as "1" (k167). The API server accepts either.
            $data{$key} = ref $value ? $value : "$value";
        } elsif ($attr_info->{is_object} && blessed($value) && $value->can('TO_JSON')) {
            $data{$key} = $value->TO_JSON;
        } elsif ($attr_info->{is_array_of_objects}) {
            $data{$key} = [ map { $_->TO_JSON } @$value ];
        } elsif ($attr_info->{is_hash_of_objects}) {
            $data{$key} = { map { $_ => $value->{$_}->TO_JSON } keys %$value };
        } elsif ($attr_info->{is_hash_of_int}) {
            $data{$key} = { map { $_ => int($value->{$_}) } keys %$value };
        } elsif ($attr_info->{is_hash_of_num}) {
            $data{$key} = { map { $_ => $value->{$_} + 0 } keys %$value };
        } elsif ($attr_info->{is_hash_of_bool}) {
            $data{$key} = { map {
                $_ => $value->{$_} ? JSON::MaybeXS::true : JSON::MaybeXS::false
            } keys %$value };
        } elsif ($attr_info->{is_hash_of_int_or_string}) {
            $data{$key} = { map {
                my $v = $value->{$_};
                $_ => (($v =~ /\A-?\d+\z/) ? int($v) : $v)
            } keys %$value };
        } elsif ($attr_info->{is_hash_of_quantity} || $attr_info->{is_hash_of_time}) {
            # Each value a JSON string, as for the scalar field (k180) --
            # limits => { cpu => 1 } goes out as {"cpu":"1"} -- in a new
            # hash (k54). A value the constructor never saw (written through
            # the accessor's hashref) may be undef or a ref; it goes out as
            # it is, the way the array branches below leave such elements.
            $data{$key} = { map {
                my $v = $value->{$_};
                $_ => (defined($v) && !ref($v) ? "$v" : $v)
            } keys %$value };
        } elsif ($attr_info->{is_hash_of_str}) {
            # The string map (k191): every scalar value a JSON string, the
            # rule a [Str] element follows (k145) -- labels => { v => 5 }
            # used to go out as {"v":5} and the API server answered 400 --
            # in a new hash (k54), the object keeping what it was given.
            # undef and a reference go out as they are. A reference can only
            # sit in the lenient { Str => 1 } form (HashRef[Str] refuses one
            # at construction, but a write through the accessor's hashref
            # can still put one there), and there it is the opaque-map use
            # that form served until k191, so it is reported, once per class
            # and field (_warn_lenient_ref).
            my %out;
            for my $k (keys %$value) {
                my $v = $value->{$k};
                if (ref $v) {
                    _warn_lenient_ref(ref($self) || $self, $key, $k)
                        if $attr_info->{is_hash_of_str_lenient};
                    $out{$k} = $v;
                } else {
                    $out{$k} = defined $v ? "$v" : $v;
                }
            }
            $data{$key} = \%out;
        } elsif ($attr_info->{is_array_of_int}) {
            $data{$key} = [ map { int($_) } @$value ];
        } elsif ($attr_info->{is_array_of_num}) {
            # Each element a JSON number, as for is_num above (k68), so a
            # numeric string passed to ->new does not go out quoted. Until
            # AutoGen typed `items: {type: number}` as [Num] (k155) no class
            # carried this form and the generic ARRAY copy below served it.
            # An undef or ref element is left alone, as in is_array_of_str.
            $data{$key} = [ map { defined($_) && !ref($_) ? $_ + 0 : $_ } @$value ];
        } elsif ($attr_info->{is_array_of_str}) {
            # Each element a JSON string, as for is_str above (k145), in a
            # new outer array -- the same one-level copy the generic ARRAY
            # branch below makes (k54). An element the constructor never
            # saw (spec_push, or a push onto the accessor's arrayref) may be
            # undef or a ref; it goes out exactly as before.
            $data{$key} = [ map { defined($_) && !ref($_) ? "$_" : $_ } @$value ];
        } elsif ($attr_info->{is_array_of_int_or_string}) {
            # The scalar is_int_or_string rule per element (k167): an
            # all-digit element goes out as a JSON number, anything else as
            # it is -- so 8080 stays 8080 and '25%' stays '25%'. Until
            # AutoGen typed int-or-string items as [IntOrStr] no generated
            # class carried this form, and the generic ARRAY copy below
            # served the hand-written ones without the rule. undef and ref
            # elements are left alone, as in is_array_of_str.
            $data{$key} = [ map {
                defined($_) && !ref($_) && /\A-?\d+\z/ ? int($_) : $_
            } @$value ];
        } elsif ($attr_info->{is_array_of_quantity} || $attr_info->{is_array_of_time}) {
            # A Quantity and a Time are JSON strings on the wire (k167) --
            # the form Kubernetes writes both in -- so a numeric Perl
            # element such as 1 for a Quantity goes out as "1", the same
            # per-element stringification is_array_of_str applies (k145),
            # in a new outer array (k54).
            $data{$key} = [ map { defined($_) && !ref($_) ? "$_" : $_ } @$value ];
        } elsif ($attr_info->{is_array_of_bool}) {
            # An undef ELEMENT dies rather than becoming a silent false
            # (k51). ArrayRef[Bool] accepts undef because
            # Types::Standard::Bool does, and _normalize_bool deliberately
            # returns it via an explicit `return undef` so the array coercer
            # keeps the position -- but there is nothing honest to put on the
            # wire here. The attribute-level answer (k48: leave it unset,
            # omit the field) does not apply inside an array, where omitting
            # would shift every later element; and the only field of this
            # shape upstream (Api::Resource::V1*::DeviceAttribute bools) is a
            # "non-empty list of true/false values", so a JSON null would be
            # schema-invalid too. Message names field and index, in the k42
            # diagnostic style.
            my @bools;
            for my $i (0 .. $#$value) {
                die 'Bool value must not be undef at element ' . $i
                    . ' while serializing ' . (ref($self) || $self)
                    . " field $key\n" unless defined $value->[$i];
                push @bools, $value->[$i] ? JSON::MaybeXS::true : JSON::MaybeXS::false;
            }
            $data{$key} = \@bools;
        } elsif (ref $value eq 'ARRAY') {
            # Shallow copy, one level (k54): the struct must not alias the
            # object, or post-processing what TO_JSON returned silently edits
            # the object and every later serialization. Deliberately one level
            # only -- a nested structure under an opaque hash attribute
            # (fieldsV1, a free-form HashRef) still shares its inner refs with
            # the object. Same depth on the way in, in IO::K8s::_inflate_struct.
            $data{$key} = [ @$value ];
        } elsif (ref $value eq 'HASH') {
            # Shallow copy, one level -- see the ARRAY branch above (k54).
            $data{$key} = { %$value };
        } else {
            $data{$key} = $value;
        }
    }

    # Unknown fields ride along (D1). Declared attributes win on a clash:
    # the bag only fills keys nothing above has set.
    my $extra = $self->_unknown_fields;
    if ($extra && %$extra) {
        for my $key (keys %$extra) {
            next if exists $data{$key};
            $data{$key} = _copy_one_level($extra->{$key});
        }
    }
    return \%data;
}

# The deprecation warning of the lenient string map (k191): a { Str => 1 }
# field holding a reference is an opaque map declared the pre-k191 way. Once
# per class and field for the life of the process, in the 'deprecated'
# category of the code that serialized it, so `no warnings 'deprecated'`
# there silences it and $SIG{__WARN__} sees it. Counted only when actually
# emitted: a serialization with the category switched off does not use up
# the one warning a later one should get.
my %_lenient_ref_warned;

sub _warn_lenient_ref {
    my ($class, $field, $map_key) = @_;
    return if $_lenient_ref_warned{$class}{$field};
    return unless warnings::enabled('deprecated');
    $_lenient_ref_warned{$class}{$field} = 1;
    warnings::warn('deprecated', "IO::K8s: field '$field' of $class is declared "
        . "{ Str => 1 }, a map of strings, but holds a reference (at key "
        . "'$map_key'); it is passed through unchanged. If the field is not a "
        . 'map of strings, declare it as Opaque or HashRef[...]');
}


sub to_json {
    my $self = shift;
    return $self->_json_encoder->encode($self->TO_JSON);
}


sub TO_YAML {
    my $self = shift;
    require YAML::PP;
    # Dumping with all three schemas quotes the union of what each would
    # resolve to a non-string; kubectl reads YAML 1.1 (go-yaml v2), so the
    # JSON schema alone left True, yes, on, ~, 012 bare (k188). Typed
    # values emit the same under all three: they share JSON's representers.
    my $yp = YAML::PP->new(schema => [qw/JSON Core YAML1_1/], boolean => 'JSON::PP');
    return $yp->dump_string($self->TO_JSON);
}

sub to_yaml {
    my $self = shift;
    return $self->TO_YAML;
}


# The inflation that FROM_HASH routes through lives on an IO::K8s instance,
# and FROM_HASH is a class method, so it borrows one shared default instance.
# That is sound because the only thing it uses the instance for is
# _struct_to_object_expanded(), which is handed class names taken straight out
# of the attribute registry -- already fully expanded, so no resource_map, no
# class_namespaces and no openapi_spec of any *particular* IO::K8s instance is
# consulted. A caller who needs their own providers to take part in the
# resolution has $k8s->inflate / ->json_to_object, which start from a Kind.
#
# `require`, not a top-level `use`: IO::K8s loads IO::K8s::Resource, which
# loads this role, so a compile-time use here would close a load cycle.
sub _default_k8s {
    require IO::K8s;
    state $k8s = IO::K8s->new;
    return $k8s;
}


sub FROM_HASH {
    my ($class, $hash) = @_;
    return _default_k8s()->_struct_to_object_expanded($class, $hash);
}


sub from_json {
    my ($class, $json_str) = @_;
    state $json = JSON::MaybeXS->new(utf8 => 1);
    return $class->FROM_HASH($json->decode($json_str));
}


# Compare local class attributes against OpenAPI schema
# Returns hashref with differences:
#   missing_locally  => [ attrs in schema but not in class ]
#   missing_in_schema => [ attrs in class but not in schema ]
#   type_mismatch    => [ { attr => $name, local => $type, schema => $type } ]
sub compare_to_schema {
    my ($class, $schema) = @_;
    $class = ref($class) if ref($class);

    # Use the merged @ISA view (same structure as the raw registry entry:
    # json_key plus type flags) so a class_namespaces-style subclass sees its
    # inherited attributes instead of an empty or partial registry entry.
    my $local_attrs = _k8s_attr_info($class);
    my $schema_props = $schema->{properties} // {};

    # Build json_key -> attr_name mapping for lookup
    my %json_to_attr;
    for my $attr (keys %$local_attrs) {
        my $jk = $local_attrs->{$attr}{json_key} // $attr;
        $json_to_attr{$jk} = $attr;
    }

    my %result = (
        missing_locally   => [],
        missing_in_schema => [],
        type_mismatch     => [],
    );

    # Check schema properties against local attributes
    for my $prop (keys %$schema_props) {
        my $attr = $json_to_attr{$prop};
        if (!defined $attr) {
            # Special case: metadata comes from Role, not k8s DSL
            next if $prop eq 'metadata' && $class->can('metadata');
            # apiVersion and kind also come from Role
            next if ($prop eq 'apiVersion' || $prop eq 'kind') && $class->can('_is_resource');
            push @{$result{missing_locally}}, $prop;
        } else {
            # Compare types
            my $local_type = _describe_local_type($local_attrs->{$attr});
            my $schema_type = _describe_schema_type($schema_props->{$prop});
            if ($local_type ne $schema_type) {
                push @{$result{type_mismatch}}, {
                    attr   => $prop,
                    local  => $local_type,
                    schema => $schema_type,
                };
            }
        }
    }

    # Check local attributes not in schema
    for my $attr (keys %$local_attrs) {
        my $jk = $local_attrs->{$attr}{json_key} // $attr;
        if (!exists $schema_props->{$jk}) {
            push @{$result{missing_in_schema}}, $jk;
        }
    }

    return \%result;
}

sub _describe_local_type {
    my ($info) = @_;
    return 'string'         if $info->{is_str};
    return 'integer'        if $info->{is_int};
    return 'int-or-string'  if $info->{is_int_or_string};
    return 'quantity'       if $info->{is_quantity};
    return 'date-time'      if $info->{is_time};
    return 'boolean'        if $info->{is_bool};
    return 'array<string>'  if $info->{is_array_of_str};
    return 'array<integer>' if $info->{is_array_of_int};
    return 'array<boolean>' if $info->{is_array_of_bool};
    return 'array<object>'  if $info->{is_array_of_objects};
    return 'hash<string>'   if $info->{is_hash_of_str};
    return 'hash<object>'   if $info->{is_hash_of_objects};
    return 'object'         if $info->{is_hash_opaque};
    return 'object'         if $info->{is_object};
    return 'unknown';
}

sub _describe_schema_type {
    my ($prop) = @_;
    if (my $ref = $prop->{'$ref'}) {
        return 'int-or-string' if $ref =~ /intstr\.IntOrString$/;
        return 'quantity'      if $ref =~ /resource\.Quantity$/;
        return 'date-time'     if $ref =~ /meta\.v1\.(Micro)?Time$/;
        return 'object';
    }
    my $type = $prop->{type} // 'unknown';
    my $format = $prop->{format} // '';
    return 'int-or-string' if $format eq 'int-or-string';
    return 'date-time'     if $format eq 'date-time';
    if ($type eq 'array') {
        my $items = $prop->{items} // {};
        if ($items->{'$ref'}) {
            return 'array<object>';
        }
        my $item_type = $items->{type} // 'unknown';
        return "array<$item_type>";
    }
    if ($type eq 'object' && $prop->{additionalProperties}) {
        my $add = $prop->{additionalProperties};
        if ($add->{'$ref'}) {
            return 'hash<object>';
        }
        my $val_type = $add->{type} // 'unknown';
        return "hash<$val_type>";
    }
    return $type;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Role::Resource - Role providing Kubernetes resource instance behavior

=head1 VERSION

version 1.109

=head1 UNKNOWN FIELDS

A constructor key that no C<k8s>-declared attribute claims is not dropped,
at every nesting level and every entry point -- a top-level C<< ->new >>,
L<IO::K8s/inflate>, L<IO::K8s/new_object>, L<IO::K8s/json_to_object>,
L<IO::K8s/struct_to_object>, and every inline struct built along the way.
It exists so a document written against a newer upstream schema than this
distribution ships still round-trips instead of silently losing the
field. C<TO_JSON> re-emits it alongside the declared attributes, with a
declared attribute winning on a name clash. The bag itself lives on
C<_unknown_fields>, a plain hashref attribute that C<TO_JSON>'s own
attribute walk never sees as a field of its own.

An instance created through L<IO::K8s> with C<< strict => 1 >> turns this
into a fatal error instead: any key that would otherwise land in the bag
dies as C<< Unknown field '<name>' for <class> >>, again at every
nesting level, for the duration of that call.

Since 1.108, L<IO::K8s::List> -- the generic envelope a list Kind (C<PodList>,
a bare C<kind: List>, ...) inflates to -- composes this role too, so its
own top-level keys besides C<items>/C<metadata>/C<item_class> are preserved
and checked exactly like any other resource's, under C<strict> or
otherwise. It keeps its own hand-rolled C<TO_JSON>/C<FROM_STRUCT> rather
than the role's (C<kind>/C<api_version> derive from the items, not from a
class name) but reuses this exact bag and C<BUILD> mechanism for
the envelope. Objects inside C<items> round-trip independently, each
through its own class's composition of this role.

=head2 TO_JSON

    my $struct = $pod->TO_JSON;

Returns a plain hashref representation of the object suitable for JSON
encoding -- the canonical wire format Kubernetes accepts. Walks the
attribute registry of the class and emits each declared field with the
right JSON type: integers unquoted, booleans as C<true>/C<false>, nested
objects recursively via their own C<TO_JSON>, hashes and arrays of objects
in their canonical shape. A C<Str> field and each element of a C<[Str]>
array are always emitted as a JSON string, even when the Perl value itself
is numeric: C<< EnvVar->new(value => 8080) >> serializes C<value> as
C<"8080">, not a bare C<8080>. The other way round, a C<Num> field and
each element of a C<[Num]> array are always emitted as a JSON number, so a
numeric string such as C<'0.25'> goes out unquoted. Each element of an
C<[IntOrStr]> array follows the rule of an C<IntOrStr> field: an all-digit
value goes out as a JSON number, anything else (C<'25%'>, C<'http'>) as the
string it is. A C<Quantity> or C<Time> value always goes out as a JSON
string, the form Kubernetes writes both in -- a scalar field, each value of
a C<< { Quantity => 1 } >> or C<< { Time => 1 } >> map and each element of a
C<[Quantity]> or C<[Time]> array alike: C<< limits => { cpu => 1 } >> is
emitted as C<{"cpu":"1"}>. The object keeps the value it was
given. Each value of a string map -- C<< { Str => 1 } >> or
C<HashRef[Str]>: labels, annotations, ConfigMap C<data>, ... -- goes out as
a JSON string too, so C<< labels => { v => 5 } >> is C<{"v":"5"}>. A
reference value in a C<< { Str => 1 } >> map is copied through unchanged
and warns once per class and field, in the C<deprecated> category: declare
such a field C<Opaque> or C<HashRef[...]>. The free map, C<Opaque> or a
bare C<HashRef> (C<fieldsV1>, a C<RawExtension>, ...), is exempt from all
of this -- its values are copied through unchanged, keeping whatever JSON
type they already had. For classes that compose
L<IO::K8s::Role::APIObject>, the C<apiVersion>, C<kind> and C<metadata>
fields are prepended.

A field that holds C<undef> is omitted -- unless it is declared
C<nullable> and present, which C<< has_<accessor> >> tells: that one is
written as an explicit JSON C<null> (see
L<IO::K8s::Resource/Field options>).

This is the entry point L</to_json> builds on, and the inverse of
L</FROM_HASH>.

=head2 to_json

    my $json = $pod->to_json;

Returns a UTF-8 encoded JSON byte string for the object. Thin wrapper over
L</TO_JSON> that runs the resulting hashref through the canonical encoder
configured internally. Symmetric to L</from_json> on the consumer side.

=head2 TO_YAML

    my $yaml_string = $pod->TO_YAML;

Returns a YAML string for the object, built via L<YAML::PP> on top of
L</TO_JSON>. Real booleans and numbers go out bare. A string is quoted
whenever a JSON, YAML 1.2 core or YAML 1.1 reader would take its bare form
for a boolean, null or number (C<True>, C<yes>, C<on>, C<~>, C<012>,
C<0x1F>, C<+1>, ...), so kubectl and the API server read it back as a
string. Symmetric to L</TO_JSON> -- the YAML is just another wire format
over the same canonical struct.

=head2 to_yaml

    my $yaml_string = $pod->to_yaml;

Returns a YAML byte string for the object, suitable for C<kubectl apply
-f>. Thin wrapper over L</TO_YAML>; provided so the role offers both
C<TO_JSON> and L<IO::K8s::APIObject/save> a single canonical entry
point.

=head2 FROM_HASH

    my $pod = IO::K8s::Api::Core::V1::Pod->FROM_HASH($struct);

Builds an object of this class from a plain hashref of JSON field names,
inflating nested objects, arrays of objects and hashes of objects through the
attribute registry -- the same inflation L<IO::K8s/inflate> performs, so a
struct from L</TO_JSON> round-trips back. Before 1.108 this was a
bare C<< $class->new(%$hash) >> and any nested field had to be pre-built.

A defined value at an object-bearing position that is not a hashref (or
already an object of the right class) -- an arrayref, a plain string, a
code or scalar reference -- fails closed the same way inflation does
everywhere else: it croaks naming the target class, the shape it
actually received, and, for a nested field, the field itself, rather than
silently building an empty object. So does a blessed value whose class has
no C<TO_JSON> returning a hashref, such as a JSON boolean, and an
array or hash field holding the wrong container. See
L<IO::K8s/new_object> for the exact messages. C<undef> and an omitted field
are unaffected and remain allowed.

=head2 from_json

    my $pod = IO::K8s::Api::Core::V1::Pod->from_json($json_bytes);

Builds an object of this class from a JSON document, symmetric to
L</to_json>. The argument is a B<UTF-8 encoded byte string> -- exactly what
C<to_json> produces; a decoded character string is not accepted and fails
loudly in the JSON decoder rather than silently round-tripping to mojibake.
Decode-tolerance was rejected on purpose: it would leave
C<from_json> more permissive than C<< $k8s->json_to_object >>, which has
always been byte-oriented.

=head2 compare_to_schema

    my $diff = IO::K8s::Api::Core::V1::Pod->compare_to_schema($swagger_def);

Drift detector used by L<maint/spec-drift-check.pl> and other coverage
checks. Compares this class's declared attributes against an OpenAPI
schema hashref (one entry from a C<swagger.json>) and returns a hashref:

    {
        missing_locally    => [ ...property names the schema has but the class does not... ],
        missing_in_schema  => [ ...json_key names the class has but the schema does not... ],
        type_mismatch      => [ { attr => $name, local => $type, schema => $type }, ... ],
    }

C<apiVersion>, C<kind> and C<metadata> are skipped on the schema side --
they are not declared with the C<k8s> DSL but are supplied by
L<IO::K8s::Role::APIObject> and the role mesh.

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
