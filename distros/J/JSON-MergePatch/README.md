# NAME

JSON::MergePatch - JSON Merge Patch implementation

# SYNOPSIS

    use JSON::MergePatch;
    use Test::More;

    my $target_json = '{"a":"b"}';
    my $patch = +{ 'a' => 'c' };

    my $result_json = json_merge_patch($target_json, $patch);
    my $diff = json_merge_diff($result_json, $target_json);

    is $result_json, '{"a":"c"}';
    is_deeply $diff, $patch;

    done_testing;

# DESCRIPTION

JSON::MergePatch is JSON Merge Patch implementation for Perl.

# METHODS

## patch($target: Scalar, $patch: HashRef) :Scalar

This method merges patch into the target JSON.

    my $result_json = JSON::MergePatch->patch('{"a":"b"}', { 'a' => 'c' });
    # $result_json = '{"a":"c"}';

## diff($source :Scalar, $target :Scalar) :HashRef

This method outputs diff between JSON.

    my $diff = JSON::MergePatch->diff('{"a":"c"}', '{"a":"b"}');
    # $diff = { 'a' => 'c' };

# FUNCTIONS

## json\_merge\_patch($target: Scalar, $patch: HashRef) :Scalar

Same as `patch()` method.

## json\_merge\_diff($source :Scalar, $target :Scalar) :HashRef

Same as `diff()` method.

# LICENSE

Copyright (C) Taishi Hiraga.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Taishi Hiraga <sojiro@cpan.org>
