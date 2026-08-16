package IO::K8s::Role::Resource;
# ABSTRACT: Role providing Kubernetes resource instance behavior
our $VERSION = '1.107';
use v5.10;
use Moo::Role;
use JSON::MaybeXS ();
use Scalar::Util qw(blessed);

has json => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_json',
);

sub _build_json {
    return JSON::MaybeXS->new(utf8 => 1, canonical => 1);
}

# The registry lookup is the hot path (every inflate / TO_JSON), so the
# merged views are cached per class. IO::K8s::Resource::_k8s() invalidates
# the affected entries whenever it registers a new attribute.
my %_attr_info_cache;
my %_attributes_cache;

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
    my %sweep;
    @sweep{keys %_attr_info_cache, keys %_attributes_cache} = ();
    for my $cached_class (keys %sweep) {
        next if $cached_class eq $class;
        next unless $cached_class->isa($class);
        delete $_attr_info_cache{$cached_class};
        delete $_attributes_cache{$cached_class};
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
        next unless defined $value;

        my $attr_info = $info->{$attr} // {};
        # Use json_key for output when attr name differs from JSON field name
        my $key = $attr_info->{json_key} // $attr;

        if ($attr_info->{is_bool}) {
            $data{$key} = $value ? JSON::MaybeXS::true : JSON::MaybeXS::false;
        } elsif ($attr_info->{is_int}) {
            $data{$key} = int($value);
        } elsif ($attr_info->{is_int_or_string}) {
            $data{$key} = ($value =~ /\A-?\d+\z/) ? int($value) : $value;
        } elsif ($attr_info->{is_object} && blessed($value) && $value->can('TO_JSON')) {
            $data{$key} = $value->TO_JSON;
        } elsif ($attr_info->{is_array_of_objects}) {
            $data{$key} = [ map { $_->TO_JSON } @$value ];
        } elsif ($attr_info->{is_hash_of_objects}) {
            $data{$key} = { map { $_ => $value->{$_}->TO_JSON } keys %$value };
        } elsif ($attr_info->{is_array_of_int}) {
            $data{$key} = [ map { int($_) } @$value ];
        } elsif ($attr_info->{is_array_of_bool}) {
            $data{$key} = [ map { $_ ? JSON::MaybeXS::true : JSON::MaybeXS::false } @$value ];
        } elsif (ref $value eq 'ARRAY') {
            $data{$key} = $value;
        } elsif (ref $value eq 'HASH') {
            $data{$key} = $value;
        } else {
            $data{$key} = $value;
        }
    }
    return \%data;
}

sub to_json {
    my $self = shift;
    return $self->json->encode($self->TO_JSON);
}

sub TO_YAML {
    my $self = shift;
    require YAML::PP;
    my $yp = YAML::PP->new(schema => [qw/JSON/], boolean => 'JSON::PP');
    return $yp->dump_string($self->TO_JSON);
}

sub to_yaml {
    my $self = shift;
    return $self->TO_YAML;
}

sub FROM_HASH {
    my ($class, $hash) = @_;
    return $class->new(%$hash);
}

sub from_json {
    my ($class, $json_str) = @_;
    state $json = JSON::MaybeXS->new;
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

version 1.107

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
