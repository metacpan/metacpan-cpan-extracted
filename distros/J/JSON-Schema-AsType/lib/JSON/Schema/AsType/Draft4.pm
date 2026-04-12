package JSON::Schema::AsType::Draft4;
our $AUTHORITY = 'cpan:YANICK';
$JSON::Schema::AsType::Draft4::VERSION = '1.0.0';
# ABSTRACT: A draft 4 JSON Schema


use 5.42.0;
use warnings;

use feature ':5.42';

use JSON;

# use Data::Visitor::Tiny;
use JSON::Schema::AsType::Visit;

use List::Util qw/ uniq /;

use Moose;

extends qw/ JSON::Schema::AsType /;

with 'JSON::Schema::AsType::Draft4::Keywords';

use feature qw/ signatures /;

has '+draft' => default => 4;

has '+metaschema' => (
    default => sub($self) {
        my $schema = _metaschema();
        return $schema;
    }
);

my $_uri_port = 1;
has '+uri' => default => sub($self) {
    my $id = $self->_has_id( $self->schema )
      // 'http://254.0.0.1:' . $_uri_port++;
    $self->clear_parent_schema;
    return $id;
};

override all_keywords => sub {
    my $self = shift;

    # $ref trumps all
    return '$ref' if $self->schema->{'$ref'};

    return uniq 'id', super();
};

sub _schema_trigger( $self, $schema, @ ) {
    return unless $schema;    # TODO
    JSON::Schema::AsType::Visit::visit(
        $schema,
        sub {
            return unless ref $_ eq 'HASH';

            my $id = $self->_has_id($_) or return;

            # that doesn't look like a 'id' for the schema
            return if ref $id;

            $self->sub_schema( $_, $id );
        }
    );
}

sub _has_id ( $self, $schema = {} ) {
    return unless ref $schema eq 'HASH';
    return $schema->{id};
}

around sub_schema => sub ( $orig, $self, $subschema, $uri ) {

    # ah AH, resolve the subschema id
    if ( my $id = $self->_has_id($subschema) ) {
        $uri = $self->resolve_uri($id) unless $subschema->{'$ref'};
    }
    $orig->( $self, $subschema, $uri );
};

sub _metaschema {
    state $METASCHEMA = __PACKAGE__->new(
        uri    => "https://json-schema.org/draft-04/schema",
        schema => from_json join '',
        <DATA>,
    );

    return $METASCHEMA;
}

=pod

=encoding UTF-8

=head1 NAME

JSON::Schema::AsType::Draft4 - A draft 4 JSON Schema

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
	"id": "http://json-schema.org/draft-04/schema#",
	"$schema": "http://json-schema.org/draft-04/schema#",
	"description": "Core schema meta-schema",
	"definitions": {
		"schemaArray": {
			"type": "array",
			"minItems": 1,
			"items": { "$ref": "#" }
		},
		"positiveInteger": {
			"type": "integer",
			"minimum": 0
		},
		"positiveIntegerDefault0": {
			"allOf": [ { "$ref": "#/definitions/positiveInteger" }, { "default": 0 } ]
		},
		"simpleTypes": {
			"enum": [ "array", "boolean", "integer", "null", "number", "object", "string" ]
		},
		"stringArray": {
			"type": "array",
			"items": { "type": "string" },
			"minItems": 1,
			"uniqueItems": true
		}
	},
	"type": "object",
	"properties": {
		"id": {
			"type": "string",
			"format": "uri"
		},
		"$schema": {
			"type": "string",
			"format": "uri"
		},
		"title": {
			"type": "string"
		},
		"description": {
			"type": "string"
		},
		"default": {},
		"multipleOf": {
			"type": "number",
			"minimum": 0,
			"exclusiveMinimum": true
		},
		"maximum": {
			"type": "number"
		},
		"exclusiveMaximum": {
			"type": "boolean",
			"default": false
		},
		"minimum": {
			"type": "number"
		},
		"exclusiveMinimum": {
			"type": "boolean",
			"default": false
		},
		"maxLength": { "$ref": "#/definitions/positiveInteger" },
		"minLength": { "$ref": "#/definitions/positiveIntegerDefault0" },
		"pattern": {
			"type": "string",
			"format": "regex"
		},
		"additionalItems": {
			"anyOf": [
				{ "type": "boolean" },
				{ "$ref": "#" }
			],
			"default": {}
		},
		"items": {
			"anyOf": [
				{ "$ref": "#" },
				{ "$ref": "#/definitions/schemaArray" }
			],
			"default": {}
		},
		"maxItems": { "$ref": "#/definitions/positiveInteger" },
		"minItems": { "$ref": "#/definitions/positiveIntegerDefault0" },
		"uniqueItems": {
			"type": "boolean",
			"default": false
		},
		"maxProperties": { "$ref": "#/definitions/positiveInteger" },
		"minProperties": { "$ref": "#/definitions/positiveIntegerDefault0" },
		"required": { "$ref": "#/definitions/stringArray" },
		"additionalProperties": {
			"anyOf": [
				{ "type": "boolean" },
				{ "$ref": "#" }
			],
			"default": {}
		},
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
		"allOf": { "$ref": "#/definitions/schemaArray" },
		"anyOf": { "$ref": "#/definitions/schemaArray" },
		"oneOf": { "$ref": "#/definitions/schemaArray" },
		"not": { "$ref": "#" }
	},
	"dependencies": {
		"exclusiveMaximum": [ "maximum" ],
		"exclusiveMinimum": [ "minimum" ]
	},
	"default": {}
}
