use strict;
use warnings;

use Test::More;
use Test::Exception;

use JSON::Schema::AsType::Draft3::Types Schema => { -as => 'SD3' };
use JSON::Schema::AsType::Draft4::Types Schema => { -as => 'SD4' };
use JSON::Schema::AsType::Draft6::Types Schema => { -as => 'SD6' };

for my $type ( SD3, SD4, SD6 ) {
    subtest $type => sub {
my $schema = $type->coerce({ type => 'integer', minimum => 5 });

ok $type->check($schema), "schema is a schema";
ok $schema->check( 6 );
ok !$schema->check( 4 );
ok !$schema->check( "banana" );

dies_ok {
    my $schema = Schema->coerce({ type => 'banana', minimum => 5 });
} "bad schema";
}
}

done_testing;
