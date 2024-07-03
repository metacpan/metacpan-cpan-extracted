use Test::More;
use strict;
use warnings;

use_ok "Exercises::API";

# Creating object without apikey should fail
eval { Exercises::API->new(); };
like( $@, qr/Attribute \(apikey\) is required/, "Missing apikey throws error" );

# Creating object with apikey should succeed
my $ea_obj = Exercises::API->new( apikey => 'test_key' );
isa_ok( $ea_obj, 'Exercises::API', 'Object created successfully' );
is( $ea_obj->apikey, 'test_key', 'apikey attribute has correct value' );

done_testing();
