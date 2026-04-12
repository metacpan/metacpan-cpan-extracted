package JSON::Schema::AsType::Draft6;
our $AUTHORITY = 'cpan:YANICK';
$JSON::Schema::AsType::Draft6::VERSION = '1.0.0';
# ABSTRACT: A draft 6 JSON Schema


use 5.42.0;
use warnings;

use feature ':5.42';
use JSON::Schema::AsType::Visit;

use JSON;
use List::Util qw/ uniq /;

use Moose;

extends qw/ JSON::Schema::AsType /;

with 'JSON::Schema::AsType::Draft6::Keywords';

use feature qw/ signatures /;

my $_uri_port = 1;
has '+uri' => default => sub($self) {
    my $id =
      eval { $self->schema->{'$id'} } // 'http://254.0.0.1:' . $_uri_port++;
    $self->clear_parent_schema;
    return $id;
};

has '+draft' => default => 6;

has '+metaschema' => (
    default => sub($self) {
        _metaschema();
    }
);

override all_keywords => sub {
    my $self = shift;

    # $ref trumps all
    return '$ref' if $self->schema->{'$ref'};

    return uniq '$id', super();
};

around sub_schema => sub ( $orig, $self, $subschema, $uri ) {

    # ah AH, resolve the subschema id
    if ( my $id = $self->_has_id($subschema) ) {
        $uri = $self->resolve_uri($id) unless $subschema->{'$ref'};
    }
    $orig->( $self, $subschema, $uri );
};

sub _schema_trigger( $self, $schema, @ ) {
    JSON::Schema::AsType::Visit::visit(
        $schema,
        sub {
            return unless ref $_ eq 'HASH';

            my $id = $self->_has_id($_) or return;

            # that doesn't look like a 'id' for the schema
            return if ref $id;

            $self->sub_schema( $_, $id );
            return;
        }
    );
}

sub _has_id ( $self, $schema = {} ) {
    return unless ref $schema eq 'HASH';
    return $schema->{'$id'};
}

sub _metaschema {
    state $METASCHEMA = __PACKAGE__->new(
        uri    => "https://json-schema.org/draft-06/schema",
        schema => from_json join '',
        <DATA>,
    );

    return $METASCHEMA;
}

=pod

=encoding UTF-8

=head1 NAME

JSON::Schema::AsType::Draft6 - A draft 6 JSON Schema

=head1 VERSION

version 1.0.0

=head1 DESCRIPTION 

Internal module for L<JSON::Schema:::AsType>. 

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
{
	"$schema": "https://json-schema.org/draft-06/schema#",
	"$id": "https://json-schema.org/draft-06/schema#",
	"title": "Core schema meta-schema",
	"definitions": {
		"schemaArray": {
			"type": "array",
			"minItems": 1,
			"items": { "$ref": "#" }
		},
		"nonNegativeInteger": {
			"type": "integer",
			"minimum": 0
		},
		"nonNegativeIntegerDefault0": {
			"allOf": [
				{ "$ref": "#/definitions/nonNegativeInteger" },
				{ "default": 0 }
			]
		},
		"simpleTypes": {
			"enum": [
				"array",
				"boolean",
				"integer",
				"null",
				"number",
				"object",
				"string"
			]
		},
		"stringArray": {
			"type": "array",
			"items": { "type": "string" },
			"uniqueItems": true,
			"default": []
		}
	},
	"type": ["object", "boolean"],
	"properties": {
		"$id": {
			"type": "string",
			"format": "uri-reference"
		},
		"$schema": {
			"type": "string",
			"format": "uri"
		},
		"$ref": {
			"type": "string",
			"format": "uri-reference"
		},
		"title": {
			"type": "string"
		},
		"description": {
			"type": "string"
		},
		"default": {},
		"examples": {
			"type": "array",
			"items": {}
		},
		"multipleOf": {
			"type": "number",
			"exclusiveMinimum": 0
		},
		"maximum": {
			"type": "number"
		},
		"exclusiveMaximum": {
			"type": "number"
		},
		"minimum": {
			"type": "number"
		},
		"exclusiveMinimum": {
			"type": "number"
		},
		"maxLength": { "$ref": "#/definitions/nonNegativeInteger" },
		"minLength": { "$ref": "#/definitions/nonNegativeIntegerDefault0" },
		"pattern": {
			"type": "string",
			"format": "regex"
		},
		"additionalItems": { "$ref": "#" },
		"items": {
			"anyOf": [
				{ "$ref": "#" },
				{ "$ref": "#/definitions/schemaArray" }
			],
			"default": {}
		},
		"maxItems": { "$ref": "#/definitions/nonNegativeInteger" },
		"minItems": { "$ref": "#/definitions/nonNegativeIntegerDefault0" },
		"uniqueItems": {
			"type": "boolean",
			"default": false
		},
		"contains": { "$ref": "#" },
		"maxProperties": { "$ref": "#/definitions/nonNegativeInteger" },
		"minProperties": { "$ref": "#/definitions/nonNegativeIntegerDefault0" },
		"required": { "$ref": "#/definitions/stringArray" },
		"additionalProperties": { "$ref": "#" },
		"definitions": {
			"type": "object",
			"additionalProperties": { "$ref": "#" },
			"default": {}
		},
		"properties": {
			"type": "object",
			"additionalProperties": { "$ref": "#" },
			"default": {}
		},
		"patternProperties": {
			"type": "object",
			"additionalProperties": { "$ref": "#" },
			"propertyNames": { "format": "regex" },
			"default": {}
		},
		"dependencies": {
			"type": "object",
			"additionalProperties": {
				"anyOf": [
					{ "$ref": "#" },
					{ "$ref": "#/definitions/stringArray" }
				]
			}
		},
		"propertyNames": { "$ref": "#" },
		"const": {},
		"enum": {
			"type": "array",
			"minItems": 1,
			"uniqueItems": true
		},
		"type": {
			"anyOf": [
				{ "$ref": "#/definitions/simpleTypes" },
				{
					"type": "array",
					"items": { "$ref": "#/definitions/simpleTypes" },
					"minItems": 1,
					"uniqueItems": true
				}
			]
		},
		"format": { "type": "string" },
		"allOf": { "$ref": "#/definitions/schemaArray" },
		"anyOf": { "$ref": "#/definitions/schemaArray" },
		"oneOf": { "$ref": "#/definitions/schemaArray" },
		"not": { "$ref": "#" }
	},
	"default": {}
}
