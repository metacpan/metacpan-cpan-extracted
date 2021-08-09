#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use lib 't/lib';

use Helper qw/test_dir detect_warnings/;
use JSONSchema::Validator;
use JSONSchema::Validator::Util qw/get_resource decode_content/;

for my $validator_class (@{$JSONSchema::Validator::OAS_VALIDATORS}) {
    my $specification = lc($validator_class->SPECIFICATION);
    my $glob_file_tests = test_dir("data/oas/${specification}/*.json");
    my @file_tests = glob($glob_file_tests);
    for my $file (@file_tests) {
        my $uri = URI::file->new($file)->as_string;
        my $tests = decode_content(get_resource({}, $uri), $uri);

        for my $test (@$tests) {
            my $test_topic = $test->{subject};
            my $validator = $validator_class->new(schema => $test->{schema}, validate_deprecated => 0);
            my $subtests = $test->{tests};
            for my $t (@$subtests) {
                my $test_name = $test_topic . ': ' . $t->{description};

                my $ctype_req = $t->{ctype_req} // 'application/json';
                my ($result, $errors, $req_warnings) = $validator->validate_request(
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
                } else {
                    is $result, 0, 'req: ' . $test_name;
                    ok @$errors > 0, 'req: ' . $test_name . '; errors is not empty';
                    for my $e (@$errors) {
                        is ref $e, 'JSONSchema::Validator::Error', 'req: ' . $test_name . '; check error type';
                    }
                }

                my $ctype_res = $t->{ctype_res} // 'application/json';
                ($result, $errors, my $res_warnings) = $validator->validate_response(
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
                    for my $e (@$errors) {
                        is ref $e, 'JSONSchema::Validator::Error', 'res: ' . $test_name . '; check error type';
                    }
                }

                my @warnings = (@$req_warnings, @$res_warnings);

                if ($t->{warnings}) {
                    ok @warnings > 0, $test_name . '; check warnings';
                    for my $w (@warnings) {
                        is ref $w, 'JSONSchema::Validator::Error', $test_name . '; check warning type';
                    }
                } else {
                    ok @warnings == 0, $test_name . '; check warnings';
                }
            }
        }
    }
}

ok detect_warnings() == 0, 'no warnings';
done_testing;
