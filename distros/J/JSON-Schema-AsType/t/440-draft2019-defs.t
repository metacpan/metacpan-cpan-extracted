use 5.42.0;
use warnings;

use Test2::V1 -Pip;

use feature qw/ signatures/;

use JSON::Schema::AsType;
use JSON;

my $schema = JSON::Schema::AsType->new(
    draft  => '2019-09',
    schema => {
        '$schema' => "https://json-schema.org/draft/2019-09/schema",
        '$ref'    => "https://json-schema.org/draft/2019-09/schema"
    }
);

ok $schema->check( { type => 'string' } ), 'all good';

done_testing;
