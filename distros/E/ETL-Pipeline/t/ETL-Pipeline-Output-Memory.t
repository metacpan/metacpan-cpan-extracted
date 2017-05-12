use ETL::Pipeline;
use Test::More;


subtest 'list' => sub {
	my $etl = ETL::Pipeline->new( {output => 'Memory'} );

	subtest 'First record' => sub {
		$etl->output->set( value => 1 );
		ok( $etl->output->write_record, 'write_record' );
		is( $etl->output->number_of_records, 1, 'number_of_records' );
		is_deeply( [$etl->output->records], [{value => 1}], 'records' );
	};
	subtest 'Second record' => sub {
		$etl->output->set( value => 2 );
		ok( $etl->output->write_record, 'write_record' );
		is( $etl->output->number_of_records, 2, 'number_of_records' );
		is_deeply( [$etl->output->records], [{value => 1}, {value => 2}], 'records' );
	};
};

subtest 'hash' => sub {
	my $etl = ETL::Pipeline->new( {output => ['Memory', key => 'key']} );

	subtest 'First record' => sub {
		$etl->output->set( key => 'a' );
		$etl->output->set( value => 1 );
		ok( $etl->output->write_record, 'write_record' );
		is( $etl->output->number_of_ids, 1, 'number_of_ids' );
		is_deeply( $etl->output->with_id( 'a' ), [{key => 'a', value => 1}], 'with_id' );
	};
	subtest 'Second record' => sub {
		$etl->output->set( key => 'a' );
		$etl->output->set( value => 2 );
		ok( $etl->output->write_record, 'write_record' );
		is( $etl->output->number_of_ids, 1, 'number_of_ids' );
		is_deeply( $etl->output->with_id( 'a' ), [{key => 'a', value => 1}, {key => 'a', value => 2}], 'with_id' );
	};
	subtest 'Different key' => sub {
		$etl->output->set( key => 'b' );
		$etl->output->set( value => 3 );
		ok( $etl->output->write_record, 'write_record' );
		is( $etl->output->number_of_ids, 2, 'number_of_ids' );
		is_deeply( $etl->output->with_id( 'b' ), [{key => 'b', value => 3}], 'with_id' );
		is_deeply( $etl->output->with_id( 'a' ), [{key => 'a', value => 1}, {key => 'a', value => 2}], 'Old id not changed' );
	};
};

done_testing;
