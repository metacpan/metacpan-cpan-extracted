#!/usr/bin/env perl

use strict;
use warnings;
use JSONSchema::Validator::OAS30;
use JSONSchema::Validator::JSONPointer;
use JSONSchema::Validator::Util qw/json_decode data_section/;

use Test::More;

my $data = data_section('main');

my $tests = json_decode($data);

for my $test (@$tests) {
    my $test_topic = $test->{subject};
    my $subtests = $test->{tests};
    for my $t (@$subtests) {
        my $validator = JSONSchema::Validator::OAS30->new(schema => $test->{schema}, validate_deprecated => $t->{validate_deprecated});

        my $test_name = $test_topic . ': ' . $t->{description};
        my $pointer = JSONSchema::Validator::JSONPointer->new(
            scope => '',
            value => $test->{schema},
            validator => $validator
        )->get($t->{pointer});
        my ($result, $errors, $warnings) = $validator->validate_schema($t->{data},
                schema => $pointer->value,
                direction => ($t->{direction} // 'request')
        );
        if ($t->{valid}) {
            is $result, 1, $test_name;
            is @$errors, 0, $test_name . '; errors is empty';
            if (defined $t->{validate_deprecated}) {
                ok @$warnings > 0, $test_name . '; deprecated warnings';
            } else {
                ok @$warnings == 0, $test_name . '; deprecated warnings';
            }
        } else {
            is $result, 0, $test_name;
            ok @$errors > 0, $test_name . '; errors is not empty';
            if (defined $t->{validate_deprecated}) {
                ok @$warnings > 0, $test_name . '; deprecated warnings';
            } else {
                ok @$warnings == 0, $test_name . '; deprecated warnings';
            }
        }
    }
}

done_testing;

__DATA__
[
    {
        "subject": "schema",
        "schema": {
            "openapi": "3.0.0",
            "info": { "title": "Nullable", "version": "" },
            "paths": {
                "/test": {
                    "parameters": [
                        {
                            "name": "integer_nullable",
                            "in" : "query",
                            "schema" : {
                                "type" : "integer",
                                "nullable": true
                            }
                        },
                        {
                            "name": "integer",
                            "in" : "query",
                            "schema" : {
                                "type" : "integer"
                            }
                        },
                        {
                            "name": "nullable",
                            "in" : "query",
                            "schema" : {
                                "nullable": true
                            }
                        },
                        {
                            "name": "nullable2",
                            "in" : "query",
                            "schema" : {
                                "nullable": false
                            }
                        },
                        {
                            "name": "items",
                            "in" : "query",
                            "content" : {
                                "application/json": {
                                    "schema": {
                                        "items": {
                                            "type" : "integer",
                                            "minimum": 3
                                        }
                                    }
                                }
                            }
                        },
                        {
                            "name": "readOnly",
                            "in" : "query",
                            "content" : {
                                "application/json": {
                                    "schema": {
                                        "$ref" : "#/components/schemas/readOnly"
                                    }
                                }
                            }
                        },
                        {
                            "name": "writeOnly",
                            "in" : "query",
                            "content" : {
                                "application/json": {
                                    "schema": {
                                        "$ref" : "#/components/schemas/writeOnly"
                                    }
                                }
                            }
                        },
                        {
                            "name": "deprecated",
                            "in" : "query",
                            "schema": {
                                "type" : "string",
                                "enum" : ["deprecated"],
                                "deprecated": true
                            }
                        },
                        {
                            "name": "empty_deprecated",
                            "in" : "query",
                            "schema": {
                                "deprecated": true
                            }
                        }
                    ],
                    "get": {
                        "responses": {
                            "200": {
                                "content": {
                                    "application/json": {
                                        "schema": {
                                            "type": "object",
                                            "properties": {
                                                "writeOnly" : {
                                                    "$ref" : "#/components/schemas/writeOnly"
                                                },
                                                "readOnly" : {
                                                    "$ref" : "#/components/schemas/readOnly"
                                                },
                                                "discriminatorOneOf" : {
                                                    "oneOf": [
                                                        { "$ref": "#/components/schemas/Cat" },
                                                        { "$ref": "#/components/schemas/Dog" }
                                                    ],
                                                    "discriminator": {
                                                        "propertyName": "petType"
                                                    }
                                                },
                                                "discriminatorInherit" : {
                                                    "$ref": "#/components/schemas/Shape"
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            },
            "components": {
                "schemas": {
                    "readOnly" : {
                        "type": "object",
                        "properties" : {
                            "name": { "type": "string" },
                            "age": { "type": "integer" },
                            "id": { "type": "integer", "readOnly": true }
                        },
                        "required" : ["name", "age", "id"]
                    },
                    "writeOnly" : {
                        "type": "object",
                        "properties" : {
                            "name": { "type": "string" },
                            "offset" : { "type": "integer", "writeOnly": true }
                        },
                        "required" : ["name", "offset"]
                    },
                    "Pet": {
                        "type": "object",
                        "properties": {
                            "name": {
                                "type": "string"
                            },
                            "petType": {
                                "type": "string"
                            }
                        },
                        "required": [
                            "name",
                            "petType"
                        ]
                    },
                    "Cat": {
                        "description": "A representation of a cat. Note that `Cat` will be used as the discriminator value.",
                        "allOf": [
                            {
                                "$ref": "#/components/schemas/Pet"
                            },
                            {
                                "type": "object",
                                "properties": {
                                    "huntingSkill": {
                                        "type": "string",
                                        "description": "The measured skill for hunting",
                                        "default": "lazy",
                                        "enum": [
                                            "clueless",
                                            "lazy",
                                            "adventurous",
                                            "aggressive"
                                        ]
                                    }
                                },
                                "required": [
                                    "huntingSkill"
                                ]
                            }
                        ]
                    },
                    "Dog": {
                        "description": "A representation of a dog. Note that `Dog` will be used as the discriminator value.",
                        "allOf": [
                            {
                                "$ref": "#/components/schemas/Pet"
                            },
                            {
                                "type": "object",
                                "properties": {
                                    "packSize": {
                                        "type": "integer",
                                        "format": "int32",
                                        "description": "the size of the pack the dog is from",
                                        "default": 0,
                                        "minimum": 0
                                    }
                                },
                                "required": [
                                    "packSize"
                                ]
                            }
                        ]
                    },
                    "Shape" : {
                        "type": "object",
                        "discriminator": {
                            "propertyName": "shapeType",
                            "mapping" : {
                                "sqr" : "Square",
                                "rect" : "#/components/schemas/Rectangle"
                            }
                        },
                        "properties": {
                            "name": {
                                "type": "string"
                            },
                            "shapeType": {
                                "type": "string"
                            }
                        },
                        "required": [
                            "name",
                            "shapeType"
                        ]
                    },
                    "Square" : {
                        "allOf": [
                            {
                                "$ref": "#/components/schemas/Shape"
                            },
                            {
                                "type": "object",
                                "properties": {
                                    "side": {
                                        "type": "integer"
                                    }
                                },
                                "required": [ "side" ]
                            }
                        ]
                    },
                    "Rectangle" : {
                        "allOf": [
                            {
                                "$ref": "#/components/schemas/Shape"
                            },
                            {
                                "type": "object",
                                "properties": {
                                    "length": { "type": "integer" },
                                    "width": { "type": "integer" }
                                },
                                "required": [ "length", "width" ]
                            }
                        ]
                    }
                }
            }
        },
        "tests": [
            {
                "description": "param \"integer_nullable\" check int",
                "data": 123,
                "valid": true,
                "pointer": "/paths/~1test/parameters/0/schema"
            },
            {
                "description": "param \"integer_nullable\" check string as int",
                "data": "321",
                "valid": true,
                "pointer": "/paths/~1test/parameters/0/schema"
            },
            {
                "description": "param \"integer_nullable\" check nullable",
                "data": null,
                "valid": true,
                "pointer": "/paths/~1test/parameters/0/schema"
            },
            {
                "description": "param \"integer_nullable\" not array",
                "data": [],
                "valid": false,
                "pointer": "/paths/~1test/parameters/0/schema"
            },
            {
                "description": "param \"integer\" check nullable",
                "data": null,
                "valid": false,
                "pointer": "/paths/~1test/parameters/1/schema"
            },
            {
                "description": "param \"nullable\" check nullable",
                "data": null,
                "valid": true,
                "pointer": "/paths/~1test/parameters/2/schema"
            },
            {
                "description": "param \"nullable2\" check nullable",
                "data": null,
                "valid": true,
                "pointer": "/paths/~1test/parameters/3/schema"
            },
            {
                "description": "param \"items\" check items",
                "data": [4, 5, 6],
                "valid": true,
                "pointer": "/paths/~1test/parameters/4/content/application~1json/schema"
            },
            {
                "description": "param \"items\" check empty array",
                "data": [],
                "valid": true,
                "pointer": "/paths/~1test/parameters/4/content/application~1json/schema"
            },
            {
                "description": "param \"items\" check minimum",
                "data": [1],
                "valid": false,
                "pointer": "/paths/~1test/parameters/4/content/application~1json/schema"
            },
            {
                "description": "param \"readOnly\" check request ok",
                "data": {
                    "name": "ilya",
                    "age": 12
                },
                "valid": true,
                "pointer": "/paths/~1test/parameters/5/content/application~1json/schema",
                "direction": "request"
            },
            {
                "description": "param \"readOnly\" check request failed",
                "data": {
                    "name": "ilya",
                    "age": 12,
                    "id": 13
                },
                "valid": false,
                "pointer": "/paths/~1test/parameters/5/content/application~1json/schema",
                "direction": "request"
            },
            {
                "description": "param \"readOnly\" check response ok",
                "data": {
                    "name": "ilya",
                    "age": 12,
                    "id": 13
                },
                "valid": true,
                "pointer": "/paths/~1test/get/responses/200/content/application~1json/schema/properties/readOnly",
                "direction": "response"
            },
            {
                "description": "param \"readOnly\" check response failed",
                "data": {
                    "name": "ilya",
                    "age": 12
                },
                "valid": false,
                "pointer": "/paths/~1test/get/responses/200/content/application~1json/schema/properties/readOnly",
                "direction": "response"
            },
            {
                "description": "param \"writeOnly\" check request ok",
                "data": {
                    "name": "ilya",
                    "offset": 5
                },
                "valid": true,
                "pointer": "/paths/~1test/parameters/6/content/application~1json/schema",
                "direction": "request"
            },
            {
                "description": "param \"writeOnly\" check request failed",
                "data": {
                    "name": "ilya"
                },
                "valid": false,
                "pointer": "/paths/~1test/parameters/6/content/application~1json/schema",
                "direction": "request"
            },
            {
                "description": "\"writeOnly\" check response ok",
                "data": {
                    "name": "ilya"
                },
                "valid": true,
                "pointer": "/paths/~1test/get/responses/200/content/application~1json/schema/properties/writeOnly",
                "direction": "response"
            },
            {
                "description": "\"writeOnly\" check response failed",
                "data": {
                    "name": "ilya",
                    "offset": 5
                },
                "valid": false,
                "pointer": "/paths/~1test/get/responses/200/content/application~1json/schema/properties/writeOnly",
                "direction": "response"
            },
            {
                "description": "discriminatorOneOf dog ok",
                "data": {
                    "name": "Terminator",
                    "petType": "Dog",
                    "packSize": 123
                },
                "valid": true,
                "pointer": "/paths/~1test/get/responses/200/content/application~1json/schema/properties/discriminatorOneOf"
            },
            {
                "description": "discriminatorOneOf cat ok",
                "data": {
                    "name": "Terminator",
                    "petType": "Cat",
                    "huntingSkill": "adventurous"
                },
                "valid": true,
                "pointer": "/paths/~1test/get/responses/200/content/application~1json/schema/properties/discriminatorOneOf"
            },
            {
                "description": "discriminatorOneOf dog failed",
                "data": {
                    "name": "Terminator",
                    "petType": "Dog",
                    "packSize": "qwe"
                },
                "valid": false,
                "pointer": "/paths/~1test/get/responses/200/content/application~1json/schema/properties/discriminatorOneOf"
            },
            {
                "description": "discriminatorOneOf cat failed",
                "data": {
                    "name": "Terminator",
                    "petType": "Cat",
                    "huntingSkill": "fast"
                },
                "valid": false,
                "pointer": "/paths/~1test/get/responses/200/content/application~1json/schema/properties/discriminatorOneOf"
            },
            {
                "description": "discriminatorInherit square ok",
                "data": {
                    "name": "A",
                    "shapeType": "sqr",
                    "side": 123
                },
                "valid": true,
                "pointer": "/paths/~1test/get/responses/200/content/application~1json/schema/properties/discriminatorInherit"
            },
            {
                "description": "discriminatorInherit rect ok",
                "data": {
                    "name": "B",
                    "shapeType": "rect",
                    "length": 12,
                    "width": 10
                },
                "valid": true,
                "pointer": "/paths/~1test/get/responses/200/content/application~1json/schema/properties/discriminatorInherit"
            },
            {
                "description": "discriminatorInherit square failed",
                "data": {
                    "name": "A",
                    "shapeType": "sqr"
                },
                "valid": false,
                "pointer": "/paths/~1test/get/responses/200/content/application~1json/schema/properties/discriminatorInherit"
            },
            {
                "description": "discriminatorInherit rect failed",
                "data": {
                    "name": "B",
                    "shapeType": "rect",
                    "length": 12
                },
                "valid": false,
                "pointer": "/paths/~1test/get/responses/200/content/application~1json/schema/properties/discriminatorInherit"
            },
            {
                "description": "deprecated valid, checked",
                "data": "deprecated",
                "valid": true,
                "pointer": "/paths/~1test/parameters/7/schema",
                "validate_deprecated": 1
            },
            {
                "description": "deprecated no valid, checked",
                "data": "another deprecated",
                "valid": false,
                "pointer": "/paths/~1test/parameters/7/schema",
                "validate_deprecated": 1
            },
            {
                "description": "deprecated valid, not check invalid value",
                "data": "another deprecated",
                "valid": true,
                "pointer": "/paths/~1test/parameters/7/schema",
                "validate_deprecated": 0
            },
            {
                "description": "empty and deprecated valid, checked invalid value",
                "data": "undescribed deprecated",
                "valid": true,
                "pointer": "/paths/~1test/parameters/8/schema",
                "validate_deprecated": 1
            },
            {
                "description": "empty and deprecated valid, not check invalid value",
                "data": "undescribed deprecated",
                "valid": true,
                "pointer": "/paths/~1test/parameters/8/schema",
                "validate_deprecated": 0
            }
        ]
    }
]
