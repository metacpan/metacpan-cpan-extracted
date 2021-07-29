#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More;
use File::Basename;
use Cwd;

use JSONSchema::Validator;
use JSONSchema::Validator::Util qw/read_file decode_content/;

# data/draft4-1-schema.json
my $resource = 'file://' . dirname(Cwd::abs_path(__FILE__)) . '/data/draft4-1-schema.json';
my $instance_file_ok = dirname(Cwd::abs_path(__FILE__)) . '/data/draft4-1-ok.json';
my $instance_file_wrong = dirname(Cwd::abs_path(__FILE__)) . '/data/draft4-1-wrong.json';

my $instance_ok = decode_content(read_file($instance_file_ok), $instance_file_ok);
my $instance_wrong = decode_content(read_file($instance_file_wrong), $instance_file_wrong);

my $validator = JSONSchema::Validator->new(resource => $resource);

my ($result, $errors) = $validator->validate_schema($instance_ok);
is $result, 1, "check validation $instance_file_ok";
ok @$errors == 0, "check validation errors $instance_file_ok";

($result, $errors) = $validator->validate_schema($instance_wrong);
is $result, 0, "check validation $instance_file_wrong";
ok @$errors > 0, "check validation errors $instance_file_wrong";

my $schema_file = dirname(Cwd::abs_path(__FILE__)) . '/data/draft4-1-schema.json';
my $schema = decode_content(read_file($schema_file), $schema_file);

## with schema and without specification
$validator = JSONSchema::Validator->new(schema => $schema);

($result, $errors) = $validator->validate_schema($instance_ok);
is $result, 1, "check validation $instance_file_ok";
ok @$errors == 0, "check validation errors $instance_file_ok";

($result, $errors) = $validator->validate_schema($instance_wrong);
is $result, 0, "check validation $instance_file_wrong";
ok @$errors > 0, "check validation errors $instance_file_wrong";

# data/draft4-2-schema.json
$resource = 'file://' . dirname(Cwd::abs_path(__FILE__)) . '/data/draft4-2-schema.json';
$instance_file_ok = dirname(Cwd::abs_path(__FILE__)) . '/data/draft4-2-ok.json';
$instance_file_wrong = dirname(Cwd::abs_path(__FILE__)) . '/data/draft4-2-wrong.json';

$instance_ok = decode_content(read_file($instance_file_ok), $instance_file_ok);
$instance_wrong = decode_content(read_file($instance_file_wrong), $instance_file_wrong);

## without specification
$result = eval { $validator = JSONSchema::Validator->new(resource => $resource) };
is $result, undef, "check exception on unknown specification of $resource";
like $@, qr/unknown specification/, "check exception message on unknown specification of $resource";

## with specification
$validator = JSONSchema::Validator->new(resource => $resource, specification => 'Draft4');

($result, $errors) = $validator->validate_schema($instance_ok);
is $result, 1, "check validation $instance_file_ok";
ok @$errors == 0, "check validation errors $instance_file_ok";

($result, $errors) = $validator->validate_schema($instance_wrong);
is $result, 0, "check validation $instance_file_wrong";
ok @$errors > 0, "check validation errors $instance_file_wrong";

$schema_file = dirname(Cwd::abs_path(__FILE__)) . '/data/draft4-2-schema.json';
$schema = decode_content(read_file($schema_file), $schema_file);

## with schema and without specification
$result = eval { $validator = JSONSchema::Validator->new(schema => $schema) };
is $result, undef, "check exception on unknown specification by schema of resource $resource";
like $@, qr/unknown specification/, "check exception message on unknown specification by schema of resource $resource";

## with schema and specification
$validator = JSONSchema::Validator->new(schema => $schema, specification => 'Draft4');

($result, $errors) = $validator->validate_schema($instance_ok);
is $result, 1, "check validation $instance_file_ok";
ok @$errors == 0, "check validation errors $instance_file_ok";

($result, $errors) = $validator->validate_schema($instance_wrong);
is $result, 0, "check validation $instance_file_wrong";
ok @$errors > 0, "check validation errors $instance_file_wrong";

# data/wrong-schema/draft4.json
$resource = 'file://' . dirname(Cwd::abs_path(__FILE__)) . '/data/wrong-schema/draft4.json';
$result = eval { my $validator = JSONSchema::Validator->new(resource => $resource) };
is $result, undef, "check exception on wrong meta schema validation of $resource";
like $@, qr/invalid schema/, "check exception message on wrong meta schema validation of $resource";

done_testing;
