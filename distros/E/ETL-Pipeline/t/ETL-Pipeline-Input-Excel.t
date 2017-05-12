use ETL::Pipeline;
use Test::More;

sub value {
	my ($etl, $field) = @_;
	my @values = $etl->input->get( $field );
	return $values[0];
}

subtest 'XLSX format' => sub {
	my $etl = ETL::Pipeline->new( {
		work_in   => 't/DataFiles',
		input     => ['Excel', matching => 'Excel2007.xlsx'],
		constants => {un => 1},
		output    => 'UnitTest',
	} );
	$etl->input->configure;

	ok( $etl->input->next_record, 'next_record' );
	is( value( $etl, 'A'       ), 'Field1', 'get A' );
	is( value( $etl, 'D'       ), 'Field4', 'get D' );
	is( value( $etl, 1         ), 'Field2', 'get 1' );
	is( value( $etl, 3         ), 'Field4', 'get 3' );
	is( value( $etl, 'Header1' ), 'Field1', 'get Header1' );
	is( value( $etl, 'Header3' ), 'Field3', 'get Header3' );

	is( $etl->input->next_record, 0, 'End of file' );
	$etl->input->finish;

	subtest 'worksheet' => sub {
		subtest 'By name' => sub {
			my $etl = ETL::Pipeline->new( {
				work_in => 't/DataFiles',
				input   => ['Excel', matching => 'Excel2007.xlsx', no_column_names => 1, worksheet => 'Sheet2'],
				constants => {un => 1},
				output    => 'UnitTest',
			} );
			$etl->input->configure;

			ok( $etl->input->next_record, 'next_record' );
			is( value( $etl, 'A' ), 'Sheet2', 'get' );

			$etl->input->finish;
		};
		subtest 'By regular expression' => sub {
			my $etl = ETL::Pipeline->new( {
				work_in => 't/DataFiles',
				input   => ['Excel', matching => 'Excel2007.xlsx', no_column_names => 1, worksheet => qr/t2$/],
				constants => {un => 1},
				output    => 'UnitTest',
			} );
			$etl->input->configure;

			ok( $etl->input->next_record, 'next_record' );
			is( value( $etl, 'A' ), 'Sheet2', 'get' );

			$etl->input->finish;
		};
	};
};

subtest 'XLS format' => sub {
	my $etl = ETL::Pipeline->new( {
		work_in   => 't/DataFiles',
		input     => ['Excel', matching => 'Excel2003.xls'],
		constants => {un => 1},
		output    => 'UnitTest',
	} );
	$etl->input->configure;

	ok( $etl->input->next_record, 'next_record' );
	is( value( $etl, 'A'       ), 'Field1', 'get A' );
	is( value( $etl, 'D'       ), 'Field4', 'get D' );
	is( value( $etl, 1         ), 'Field2', 'get 1' );
	is( value( $etl, 3         ), 'Field4', 'get 3' );
	is( value( $etl, 'Header1' ), 'Field1', 'get Header1' );
	is( value( $etl, 'Header3' ), 'Field3', 'get Header3' );

	is( $etl->input->next_record, 0, 'End of file' );
	$etl->input->finish;

	subtest 'worksheet' => sub {
		subtest 'By name' => sub {
			my $etl = ETL::Pipeline->new( {
				work_in => 't/DataFiles',
				input   => ['Excel', matching => 'Excel2003.xls', no_column_names => 1, worksheet => 'Sheet2'],
				constants => {un => 1},
				output    => 'UnitTest',
			} );
			$etl->input->configure;

			ok( $etl->input->next_record, 'next_record' );
			is( value( $etl, 'A' ), 'Sheet2', 'get' );

			$etl->input->finish;
		};
		subtest 'By regular expression' => sub {
			my $etl = ETL::Pipeline->new( {
				work_in => 't/DataFiles',
				input   => ['Excel', matching => 'Excel2003.xls', no_column_names => 1, worksheet => qr/t2$/],
				constants => {un => 1},
				output    => 'UnitTest',
			} );
			$etl->input->configure;

			ok( $etl->input->next_record, 'next_record' );
			is( value( $etl, 'A' ), 'Sheet2', 'get' );

			$etl->input->finish;
		};
	};
};

done_testing();
