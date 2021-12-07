#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use lib 't/lib';

use Helper qw/test_dir detect_warnings/;
use JSONSchema::Validator;
use JSONSchema::Validator::Util qw/get_resource decode_content/;

for my $validator_class (@{$JSONSchema::Validator::JSON_SCHEMA_VALIDATORS}, @{$JSONSchema::Validator::OAS_VALIDATORS}) {
    my $specification = lc($validator_class->SPECIFICATION);
    my $glob_file_tests = test_dir("data/json_schema/${specification}/*.json");
    my @file_tests = glob($glob_file_tests);
    for my $file (@file_tests) {
        my $uri = URI::file->new($file)->as_string;
        my $tests = decode_content(get_resource({}, $uri), $uri);
        for my $test (@$tests) {
            my $subtests = $test->{tests};
            for my $t (@$subtests) {
                my %new_params = %{$t->{new_params} // {}};
                my %validate_params = ((direction => 'request'), %{$t->{v_params} // {}}); # for OAS30 need to set "direction" params
                my $validator = $validator_class->new(schema => $test->{schema}, %new_params);
                my $test_name = "path: $file; specification: $specification; subject: $test->{subject}; description: $t->{description}";
                my ($result, $errors) = $validator->validate_schema($t->{data}, %validate_params);
                if ($t->{valid}) {
                    is $result, 1, "$test_name; result is ok";
                    is @$errors, 0, (
                      @$errors
                      ? join $/, map {("$test_name; errors:", @{$_->unwind_to_string_list})} @$errors
                      : "$test_name; errors is empty"
                    );
                } else {
                    is $result, 0, "$test_name; result is fail";
                    ok @$errors > 0, "$test_name; errors is not empty";
                    for my $e (@$errors) {
                        is ref $e, 'JSONSchema::Validator::Error', "$test_name; check error type";
                    }
                }
            }
        }
    }
}

ok detect_warnings() == 0, 'no warnings';
done_testing;
