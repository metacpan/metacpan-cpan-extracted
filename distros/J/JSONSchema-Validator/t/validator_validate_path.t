#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use lib 't/lib';

use Helper qw/test_dir detect_warnings/;
use JSONSchema::Validator;

my $glob_ok = test_dir('data/validator_json_schema/*-1-schema.json');

my $result_ok = JSONSchema::Validator->validate_paths([$glob_ok]);
for my $file (keys %$result_ok) {
    my ($res, $errors) = @{$result_ok->{$file}};
    is $res, 1, "check result of validation of $file";
    ok @$errors == 0, "check errors of validation of $file";
}

my $glob_wrong = test_dir('data/validator_json_schema/wrong-schema/*.json');
my $result_wrong = JSONSchema::Validator->validate_paths([$glob_wrong]);
for my $file (keys %$result_wrong) {
    my ($res, $errors) = @{$result_wrong->{$file}};
    is $res, 0, "check result of validation of $file";
    ok @$errors > 0, "check errors of validation of $file";
}

ok detect_warnings() == 0, 'no warnings';
done_testing;
