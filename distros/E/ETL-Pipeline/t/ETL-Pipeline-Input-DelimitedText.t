use ETL::Pipeline;
use Test::More;

subtest 'Process file' => sub {
	my $etl = ETL::Pipeline->new( {
		constants => {un => 1},
		input     => ['DelimitedText', file => 'DelimitedText.txt'],
		mapping   => {
			One   => '0',
			Two   => '1',
			Three => '2',
			Four  => '3',
			Five  => '4',
			Six   => 'Header1',
			Seven => 'Header2',
			Eight => 'Header3',
			Nine  => 'Header4',
		},
		output    => 'UnitTest',
		work_in   => 't/DataFiles',
	} )->process;
	is( $etl->output->number_of_records, 2, 'All records processed' );

	my $record = $etl->output->get_record( 0 );
	subtest 'Field number' => sub {
		is( $record->{One  }, 'Field1', 'Field 1'  );
		is( $record->{Two  }, 'Field2', 'Field 2'  );
		is( $record->{Three}, 'Field3', 'Field 3'  );
		is( $record->{Four }, 'Field4', 'Field 4'  );
		is( $record->{Five }, 'Field5', 'Field 5'  );
	};
	subtest 'Field name' => sub {
		is( $record->{Six  }, 'Field1', 'Header 1' );
		is( $record->{Seven}, 'Field2', 'Header 2' );
		is( $record->{Eight}, 'Field3', 'Header 3' );
		is( $record->{Nine }, 'Field4', 'Header 4' );
	};
};
subtest 'no_column_names' => sub {
	my $etl = ETL::Pipeline->new( {
		constants => {un => 1},
		input     => ['DelimitedText', file => 'DelimitedText.txt', no_column_names => 1],
		mapping   => {
			One   => '0',
			Two   => '1',
			Three => '2',
			Four  => '3',
			Six   => 'Header1',
			Seven => 'Header2',
			Eight => 'Header3',
			Nine  => 'Header4',
		},
		output    => 'UnitTest',
		work_in   => 't/DataFiles',
	} )->process;
	is( scalar( $etl->aliases ), 0, 'No aliases' );

	my $record = $etl->output->get_record( 0 );
	subtest 'Field number' => sub {
		is( $record->{One  }, 'Header1', 'Field 1'  );
		is( $record->{Two  }, 'Header2', 'Field 2'  );
		is( $record->{Three}, 'Header3', 'Field 3'  );
		is( $record->{Four }, 'Header4', 'Field 4'  );
	};
	subtest 'Field name' => sub {
		is( $record->{Six  }, undef, 'Header 1' );
		is( $record->{Seven}, undef, 'Header 2' );
		is( $record->{Eight}, undef, 'Header 3' );
		is( $record->{Nine }, undef, 'Header 4' );
	};
};
subtest 'skipping' => sub {
	my $etl = ETL::Pipeline->new( {
		constants => {un => 1},
		input     => ['DelimitedText', file => 'DelimitedText.txt', skipping => 1],
		output    => 'UnitTest',
		work_in   => 't/DataFiles',
	} )->process;
	is( $etl->output->number_of_records, 1, 'One row skipped' );

	$etl = ETL::Pipeline->new( {
		constants => {un => 1},
		input     => ['DelimitedText', file => 'DelimitedText.txt', skipping => sub { shift =~ m/^Header/ ? 1 : 0 }],
		output    => 'UnitTest',
		work_in   => 't/DataFiles',
	} )->process;
	is( $etl->output->number_of_records, 1, 'Code skipped headers' );
};

done_testing;
