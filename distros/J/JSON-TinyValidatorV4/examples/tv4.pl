#!/usr/bin/env perl

use JSON::TinyValidatorV4;
use Data::Dumper 'Dumper';

my $tv4 = JSON::TinyValidatorV4->new;

my $data   = get_data();
my $schema = get_schema();

print Dumper( $tv4->validate( $data, $schema, 1, 1 ) );

print Dumper( $tv4->validateResult( $data, $schema, 0, 1 ) );

exit;

sub get_data {
    [
        {
            'price'      => 12.5,
            'dimensions' => {
                'width'  => 12,
                'elevation' => 9.5,
                'length' => 7
            },
            'tags' => [
                'cold',
                'ice'
            ],
            'id'                => 2,
            'name'              => 'An ice sculpture',
            'warehouseLocation' => {
                'longitude' => -128.323746,
                'latitude'  => -24.375870
              }
        },
        {
            'warehouseLocation' => {
                'longitude' => -32.7,
                'latitude'  => 54.4
            },
            'name'       => 'A blue mouse',
            'id'         => 3,
            'price'      => 25.5,
            'dimensions' => {
                'length' => 3.1,
                'elevation' => 1,
                'width'  => 1
              }
        }
    ]
}

sub get_schema {
    {
        'items' => {
            'required' => [
                'id',
                'name',
                'price'
            ],
            'properties' => {
                'price' => {
                    'minimum'          => 0,
                    'type'             => 'number',
                    'exclusiveMinimum' => 1
                },
                'dimensions' => {
                    'type'     => 'object',
                    'required' => [
                        'length',
                        'width',
                        'elevation'
                    ],
                    'properties' => {
                        'elevation' => {
                            'type' => 'number'
                        },
                        'length' => {
                            'type' => 'number'
                        },
                        'width' => {
                            'type' => 'number'
                          }
                      }
                },
                'tags' => {
                    'items' => {
                        'type' => 'string'
                    },
                    'uniqueItems' => 1,
                    'type'        => 'array',
                    'minItems'    => 1
                },
                'name' => {
                    'type' => 'string'
                },
                'id' => {
                    'description' => 'The unique identifier for a product',
                    'type'        => 'number'
                },
                'warehouseLocation' => {
                    'description' => 'Coordinates of the warehouse with the product',
                    'type'        => 'object',
                    'properties'  => {
                        'latitude'  => { 'type' => 'number' },
                        'longitude' => { 'type' => 'number' }
                      }
                  }
            },
            'type'  => 'object',
            'title' => 'Product'
        },
        'type'    => 'array',
        'title'   => 'Product set',
        '$schema' => 'http://json-schema.org/draft-04/schema#'
    }
}
