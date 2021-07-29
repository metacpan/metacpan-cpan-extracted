#!/usr/bin/env perl

use strict;
use warnings;
use JSONSchema::Validator::Draft4;
use JSONSchema::Validator::Util qw/json_decode data_section/;

use Test::More;

my $data = data_section('main');

my $tests = json_decode($data);

for my $test (@$tests) {
    my $test_topic = $test->{subject};
    my $validator = JSONSchema::Validator::Draft4->new(schema => $test->{schema});
    my $subtests = $test->{tests};
    for my $t (@$subtests) {
        my $test_name = $test_topic . ': ' . $t->{description};
        my ($result, $errors) = $validator->validate_schema($t->{data});
        if ($t->{valid}) {
            is $result, 1, $test_name;
            is @$errors, 0, $test_name . '; errors is empty';
        } else {
            is $result, 0, $test_name;
            ok @$errors > 0, $test_name . '; errors is not empty';
        }
    }
}

done_testing;

__DATA__
[
    {
        "subject": "recursive",
        "schema": {
            "$schema": "http://json-schema.org/draft-04/schema#",
            "definitions":  {
                "person": {
                    "type": "object",
                    "properties": {
                        "name": { "type": "string" },
                        "age": { "type": "integer" },
                        "children": {
                            "type": "array",
                            "items": { "$ref": "#/definitions/person" },
                            "default": []
                        }
                    }
                }
            },
            "type": "object",
            "properties": {
                "person": { "$ref": "#/definitions/person" }
            }
        },
        "tests": [
            {
                "description": "ok",
                "data": {
                    "person": {
                        "name": "Elizabeth",
                        "children": [
                            {
                                "name": "Charles",
                                "children": [
                                    {
                                        "name": "William",
                                        "children": [
                                            { "name": "George" },
                                            { "name": "Charlotte", "age": 12 }
                                        ]
                                    },
                                    {
                                        "name": "Harry"
                                    }
                                ]
                            }
                        ]
                    }
                },
                "valid": true
            },
            {
                "description": "fail, \"age\" type is string",
                "data": {
                    "person": {
                        "name": "Elizabeth",
                        "children": [
                            {
                                "name": "Charles",
                                "children": [
                                    {
                                        "name": "William",
                                        "children": [
                                            { "name": "George" },
                                            { "name": "Charlotte", "age": "12" }
                                        ]
                                    },
                                    {
                                        "name": "Harry"
                                    }
                                ]
                            }
                        ]
                    }
                },
                "valid": false
            }
        ]
    },

    {
        "subject": "complex allOf",
        "schema": {
            "$schema": "http://json-schema.org/draft-04/schema#",
            "definitions": {
                "address": {
                    "type": "object",
                    "properties": {
                        "street_address": { "type": "string" },
                        "city":           { "type": "string" },
                        "state":          { "type": "string" }
                    },
                    "required": ["street_address", "city", "state"]
                }
            },
            "type": "object",
            "properties": {
                "billing_address": { "$ref": "#/definitions/address" },
                "shipping_address": {
                    "allOf": [
                        { "$ref": "#/definitions/address" },
                        {
                            "properties": {
                                "type": {
                                    "enum": [ "residential", "business" ]
                                }
                            },
                            "required": ["type"]
                        }
                    ]
                }
            }
        },
        "tests": [
            {
                "description": "fail, \"type\" missing",
                "data": {
                    "shipping_address": {
                        "street_address": "1600 Pennsylvania Avenue NW",
                        "city": "Washington",
                        "state": "DC"
                    }
                },
                "valid": false
            },
            {
                "description": "ok",
                "data": {
                    "shipping_address": {
                        "street_address": "1600 Pennsylvania Avenue NW",
                        "city": "Washington",
                        "state": "DC",
                        "type": "business"
                    }
                },
                "valid": true
            }
        ]
    },

    {
        "subject": "complex ref",
        "schema": {
            "id": "http://localhost:1234/scope_change_defs2.json",
            "type" : "object",
            "properties": {
                "list": {"$ref": "#/definitions/baz/definitions/bar"},
                "empty_key" : {"$ref" : "#/"}
            },
            "definitions": {
                "baz": {
                    "id": "baseUriChangeFolderInSubschema/",
                    "definitions": {
                        "bar": {
                            "type": "array",
                            "items": {"$ref": "folderInteger.json"}
                        },
                        "baz": {
                            "id": "folderInteger.json",
                            "type": "integer"
                        }
                    }
                }
            },
            "" : {
                "type" : "integer"
            }
        },
        "tests": [
            {
                "description": "ok",
                "data": {"list": [1]},
                "valid": true
            },
            {
                "description": "fail, type mismatch",
                "data": {"list": ["asd"]},
                "valid": false
            },
            {
                "description": "check empty key type",
                "data": {"empty_key": 1},
                "valid": true
            },
            {
                "description": "failed to check empty key type",
                "data": {"empty_key": [1]},
                "valid": false
            }
        ]
    }
]
