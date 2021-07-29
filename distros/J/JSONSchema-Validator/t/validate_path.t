#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More;
use File::Basename;

use JSONSchema::Validator;

my $dir = dirname(__FILE__);

my $glob_ok = "$dir/data/*-1-schema.json";

my $result_ok = JSONSchema::Validator->validate_paths([$glob_ok]);
for my $file (keys %$result_ok) {
    my ($res, $errors) = @{$result_ok->{$file}};
    is $res, 1, "check result of validation of $file";
    ok @$errors == 0, "check errors of validation of $file";
}

my $glob_wrong = "$dir/data/wrong-schema/*.json";
my $result_wrong = JSONSchema::Validator->validate_paths([$glob_wrong]);
for my $file (keys %$result_wrong) {
    my ($res, $errors) = @{$result_wrong->{$file}};
    is $res, 0, "check result of validation of $file";
    ok @$errors > 0, "check errors of validation of $file";
}

done_testing;
