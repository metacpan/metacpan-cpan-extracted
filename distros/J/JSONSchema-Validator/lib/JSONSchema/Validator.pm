package JSONSchema::Validator;

# ABSTRACT: Validator for JSON Schema Draft4/Draft6/Draft7 and OpenAPI Specification 3.0

use strict;
use warnings;
use URI::file;
use Carp 'croak';
use Cwd;

use JSONSchema::Validator::Draft4;
use JSONSchema::Validator::Draft6;
use JSONSchema::Validator::Draft7;
use JSONSchema::Validator::OAS30;
use JSONSchema::Validator::Util qw(get_resource decode_content read_file);

our $VERSION = '0.006';

my $SPECIFICATIONS = {
    JSONSchema::Validator::OAS30::ID => JSONSchema::Validator::OAS30::SPECIFICATION,
    JSONSchema::Validator::Draft4::ID => JSONSchema::Validator::Draft4::SPECIFICATION,
    JSONSchema::Validator::Draft6::ID => JSONSchema::Validator::Draft6::SPECIFICATION,
    JSONSchema::Validator::Draft7::ID => JSONSchema::Validator::Draft7::SPECIFICATION
};

our $JSON_SCHEMA_VALIDATORS = ['JSONSchema::Validator::Draft4', 'JSONSchema::Validator::Draft6', 'JSONSchema::Validator::Draft7'];
our $OAS_VALIDATORS = ['JSONSchema::Validator::OAS30'];


sub new {
    my ($class, %params) = @_;

    my $resource = delete $params{resource};
    my $validate_schema = delete($params{validate_schema}) // 1;
    my $schema = delete $params{schema};
    my $base_uri = delete $params{base_uri};
    my $specification = delete $params{specification};

    $schema = resource_schema($resource, \%params) if !$schema && $resource;
    croak 'resource or schema must be specified' unless defined $schema;

    my $validator_class = find_validator($specification // schema_specification($schema));
    croak 'unknown specification' unless $validator_class;

    if ($validate_schema) {
        my ($result, $errors) = $class->validate_resource_schema($schema, $validator_class->SPECIFICATION);
        croak "invalid schema:\n" . join "\n", @$errors unless $result;
    }

    # schema may be boolean value according to json schema draft6
    if (ref $schema eq 'HASH') {
        $base_uri //= $resource || $schema->{'$id'} || $schema->{id};
    }

    return $validator_class->new(schema => $schema, base_uri => $base_uri, %params);
}


sub validate_paths {
    my ($class, $globs) = @_;
    my $results = {};
    for my $glob (@$globs) {
        my @resources = map { Cwd::abs_path($_) } glob $glob;
        for my $resource (@resources) {
            my $uri = URI::file->new($resource)->as_string;
            my ($result, $errors) = $class->validate_resource($uri);
            $results->{$resource} = [$result, $errors];
        }
    }
    return $results;
}


sub validate_resource {
    my ($class, $resource, %params) = @_;
    my $schema_to_validate = resource_schema($resource, \%params);

    my $validator_class = find_validator(schema_specification($schema_to_validate));
    croak "unknown specification of resource $resource" unless $validator_class;

    return $class->validate_resource_schema($schema_to_validate, $validator_class->SPECIFICATION);
}


sub validate_resource_schema {
    my ($class, $schema_to_validate, $schema_specification) = @_;

    my $schema = read_specification($schema_specification);
    my $meta_schema = $schema->{'$schema'};

    my $meta_schema_specification = $SPECIFICATIONS->{$meta_schema} // $SPECIFICATIONS->{$meta_schema . '#'};
    croak "unknown meta schema: $meta_schema" unless $meta_schema_specification;

    my $validator_class = find_validator($meta_schema_specification);
    croak "can't find validator by meta schema: $meta_schema" unless $validator_class;

    my $validator = $validator_class->new(schema => $schema);
    my ($result, $errors) = $validator->validate_schema($schema_to_validate);
    return ($result, $errors);
}

sub read_specification {
    my $filename = shift;
    my $curret_filepath = __FILE__;
    my $schema_filepath = ($curret_filepath =~ s/\.pm$//r) . '/schemas/' . lc($filename) . '.json';
    my ($content, $mime_type) = read_file($schema_filepath);
    return decode_content($content, $mime_type, $schema_filepath);
}

sub resource_schema {
    my ($resource, $params) = @_;
    my ($response, $mime_type) = get_resource($params->{scheme_handlers}, $resource);
    my $schema = decode_content($response, $mime_type, $resource);
    return $schema;
}

sub find_validator {
    my $specification = shift;
    my ($validator_class) = grep { lc($_->SPECIFICATION) eq lc($specification // '') } @$JSON_SCHEMA_VALIDATORS, @$OAS_VALIDATORS;
    return $validator_class;
}

sub schema_specification {
    my $schema = shift;
    return if ref $schema ne 'HASH';

    my $meta_schema = $schema->{'$schema'};
    my $specification = $meta_schema ? $SPECIFICATIONS->{$meta_schema} // $SPECIFICATIONS->{$meta_schema . '#'} : undef;

    if (!$specification && $schema->{openapi}) {
        my @vers = split /\./, $schema->{openapi};
        $specification = 'OAS' . $vers[0] . $vers[1];
    }

    return $specification;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSONSchema::Validator - Validator for JSON Schema Draft4/Draft6/Draft7 and OpenAPI Specification 3.0

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    # to get OpenAPI validator of schema in YAML format
    $validator = JSONSchema::Validator->new(resource => 'file:///some/path/to/oas30.yml');
    my ($result, $errors, $warnings) = $validator->validate_request(
        method => 'GET',
        openapi_path => '/user/{id}/profile',
        parameters => {
            path => {
                id => 1234
            },
            query => {
                details => 'short'
            },
            header => {
                header => 'header value'
            },
            cookie => {
                name => 'value'
            },
            body => [$is_exists, $content_type, $data]
        }
    );
    my ($result, $errors, $warnings) = $validator->validate_response(
        method => 'GET',
        openapi_path => '/user/{id}/profile',
        status => '200',
        parameters => {
            header => {
                header => 'header value'
            },
            body => [$is_exists, $content_type, $data]
        }
    )

    # to get JSON Schema Draft4/Draft6/Draft7 validator of schema in JSON format
    $validator = JSONSchema::Validator->new(resource => 'http://example.com/draft4/schema.json')
    my ($result, $errors) = $validator->validate_schema($object_to_validate)

=head1 DESCRIPTION

OpenAPI specification and JSON Schema Draft4/Draft6/Draft7 validators with minimum dependencies.

=head1 METHODS

=head2 new

Creates one of the following validators: JSONSchema::Validator::Draft4, JSONSchema::Validator::Draft6, JSONSchema::Validator::Draft7, JSONSchema::Validator::OAS30.

    my $validator = JSONSchema::Validator->new(resource => 'file:///some/path/to/oas30.yml');
    my $validator = JSONSchema::Validator->new(resource => 'http://example.com/draft4/schema.json');
    my $validator = JSONSchema::Validator->new(schema => {'$schema' => 'path/to/schema', ...});
    my $validator = JSONSchema::Validator->new(schema => {...}, specification => 'Draft4');

if parameter C<specification> is not specified then type of validator will be determined by C<$schema> key
for JSON Schema Draft4/Draft6/Draft7 and by C<openapi> key for OpenAPI Specification 3.0 in C<schema> parameter.

=head3 Parameters

=head4 resources

To get schema by uri

=head4 schema

To get explicitly specified schema

=head4 specification

To specify specification of schema

=head4 validate_schema

Do not validate specified schema

=head4 base_uri

To specify base uri of schema.
This parameter used to build absolute path by relative reference in schema.
By default C<base_uri> is equal to the resource path if the resource parameter is specified otherwise the C<$id> key in the schema.

=head3 Additional parameters

Additional parameters need to be looked at in a specific validator class.
Currently there are validators: JSONSchema::Validator::Draft4, JSONSchema::Validator::Draft6, JSONSchema::Validator::Draft7, JSONSchema::Validator::OAS30.

=head2 validate_paths

Validates all files specified by path globs.

    my $result = JSONSchema::Validator->validate_paths(['/some/path/to/openapi.*.yaml', '/some/path/to/jsonschema.*.json']);
    for my $file (keys %$result) {
        my ($res, $errors) = @{$result->{$file}};
    }

=head2 validate_resource

=head2 validate_resource_schema

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

=head1 CONTRIBUTOR

=for stopwords James Waters

James Waters <james@jcwaters.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Alexey Stavrov.

This is free software, licensed under:

  The MIT (X11) License

=cut
