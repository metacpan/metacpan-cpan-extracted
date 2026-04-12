package JSON::Schema::AsType::Draft2019_09;
our $AUTHORITY = 'cpan:YANICK';
$JSON::Schema::AsType::Draft2019_09::VERSION = '1.0.0';
# ABSTRACT: A draft 2019-09 JSON Schema


use 5.42.0;
use warnings;

use feature ':5.42', 'try';
use JSON::Schema::AsType::Visit;
use List::Util      qw/ pairmap uniq /;
use List::MoreUtils qw/ /;
use List::UtilsBy   qw/ nsort_by /;
use Moose::Util     qw/ ensure_all_roles /;
use Module::Runtime qw/ use_module /;

use JSON;

use Moose;

extends qw/ JSON::Schema::AsType /;

use feature qw/ signatures /;

my $_uri_port = 1;
has '+uri' => lazy => 1,
  default  => sub($self) {

    my $id = $self->_has_id( $self->schema );

    unless ($id) {
        do {
            $id = 'http://254.0.0.1:' . $_uri_port++;
        } while $self->registered_schema($id);
    }

    # TODO not required?
    #$self->clear_parent_schema;

    return $id;
  };

has '+draft' => default => "2019-09";

has is_own_metaschema => (
    is      => 'ro',
    default => 0,
);

has '+metaschema' => (
    default => sub($self) {
        return $self if $self->is_own_metaschema;

        if ( ref $self->schema eq 'HASH' ) {
            if ( my $uri = $self->schema->{'$schema'} ) {
                unless ( ref $uri ) {
                    return $self->fetch($uri);
                }
            }
        }

        return $self->parent_schema->metaschema if $self->parent_schema;

        return _metaschema();
    }
);

has vocabularies => (
    is      => 'ro',
    lazy    => 1,
    default => sub($self) {

        my $v = $self->metaschema->schema->{'$vocabulary'} or return [];

        return [ pairmap { ($a) x !!$b } %$v ];
    }
);

%JSON::Schema::AsType::VOCABULARY = (
    %JSON::Schema::AsType::VOCABULARY,
    map {
        m#([^/]+)$#;
        $_ => __PACKAGE__ . '::Vocabulary::' . ucfirst($1) =~ s/-//r
    } ( "https://json-schema.org/draft/2019-09/vocab/core",
        "https://json-schema.org/draft/2019-09/vocab/applicator",
        "https://json-schema.org/draft/2019-09/vocab/validation",
        "https://json-schema.org/draft/2019-09/vocab/meta-data",
        "https://json-schema.org/draft/2019-09/vocab/format",
        "https://json-schema.org/draft/2019-09/vocab/content",
      )
);

# in D2019_09::Core ?
after _schema_trigger => sub ( $self, $schema, @ ) {
    JSON::Schema::AsType::Visit::visit(
        $schema,
        sub {
            return unless ref $_ eq 'HASH';

            my $anchor = $_->{'$anchor'} or return;

            my $uri = URI->new( $self->uri );

            if ( my $id = $self->_has_id($_) ) {
                $uri = $self->resolve_uri($id);
            }

            $uri->fragment($anchor);

            #$self->sub_schema( $_, $uri);
            $self->register_schema( $uri => $_ );
            return;
        }
    );
};

around sub_schema => sub ( $orig, $self, $subschema, $uri ) {

    # ah AH, resolve the subschema id
    if ( my $id = $self->_has_id($subschema) ) {
        $uri = $self->resolve_uri($id) unless $subschema->{'$ref'};
        $subschema->{'$id'} = "" . $uri;    # TODO sane?
    }
    $orig->( $self, $subschema, $uri );
};

my %keyword_index = reverse indexed '$id', '$ref', '$recursiveRef',
  qw/ properties items patternItems prefixItems patternProperties additionalProperties additionalItems
  allOf anyOf oneOf if dependentSchemas unevaluatedProperties
  unevaluatedItems /;

override all_keywords => sub($self) {

    return nsort_by {
        $keyword_index{$_} // 999
    }
    map { /^_keyword_(.*)/ } $self->meta->get_method_list;
};

sub _schema_trigger( $self, $schema, @ ) {
    JSON::Schema::AsType::Visit::visit(
        $schema,
        sub {
            return unless ref $_ eq 'HASH';

            my $id = $self->_has_id($_) or return;

            $self->sub_schema( $_, $id );
            return;
        }
    );
}

sub _has_id ( $self, $schema = {} ) {
    return unless ref $schema eq 'HASH';
    my $id = $schema->{'$id'};
    return if ref $id;    # not a real $id
    return $id;
}

sub _metaschema {
    state @docs = ( from_json join '', <DATA> )->@*;

    state $METASCHEMA = __PACKAGE__->new(
        uri               => "https://json-schema.org/draft/2019-09/schema",
        schema            => shift @docs,
        is_own_metaschema => 1,
    );

    state $done = 0;

    if ( not $done ) {
        $METASCHEMA->register_schema(
            "https://json-schema.org/v1" => $METASCHEMA, );
        $METASCHEMA->register_schema( $_->{'$id'} => $_ ) for @docs;
        $done++;
    }

    return $METASCHEMA;
}

=pod

=encoding UTF-8

=head1 NAME

JSON::Schema::AsType::Draft2019_09 - A draft 2019-09 JSON Schema

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
[
{
    "$schema": "https://json-schema.org/draft/2019-09/schema",
    "$id": "https://json-schema.org/draft/2019-09/schema",
    "$vocabulary": {
        "https://json-schema.org/draft/2019-09/vocab/core": true,
        "https://json-schema.org/draft/2019-09/vocab/applicator": true,
        "https://json-schema.org/draft/2019-09/vocab/validation": true,
        "https://json-schema.org/draft/2019-09/vocab/meta-data": true,
        "https://json-schema.org/draft/2019-09/vocab/format": false,
        "https://json-schema.org/draft/2019-09/vocab/content": true
    },
    "$recursiveAnchor": true,

    "title": "Core and Validation specifications meta-schema",
    "allOf": [
        {"$ref": "meta/core"},
        {"$ref": "meta/applicator"},
        {"$ref": "meta/validation"},
        {"$ref": "meta/meta-data"},
        {"$ref": "meta/format"},
        {"$ref": "meta/content"}
    ],
    "type": ["object", "boolean"],
    "properties": {
        "definitions": {
            "$comment": "While no longer an official keyword as it is replaced by $defs, this keyword is retained in the meta-schema to prevent incompatible extensions as it remains in common use.",
            "type": "object",
            "additionalProperties": { "$recursiveRef": "#" },
            "default": {}
        },
        "dependencies": {
            "$comment": "\"dependencies\" is no longer a keyword, but schema authors should avoid redefining it to facilitate a smooth transition to \"dependentSchemas\" and \"dependentRequired\"",
            "type": "object",
            "additionalProperties": {
                "anyOf": [
                    { "$recursiveRef": "#" },
                    { "$ref": "meta/validation#/$defs/stringArray" }
                ]
            }
        }
    }
}
,
{
    "$schema": "https://json-schema.org/draft/2019-09/schema",
    "$id": "https://json-schema.org/draft/2019-09/meta/core",
    "$recursiveAnchor": true,

    "title": "Core vocabulary meta-schema",
    "type": ["object", "boolean"],
    "properties": {
        "$id": {
            "type": "string",
            "format": "uri-reference",
            "$comment": "Non-empty fragments not allowed.",
            "pattern": "^[^#]*#?$"
        },
        "$schema": {
            "type": "string",
            "format": "uri"
        },
        "$anchor": {
            "type": "string",
            "pattern": "^[A-Za-z][-A-Za-z0-9.:_]*$"
        },
        "$ref": {
            "type": "string",
            "format": "uri-reference"
        },
        "$recursiveRef": {
            "type": "string",
            "format": "uri-reference"
        },
        "$recursiveAnchor": {
            "type": "boolean",
            "default": false
        },
        "$vocabulary": {
            "type": "object",
            "propertyNames": {
                "type": "string",
                "format": "uri"
            },
            "additionalProperties": {
                "type": "boolean"
            }
        },
        "$comment": {
            "type": "string"
        },
        "$defs": {
            "type": "object",
            "additionalProperties": { "$recursiveRef": "#" },
            "default": {}
        }
    }
}
,
{
    "$schema": "https://json-schema.org/draft/2019-09/schema",
    "$id": "https://json-schema.org/draft/2019-09/meta/applicator",
    "$recursiveAnchor": true,

    "title": "Applicator vocabulary meta-schema",
    "type": ["object", "boolean"],
    "properties": {
        "additionalItems": { "$recursiveRef": "#" },
        "unevaluatedItems": { "$recursiveRef": "#" },
        "items": {
            "anyOf": [
                { "$recursiveRef": "#" },
                { "$ref": "#/$defs/schemaArray" }
            ]
        },
        "contains": { "$recursiveRef": "#" },
        "additionalProperties": { "$recursiveRef": "#" },
        "unevaluatedProperties": { "$recursiveRef": "#" },
        "properties": {
            "type": "object",
            "additionalProperties": { "$recursiveRef": "#" },
            "default": {}
        },
        "patternProperties": {
            "type": "object",
            "additionalProperties": { "$recursiveRef": "#" },
            "propertyNames": { "format": "regex" },
            "default": {}
        },
        "dependentSchemas": {
            "type": "object",
            "additionalProperties": {
                "$recursiveRef": "#"
            }
        },
        "propertyNames": { "$recursiveRef": "#" },
        "if": { "$recursiveRef": "#" },
        "then": { "$recursiveRef": "#" },
        "else": { "$recursiveRef": "#" },
        "allOf": { "$ref": "#/$defs/schemaArray" },
        "anyOf": { "$ref": "#/$defs/schemaArray" },
        "oneOf": { "$ref": "#/$defs/schemaArray" },
        "not": { "$recursiveRef": "#" }
    },
    "$defs": {
        "schemaArray": {
            "type": "array",
            "minItems": 1,
            "items": { "$recursiveRef": "#" }
        }
    }
}
,
{
    "$schema": "https://json-schema.org/draft/2019-09/schema",
    "$id": "https://json-schema.org/draft/2019-09/meta/validation",
    "$recursiveAnchor": true,

    "title": "Validation vocabulary meta-schema",
    "type": ["object", "boolean"],
    "properties": {
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
        "maxLength": { "$ref": "#/$defs/nonNegativeInteger" },
        "minLength": { "$ref": "#/$defs/nonNegativeIntegerDefault0" },
        "pattern": {
            "type": "string",
            "format": "regex"
        },
        "maxItems": { "$ref": "#/$defs/nonNegativeInteger" },
        "minItems": { "$ref": "#/$defs/nonNegativeIntegerDefault0" },
        "uniqueItems": {
            "type": "boolean",
            "default": false
        },
        "maxContains": { "$ref": "#/$defs/nonNegativeInteger" },
        "minContains": {
            "$ref": "#/$defs/nonNegativeInteger",
            "default": 1
        },
        "maxProperties": { "$ref": "#/$defs/nonNegativeInteger" },
        "minProperties": { "$ref": "#/$defs/nonNegativeIntegerDefault0" },
        "required": { "$ref": "#/$defs/stringArray" },
        "dependentRequired": {
            "type": "object",
            "additionalProperties": {
                "$ref": "#/$defs/stringArray"
            }
        },
        "const": true,
        "enum": {
            "type": "array",
            "items": true
        },
        "type": {
            "anyOf": [
                { "$ref": "#/$defs/simpleTypes" },
                {
                    "type": "array",
                    "items": { "$ref": "#/$defs/simpleTypes" },
                    "minItems": 1,
                    "uniqueItems": true
                }
            ]
        }
    },
    "$defs": {
        "nonNegativeInteger": {
            "type": "integer",
            "minimum": 0
        },
        "nonNegativeIntegerDefault0": {
            "$ref": "#/$defs/nonNegativeInteger",
            "default": 0
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
    }
}
,
{
    "$schema": "https://json-schema.org/draft/2019-09/schema",
    "$id": "https://json-schema.org/draft/2019-09/meta/meta-data",
    "$recursiveAnchor": true,

    "title": "Meta-data vocabulary meta-schema",

    "type": ["object", "boolean"],
    "properties": {
        "title": {
            "type": "string"
        },
        "description": {
            "type": "string"
        },
        "default": true,
        "deprecated": {
            "type": "boolean",
            "default": false
        },
        "readOnly": {
            "type": "boolean",
            "default": false
        },
        "writeOnly": {
            "type": "boolean",
            "default": false
        },
        "examples": {
            "type": "array",
            "items": true
        }
    }
}
,
{
    "$schema": "https://json-schema.org/draft/2019-09/schema",
    "$id": "https://json-schema.org/draft/2019-09/meta/format",
    "$recursiveAnchor": true,

    "title": "Format vocabulary meta-schema",
    "type": ["object", "boolean"],
    "properties": {
        "format": { "type": "string" }
    }
}
,
{
    "$schema": "https://json-schema.org/draft/2019-09/schema",
    "$id": "https://json-schema.org/draft/2019-09/meta/content",
    "$recursiveAnchor": true,

    "title": "Content vocabulary meta-schema",

    "type": ["object", "boolean"],
    "properties": {
        "contentMediaType": { "type": "string" },
        "contentEncoding": { "type": "string" },
        "contentSchema": { "$recursiveRef": "#" }
    }
}
]
