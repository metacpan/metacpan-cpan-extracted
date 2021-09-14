#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Config;

use lib 't/lib';

use Helper 'detect_warnings';
use JSONSchema::Validator;
use JSONSchema::Validator::Util qw/get_resource/;

BEGIN {
    unless ($ENV{ACCEPTANCE_TESTING}) {
        print qq{1..0 # SKIP these tests are for testing by the developer\n};
        exit
    }
}

unless (eval { require Test::JSON::Schema::Acceptance; 1; }) {
    plan skip_all => 'Test::JSON::Schema::Acceptance is not installed'
}

for my $validator_class (@{$JSONSchema::Validator::JSON_SCHEMA_VALIDATORS}) {
    my $specification = lc($validator_class->SPECIFICATION);
    my $accepter = Test::JSON::Schema::Acceptance->new(specification => $specification);

    my $ua_get = sub {
        my $uri = shift;
        my $path = $accepter->additional_resources;
        $uri =~ s/^http:\/\/localhost:1234/file:\/\/$path/;
        return get_resource({}, $uri);
    };

    $accepter->acceptance(
        validate_data => sub {
            my ($schema, $input_data) = @_;
            my ($result, $errors) = JSONSchema::Validator->new(
                schema => $schema,
                validate_schema => 0,
                specification => $specification,
                scheme_handlers => {'http' => $ua_get}
            )->validate_schema($input_data);
            return $result;
        },
        todo_tests => [
            $Config{nvsize} >= 12
                ? { file => 'multipleOf.json' } # issue https://github.com/json-schema-org/JSON-Schema-Test-Suite/pull/438
                : ()
        ]
    );
}

ok detect_warnings() == 0, 'no warnings';
done_testing;
