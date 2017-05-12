use Test::More;

my $class = 'Geo::GeoNames';
my $method = 'new';

use_ok( $class );
can_ok( $class, $method );

my $rc = eval { $class->$method(
	username => 'fakename',
	url      => 'http://www.example.com',
	) };
	
done_testing();
