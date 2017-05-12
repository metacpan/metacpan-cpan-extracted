use ETL::Pipeline;
use Test::More;


subtest 'set' => sub {
	my $etl = ETL::Pipeline->new( {output => 'UnitTest'} );

	$etl->output->set( value => 1 );
	is( $etl->output->get_value( 'value' ), 1, 'Single value' );

	$etl->output->set( value => 3, 4, 5 );
	my $value = $etl->output->get_value( 'value' );
	is( ref( $value ), 'ARRAY', 'Multiple values' );
	is_deeply( $value, [3, 4, 5], 'All values saved' );
};

done_testing;
