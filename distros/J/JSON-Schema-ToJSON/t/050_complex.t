#!perl

use strict;
use warnings;

use JSON::Schema::ToJSON;
use JSON::Validator;
use Cpanel::JSON::XS;
use Test::Most;

plan skip_all => '$ref resolution currently broken';

my $ToJSON = JSON::Schema::ToJSON->new;

isa_ok( $ToJSON,'JSON::Schema::ToJSON' );

my $schema = decode_json( do { local $/ = undef; <DATA> } );

my $json = $ToJSON->json_schema_to_json(
	schema => {
		# as the "schema" below is an OpenAPI spec we need to set something
		# at the top level to force some JSON to be created as there is no
		# type key at the top level of an OpenAPI spec - this is purely for
		# testing purposes (and to check refs resolve)
		type => 'object',
		properties => {
			"items" => {
				"items" => {
					'$ref' => "#/definitions/Property"
				},
				"description" => "List of Property objects",
				"type" => "array"
			}
		},
		%{ $schema },
	},
);

my $validator = JSON::Validator->new;
 
$validator->schema( $schema );
my @errors = $validator->validate( $json );

ok( ! @errors,'round trip' );

done_testing();

# vim:noet:sw=4:ts=4

__DATA__
{
   "basePath" : "/api/v1.0",
   "paths" : {
      "/test/protected" : {
         "get" : {
            "responses" : {
               "200" : {
                  "schema" : {
                     "properties" : {
                        "scopes" : {
                           "description" : "List of scopes",
                           "type" : "array"
                        }
                     },
                     "type" : "object"
                  },
                  "description" : "A list of scopes"
               },
               "403" : {
                  "schema" : {
                     "type" : "object",
                     "$ref" : "#/definitions/Error"
                  },
                  "description" : "Invalid privileges error"
               }
            },
            "operationId" : "test_protected",
            "tags" : [
               "Tests"
            ],
            "description" : "Returns a list of API scopes\n",
            "summary" : "test the API"
         }
      },
      "/properties" : {
         "get" : {
            "operationId" : "get_all_properties",
            "responses" : {
               "501" : {
                  "schema" : {
                     "type" : "object",
                     "$ref" : "#/definitions/Error"
                  },
                  "description" : "Not implemented error"
               },
               "404" : {
                  "schema" : {
                     "$ref" : "#/definitions/Error",
                     "type" : "object"
                  },
                  "description" : "Not found error"
               },
               "403" : {
                  "schema" : {
                     "$ref" : "#/definitions/Error",
                     "type" : "object"
                  },
                  "description" : "Invalid privileges error"
               },
               "200" : {
                  "description" : "A list of property objects",
                  "schema" : {
                     "type" : "object",
                     "properties" : {
                        "items" : {
                           "items" : {
                              "$ref" : "#/definitions/Property"
                           },
                           "description" : "List of Property objects",
                           "type" : "array"
                        }
                     }
                  }
               }
            },
            "parameters" : [
               {
                  "required" : "",
                  "name" : "country_code",
                  "type" : "string",
                  "in" : "query",
                  "description" : "Search for properties by country code"
               },
               {
                  "in" : "query",
                  "type" : "string",
                  "description" : "Search for properties by first line",
                  "name" : "first_line",
                  "required" : ""
               },
               {
                  "name" : "state",
                  "required" : "",
                  "in" : "query",
                  "type" : "string",
                  "description" : "Search for properties by state"
               },
               {
                  "description" : "Search for properties by city",
                  "type" : "string",
                  "in" : "query",
                  "required" : "",
                  "name" : "city"
               },
               {
                  "in" : "query",
                  "type" : "string",
                  "description" : "Search for properties by zip code",
                  "name" : "zip_code",
                  "required" : ""
               },
               {
                  "name" : "extended",
                  "required" : "",
                  "description" : "Return extended information for properties, including balance and previous tenant information",
                  "in" : "query",
                  "type" : "boolean"
               },
               {
                  "in" : "query",
                  "type" : "integer",
                  "description" : "Restrict rows returned",
                  "name" : "rows",
                  "required" : ""
               },
               {
                  "required" : "",
                  "name" : "page",
                  "type" : "integer",
                  "in" : "query",
                  "description" : "Return given page number"
               },
               {
                  "description" : "Make any search parameters fuzzy",
                  "in" : "query",
                  "type" : "boolean",
                  "name" : "like",
                  "required" : ""
               }
            ],
            "tags" : [
               "Property"
            ],
            "summary" : "get all propery details"
         }
      },
      "/payments/{external_id}" : {
         "get" : {
            "summary" : "get payment details",
            "tags" : [
               "Payments"
            ],
            "description" : "Returns the payment linked to the passed external_id\n",
            "responses" : {
               "501" : {
                  "description" : "Not implemented error",
                  "schema" : {
                     "type" : "object",
                     "$ref" : "#/definitions/Error"
                  }
               },
               "404" : {
                  "description" : "Not found error",
                  "schema" : {
                     "type" : "object",
                     "$ref" : "#/definitions/Error"
                  }
               },
               "403" : {
                  "description" : "Invalid privileges error",
                  "schema" : {
                     "$ref" : "#/definitions/Error",
                     "type" : "object"
                  }
               },
               "200" : {
                  "schema" : {
                     "type" : "object",
                     "properties" : {
                        "items" : {
                           "items" : {
                              "$ref" : "#/definitions/Payment"
                           },
                           "description" : "List of Payment objects",
                           "type" : "array"
                        }
                     }
                  },
                  "description" : "A list of payment objects"
               }
            },
            "operationId" : "get_payments",
            "parameters" : [
               {
                  "type" : "string",
                  "in" : "path",
                  "description" : "External ID of payment",
                  "required" : 1,
                  "name" : "external_id"
               }
            ]
         }
      },
      "/me/portfolio" : {
         "get" : {
            "summary" : "get user portfolio",
            "description" : "Details of the user's portfolio, specifically income, expenses, arrears, and so on. Note that by default the data will correspond to the current month, query params will need to be used to get details for earlier dates\n",
            "tags" : [
               "User"
            ],
            "operationId" : "portfolio",
            "responses" : {
               "403" : {
                  "description" : "Invalid privileges error",
                  "schema" : {
                     "type" : "object",
                     "$ref" : "#/definitions/Error"
                  }
               },
               "200" : {
                  "schema" : {
                     "type" : "object",
                     "$ref" : "#/definitions/Portfolio"
                  },
                  "description" : "Portfolio information for a user"
               },
               "501" : {
                  "description" : "Not implemented error",
                  "schema" : {
                     "type" : "object",
                     "$ref" : "#/definitions/Error"
                  }
               },
               "404" : {
                  "schema" : {
                     "$ref" : "#/definitions/Error",
                     "type" : "object"
                  },
                  "description" : "Not found error"
               }
            },
            "parameters" : [
               {
                  "name" : "from_date",
                  "required" : "",
                  "pattern" : "\\d{4}-\\d{2}-\\d{2}",
                  "in" : "query",
                  "type" : "string",
                  "description" : "Show portfolio from given date (e.g. 2016-01-01)"
               },
               {
                  "in" : "query",
                  "type" : "string",
                  "description" : "Show portfolio to given date (e.g. 2016-01-31)",
                  "name" : "to_date",
                  "required" : "",
                  "pattern" : "\\d{4}-\\d{2}-\\d{2}"
               }
            ]
         }
      },
      "/agencies/{external_id}" : {
         "get" : {
            "description" : "Returns the agency linked to the passed external_id\n",
            "tags" : [
               "Agency"
            ],
            "operationId" : "get_agencies",
            "responses" : {
               "501" : {
                  "description" : "Not implemented error",
                  "schema" : {
                     "type" : "object",
                     "$ref" : "#/definitions/Error"
                  }
               },
               "404" : {
                  "description" : "Not found error",
                  "schema" : {
                     "type" : "object",
                     "$ref" : "#/definitions/Error"
                  }
               },
               "403" : {
                  "description" : "Invalid privileges error",
                  "schema" : {
                     "$ref" : "#/definitions/Error",
                     "type" : "object"
                  }
               },
               "200" : {
                  "schema" : {
                     "properties" : {
                        "items" : {
                           "type" : "array",
                           "description" : "List of Agency objects",
                           "items" : {
                              "$ref" : "#/definitions/Agency"
                           }
                        }
                     },
                     "type" : "object"
                  },
                  "description" : "A list of agency objects"
               }
            },
            "parameters" : [
               {
                  "type" : "string",
                  "in" : "path",
                  "description" : "External ID of agency",
                  "required" : 1,
                  "name" : "external_id"
               }
            ],
            "summary" : "get agency details"
         }
      },
      "/properties/{external_id}" : {
         "get" : {
            "summary" : "get property details",
            "parameters" : [
               {
                  "description" : "External ID of property",
                  "type" : "string",
                  "in" : "path",
                  "required" : 1,
                  "name" : "external_id"
               },
               {
                  "required" : "",
                  "name" : "extended",
                  "description" : "Return extended information for property, including balance and previous tenant information",
                  "type" : "boolean",
                  "in" : "query"
               }
            ],
            "responses" : {
               "404" : {
                  "schema" : {
                     "type" : "object",
                     "$ref" : "#/definitions/Error"
                  },
                  "description" : "Not found error"
               },
               "501" : {
                  "description" : "Not implemented error",
                  "schema" : {
                     "type" : "object",
                     "$ref" : "#/definitions/Error"
                  }
               },
               "200" : {
                  "schema" : {
                     "type" : "object",
                     "properties" : {
                        "items" : {
                           "items" : {
                              "$ref" : "#/definitions/Property"
                           },
                           "type" : "array",
                           "description" : "List of Property objects"
                        }
                     }
                  },
                  "description" : "A list of property objects"
               },
               "403" : {
                  "description" : "Invalid privileges error",
                  "schema" : {
                     "$ref" : "#/definitions/Error",
                     "type" : "object"
                  }
               }
            },
            "operationId" : "get_properties",
            "description" : "Returns the property linked to the passed external_id\n",
            "tags" : [
               "Property"
            ]
         }
      },
      "/test" : {
         "get" : {
            "summary" : "test the API",
            "responses" : {
               "200" : {
                  "description" : "A list of scopes",
                  "schema" : {
                     "properties" : {
                        "scopes" : {
                           "type" : "array",
                           "description" : "List of scopes"
                        }
                     },
                     "type" : "object"
                  }
               },
               "403" : {
                  "schema" : {
                     "type" : "object",
                     "$ref" : "#/definitions/Error"
                  },
                  "description" : "Invalid privileges error"
               }
            },
            "operationId" : "test",
            "description" : "Returns a list of API scopes\n",
            "tags" : [
               "Tests"
            ]
         }
      },
      "/agencies" : {
         "get" : {
            "summary" : "get all agency details",
            "parameters" : [
               {
                  "type" : "string",
                  "in" : "query",
                  "description" : "Search for agencies by username",
                  "required" : "",
                  "name" : "username"
               },
               {
                  "required" : "",
                  "name" : "category",
                  "type" : "string",
                  "in" : "query",
                  "description" : "Search for agencies by category"
               },
               {
                  "in" : "query",
                  "type" : "string",
                  "description" : "Search for agencies by subdomain",
                  "name" : "subdomain",
                  "required" : ""
               },
               {
                  "description" : "Search for agencies by currency",
                  "in" : "query",
                  "type" : "string",
                  "name" : "currency",
                  "required" : ""
               },
               {
                  "required" : "",
                  "name" : "country_code",
                  "type" : "string",
                  "in" : "query",
                  "description" : "Search for agencies by country code"
               },
               {
                  "name" : "first_line",
                  "required" : "",
                  "in" : "query",
                  "type" : "string",
                  "description" : "Search for agencies by first line"
               },
               {
                  "in" : "query",
                  "type" : "string",
                  "description" : "Search for agencies by state",
                  "name" : "state",
                  "required" : ""
               },
               {
                  "required" : "",
                  "name" : "city",
                  "type" : "string",
                  "in" : "query",
                  "description" : "Search for agencies by city"
               },
               {
                  "description" : "Search for agencies by zip code",
                  "type" : "string",
                  "in" : "query",
                  "required" : "",
                  "name" : "zip_code"
               },
               {
                  "name" : "rows",
                  "required" : "",
                  "description" : "Restrict rows returned",
                  "in" : "query",
                  "type" : "integer"
               },
               {
                  "required" : "",
                  "name" : "page",
                  "type" : "integer",
                  "in" : "query",
                  "description" : "Return given page number"
               },
               {
                  "required" : "",
                  "name" : "like",
                  "type" : "boolean",
                  "in" : "query",
                  "description" : "Make any search parameters fuzzy"
               }
            ],
            "responses" : {
               "404" : {
                  "description" : "Not found error",
                  "schema" : {
                     "type" : "object",
                     "$ref" : "#/definitions/Error"
                  }
               },
               "501" : {
                  "description" : "Not implemented error",
                  "schema" : {
                     "type" : "object",
                     "$ref" : "#/definitions/Error"
                  }
               },
               "200" : {
                  "description" : "A list of agency objects",
                  "schema" : {
                     "properties" : {
                        "items" : {
                           "items" : {
                              "$ref" : "#/definitions/Agency"
                           },
                           "type" : "array",
                           "description" : "List of Agency objects"
                        }
                     },
                     "type" : "object"
                  }
               },
               "403" : {
                  "schema" : {
                     "$ref" : "#/definitions/Error",
                     "type" : "object"
                  },
                  "description" : "Invalid privileges error"
               }
            },
            "operationId" : "get_all_agencies",
            "tags" : [
               "Agency"
            ]
         }
      },
      "/payments" : {
         "get" : {
            "tags" : [
               "Payment"
            ],
            "operationId" : "get_all_payments",
            "responses" : {
               "403" : {
                  "description" : "Invalid privileges error",
                  "schema" : {
                     "type" : "object",
                     "$ref" : "#/definitions/Error"
                  }
               },
               "200" : {
                  "schema" : {
                     "properties" : {
                        "items" : {
                           "description" : "List of Payment objects",
                           "type" : "array",
                           "items" : {
                              "$ref" : "#/definitions/Payment"
                           }
                        }
                     },
                     "type" : "object"
                  },
                  "description" : "A list of payment objects"
               },
               "501" : {
                  "schema" : {
                     "$ref" : "#/definitions/Error",
                     "type" : "object"
                  },
                  "description" : "Not implemented error"
               },
               "404" : {
                  "schema" : {
                     "type" : "object",
                     "$ref" : "#/definitions/Error"
                  },
                  "description" : "Not found error"
               }
            },
            "parameters" : [
               {
                  "type" : "string",
                  "in" : "query",
                  "description" : "Search for payments by country code",
                  "required" : "",
                  "name" : "country_code"
               },
               {
                  "required" : "",
                  "name" : "first_line",
                  "description" : "Search for payments by first line",
                  "type" : "string",
                  "in" : "query"
               },
               {
                  "description" : "Search for payments by state",
                  "in" : "query",
                  "type" : "string",
                  "name" : "state",
                  "required" : ""
               },
               {
                  "name" : "city",
                  "required" : "",
                  "in" : "query",
                  "type" : "string",
                  "description" : "Search for payments by city"
               },
               {
                  "in" : "query",
                  "type" : "string",
                  "description" : "Search for payments by zip code",
                  "name" : "zip_code",
                  "required" : ""
               },
               {
                  "required" : "",
                  "name" : "rows",
                  "type" : "integer",
                  "in" : "query",
                  "description" : "Restrict rows returned"
               },
               {
                  "name" : "page",
                  "required" : "",
                  "description" : "Return given page number",
                  "in" : "query",
                  "type" : "integer"
               },
               {
                  "required" : "",
                  "name" : "like",
                  "description" : "Make any search parameters fuzzy",
                  "type" : "boolean",
                  "in" : "query"
               }
            ],
            "summary" : "get all payment details"
         }
      },
      "/me" : {
         "get" : {
            "tags" : [
               "User"
            ],
            "description" : "The response data will depend on the user type. When the user is linked to an agency the response will contain the details of that agency, when linked to an owner the details of that owner, and so on\n",
            "responses" : {
               "501" : {
                  "description" : "Not implemented error",
                  "schema" : {
                     "$ref" : "#/definitions/Error",
                     "type" : "object"
                  }
               },
               "404" : {
                  "description" : "Not found error",
                  "schema" : {
                     "$ref" : "#/definitions/Error",
                     "type" : "object"
                  }
               },
               "403" : {
                  "schema" : {
                     "type" : "object",
                     "$ref" : "#/definitions/Error"
                  },
                  "description" : "Invalid privileges error"
               },
               "200" : {
                  "schema" : {
                     "$ref" : "#/definitions/Profile",
                     "type" : "object"
                  },
                  "description" : "Profile information for a user"
               }
            },
            "operationId" : "from_token",
            "summary" : "get user details"
         }
      }
   },
   "produces" : [
      "application/json"
   ],
   "host" : "za.payprop.com",
   "swagger" : "2.0",
   "definitions" : {
      "Payment" : {
         "type" : "object",
         "properties" : {
            "id" : {
               "type" : "string",
               "description" : "ID of the payment.",
               "x-example" : "E9fKQxAH8k"
            },
            "agent" : {
               "type" : "object",
               "$ref" : "#/definitions/User"
            },
            "name" : {
               "type" : [
                  "string",
                  null
               ],
               "x-example" : "April Payment",
               "description" : "Name of the payment."
            },
            "start_date" : {
               "type" : "string",
               "description" : "The start date of the payment.",
               "x-example" : "2000-04-01T00:00:00",
               "format" : "date-time"
            },
            "end_date" : {
               "type" : "string",
               "x-example" : "2000-05-01T00:00:00",
               "description" : "The end date of the payment.",
               "format" : "date-time"
            },
            "description" : {
               "x-example" : "Lease payment for April.",
               "description" : "Description of the payment.",
               "type" : "string"
            },
            "agency" : {
               "type" : "object",
               "$ref" : "#/definitions/Agency"
            },
            "address" : {
               "type" : "object",
               "$ref" : "#/definitions/Address"
            },
            "modify_date" : {
               "type" : "string",
               "description" : "The date the payment was last modified.",
               "x-example" : "2000-04-01T00:00:00",
               "format" : "date-time"
            },
            "currency" : {
               "x-example" : "CHF",
               "type" : "string"
            },
            "create_date" : {
               "format" : "date-time",
               "x-example" : "2000-04-01T00:00:00",
               "description" : "The date the payment was created.",
               "type" : "string"
            }
         }
      },
      "PropertyPortfolio" : {
         "properties" : {
            "arrears" : {
               "x-example" : 1000.01,
               "type" : "number",
               "format" : "float"
            },
            "income" : {
               "format" : "float",
               "x-example" : 1000.01,
               "type" : "number"
            },
            "property_address" : {
               "$ref" : "#/definitions/Address",
               "type" : "object"
            },
            "property_name" : {
               "x-example" : "Magnolia Rd 4",
               "type" : "string"
            },
            "expenses" : {
               "type" : "number",
               "x-example" : 1000.01,
               "format" : "float"
            }
         },
         "type" : "object"
      },
      "Tenant" : {
         "type" : "object",
         "properties" : {
            "display_name" : {
               "type" : "string",
               "x-example" : "John Smith",
               "description" : "Full name of the tenant."
            },
            "last_name" : {
               "type" : "string",
               "x-example" : "Smith",
               "description" : "Last name of the tenant."
            },
            "id" : {
               "type" : "string",
               "x-example" : "D8eJPwZG7j",
               "description" : "ID of the tenant."
            },
            "email" : {
               "x-example" : "foo@bar.com",
               "description" : "Email address of the tenant.",
               "type" : "string"
            },
            "first_name" : {
               "description" : "First name of the tenant.",
               "x-example" : "John",
               "type" : "string"
            }
         }
      },
      "Agency" : {
         "properties" : {
            "address" : {
               "properties" : {
                  "billing" : {
                     "$ref" : "#/definitions/Address",
                     "type" : "object"
                  },
                  "statement" : {
                     "$ref" : "#/definitions/Address",
                     "type" : "object"
                  }
               },
               "type" : "object"
            },
            "company_name" : {
               "type" : "string",
               "x-example" : "Prop Corp"
            },
            "currency" : {
               "x-example" : "CHF",
               "type" : "string"
            },
            "user" : {
               "properties" : {
                  "last_name" : {
                     "type" : "string",
                     "x-example" : "Smit"
                  },
                  "cell_phone" : {
                     "type" : "string",
                     "x-example" : "020 1234 5678"
                  },
                  "email" : {
                     "x-example" : "foo@gmail.com",
                     "type" : "string"
                  },
                  "first_name" : {
                     "x-example" : "John",
                     "type" : "string"
                  }
               },
               "type" : "object"
            },
            "country_code" : {
               "x-example" : "CH",
               "type" : "string"
            },
            "name" : {
               "x-example" : "Prop Corp",
               "type" : "string"
            },
            "web_address" : {
               "type" : [
                  "string",
                  null
               ]
            },
            "category" : {
               "type" : "string",
               "x-example" : "Residential"
            },
            "id" : {
               "type" : "string",
               "x-example" : "D8eJPwZG7j"
            }
         },
         "type" : "object"
      },
      "Error" : {
         "properties" : {
            "error" : {
               "type" : "string"
            }
         },
         "type" : "object"
      },
      "Portfolio" : {
         "type" : "object",
         "properties" : {
            "items" : {
               "description" : "List of PropertyPortfolio objects",
               "type" : "array",
               "items" : {
                  "$ref" : "#/definitions/PropertyPortfolio"
               }
            },
            "to_date" : {
               "type" : "string",
               "x-example" : "2000-01-01T00:00:01",
               "format" : "date-time"
            },
            "arrears" : {
               "format" : "float",
               "type" : "number",
               "x-example" : 1000.01
            },
            "currency" : {
               "x-example" : "CHF",
               "type" : "string"
            },
            "income" : {
               "format" : "float",
               "x-example" : 1000.01,
               "type" : "number"
            },
            "from_date" : {
               "format" : "date-time",
               "type" : "string",
               "x-example" : "2000-01-01T00:00:01"
            },
            "expenses" : {
               "x-example" : 1000.01,
               "type" : "number",
               "format" : "float"
            }
         }
      },
      "Property" : {
         "type" : "object",
         "properties" : {
            "end_date" : {
               "x-example" : "2000-01-01T00:00:00",
               "description" : "The end date of the property.",
               "type" : [
                  "string",
                  null
               ],
               "format" : "date-time"
            },
            "description" : {
               "type" : "string",
               "description" : "Description of the property.",
               "x-example" : "Some old castle on a hill"
            },
            "address" : {
               "$ref" : "#/definitions/Address",
               "type" : "object"
            },
            "agency" : {
               "$ref" : "#/definitions/Agency",
               "type" : "object"
            },
            "create_date" : {
               "description" : "The date the property was created.",
               "x-example" : "2000-01-01T00:00:00",
               "type" : "string",
               "format" : "date-time"
            },
            "modify_date" : {
               "format" : "date-time",
               "x-example" : "2000-01-01T00:00:00",
               "description" : "The date the property was last modified.",
               "type" : "string"
            },
            "previous_tenants" : {
               "type" : "array",
               "items" : {
                  "$ref" : "#/definitions/Tenant"
               }
            },
            "name" : {
               "x-example" : "Castle Hill",
               "description" : "Name of the property.",
               "type" : "string"
            },
            "tenant_balance" : {
               "format" : "float",
               "x-example" : 1000.01,
               "type" : "number"
            },
            "currency" : {
               "type" : "string",
               "x-example" : "CHF"
            },
            "damage_deposit_balance" : {
               "format" : "float",
               "x-example" : 1000.01,
               "type" : "number"
            },
            "tenant" : {
               "$ref" : "#/definitions/Tenant",
               "type" : "object"
            },
            "id" : {
               "type" : "string",
               "description" : "ID of the property.",
               "x-example" : "D8eJPwZG7j"
            },
            "account_balance" : {
               "format" : "float",
               "type" : "number",
               "x-example" : 1000.01
            },
            "agent" : {
               "type" : "object",
               "$ref" : "#/definitions/User"
            },
            "start_date" : {
               "type" : [
                  "string",
                  null
               ],
               "description" : "The start date of the property.",
               "x-example" : "2000-01-01T00:00:00",
               "format" : "date-time"
            }
         }
      },
      "Address" : {
         "type" : "object",
         "properties" : {
            "country_code" : {
               "x-example" : "CH",
               "type" : [
                  "string",
                  null
               ]
            },
            "city" : {
               "type" : [
                  "string",
                  null
               ],
               "x-example" : "Villars-sur-Ollon"
            },
            "longitude" : {
               "x-example" : 18.4195876121522,
               "type" : [
                  "number",
                  null
               ],
               "format" : "float"
            },
            "state" : {
               "x-example" : "Vaud",
               "type" : [
                  "string",
                  null
               ]
            },
            "modified" : {
               "x-example" : "2000-01-01T00:00:01",
               "type" : "string",
               "format" : "date-time"
            },
            "id" : {
               "type" : "string",
               "x-example" : "D8eJPwZG7j"
            },
            "fax" : {
               "x-example" : "020 1234 5678",
               "type" : [
                  "string",
                  null
               ]
            },
            "zip_code" : {
               "type" : [
                  "string",
                  null
               ],
               "x-example" : "1884"
            },
            "second_line" : {
               "type" : [
                  "string",
                  null
               ]
            },
            "created" : {
               "type" : "string",
               "x-example" : "2000-01-01T00:00:00",
               "format" : "date-time"
            },
            "phone" : {
               "x-example" : "020 1234 5678",
               "type" : [
                  "string",
                  null
               ]
            },
            "first_line" : {
               "type" : [
                  "string",
                  null
               ],
               "x-example" : "Av. Centrale"
            },
            "third_line" : {
               "type" : [
                  "string",
                  null
               ]
            },
            "latitude" : {
               "format" : "float",
               "x-example" : "-33.93515325806508",
               "type" : [
                  "number",
                  null
               ]
            },
            "email" : {
               "x-example" : "foo@gmail.com",
               "type" : [
                  "string",
                  null
               ]
            }
         }
      },
      "Profile" : {
         "required" : [
            "user",
            "scopes"
         ],
         "properties" : {
            "agency" : {
               "properties" : {
                  "id" : {
                     "type" : "string",
                     "x-example" : "D8eJPwZG7j"
                  },
                  "name" : {
                     "x-example" : "Prop Corp",
                     "type" : "string"
                  }
               },
               "type" : "object"
            },
            "scopes" : {
               "type" : "array",
               "items" : {
                  "type" : "string"
               }
            },
            "user" : {
               "type" : "object",
               "$ref" : "#/definitions/User"
            }
         },
         "type" : "object"
      },
      "User" : {
         "type" : "object",
         "properties" : {
            "id" : {
               "description" : "ID of the PayProp user.",
               "x-example" : "D8eJPwZG7j",
               "type" : "string"
            },
            "full_name" : {
               "type" : "string",
               "description" : "Full name of the PayProp user.",
               "x-example" : "John Smith"
            },
            "type" : {
               "description" : "The type of the PayProp user.",
               "x-example" : "agent",
               "type" : "string"
            },
            "email" : {
               "type" : "string",
               "x-example" : "foo@bar.com",
               "description" : "Email address of the PayProp user."
            },
            "is_admin" : {
               "x-example" : 1,
               "description" : "If the user is an admin for their type.",
               "type" : "boolean"
            }
         }
      }
   },
   "consumes" : [
      "application/json"
   ],
   "info" : {
      "title" : "PayProp API Version 1.0",
      "description" : "OpenAPI config for PayProp API version 1.0",
      "version" : "1.0"
   },
   "schemes" : [
      "https"
   ]
}
