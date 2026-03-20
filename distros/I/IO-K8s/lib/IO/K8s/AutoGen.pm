package IO::K8s::AutoGen;
# ABSTRACT: Dynamically generate IO::K8s classes from OpenAPI schema
our $VERSION = '1.009';
use v5.10;
use strict;
use warnings;
use Carp qw(croak);
use Package::Stash;

# Cache of generated classes
my %_generated;

# Default namespace for auto-generated classes
our $DEFAULT_NAMESPACE = 'IO::K8s::_AUTOGEN';

# Convert OpenAPI definition name to Perl class name
# With namespace 'MyProject::K8s':
#   helm.cattle.io.v1.HelmChart -> MyProject::K8s::helm::cattle::io::v1::HelmChart
sub def_to_class {
    my ($def_name, $namespace) = @_;
    $namespace //= $DEFAULT_NAMESPACE;
    my $class = $def_name;
    $class =~ s/\./::/g;
    return "${namespace}::$class";
}

# Convert Perl class name back to OpenAPI definition name
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
sub get_or_generate {
    my ($def_name, $schema, $all_defs, $namespace, %opts) = @_;

    my $class = def_to_class($def_name, $namespace);
    return $class if $_generated{$class};

    _generate_class($class, $def_name, $schema, $all_defs, $namespace, %opts);
    return $class;
}

# Generate a class from OpenAPI schema using IO::K8s::Resource
sub _generate_class {
    my ($class, $def_name, $schema, $all_defs, $namespace, %opts) = @_;

    return if $_generated{$class};
    $_generated{$class} = 1;  # Mark early to prevent recursion

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

    my $properties = $schema->{properties} // {};

    # Generate attributes using k8s DSL
    # Property names with special characters ($ref, x-kubernetes-*) are
    # automatically sanitized to valid Perl identifiers by _k8s(), with
    # init_arg mapping so constructors still accept the original JSON keys.
    for my $prop (sort keys %$properties) {
        my $prop_schema = $properties->{$prop};
        my $type_spec = _schema_to_type_spec($prop_schema, $all_defs, $namespace, $prop);
        next unless defined $type_spec;  # Skip unsupported types

        $k8s->($prop, $type_spec);
    }

    # Determine api_version/kind from schema or explicit options
    my ($api_ver, $kind_val, $res_plural, $is_namespaced);

    if (my $gvk = $schema->{'x-kubernetes-group-version-kind'}) {
        my $entry = ref($gvk) eq 'ARRAY' ? $gvk->[0] : $gvk;
        my $group = $entry->{group} // '';
        my $version = $entry->{version} // '';
        $kind_val = $entry->{kind} // '';
        $api_ver = $group ? "$group/$version" : $version;
    }

    # Explicit options override schema-derived values
    $api_ver       = $opts{api_version}     if exists $opts{api_version};
    $kind_val      = $opts{kind}            if exists $opts{kind};
    $res_plural    = $opts{resource_plural} if exists $opts{resource_plural};
    $is_namespaced = $opts{is_namespaced}   if exists $opts{is_namespaced};

    # Install class methods if we have api_version/kind
    if (defined $api_ver && defined $kind_val) {
        my $stash = Package::Stash->new($class);

        $stash->add_symbol('&api_version', sub { $api_ver });
        $stash->add_symbol('&kind', sub { $kind_val });
        $stash->add_symbol('&resource_plural', sub { $res_plural });

        # Apply Role::APIObject for metadata, to_yaml, save, etc.
        require Moo::Role;
        require IO::K8s::Role::APIObject;
        Moo::Role->apply_roles_to_package($class, 'IO::K8s::Role::APIObject');

        # Register metadata attribute via k8s DSL so _inflate_struct knows the type
        # (same as IO::K8s::APIObject::import does for hand-written classes)
        $k8s->('metadata', 'Meta::V1::ObjectMeta');

        # Apply Namespaced role if requested or schema suggests it
        if ($is_namespaced) {
            require IO::K8s::Role::Namespaced;
            Moo::Role->apply_roles_to_package($class, 'IO::K8s::Role::Namespaced');
        }
    }

    return $class;
}

# Opaque type definitions that should be HashRef, not object references
my %OPAQUE_TYPES = map { $_ => 1 } qw(
    io.k8s.apimachinery.pkg.apis.meta.v1.FieldsV1
    io.k8s.apimachinery.pkg.runtime.RawExtension
);

# Convert OpenAPI schema to k8s() type spec
sub _schema_to_type_spec {
    my ($schema, $all_defs, $namespace, $field_name) = @_;

    # Handle $ref
    if (my $ref = $schema->{'$ref'}) {
        $ref =~ s{^#/definitions/}{};

        # Special apimachinery types - not object references
        if ($ref =~ /intstr\.IntOrString$/) {
            return 'IntOrStr';
        }
        if ($ref =~ /resource\.Quantity$/) {
            return 'Quantity';
        }
        if ($ref =~ /meta\.v1\.(Micro)?Time$/) {
            return 'Time';
        }

        # Opaque types should be HashRef, not object references
        if ($OPAQUE_TYPES{$ref}) {
            return { Str => 1 };  # HashRef
        }

        # Generate referenced class if needed
        if ($all_defs && $all_defs->{$ref}) {
            my $ref_class = get_or_generate($ref, $all_defs->{$ref}, $all_defs, $namespace);
            return "+$ref_class";  # + prefix for full class name
        }
        return undef;  # Can't resolve reference
    }

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
        return 'Str';  # Treat numbers as strings for now
    }
    elsif ($type eq 'boolean') {
        return 'Bool';
    }
    elsif ($type eq 'array') {
        my $items = $schema->{items} // {};
        if (my $ref = $items->{'$ref'}) {
            $ref =~ s{^#/definitions/}{};
            if ($all_defs && $all_defs->{$ref}) {
                my $ref_class = get_or_generate($ref, $all_defs->{$ref}, $all_defs, $namespace);
                return ["+$ref_class"];
            }
            return undef;
        }
        my $item_type = $items->{type} // 'string';
        return ['Str'] if $item_type eq 'string';
        return ['Int'] if $item_type eq 'integer';
        return ['Str'];  # Default
    }
    elsif ($type eq 'object') {
        if (my $addl = $schema->{additionalProperties}) {
            if (my $ref = $addl->{'$ref'}) {
                $ref =~ s{^#/definitions/}{};
                if ($all_defs && $all_defs->{$ref}) {
                    my $ref_class = get_or_generate($ref, $all_defs->{$ref}, $all_defs, $namespace);
                    return { "+$ref_class" => 1 };
                }
                return undef;
            }
            return { Str => 1 };  # Hash of strings
        }
        return { Str => 1 };  # Generic object -> hash of strings
    }

    # Unknown type
    return 'Str';
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

# Clear generated class cache (mainly for testing)
sub clear_cache {
    %_generated = ();
}

# List all generated classes
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

version 1.009

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

=head1 NAME

IO::K8s::AutoGen - Dynamically generate IO::K8s classes from OpenAPI schema

=head1 FUNCTIONS

=head2 get_or_generate($def_name, $schema, $all_defs, $namespace)

Generate (or return cached) class for the given OpenAPI definition.

=head2 def_to_class($def_name, $namespace)

Convert OpenAPI definition name to Perl class name.

=head2 class_to_def($class)

Convert Perl class name back to OpenAPI definition name.

=head2 is_autogen($class)

Returns true if the class was auto-generated.

=head2 clear_cache()

Clear the generated class cache.

=head2 generated_classes()

List all generated class names.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

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

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
