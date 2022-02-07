use ETL::Pipeline;
use Test::More;


subtest 'list' => sub {
	my $etl = ETL::Pipeline->new( {
		input     => 'UnitTest',
		mapping   => {value => 0},
		output    => 'Memory',
		work_in => 't/DataFiles',
	} )->process;

	is( $etl->output->number_of_records, 2, 'number_of_records' );
	is_deeply( [$etl->output->records], [{value => 'Field1'}, {value => 'Field11'}], 'Records saved' );
};
subtest 'hash' => sub {
	my $etl = ETL::Pipeline->new( {
		input     => 'UnitTest',
		mapping   => {key => 0, value => 1},
		output    => ['Memory', key => 'key'],
		work_in => 't/DataFiles',
	} )->process;

	is( $etl->output->number_of_ids, 2, 'number_of_ids' );
	is_deeply( $etl->output->with_id( 'Field1'  ), [{key => 'Field1' , value => 'Field2' }], 'First record'  );
	is_deeply( $etl->output->with_id( 'Field11' ), [{key => 'Field11', value => 'Field12'}], 'Second record' );
};

done_testing;
