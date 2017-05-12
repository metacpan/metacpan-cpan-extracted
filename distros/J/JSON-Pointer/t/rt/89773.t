use strict;
use warnings;

use Test::More;
use Test::Exception;
use JSON::Pointer;
use JSON;

lives_and {
    my $json = JSON::decode_json('{"t": true}');
    my $patched_json = JSON::Pointer->add($json, "/foo", "bar");
    is_deeply(
        $patched_json,
        +{
            t => JSON::true,
            foo => "bar"
        }
    );
} 'Cloned and added value';

done_testing;

