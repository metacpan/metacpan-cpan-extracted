use 5.42.0;

use Test2::V1 -Pip;

use JSON::Schema::AsType;

my $schema = JSON::Schema::AsType->new(
    schema => { definitions => { stuff => { type => 'boolean' } } } );

is $schema->fetch('#/definitions/stuff')->schema => +{ type => 'boolean' },
  'can get to my (local) stuff';

done_testing;
