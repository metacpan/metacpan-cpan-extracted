package JSONSchema::Validator::Constraints::OAS30;

# ABSTRACT: OpenAPI 3.0 specification constraints

use strict;
use warnings;
use URI;
use Carp 'croak';

use parent 'JSONSchema::Validator::Constraints::Draft4';

use JSONSchema::Validator::JSONPointer 'json_pointer';
use JSONSchema::Validator::Error 'error';
use JSONSchema::Validator::Util qw(is_type serialize unbool round detect_type);

sub type {
    my ($self, $instance, $type, $schema, $instance_path, $schema_path, $data) = @_;

    if (is_type($instance, 'null', $self->strict)) {
        return $self->nullable( $instance,
                                $schema->{nullable} // 0,
                                $schema,
                                $instance_path,
                                $schema_path,
                                $data);
    }

    my $result = 1;
    $result = 0 unless is_type($instance, $type, $self->strict);

    # # items must be present if type eq array
    # if ($result && $type eq 'array') {
    #     $result = 0 unless exists $schema->{items};
    # }

    return 1 if $result;

    push @{$data->{errors}}, error(
        message => 'type mismatch',
        instance_path => $instance_path,
        schema_path => $schema_path
    );
    return 0;
}

sub items {
    my ($self, $instance, $items, $schema, $instance_path, $schema_path, $data) = @_;
    return 1 unless is_type($instance, 'array', $self->strict);

    # items is object and NOT array

    my $result = 1;
    for my $i (0 .. $#{$instance}) {
        my $item = $instance->[$i];
        my $ipath = json_pointer->append($instance_path, $i);
        my $r = $self->validator->_validate_schema($item, $items, $ipath, $schema_path, $data);
        $result = 0 unless $r;
    }
    return $result;
}

sub nullable {
    my ($self, $instance, $nullable, $schema, $instance_path, $schema_path, $data) = @_;
    # A true value adds "null" to the allowed type specified by the type keyword, only if type is explicitly defined within the same Schema Object.
    return 1 unless $schema->{type};
    return 1 if $nullable;
    unless (defined $instance) {
        push @{$data->{errors}}, error(
            message => 'instance is nullable',
            instance_path => $instance_path,
            schema_path => $schema_path
        );
        return 0;
    }
    return 1;
}

sub readOnly {
    my ($self, $instance, $readOnly, $schema, $instance_path, $schema_path, $data) = @_;
    return 1 unless $readOnly;
    return 1 if $data->{direction} eq 'response';

    push @{$data->{errors}}, error(
        message => 'instance is invalid in request because of readOnly property',
        instance_path => $instance_path,
        schema_path => $schema_path
    );
    return 0;
}

sub writeOnly {
    my ($self, $instance, $writeOnly, $schema, $instance_path, $schema_path, $data) = @_;
    return 1 unless $writeOnly;
    return 1 if $data->{direction} eq 'request';

    push @{$data->{errors}}, error(
        message => "instance is invalid in response because of writeOnly property",
        instance_path => $instance_path,
        schema_path => $schema_path
    );
    return 0;
}

sub required {
    my ($self, $instance, $required, $schema, $instance_path, $schema_path, $data) = @_;
    return 1 unless is_type($instance, 'object', $self->strict);

    my $result = 1;
    for my $idx (0 .. $#{$required}) {
        my $prop = $required->[$idx];
        next if exists $instance->{$prop};

        if ($schema->{properties} && $schema->{properties}{$prop}) {
            my $prop = $schema->{properties}{$prop};
            my $read_only = $prop->{readOnly} // 0;
            my $write_only = $prop->{writeOnly} // 0;
            my $direction = $data->{direction};

            next if $direction eq 'request' && $read_only;
            next if $direction eq 'response' && $write_only;
        }

        push @{$data->{errors}}, error(
            message => qq{instance does not have required property "${prop}"},
            instance_path => $instance_path,
            schema_path => json_pointer->append($schema_path, $idx)
        );
        $result = 0;
    }
    return $result;
}

sub discriminator {
    my ($self, $instance, $discriminator, $origin_schema, $instance_path, $schema_path, $data) = @_;
    return 1 unless is_type($instance, 'object', $self->strict);

    my $path = $instance_path;

    my $property_name = $discriminator->{propertyName};
    my $mapping = $discriminator->{mapping} // {};

    my $type = $instance->{$property_name};
    my $ref = $mapping->{$type};

    $ref = $self->__detect_discriminator_ref($ref || $type);

    # status == 1 needs to prevent recursion
    $data->{discriminator}{$path} = 1;

    my $scope = $self->validator->scope;
    $ref = URI->new($ref);
    $ref = $ref->abs($scope) if $scope;

    my ($current_scope, $schema) = $self->validator->resolver->resolve($ref);

    croak "schema not resolved by ref $ref" unless $schema;

    push @{$self->validator->scopes}, $current_scope;

    my $result = eval {
        $self->validator->_validate_schema($instance, $schema, $instance_path, $schema_path, $data, apply_scope => 0);
    };

    if ($@) {
        $result = 0;
        push @{$data->{errors}}, error(
            message => "exception: $@",
            instance_path => $instance_path,
            schema_path => $schema_path
        );
    }

    pop @{$self->validator->scopes};

    delete $data->{discriminator}{$path};

    return $result;
}

sub deprecated {
    my ($self, $instance, $deprecated, $schema, $instance_path, $schema_path, $data) = @_;
    return 1 unless $deprecated;
    push @{$data->{warnings}}, error(
        message => 'instance is deprecated',
        instance_path => $instance_path,
        schema_path => $schema_path
    );
    return 1;
}

# Additional properties defined by the JSON Schema specification that are not mentioned in OAS30 are strictly unsupported.
sub dependencies { 1 }
sub additionalItems { 1 }
sub patternProperties { 1 }

sub __detect_discriminator_ref {
    my ($self, $ref) = @_;
    # heuristic
    return $ref if $ref =~ m|/|;
    return $ref if $ref =~ m/\.json$/;
    return '#/components/schemas/' . $ref;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSONSchema::Validator::Constraints::OAS30 - OpenAPI 3.0 specification constraints

=head1 VERSION

version 0.002

=head1 AUTHORS

=over 4

=item *

Alexey Stavrov <logioniz@ya.ru>

=item *

Ivan Putintsev <uid@rydlab.ru>

=item *

Anton Fedotov <tosha.fedotov.2000@gmail.com>

=item *

Denis Ibaev <dionys@gmail.com>

=item *

Andrey Khozov <andrey@rydlab.ru>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Alexey Stavrov.

This is free software, licensed under:

  The MIT (X11) License

=cut
