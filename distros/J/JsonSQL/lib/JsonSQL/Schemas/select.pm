# ABSTRACT: JsonSQL 'select' JSON schema.


use strict;
use warnings;
use 5.014;

package JsonSQL::Schemas::select;

our $VERSION = '0.41'; # VERSION

use base qw( JsonSQL::Schemas::Schema );



my $jsonSchema = '
{
    "title": "SQL Select Schema",
    "id": "sqlSelectSchema",
    "$schema": "http://json-schema.org/draft-04/schema#",
    "description": "JSON schema to describe an SQL SELECT query",
    "type": "object",
    "properties": {
        "defaultschema": {
            "type": "string",
            "pattern": "^[a-zA-Z_][a-zA-Z0-9_]*$"
        },
        "distinct": {
            "type": "string",
            "enum": ["true", "false"]
        },
        "fields": {
            "type": "array",
            "items": {
                "oneOf": [
                    {"$ref": "#/definitions/sqlAllFieldsObject"},
                    {"$ref": "#/definitions/sqlFromFieldObject"}
                ]
            },
            "minItems": 1
        },
        "from": {
            "type": "array",
            "items": {"$ref": "#/definitions/sqlTableObject"},
            "minItems": 1
        },
        "joins": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "jointype": {
                        "type": "string",
                        "enum": ["inner", "outerleft", "outerright", "outerfull", "cross"]
                    },
                    "from": {"$ref": "#/definitions/sqlTableObject"},
                    "to": {"$ref": "#/definitions/sqlTableObject"},
                    "on": {
                        "type": "object",
                        "patternProperties": {
                            "^eq$|^ne$|^gt$|^ge$|^lt$|^le$": {
                                "type": "object",
                                "properties": {
                                    "field": {"$ref": "#/definitions/sqlWhereFieldObject"},
                                    "value": {"$ref": "#/definitions/sqlWhereFieldObject"}
                                },
                               "additionalProperties": false,
                               "required": ["field", "value"]
                            }
                        },
                        "additionalProperties": false,
                        "minProperties": 1,
                        "maxProperties": 1
                    }
                },
                "additionalProperties": false,
                "required": ["jointype", "from", "to"]
            },
            "minItems": 1
        },
        "where": {"$ref": "#/definitions/conditionalOperator"},
        "groupby": {
            "type": "array",
            "items": {"$ref": "#/definitions/sqlWhereFieldObject"},
            "minItems": 1
        },
        "having": {"$ref": "#/definitions/conditionalOperator"},
        "orderby": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "field": {"$ref": "#/definitions/sqlWhereFieldObject"},
                    "order": {
                        "type": "string",
                        "enum": ["ASC", "DESC"]
                    },
                    "nulls": {
                        "type": "string",
                        "enum": ["FIRST", "LAST"]
                    }
                },
                "additionalProperties": false
            },
            "minItems": 1
        },
        "limit": {
            "type": "integer",
            "minimum": 1
        },
        "offset": {
            "type": "integer",
            "minimum": 1
        }
    },
    "additionalProperties": false,
    "required": ["fields"],
    "dependencies": {
        "anyOf": [
            {"fields": ["from"]},
            {"fields": ["joins"]}
        ]
    },
    "definitions": {
        "sqlAllFieldsObject": {
            "type": "object",
            "properties": {
                "schema": {
                    "type": "string",
                    "pattern": "^[a-zA-Z_][a-zA-Z0-9_]*$"
                },
                "table": {
                    "type": "string",
                    "pattern": "^[a-zA-Z_][a-zA-Z0-9_]*$"
                },
                "column": {
                    "type": "string",
                    "pattern": "^\\\\*$"
                }
            },
            "additionalProperties": false,
            "required": ["column"],
            "dependencies": {"schema": ["table"]}
        },
        "sqlFromFieldObject": {
            "type": "object",
            "properties": {
                "schema": {
                    "type": "string",
                    "pattern": "^[a-zA-Z_][a-zA-Z0-9_]*$"
                },
                "table": {
                    "type": "string",
                    "pattern": "^[a-zA-Z_][a-zA-Z0-9_]*$"
                },
                "column": {
                    "type": "string",
                    "pattern": "^[a-zA-Z_][a-zA-Z0-9_]*$"
                },
                "alias": {
                    "type": "string",
                    "pattern": "^[a-zA-Z_][a-zA-Z0-9_]*$"
                }
            },
            "additionalProperties": false,
            "required": ["column"],
            "dependencies": {"schema": ["table"]}
        },
        "sqlWhereFieldObject": {
            "type": "object",
            "properties": {
                "schema": {
                    "type": "string",
                    "pattern": "^[a-zA-Z_][a-zA-Z0-9_]*$"
                },
                "table": {
                    "type": "string",
                    "pattern": "^[a-zA-Z_][a-zA-Z0-9_]*$"
                },
                "column": {
                    "type": "string",
                    "pattern": "^[a-zA-Z_][a-zA-Z0-9_:]*$"
                }
            },
            "additionalProperties": false,
            "required": ["column"],
            "dependencies": {"schema": ["table"]}
        },
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
        "conditionalOperator": {
            "type": "object",
            "patternProperties": {
                "^eq$|^ne$|^gt$|^ge$|^lt$|^le$": {
                    "type": "object",
                    "properties": {
                        "field": {"$ref": "#/definitions/sqlWhereFieldObject"},
                        "value": {
                            "oneOf": [
                                {"$ref": "#/definitions/sqlWhereFieldObject"},
                                {"type": "string"},
                                {"type": "number"}
                            ]
                        }
                    },
                    "additionalProperties": false,
                    "required": ["field", "value"]
                },
                "^in$|^ni$": {
                    "type": "object",
                    "properties": {
                        "field": {"$ref": "#/definitions/sqlWhereFieldObject"},
                        "list": {
                            "type": "array",
                            "items": {"type": "string"},
                            "minItems": 2
                        }
                    },
                    "additionalProperties": false,
                    "required": ["field", "list"]
                },
                "^bt$|^nb$": {
                    "type": "object",
                    "properties": {
                        "field": {"$ref": "#/definitions/sqlWhereFieldObject"},
                        "minvalue": {
                            "oneOf": [
                                {"$ref": "#/definitions/sqlWhereFieldObject"},
                                {"type": "string"},
                                {"type": "number"}
                            ]
                        },
                        "maxvalue": {
                            "oneOf": [
                                {"$ref": "#/definitions/sqlWhereFieldObject"},
                                {"type": "string"},
                                {"type": "number"}
                            ]
                        }
                    },
                    "additionalProperties": false,
                    "required": ["field", "minvalue", "maxvalue"]
                },
                "^isnull$|^notnull$": {
                    "type": "object",
                    "properties": {
                        "field": {"$ref": "#/definitions/sqlWhereFieldObject"}
                    },
                    "additionalProperties": false,
                    "required": ["field"]
                },
                "^and$|^or$": {
                    "type": "array",
                    "items": {"$ref": "#/definitions/conditionalOperator"},
                    "minItems": 2
                }
            },
            "additionalProperties": false,
            "minProperties": 1,
            "maxProperties": 1
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

JsonSQL::Schemas::select - JsonSQL 'select' JSON schema.

=head1 VERSION

version 0.41

=head1 SYNOPSIS

This is a JSON schema describing an SQL SELECT statement. It tries to support most of the commonly used features, including JOINs.
You can instantiate this directly, but it is better to use the load_schema dispatcher from L<JsonSQL::Schemas::Schema>.

To use this:

    my $schema = JsonSQL::Schemas::select->new;
    if ( eval { $schema->is_error } ) {
        return "Could not load JSON schema: $schema->{message}";
    } else {
        my $schemaObj = parse_json($schema->{_json});
        ...
    }

For this to be useful, you will have to create a JSON::Validator object to validate parsed JSON strings, or just use L<JsonSQL::Validator>.

=head1 ATTRIBUTES

=head2 $jsonSchema

The SELECT schema as a JSON string.

=head1 METHODS

=head2 Constructor new -> JsonSQL::Schemas::select

Constructor method to return the $jsonSchema as a property of a new instance of this object.

=head1 AUTHOR

Chris Hoefler <bhoefler@draper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Hoefler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
