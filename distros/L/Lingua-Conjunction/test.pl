
use Test; 

BEGIN { plan tests => 7, todo => [ ] }

use Lingua::Conjunction 2.00;
ok(1);

ok( "A" eq conjunction( qw( A ) ) );
ok( "A and C" eq conjunction( qw( A C ) ) );
ok( "A, B, and C" eq conjunction( qw( A B C ) ) );

Lingua::Conjunction->connector_type("or");

ok( "A" eq conjunction( qw( A ) ) );
ok( "A or C" eq conjunction( qw( A C ) ) );
ok( "A, B, or C" eq conjunction( qw( A B C ) ) );

