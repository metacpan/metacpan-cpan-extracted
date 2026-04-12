use 5.42.0;
use warnings;

use Test2::V1 -Pip;

use feature qw/ signatures/;

use JSON::Schema::AsType;
use JSON;

my $schema = JSON::Schema::AsType->new(
    draft  => '2020-12',
    schema => {
        type    => 'string',
        pattern => '^\\p{Letter}+$'
    },
);

ok $schema->check('Ï'), 'all good';

done_testing;
