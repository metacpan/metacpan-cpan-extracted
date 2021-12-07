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
use JSONSchema::Validator::Util qw(is_type);

use constant SPECIFICATION => 'Draft4';
use constant ID => 'http://json-schema.org/draft-04/schema#';
use constant ID_FIELD => 'id';

sub create {
    my ($class, %params) = @_;

    croak 'schema is required' unless exists $params{schema};

    my $schema = $params{schema};
    my $using_id_with_ref = $params{using_id_with_ref} // 1;

    my $scheme_handlers = $params{scheme_handlers} // {};

    my $self = {
        schema => $schema,
        errors => [],
        scopes => [],
        using_id_with_ref => $using_id_with_ref
    };

    bless $self, $class;

    # schema may be boolean value according to json schema draft6
    my $base_uri = $params{base_uri};
    $base_uri //= $schema->{$self->ID_FIELD} if ref $schema eq 'HASH';
    $base_uri //= '';
    $self->{base_uri} = $base_uri;

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

sub new {
    my ($class, %params) = @_;

    my $self = $class->create(%params);

    my $constraints = JSONSchema::Validator::Constraints::Draft4->new(validator => $self, strict => $params{strict} // 1);
    $self->{constraints} = $constraints;

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

    my $schema = $params{schema} // $self->schema;
    my $instance_path = $params{instance_path} // '/';
    my $schema_path = $params{schema_path} // '/';
    my $scope = $params{scope};

    croak 'No schema specified' unless defined $schema;

    push @{$self->scopes}, $scope if $scope;

    my $errors = [];
    my $result = $self->_validate_schema($instance, $schema, $instance_path, $schema_path, {errors => $errors});

    pop @{$self->scopes} if $scope;

    return $result, $errors;
}

sub _validate_schema {
    my ($self, $instance, $schema, $instance_path, $schema_path, $data, %params) = @_;

    # for json schema draft 6 which allow boolean value for schema
    if (is_type($schema, 'boolean', 1)) {
        return 1 if $schema;
        push @{$data->{errors}}, error(
            message => 'Schema with value "false" does not allow anything',
            instance_path => $instance_path,
            schema_path => $schema_path
        );
        return 0;
    }

    my $apply_scope = $params{apply_scope} // 1;

    my $is_exists_ref = exists $schema->{'$ref'};

    my $id = $schema->{$self->ID_FIELD};
    if ($id && $apply_scope && $self->using_id_with_ref && !$is_exists_ref) {
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

    pop @{$self->scopes} if $id && $apply_scope && $self->using_id_with_ref && !$is_exists_ref;
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

version 0.010

=head1 SYNOPSIS

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

Scheme according to which validation occurs.

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
