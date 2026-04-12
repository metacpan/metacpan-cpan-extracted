use strict;
use warnings;

use Test2::V1 -Pip;

use JSON::Schema::AsType;

my $schema = JSON::Schema::AsType->new(
    draft  => 7,
    schema => {
        properties => {
            foo => { type => 'integer' },
            bar => { type => 'object' },
        },
    }
);

ok $schema->check( { foo => 1, bar => { two => 2 } } ), "valid check";
ok !$schema->check( { foo => 'potato', bar => { two => 2 } } ),
  "invalid check";

subtest 'can create empty schemas' => sub {
    ok( JSON::Schema::AsType->new(
            draft  => $_,
            schema => {}
        ),
        $_
      )
      for qw/ 2019-09 2020-12 /;
};

done_testing;

