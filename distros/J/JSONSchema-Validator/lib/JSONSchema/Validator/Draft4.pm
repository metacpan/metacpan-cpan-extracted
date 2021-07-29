package JSONSchema::Validator::Draft4;

# ABSTRACT: Validator for JSON Schema Draft4

use strict;
use warnings;
use URI;
use Carp 'croak';

use JSONSchema::Validator::Error 'error';
use JSONSchema::Validator::JSONPointer 'json_pointer';
use JSONSchema::Validator::Constraints::Draft4;
use JSONSchema::Validator::URIResolver;

use constant ID => 'id';

sub new {
    my ($class, %params) = @_;

    my $schema = $params{schema} or croak 'schema is required';
    my $strict = $params{strict} // 1;
    my $using_id_with_ref = $params{using_id_with_ref} // 1;

    my $scheme_handlers = $params{scheme_handlers} // {};

    my $self = {
        schema => $schema,
        errors => [],
        scopes => [],
        using_id_with_ref => $using_id_with_ref
    };

    bless $self, $class;

    my $base_uri = $params{base_uri} // $schema->{$self->ID} // '';
    $self->{base_uri} = $base_uri;

    my $constraints = JSONSchema::Validator::Constraints::Draft4->new(validator => $self, strict => $strict);
    $self->{constraints} = $constraints;

    my $resolver = JSONSchema::Validator::URIResolver->new(
        validator => $self,
        base_uri => $base_uri,
        schema => $schema,
        scheme_handlers => $scheme_handlers
    );
    $self->{resolver} = $resolver;

    push @{$self->scopes}, $base_uri;

    return $self;
}

sub schema { shift->{schema} }
sub constraints { shift->{constraints} }
sub resolver { shift->{resolver} }
sub scopes { shift->{scopes} }
sub scope { shift->{scopes}[-1] }
sub base_uri { shift->{base_uri} }
sub using_id_with_ref { shift->{using_id_with_ref} }

sub validate_schema {
    my ($self, $instance, %params) = @_;

    my $schema = $params{schema} || $self->schema;
    my $instance_path = $params{instance_path} // '/';
    my $schema_path = $params{schema_path} // '/';
    my $scope = $params{scope};

    croak 'No schema specified' unless $schema;

    push @{$self->scopes}, $scope if $scope;

    my $errors = [];
    my $result = $self->_validate_schema($instance, $schema, $instance_path, $schema_path, {errors => $errors});

    pop @{$self->scopes} if $scope;

    return $result, $errors;
}

sub _validate_schema {
    my ($self, $instance, $schema, $instance_path, $schema_path, $data, %params) = @_;

    my $apply_scope = $params{apply_scope} // 1;

    my $id = $schema->{$self->ID};
    if ($id && $apply_scope && $self->using_id_with_ref) {
        my $uri = $id;
        $uri = URI->new($id)->abs($self->scope)->as_string if $self->scope;
        push @{$self->scopes}, $uri;
    }

    my @schema_keys = $self->_schema_keys($schema, $instance_path, $data);

    my $result = 1;
    for my $k (@schema_keys) {
        my $v = $schema->{$k};

        my $method = $k eq '$ref' ? 'ref' : $k;
        next unless my $constraint = $self->constraints->can($method);

        my $spath = json_pointer->append($schema_path, $k);

        my $r = eval {
            $self->constraints->$constraint($instance, $v, $schema, $instance_path, $spath, $data);
        };
        push @{$data->{errors}}, error(
                message => "exception: $@",
                instance_path => $instance_path,
                schema_path => $spath
            ) if $@;
        $result = 0 unless $r;
    }

    pop @{$self->scopes} if $id && $apply_scope && $self->using_id_with_ref;
    return $result;
}

sub _schema_keys {
    my ($self, $schema, $instance_path, $data) = @_;
    # if ref exists other preperties MUST be ignored
    return '$ref' if $schema->{'$ref'};
    return keys %$schema;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSONSchema::Validator::Draft4 - Validator for JSON Schema Draft4

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    # to get OpenAPI validator of schema in YAML format
    $validator = JSONSchema::Validator::Draft4->new(schema => {...});
    my ($result, $errors) = $validator->validate_schema($object_to_validate);

=head1 DESCRIPTION

JSON Schema Draft4 validator with minimum dependencies.

=head1 CLASS METHODS

=head2 new

Creates JSONSchema::Validator::Draft4 object.

    $validator = JSONSchema::Validator::Draft4->new(schema => {...});

=head3 Parameters

=head4 schema

Scheme according to which validation occures.

=head4 strict

Use strong type checks. Default value is 1.

=head4 using_id_with_ref

Consider key C<$id> to identify subschema when resolving links.
For more details look at json schema docs about L<named anchors|https://json-schema.org/understanding-json-schema/structuring.html#id12> and L<bundling|https://json-schema.org/understanding-json-schema/structuring.html#id19>.

=head4 scheme_handlers

At the moment, the validator can load a resource using the http, https protocols. You can add other protocols yourself.

    sub loader {
        my $uri = shift;
        ...
    }
    $validator = JSONSchema::Validator::Draft4->new(schema => {...}, scheme_handlers => {ftp => \&loader});

=head1 METHODS

=head2 validate_schema

Validate object instance according to schema.

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
