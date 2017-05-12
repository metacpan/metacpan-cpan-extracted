use strict;
use warnings;

use Test::More tests => 2;

use JSON::Schema::AsType;

my $schema = JSON::Schema::AsType->new( schema => {
        properties => {
            foo => { type => 'integer' },
            bar => { type => 'object' },
        },
});

ok $schema->check({ foo => 1, bar => { two => 2 } }), "valid check";
ok !$schema->check({ foo => 'potato', bar => { two => 2 } }), "invalid check";



