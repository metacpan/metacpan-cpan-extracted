package IO::K8s::Role::Resource;
# ABSTRACT: Role providing Kubernetes resource instance behavior
our $VERSION = '1.006';
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

# Get attribute info from the global registry in IO::K8s::Resource
sub _k8s_attr_info {
    my ($class) = @_;
    $class = ref($class) if ref($class);
    return $IO::K8s::Resource::_attr_registry{$class} // {};
}

# Get attribute list (stored as per-class package variable)
sub _k8s_attributes {
    my ($self) = @_;
    my $class = ref($self) || $self;
    no strict 'refs';
    return \@{"${class}::_k8s_attributes"};
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
    return YAML::PP::Dump($self->TO_JSON);
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

    my $local_attrs = $IO::K8s::Resource::_attr_registry{$class} // {};
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

version 1.006

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

Jose Luis Martinez <jlmartin@cpan.org> (original author, inactive)

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jose Luis Martinez.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
