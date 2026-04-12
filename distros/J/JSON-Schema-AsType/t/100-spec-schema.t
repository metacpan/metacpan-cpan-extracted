use strict;
use warnings;

use Test::More;

use JSON::Schema::AsType;

for ( 3, 4, 6, 7 ) {
    isa_ok(
        JSON::Schema::AsType->new( draft => $_ )->metaschema =>
          'JSON::Schema::AsType',
        "draft$_"
    );
}

subtest "good schema" => sub {
    my $good = { properties => { foo => { type => 'string' } } };

    ok !JSON::Schema::AsType->new( draft => 7, schema => $good )
      ->validate_schema;
    ok !JSON::Schema::AsType->new( draft => 7, schema => $good )
      ->validate_explain_schema;
};

subtest "bad schema" => sub {
    my $bad = { '$ref' => [] };

    ok( JSON::Schema::AsType->new( draft => 7, schema => $bad )
          ->validate_schema );
    ok( JSON::Schema::AsType->new( draft => 7, schema => $bad )
          ->validate_explain_schema );
};

done_testing;
