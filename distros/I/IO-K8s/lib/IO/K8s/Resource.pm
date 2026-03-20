package IO::K8s::Resource;
# ABSTRACT: Base class for all Kubernetes resources
our $VERSION = '1.009';
use v5.10;
use Moo ();
use Moo::Role ();
use Import::Into;
use Package::Stash;
use Types::Standard qw( ArrayRef Bool HashRef InstanceOf Int Maybe Str );
use IO::K8s::Types qw( IntOrStr Quantity Time );
use Scalar::Util qw(blessed);

# Registry: class -> attr -> { type, class, is_array, is_hash, is_bool, is_int }
# Use 'our' to make it a proper package variable accessible via symbol table
our %_attr_registry;

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
    'Meta'           => 'IO::K8s::Apimachinery::Pkg::Apis::Meta',
    'Apiextensions'  => 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions',
    'KubeAggregator' => 'IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration',
);

# Type flag lookup table
my %TYPE_FLAGS = (
    Str      => { is_str => 1 },
    Int      => { is_int => 1 },
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
    Bool => Bool,
);

sub import {
    my $class = shift;
    my $caller = caller;
    $class->_setup_class($caller);
}

sub _setup_class {
    my ($class, $target) = @_;
    Moo->import::into($target);
    Types::Standard->import::into($target, qw( Str Int Bool ));
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

    # Check for prefix match (e.g., Core::V1::Pod)
    if ($short =~ /^([A-Z][a-z]+)::/) {
        my $prefix = $1;
        if (my $expansion = $_class_prefix{$prefix}) {
            $short =~ s/^$prefix/$expansion/;
            return $short;
        }
    }

    # Default: assume it's under IO::K8s::Api
    return "IO::K8s::Api::$short";
}

sub _is_type_tiny {
    my ($obj) = @_;
    return blessed($obj) && $obj->isa('Type::Tiny');
}

# Sanitize JSON field names into valid Perl identifiers for Moo attributes
# $ref -> _ref, $schema -> _schema, x-kubernetes-foo -> x_kubernetes_foo
sub _sanitize_attr_name {
    my ($name) = @_;
    return $name unless $name =~ /[^a-zA-Z0-9_]/;
    (my $safe = $name) =~ s/^\$/_/;
    $safe =~ s/-/_/g;
    return $safe;
}

sub _k8s {
    my ($class, $caller, $name, $type_spec, $required_marker) = @_;

    my $json_key = $name;
    my $attr_name = _sanitize_attr_name($name);

    # Ensure the registry entry exists
    $_attr_registry{$caller} = {} unless exists $_attr_registry{$caller};

    my %info;
    my $isa;
    my $required = $required_marker && $required_marker eq 'required' ? 1 : 0;

    # Check for ! suffix on strings (legacy/alternative required syntax)
    if (!ref $type_spec && !_is_type_tiny($type_spec) && $type_spec =~ s/!$//) {
        $required = 1;
    } elsif (ref $type_spec eq 'ARRAY' && !_is_type_tiny($type_spec->[0]) && $type_spec->[0] =~ s/!$//) {
        $required = 1;
    }

    # Handle Type::Tiny objects directly (Str, Int, Bool, IntOrStr, Quantity, Time)
    if (_is_type_tiny($type_spec)) {
        my $flags = $TYPE_FLAGS{$type_spec->name};
        if ($flags) {
            %info = %$flags;
            $isa = $required ? $type_spec : Maybe[$type_spec];
        }
    } elsif (!ref $type_spec) {
        if (my $flags = $TYPE_FLAGS{$type_spec}) {
            %info = %$flags;
            my $base = $STR_ISA_MAP{$type_spec} // Str;
            $isa = $required ? $base : Maybe[$base];
        } else {
            my $full_class = _expand_class($type_spec);
            $info{is_object} = 1;
            $info{class} = $full_class;
            $isa = $required ? InstanceOf[$full_class] : Maybe[InstanceOf[$full_class]];
        }
    } elsif (ref $type_spec eq 'ARRAY') {
        my $inner = $type_spec->[0];
        # Handle [Str] with Type::Tiny object
        if (_is_type_tiny($inner)) {
            my $type_name = $inner->name;
            if ($type_name eq 'Str') {
                $info{is_array_of_str} = 1;
            } elsif ($type_name eq 'Int') {
                $info{is_array_of_int} = 1;
            }
            $isa = $required ? ArrayRef[$inner] : Maybe[ArrayRef[$inner]];
        } elsif ($inner eq 'Str') {
            $info{is_array_of_str} = 1;
            $isa = $required ? ArrayRef[Str] : Maybe[ArrayRef[Str]];
        } elsif ($inner eq 'Int') {
            $info{is_array_of_int} = 1;
            $isa = $required ? ArrayRef[Int] : Maybe[ArrayRef[Int]];
        } else {
            my $full_class = _expand_class($inner);
            $info{is_array_of_objects} = 1;
            $info{class} = $full_class;
            $isa = $required ? ArrayRef[InstanceOf[$full_class]] : Maybe[ArrayRef[InstanceOf[$full_class]]];
        }
    } elsif (ref $type_spec eq 'HASH') {
        my ($inner) = keys %$type_spec;
        if ($inner eq 'Str') {
            $info{is_hash_of_str} = 1;
            # Use plain HashRef without inner constraint - K8s has nested hashes
            # in fields like fieldsV1, annotations, labels which can have any structure
            $isa = $required ? HashRef : Maybe[HashRef];
        } else {
            my $full_class = _expand_class($inner);
            $info{is_hash_of_objects} = 1;
            $info{class} = $full_class;
            $isa = $required ? HashRef[InstanceOf[$full_class]] : Maybe[HashRef[InstanceOf[$full_class]]];
        }
    }


    # Store json_key when it differs from the Perl attribute name
    $info{json_key} = $json_key if $attr_name ne $json_key;

    # Register - use hash slice to copy values, not reference
    $_attr_registry{$caller}{$attr_name} = { %info };
    no strict 'refs';
    push @{"${caller}::_k8s_attributes"}, $attr_name;

    # Only create the attribute if it doesn't already exist (e.g., from a role)
    return if $caller->can($attr_name);

    # Call Moo's has — use init_arg to map JSON key to Perl-safe attribute name
    my $has = $caller->can('has');
    my @coerce;
    # Bool attributes: coerce \0/\1 refs and JSON booleans to plain 0/1
    if ($info{is_bool}) {
        @coerce = (coerce => sub { ref $_[0] ? (${$_[0]} ? 1 : 0) : ($_[0] ? 1 : 0) });
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

version 1.009

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
    k8s suspend => 'Bool';
    k8s spec => 'Core::V1::PodSpec';           # Short class name
    k8s containers => ['Core::V1::Container']; # Array of objects
    k8s labels => { Str => 1 };                # Hash of strings

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
