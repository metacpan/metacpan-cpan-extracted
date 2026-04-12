use Test2::V1 -Pip;

use JSON::Schema::AsType;

my $schema = JSON::Schema::AsType->new( draft => 4, schema => {} );

is [ $schema->all_keywords ] => subset { item 'id' };

done_testing;
