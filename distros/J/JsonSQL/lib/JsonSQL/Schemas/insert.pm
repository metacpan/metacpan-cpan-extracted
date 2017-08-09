# ABSTRACT: JsonSQL 'insert' JSON schema.


use strict;
use warnings;
use 5.014;

package JsonSQL::Schemas::insert;

our $VERSION = '0.41'; # VERSION

use base qw( JsonSQL::Schemas::Schema );



my $jsonSchema = '
{
    "title": "SQL Insert Schema",
    "id": "sqlInsertSchema",
    "$schema": "http://json-schema.org/draft-04/schema#",
    "description": "JSON schema to describe an SQL INSERT",
    "type": "object",
    "properties": {
        "defaultschema": {
            "type": "string",
            "pattern": "^[a-zA-Z_][a-zA-Z0-9_]*$"
        },
        "inserts": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "table": {"$ref": "#/definitions/sqlTableObject"},
                    "values": {
                        "type": "array",
                        "items": {"$ref": "#/definitions/sqlInsertValueObject"},
                        "minItems": 1
                    },
                    "returning": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties" : {
                                "column": {"type": "string", "pattern": "^[a-zA-Z_][a-zA-Z0-9_]*$"},
                                "as": {"type": "string", "pattern": "^[a-zA-Z_][a-zA-Z0-9_]*$"}
                            },
                            "additionalProperties": false,
                            "required": ["column"]
                        },
                        "minItems": 1
                    }
                },
                "required": ["table", "values"]
            },
            "minItems": 1
        }
    },
    "additionalProperties": false,
    "required": ["inserts"],
    "definitions": {
        "sqlTableObject": {
            "type": "object",
            "properties": {
                "schema": {
                    "type": "string",
                    "pattern": "^[a-zA-Z_][a-zA-Z0-9_]*$"
                },
                "table": {
                    "type": "string",
                    "pattern": "^[a-zA-Z_][a-zA-Z0-9_]*$"
                }
            },
            "additionalProperties": false,
            "required": ["table"]
        },
        "sqlInsertValueObject": {
            "type": "object",
            "properties": {
                "column": {
                    "type": "string",
                    "pattern": "^[a-zA-Z_][a-zA-Z0-9_]*$"
                },
                "value": {
                    "oneOf": [
                        {"type": "string"},
                        {"type": "number"}
                    ]
                }
            },
            "additionalProperties": false,
            "required": ["column", "value"]
        }
    }
}
';



sub new {
    my $class = shift;
    
    my $self = $class->SUPER::new();

    $self->{_json} = $jsonSchema;
    
    return $self;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JsonSQL::Schemas::insert - JsonSQL 'insert' JSON schema.

=head1 VERSION

version 0.41

=head1 SYNOPSIS

This is a JSON schema describing an SQL INSERT statement. The main "inserts" property is an array, allowing support for batching
of multiple INSERT statements into one query. For each INSERT, the table and values parameters are specified as separate properties.
There is rudimentary support for the RETURNING clause if your database supports it.

You can instantiate this directly, but it is better to use the load_schema dispatcher from L<JsonSQL::Schemas::Schema>.

To use this:

    my $schema = JsonSQL::Schemas::insert->new;
    if ( eval { $schema->is_error } ) {
        return "Could not load JSON schema: $schema->{message}";
    } else {
        my $schemaObj = parse_json($schema->{_json});
        ...
    }

For this to be useful, you will have to create a JSON::Validator object to validate parsed JSON strings, or just use L<JsonSQL::Validator>.

=head1 ATTRIBUTES

=head2 $jsonSchema

The INSERT schema as a JSON string.

=head1 METHODS

=head2 Constructor new -> JsonSQL::Schemas::insert

Constructor method to return the $jsonSchema as a property of a new instance of this object.

=head1 AUTHOR

Chris Hoefler <bhoefler@draper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Hoefler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
