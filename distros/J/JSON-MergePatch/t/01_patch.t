use strict;
use warnings;
use Test::More;
use Test::JSON;

use JSON::MergePatch;

my $test_cases = +[
    +{ target => '{"a":"b"}',         patch => {'a'=>'c'},                    expected => '{"a":"c"}' },
    +{ target => '{"a":"b"}',         patch => {'b'=>'c'},                    expected => '{"a":"b","b":"c"}' },
    +{ target => '{"a":"b"}',         patch => {'a'=>undef},                  expected => '{}' },
    +{ target => '{"a":"b","b":"c"}', patch => {'a'=>undef},                  expected => '{"b":"c"}' },
    +{ target => '{"a":["b"]}',       patch => {'a'=>'c'},                    expected => '{"a":"c"}' },
    +{ target => '{"a":"c"}',         patch => {'a'=>['b']},                  expected => '{"a":"[\"b\"]"}' },
    +{ target => '{"a":{"b":"c"}}',   patch => {'a'=>{'b'=>'d','c'=>undef}},  expected => '{"a":"{\"b\":\"d\"}"}' },
    +{ target => '{"a":"b"}',         patch => {'a'=>[1]},                    expected => '{"a":"[1]"}' },
    +{ target => '["a","b"]',         patch => ['c','d'],                     expected => '["c","d"]' },
    +{ target => '{"a":"b"}',         patch => ['c'],                         expected => '["c"]' },
    +{ target => '{"a":"foo"}',       patch => undef,                         expected => undef, result_not_json => 1 },
    +{ target => '{"a":"foo"}',       patch => 'bar',                         expected => 'bar', result_not_json => 1 },
    +{ target => '{"e":null}',        patch => {'a'=>1},                      expected => '{"e":null,"a":1}' },
    +{ target => '[1,2]',             patch => {'a'=>'b','c'=>undef},         expected => '{"a":"b"}' },
    +{ target => '{}',                patch => {'a'=>{'bb'=>{'ccc'=>undef}}}, expected => '{"a":"{\"bb\":\"{}\"}"}' },
];

for my $test_case (@$test_cases) {
    if ($test_case->{result_not_json}) {
        is (JSON::MergePatch->patch($test_case->{target}, $test_case->{patch}), $test_case->{expected});
        is (json_merge_patch($test_case->{target}, $test_case->{patch}), $test_case->{expected});
    }
    else {
        is_json (JSON::MergePatch->patch($test_case->{target}, $test_case->{patch}), $test_case->{expected});
        is_json (json_merge_patch($test_case->{target}, $test_case->{patch}), $test_case->{expected});
    }
}

done_testing;
