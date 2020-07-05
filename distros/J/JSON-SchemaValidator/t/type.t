#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON;
use JSON::SchemaValidator;

subtest 'types' => sub {
    is JSON::SchemaValidator::_type(undef), 'null';
    ok JSON::SchemaValidator::_is_type(undef, 'null');
    ok JSON::SchemaValidator::_is_null(undef);

    is JSON::SchemaValidator::_type(JSON::true), 'boolean';
    ok JSON::SchemaValidator::_is_type(JSON::true, 'boolean');

    is JSON::SchemaValidator::_type(1), 'integer';
    ok JSON::SchemaValidator::_is_type(1, 'integer');
    ok JSON::SchemaValidator::_is_integer(1);

    ok JSON::SchemaValidator::_is_number(1);
    ok JSON::SchemaValidator::_is_type(1, 'number');

    is JSON::SchemaValidator::_type(1.0), 'number';
    ok JSON::SchemaValidator::_is_type(1.0, 'number');
    ok JSON::SchemaValidator::_is_number(1.0);

    ok JSON::SchemaValidator::_is_number(0.0);

    is JSON::SchemaValidator::_type(1.2), 'number';
    ok JSON::SchemaValidator::_is_type(1.2, 'number');

    is JSON::SchemaValidator::_type('hello'), 'string';
    ok JSON::SchemaValidator::_is_type('hello', 'string');

    is JSON::SchemaValidator::_type({foo => 'bar'}), 'object';
    ok JSON::SchemaValidator::_is_type({foo => 'bar'}, 'object');

    is JSON::SchemaValidator::_type([1, 2, 3]), 'array';
    ok JSON::SchemaValidator::_is_type([1, 2, 3], 'array');
};

done_testing;
