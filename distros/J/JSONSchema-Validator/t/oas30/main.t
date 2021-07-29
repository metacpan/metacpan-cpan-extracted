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
    my $validator = JSONSchema::Validator::OAS30->new(schema => $test->{schema}, validate_deprecated => 0);
    my $subtests = $test->{tests};
    for my $t (@$subtests) {
        my $test_name = $test_topic . ': ' . $t->{description};

        my $ctype_req = $t->{ctype_req} // 'application/json';
        my ($result, $errors, $warnings) = $validator->validate_request(
            method => $t->{method},
            openapi_path => $t->{openapi_path},
            parameters => {
                path => $t->{path},
                query => $t->{query},
                header => $t->{header_req},
                body => $t->{body_req} ? [1, $ctype_req, $t->{body_req}] : [0, $ctype_req, undef]
            }
        );
        if ($t->{valid_req}) {
            is $result, 1, 'req: ' . $test_name;
            is @$errors, 0, 'req: ' . $test_name . '; errors is empty';
            if ($t->{warnings}) {
                ok @$warnings > 0, 'req: ' . $test_name . '; check warnings';
            } else {
                ok @$warnings == 0, 'req: ' . $test_name . '; check warnings';
            }
        } else {
            is $result, 0, 'req: ' . $test_name;
            ok @$errors > 0, 'req: ' . $test_name . '; errors is not empty';
            if ($t->{warnings}) {
                ok @$warnings > 0, 'req: ' . $test_name . '; check warnings';
            } else {
                ok @$warnings == 0, 'req: ' . $test_name . '; check warnings';
            }
        }

        my $ctype_res = $t->{ctype_res} // 'application/json';
        ($result, $errors) = $validator->validate_response(
            method => $t->{method},
            openapi_path => $t->{openapi_path},
            status => $t->{status},
            parameters => {
                header => $t->{header_res},
                body => $t->{body_res} ? [1, $ctype_res, $t->{body_res}] : [0, $ctype_res, undef]
            }
        );
        if ($t->{valid_res}) {
            is $result, 1, 'res: ' . $test_name;
            is @$errors, 0, 'res: ' . $test_name . '; errors is empty';
        } else {
            is $result, 0, 'res: ' . $test_name;
            ok @$errors > 0, 'res: ' . $test_name . '; errors is not empty';
        }
    }
}

done_testing;

__DATA__
[
    {
        "subject": "req/res",
        "schema": {
            "openapi": "3.0.0",
            "info": { "title": "Nullable", "version": "" },
            "paths": {
                "/company/{company}/pets": {
                    "parameters": [
                        {
                            "name": "company",
                            "in" : "path",
                            "schema" : {
                                "type" : "string",
                                "enum": [ "google", "amazon", "skbkontur" ]
                            },
                            "required": true
                        }
                    ],
                    "post": {
                        "parameters": [
                            {
                                "name": "X-VERSIon",
                                "in" : "header",
                                "schema" : {
                                    "type" : "string",
                                    "enum": [ "7.3Rev2", "7.3Rev3" ]
                                },
                                "required": true
                            },
                            {
                                "name": "params",
                                "in" : "query",
                                "content" : {
                                    "application/json" : {
                                        "schema" : {
                                            "$ref" : "#/components/schemas/params"
                                        }
                                    }
                                },
                                "required": true
                            },
                            {
                                "name": "optional_param",
                                "in" : "query",
                                "schema" : {
                                    "type" : "string",
                                    "enum" : ["optional"]
                                },
                                "required": false
                            },
                            {
                                "name": "deprecated_param",
                                "in" : "query",
                                "schema" : {
                                    "type" : "string",
                                    "enum" : ["deprecated"]
                                },
                                "deprecated": true
                            },
                            {
                                "name": "int_param",
                                "in" : "query",
                                "schema" : {
                                    "$ref" : "#/components/schemas/"
                                }
                            }
                        ],
                        "requestBody": {
                            "content": {
                                "application/json": {
                                    "schema": {
                                        "$ref" : "#/components/schemas/Pet"
                                    }
                                }
                            }
                        },
                        "responses": {
                            "200": {
                                "description" : "Pets list",
                                "content": {
                                    "application/json": {
                                        "schema": {
                                            "type": "object",
                                            "properties": {
                                                "params": {
                                                    "$ref" : "#/components/schemas/params"
                                                },
                                                "pets" : {
                                                    "type" : "array",
                                                    "items" : {
                                                        "$ref" : "#/components/schemas/Pet"
                                                    }
                                                }
                                            }
                                        }
                                    }
                                },
                                "headers" : {
                                    "X-SERVER-sUPPoRTED-vERSIONs" : {
                                        "required" : true,
                                        "content" : {
                                            "application/json" : {
                                                "schema" : {
                                                    "type" : "array",
                                                    "items" : {
                                                        "type" : "integer"
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            },
                            "default": {
                                "description": "unexpected error",
                                    "content": {
                                        "application/json": {
                                            "schema": {
                                                "$ref": "#/components/schemas/Error"
                                            }
                                        }
                                    }
                                }
                            }
                    },
                    "get" : {
                        "deprecated": true,
                        "parameters" : [
                            {
                                "name": "number",
                                "in" : "query",
                                "schema" : {
                                    "type" : "string",
                                    "enum": [ 1 ]
                                }
                            }
                        ],
                        "responses" : {
                            "200" : {
                                "description" : "success"
                            }
                        }
                    }
                }
            },
            "components": {
                "schemas": {
                    "" : {
                        "type" : "integer",
                        "format" : "int32"
                    },
                    "params": {
                        "type" : "object",
                        "properties" : {
                            "theme" : {
                                "type" : "string",
                                "enum" : ["butterfly", "alligator"]
                            },
                            "offset": {
                                "type" : "integer",
                                "writeOnly": true
                            }
                        },
                        "required" : [ "theme", "offset" ]
                    },
                    "Pet": {
                        "type": "object",
                        "discriminator": {
                            "propertyName": "petType"
                        },
                        "properties": {
                            "name": {
                                "type": "string"
                            },
                            "petType": {
                                "type": "string"
                            },
                            "id": {
                                "type": "integer",
                                "readOnly": true
                            },
                            "like" : {
                                "type": "string",
                                "enum": ["fish", "bone", "meat"]
                            }
                        },
                        "required": [ "name", "petType", "id"]
                    },
                    "Cat": {
                        "allOf": [
                            {
                                "$ref": "#/components/schemas/Pet"
                            },
                            {
                                "type": "object",
                                "properties": {
                                    "huntingSkill": {
                                        "type": "string",
                                        "enum": [
                                            "lazy",
                                            "adventurous",
                                            "aggressive"
                                        ]
                                    }
                                },
                                "required": [ "huntingSkill" ]
                            }
                        ]
                    },
                    "Dog": {
                        "allOf": [
                            {
                                "$ref": "#/components/schemas/Pet"
                            },
                            {
                                "type": "object",
                                "properties": {
                                    "packSize": { "type": "integer" }
                                },
                                "required": [ "packSize" ]
                            }
                        ]
                    },
                    "Error": {
                        "type": "object",
                        "required": [
                            "code",
                            "message"
                        ],
                        "properties": {
                            "code": {
                                "type": "integer",
                                "format": "int32"
                            },
                            "message": {
                                "type": "string"
                            }
                        }
                    }
                }
            }
        },
        "tests": [
            {
                "description": "complex test ok",
                "method" : "post",
                "openapi_path" : "/company/{company}/pets",

                "path" : {
                    "company" : "skbkontur"
                },
                "query" : {
                    "params" : "{ \"theme\" : \"butterfly\", \"offset\" : 10 }",
                    "optional_param" : "optional",
                    "int_param" : "123"
                },
                "header_req" : {
                    "X-VERSION" : "7.3Rev2"
                },
                "body_req" : {
                    "petType" : "Dog",
                    "name" : "Ilya",
                    "like" : "bone",
                    "packSize" : "123"
                },
                "ctype_req" : "application/json",

                "status" : "200",
                "body_res" : {
                    "params" : {
                        "theme" : "butterfly"
                    },
                    "pets" : [
                        {
                            "petType" : "Cat",
                            "name" : "Vanya",
                            "like" : "fish",
                            "huntingSkill" : "aggressive",
                            "id" : 10
                        },
                        {
                            "petType" : "Dog",
                            "name" : "Ilya",
                            "like" : "bone",
                            "packSize" : "123",
                            "id" : 11
                        }
                    ]
                },
                "ctype_res" : "application/json",

                "valid_req": true,
                "valid_res": true
            },

            {
                "description": "complex test ok without optional params and wrong deprecated field value which validation skipped",
                "method" : "post",
                "openapi_path" : "/company/{company}/pets",

                "warnings" : true,

                "path" : {
                    "company" : "skbkontur"
                },
                "query" : {
                    "params" : "{ \"theme\" : \"butterfly\", \"offset\" : 10 }",
                    "deprecated_param" : "another value"
                },
                "header_req" : {
                    "X-VERSION" : "7.3Rev2"
                },
                "body_req" : {
                    "petType" : "Dog",
                    "name" : "Ilya",
                    "packSize" : "123"
                },
                "ctype_req" : "application/json",

                "status" : "200",
                "body_res" : {
                    "params" : {
                        "theme" : "butterfly"
                    },
                    "pets" : [
                        {
                            "petType" : "Cat",
                            "name" : "Vanya",
                            "huntingSkill" : "aggressive",
                            "id" : 10
                        },
                        {
                            "petType" : "Dog",
                            "name" : "Ilya",
                            "packSize" : "123",
                            "id" : 11
                        }
                    ]
                },
                "ctype_res" : "application/json",

                "valid_req": true,
                "valid_res": true
            },

            {
                "description": "complex test wrong, required params offset, pet.id",
                "method" : "post",
                "openapi_path" : "/company/{company}/pets",

                "path" : {
                    "company" : "skbkontur"
                },
                "query" : {
                    "params" : "{ \"theme\" : \"butterfly\" }",
                    "optional_param" : "optional"
                },
                "header_req" : {
                    "X-VERSION" : "7.3Rev2"
                },
                "body_req" : {
                    "petType" : "Dog",
                    "name" : "Ilya",
                    "like" : "bone",
                    "packSize" : "123"
                },
                "ctype_req" : "application/json",

                "status" : "200",
                "body_res" : {
                    "params" : {
                        "theme" : "butterfly"
                    },
                    "pets" : [
                        {
                            "petType" : "Cat",
                            "name" : "Vanya",
                            "like" : "fish",
                            "huntingSkill" : "aggressive"
                        },
                        {
                            "petType" : "Dog",
                            "name" : "Ilya",
                            "like" : "bone",
                            "packSize" : "123",
                            "id" : 11
                        }
                    ]
                },
                "ctype_res" : "application/json",

                "valid_req": false,
                "valid_res": false
            },

            {
                "description": "complex test wrong, required params compony, pet.packSize",
                "method" : "post",
                "openapi_path" : "/company/{company}/pets",

                "path" : {
                },
                "query" : {
                    "params" : "{ \"theme\" : \"butterfly\", \"offset\" : 10 }",
                    "optional_param" : "optional"
                },
                "header_req" : {
                    "X-VERSION" : "7.3Rev2"
                },
                "body_req" : {
                    "petType" : "Dog",
                    "name" : "Ilya",
                    "like" : "bone",
                    "packSize" : "123"
                },
                "ctype_req" : "application/json",

                "status" : "200",
                "body_res" : {
                    "params" : {
                        "theme" : "butterfly"
                    },
                    "pets" : [
                        {
                            "petType" : "Cat",
                            "name" : "Vanya",
                            "like" : "fish",
                            "huntingSkill" : "aggressive",
                            "id" : 10
                        },
                        {
                            "petType" : "Dog",
                            "name" : "Ilya",
                            "like" : "bone",
                            "id" : 11
                        }
                    ]
                },
                "ctype_res" : "application/json",

                "valid_req": false,
                "valid_res": false
            },

            {
                "description": "complex test wrong, required X-VERSION, wrong status",
                "method" : "post",
                "openapi_path" : "/company/{company}/pets",

                "path" : {
                    "company" : "skbkontur"
                },
                "query" : {
                    "params" : "{ \"theme\" : \"butterfly\", \"offset\" : 10 }",
                    "optional_param" : "optional"
                },
                "header_req" : {
                },
                "body_req" : {
                    "petType" : "Dog",
                    "name" : "Ilya",
                    "like" : "bone",
                    "packSize" : "123"
                },
                "ctype_req" : "application/json",

                "status" : "201",
                "body_res" : {
                    "params" : {
                        "theme" : "butterfly"
                    },
                    "pets" : [
                        {
                            "petType" : "Cat",
                            "name" : "Vanya",
                            "like" : "fish",
                            "huntingSkill" : "aggressive",
                            "id" : 10
                        },
                        {
                            "petType" : "Dog",
                            "name" : "Ilya",
                            "like" : "bone",
                            "packSize" : "123",
                            "id" : 11
                        }
                    ]
                },
                "ctype_res" : "application/json",

                "valid_req": false,
                "valid_res": false
            },

            {
                "description": "complex test wrong, readOnly and writeOnly params",
                "method" : "post",
                "openapi_path" : "/company/{company}/pets",

                "path" : {
                    "company" : "skbkontur"
                },
                "query" : {
                    "params" : "{ \"theme\" : \"butterfly\", \"offset\" : 10 }",
                    "optional_param" : "optional"
                },
                "header_req" : {
                    "X-VERSION" : "7.3Rev2"
                },
                "body_req" : {
                    "petType" : "Dog",
                    "name" : "Ilya",
                    "like" : "bone",
                    "packSize" : "123",
                    "id" : 11
                },
                "ctype_req" : "application/json",

                "status" : "200",
                "body_res" : {
                    "params" : {
                        "theme" : "butterfly",
                        "offset": 10
                    },
                    "pets" : [
                        {
                            "petType" : "Cat",
                            "name" : "Vanya",
                            "like" : "fish",
                            "huntingSkill" : "aggressive",
                            "id" : 10
                        },
                        {
                            "petType" : "Dog",
                            "name" : "Ilya",
                            "like" : "bone",
                            "packSize" : "123",
                            "id" : 11
                        }
                    ]
                },
                "ctype_res" : "application/json",

                "valid_req": false,
                "valid_res": false
            },

            {
                "description": "complex test ok, match response error",
                "method" : "post",
                "openapi_path" : "/company/{company}/pets",

                "path" : {
                    "company" : "skbkontur"
                },
                "query" : {
                    "params" : "{ \"theme\" : \"butterfly\", \"offset\" : 10 }",
                    "optional_param" : "optional"
                },
                "header_req" : {
                    "X-VERSION" : "7.3Rev2"
                },
                "body_req" : {
                    "petType" : "Dog",
                    "name" : "Ilya",
                    "like" : "bone",
                    "packSize" : "123"
                },
                "ctype_req" : "application/json",

                "status" : "500",
                "body_res" : {
                    "code" : 12345,
                    "message" : "some error occured"
                },
                "ctype_res" : "application/json",

                "valid_req": true,
                "valid_res": true
            },

            {
                "description": "test ok, skip deprecated operation object, so param number is not validated",
                "method" : "get",
                "openapi_path" : "/company/{company}/pets",

                "warnings" : true,

                "path" : {
                },
                "query" : {
                    "number" : "2"
                },
                "header_req" : {
                },
                "body_req" : {
                },
                "ctype_req" : "application/json",

                "status" : "200",
                "body_res" : {
                },
                "ctype_res" : "application/json",

                "valid_req": true,
                "valid_res": true
            },

            {
                "description": "test format, wrong int parameter",
                "method" : "post",
                "openapi_path" : "/company/{company}/pets",

                "path" : {
                    "company" : "skbkontur"
                },
                "query" : {
                    "params" : "{ \"theme\" : \"butterfly\", \"offset\" : 10 }",
                    "optional_param" : "optional",
                    "int_param" : "123.2"
                },
                "header_req" : {
                    "X-VERSION" : "7.3Rev2"
                },
                "body_req" : {
                    "petType" : "Dog",
                    "name" : "Ilya",
                    "like" : "bone",
                    "packSize" : "123"
                },
                "ctype_req" : "application/json",

                "status" : "200",
                "body_res" : {
                    "params" : {
                        "theme" : "butterfly"
                    },
                    "pets" : [
                        {
                            "petType" : "Cat",
                            "name" : "Vanya",
                            "like" : "fish",
                            "huntingSkill" : "aggressive",
                            "id" : 10
                        },
                        {
                            "petType" : "Dog",
                            "name" : "Ilya",
                            "like" : "bone",
                            "packSize" : "123",
                            "id" : 11
                        }
                    ]
                },
                "ctype_res" : "application/json",

                "valid_req": false,
                "valid_res": true
            }
        ]
    }
]
