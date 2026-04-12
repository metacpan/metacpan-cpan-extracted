package JSON::Schema::AsType::Draft2020_12;
our $AUTHORITY = 'cpan:YANICK';
$JSON::Schema::AsType::Draft2020_12::VERSION = '1.0.0';
# ABSTRACT: A draft 2020-12 JSON Schema


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

has '+draft' => default => "2020-12";

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

%JSON::Schema::AsType::VOCABULARY = (
    %JSON::Schema::AsType::VOCABULARY,
    map {
        m#([^/]+)$#;
        $_ => __PACKAGE__ . '::Vocabulary::' . ucfirst($1) =~ s/-//r
    } ( "https://json-schema.org/draft/2020-12/vocab/core",
        "https://json-schema.org/draft/2020-12/vocab/applicator",
        "https://json-schema.org/draft/2020-12/vocab/validation",
        "https://json-schema.org/draft/2020-12/vocab/unevaluated",
        "https://json-schema.org/draft/2020-12/vocab/meta-data",
        "https://json-schema.org/draft/2020-12/vocab/format-annotation",
        "https://json-schema.org/draft/2020-12/vocab/content",
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

my %keyword_index = reverse indexed '$id', '$ref', '$recursiveRef', qw/
  properties
  items
  contains
  minContains
  maxContains
  prefixItems
  patternItems
  prefixItems
  patternProperties
  additionalProperties
  additionalItems
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
        uri               => "https://json-schema.org/draft/2020-12/schema",
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

JSON::Schema::AsType::Draft2020_12 - A draft 2020-12 JSON Schema

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
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "$id": "https://json-schema.org/draft/2020-12/schema",
    "$vocabulary": {
        "https://json-schema.org/draft/2020-12/vocab/core": true,
        "https://json-schema.org/draft/2020-12/vocab/applicator": true,
        "https://json-schema.org/draft/2020-12/vocab/unevaluated": true,
        "https://json-schema.org/draft/2020-12/vocab/validation": true,
        "https://json-schema.org/draft/2020-12/vocab/meta-data": true,
        "https://json-schema.org/draft/2020-12/vocab/format-annotation": true,
        "https://json-schema.org/draft/2020-12/vocab/content": true
    },
    "$dynamicAnchor": "meta",

    "title": "Core and Validation specifications meta-schema",
    "allOf": [
        {"$ref": "meta/core"},
        {"$ref": "meta/applicator"},
        {"$ref": "meta/unevaluated"},
        {"$ref": "meta/validation"},
        {"$ref": "meta/meta-data"},
        {"$ref": "meta/format-annotation"},
        {"$ref": "meta/content"}
    ],
    "type": ["object", "boolean"],
    "$comment": "This meta-schema also defines keywords that have appeared in previous drafts in order to prevent incompatible extensions as they remain in common use.",
    "properties": {
        "definitions": {
            "$comment": "\"definitions\" has been replaced by \"$defs\".",
            "type": "object",
            "additionalProperties": { "$dynamicRef": "#meta" },
            "deprecated": true,
            "default": {}
        },
        "dependencies": {
            "$comment": "\"dependencies\" has been split and replaced by \"dependentSchemas\" and \"dependentRequired\" in order to serve their differing semantics.",
            "type": "object",
            "additionalProperties": {
                "anyOf": [
                    { "$dynamicRef": "#meta" },
                    { "$ref": "meta/validation#/$defs/stringArray" }
                ]
            },
            "deprecated": true,
            "default": {}
        },
        "$recursiveAnchor": {
            "$comment": "\"$recursiveAnchor\" has been replaced by \"$dynamicAnchor\".",
            "$ref": "meta/core#/$defs/anchorString",
            "deprecated": true
        },
        "$recursiveRef": {
            "$comment": "\"$recursiveRef\" has been replaced by \"$dynamicRef\".",
            "$ref": "meta/core#/$defs/uriReferenceString",
            "deprecated": true
        }
    }
},
{
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "$id": "https://json-schema.org/draft/2020-12/meta/core",
    "$dynamicAnchor": "meta",

    "title": "Core vocabulary meta-schema",
    "type": ["object", "boolean"],
    "properties": {
        "$id": {
            "$ref": "#/$defs/uriReferenceString",
            "$comment": "Non-empty fragments not allowed.",
            "pattern": "^[^#]*#?$"
        },
        "$schema": { "$ref": "#/$defs/uriString" },
        "$ref": { "$ref": "#/$defs/uriReferenceString" },
        "$anchor": { "$ref": "#/$defs/anchorString" },
        "$dynamicRef": { "$ref": "#/$defs/uriReferenceString" },
        "$dynamicAnchor": { "$ref": "#/$defs/anchorString" },
        "$vocabulary": {
            "type": "object",
            "propertyNames": { "$ref": "#/$defs/uriString" },
            "additionalProperties": {
                "type": "boolean"
            }
        },
        "$comment": {
            "type": "string"
        },
        "$defs": {
            "type": "object",
            "additionalProperties": { "$dynamicRef": "#meta" }
        }
    },
    "$defs": {
        "anchorString": {
            "type": "string",
            "pattern": "^[A-Za-z_][-A-Za-z0-9._]*$"
        },
        "uriString": {
            "type": "string",
            "format": "uri"
        },
        "uriReferenceString": {
            "type": "string",
            "format": "uri-reference"
        }
    }
},
{
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "$id": "https://json-schema.org/draft/2020-12/meta/applicator",
    "$dynamicAnchor": "meta",

    "title": "Applicator vocabulary meta-schema",
    "type": ["object", "boolean"],
    "properties": {
        "prefixItems": { "$ref": "#/$defs/schemaArray" },
        "items": { "$dynamicRef": "#meta" },
        "contains": { "$dynamicRef": "#meta" },
        "additionalProperties": { "$dynamicRef": "#meta" },
        "properties": {
            "type": "object",
            "additionalProperties": { "$dynamicRef": "#meta" },
            "default": {}
        },
        "patternProperties": {
            "type": "object",
            "additionalProperties": { "$dynamicRef": "#meta" },
            "propertyNames": { "format": "regex" },
            "default": {}
        },
        "dependentSchemas": {
            "type": "object",
            "additionalProperties": { "$dynamicRef": "#meta" },
            "default": {}
        },
        "propertyNames": { "$dynamicRef": "#meta" },
        "if": { "$dynamicRef": "#meta" },
        "then": { "$dynamicRef": "#meta" },
        "else": { "$dynamicRef": "#meta" },
        "allOf": { "$ref": "#/$defs/schemaArray" },
        "anyOf": { "$ref": "#/$defs/schemaArray" },
        "oneOf": { "$ref": "#/$defs/schemaArray" },
        "not": { "$dynamicRef": "#meta" }
    },
    "$defs": {
        "schemaArray": {
            "type": "array",
            "minItems": 1,
            "items": { "$dynamicRef": "#meta" }
        }
    }
},
{
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "$id": "https://json-schema.org/draft/2020-12/meta/validation",
    "$dynamicAnchor": "meta",

    "title": "Validation vocabulary meta-schema",
    "type": ["object", "boolean"],
    "properties": {
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
        },
        "const": true,
        "enum": {
            "type": "array",
            "items": true
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
},
{
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "$id": "https://json-schema.org/draft/2020-12/meta/unevaluated",
    "$dynamicAnchor": "meta",

    "title": "Unevaluated applicator vocabulary meta-schema",
    "type": ["object", "boolean"],
    "properties": {
        "unevaluatedItems": { "$dynamicRef": "#meta" },
        "unevaluatedProperties": { "$dynamicRef": "#meta" }
    }
},
{
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "$id": "https://json-schema.org/draft/2020-12/meta/meta-data",
    "$dynamicAnchor": "meta",

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
},
{
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "$id": "https://json-schema.org/draft/2020-12/meta/format-annotation",
    "$dynamicAnchor": "meta",

    "title": "Format vocabulary meta-schema for annotation results",
    "type": ["object", "boolean"],
    "properties": {
        "format": { "type": "string" }
    }
},
{
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "$id": "https://json-schema.org/draft/2020-12/meta/content",
    "$dynamicAnchor": "meta",

    "title": "Content vocabulary meta-schema",

    "type": ["object", "boolean"],
    "properties": {
        "contentEncoding": { "type": "string" },
        "contentMediaType": { "type": "string" },
        "contentSchema": { "$dynamicRef": "#meta" }
    }
}
]
