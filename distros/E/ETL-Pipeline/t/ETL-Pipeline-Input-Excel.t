use ETL::Pipeline;
use Test::More;

subtest 'XLS file' => sub {
	my $etl = ETL::Pipeline->new( {
		input   => ['Excel', path => 'Excel2003.xls'],
		mapping => {
			One      => 0,
			Two      => 1,
			Three    => 2,
			Four     => 3,
			Five     => 4,
			Six      => 'A',
			Seven    => 'B',
			Eight    => 'C',
			Nine     => 'D',
			Ten      => 'E',
			Eleven   => 'Header1',
			Twelve   => 'Header2',
			Thirteen => 'Header3',
			Fourteen => 'Header4',
			Fifteen  => 'Header5',
		},
		output  => 'UnitTest',
		work_in => 't/DataFiles',
	} )->process;
	is( $etl->output->number_of_records, 1, 'All records processed' );

	my $output = $etl->output->get_record( 0 );
	subtest 'Field number' => sub {
		is( $output->{One  }, 'Field1', 'Field 1' );
		is( $output->{Two  }, 'Field2', 'Field 2' );
		is( $output->{Three}, 'Field3', 'Field 3' );
		is( $output->{Four }, 'Field4', 'Field 4' );
		is( $output->{Five }, 'Field5', 'Field 5' );
	};
	subtest 'Column letter' => sub  {
		is( $output->{Six  }, 'Field1', 'Column A' );
		is( $output->{Seven}, 'Field2', 'Column B' );
		is( $output->{Eight}, 'Field3', 'Column C' );
		is( $output->{Nine }, 'Field4', 'Column D' );
		is( $output->{Ten  }, 'Field5', 'Column E' );
	};
	subtest 'Field name' => sub {
		is( $output->{Eleven  }, 'Field1', 'Header 1' );
		is( $output->{Twelve  }, 'Field2', 'Header 2' );
		is( $output->{Thirteen}, 'Field3', 'Header 3' );
		is( $output->{Fourteen}, 'Field4', 'Header 4' );
		is( $output->{Fifteen }, 'Field5', 'Header 5' );
	};
};
subtest 'XLSX file' => sub {
	my $etl = ETL::Pipeline->new( {
		input   => ['Excel', path => 'Excel2007.xlsx'],
		mapping => {
			One      => 0,
			Two      => 1,
			Three    => 2,
			Four     => 3,
			Five     => 4,
			Six      => 'A',
			Seven    => 'B',
			Eight    => 'C',
			Nine     => 'D',
			Ten      => 'E',
			Eleven   => 'Header1',
			Twelve   => 'Header2',
			Thirteen => 'Header3',
			Fourteen => 'Header4',
			Fifteen  => 'Header5',
		},
		output  => 'UnitTest',
		work_in => 't/DataFiles',
	} )->process;
	is( $etl->output->number_of_records, 1, 'All records processed' );

	my $output = $etl->output->get_record( 0 );
	subtest 'Field number' => sub {
		is( $output->{One  }, 'Field1', 'Field 1' );
		is( $output->{Two  }, 'Field2', 'Field 2' );
		is( $output->{Three}, 'Field3', 'Field 3' );
		is( $output->{Four }, 'Field4', 'Field 4' );
		is( $output->{Five }, 'Field5', 'Field 5' );
	};
	subtest 'Column letter' => sub  {
		is( $output->{Six  }, 'Field1', 'Column A' );
		is( $output->{Seven}, 'Field2', 'Column B' );
		is( $output->{Eight}, 'Field3', 'Column C' );
		is( $output->{Nine }, 'Field4', 'Column D' );
		is( $output->{Ten  }, 'Field5', 'Column E' );
	};
	subtest 'Field name' => sub {
		is( $output->{Eleven  }, 'Field1', 'Header 1' );
		is( $output->{Twelve  }, 'Field2', 'Header 2' );
		is( $output->{Thirteen}, 'Field3', 'Header 3' );
		is( $output->{Fourteen}, 'Field4', 'Header 4' );
		is( $output->{Fifteen }, 'Field5', 'Header 5' );
	};
};
subtest 'worksheet' => sub {
	my $etl = ETL::Pipeline->new( {
		input   => ['Excel', path => 'Excel2007.xlsx', no_column_names => 1, worksheet => 'Sheet2'],
		mapping => {1 => 'A'},
		output  => 'UnitTest',
		work_in => 't/DataFiles',
	} )->process;
	my $output = $etl->output->get_record( 0 );
	is( $output->{1}, 'Sheet2', 'By name' );

	my $etl = ETL::Pipeline->new( {
		input   => ['Excel', path => 'Excel2007.xlsx', no_column_names => 1, worksheet => qr/t2$/],
		mapping => {1 => 'A'},
		output  => 'UnitTest',
		work_in => 't/DataFiles',
	} )->process;
	my $output = $etl->output->get_record( 0 );
	is( $output->{1}, 'Sheet2', 'By regular expression' );
};
subtest 'no_column_names' => sub {
	my $etl = ETL::Pipeline->new( {
		input   => ['Excel', path => 'Excel2007.xlsx', no_column_names => 1],
		mapping => {
			One      => 0,
			Two      => 1,
			Three    => 2,
			Four     => 3,
			Five     => 4,
			Six      => 'A',
			Seven    => 'B',
			Eight    => 'C',
			Nine     => 'D',
			Ten      => 'E',
			Eleven   => 'Header1',
			Twelve   => 'Header2',
			Thirteen => 'Header3',
			Fourteen => 'Header4',
			Fifteen  => 'Header5',
		},
		output  => 'UnitTest',
		work_in => 't/DataFiles',
	} )->process;
	is( scalar( $etl->aliases ), 1, 'No headers' );

	my $output = $etl->output->get_record( 0 );
	subtest 'Field number' => sub {
		is( $output->{One  }, 'Header1', 'Field 1' );
		is( $output->{Two  }, 'Header2', 'Field 2' );
		is( $output->{Three}, 'Header3', 'Field 3' );
		is( $output->{Four }, 'Header4', 'Field 4' );
		is( $output->{Five }, 'Header5', 'Field 5' );
	};
	subtest 'Column letter' => sub  {
		is( $output->{Six  }, 'Header1', 'Column A' );
		is( $output->{Seven}, 'Header2', 'Column B' );
		is( $output->{Eight}, 'Header3', 'Column C' );
		is( $output->{Nine }, 'Header4', 'Column D' );
		is( $output->{Ten  }, 'Header5', 'Column E' );
	};
	subtest 'Field name' => sub {
		is( $output->{Eleven  }, undef, 'Header 1' );
		is( $output->{Twelve  }, undef, 'Header 2' );
		is( $output->{Thirteen}, undef, 'Header 3' );
		is( $output->{Fourteen}, undef, 'Header 4' );
		is( $output->{Fifteen }, undef, 'Header 5' );
	};
};
subtest 'skipping' => sub {
	my $etl = ETL::Pipeline->new( {
		input => ['Excel',
			path            => 'Excel2007.xlsx',
			no_column_names => 1,
			skipping        => 1,
		],
		mapping => {One => 'A'},
		output  => 'UnitTest',
		work_in => 't/DataFiles',
	} )->process;
	is( $etl->output->number_of_records, 1, 'Number' );

	$etl = ETL::Pipeline->new( {
		input => ['Excel',
			path => 'Excel2007.xlsx',
			no_column_names => 1,
			skipping => sub { shift->{1} =~ m/^Header/ ? 1 : 0 },
		],
		mapping => {One => 'A'},
		output  => 'UnitTest',
		work_in => 't/DataFiles',
	} )->process;
	is( $etl->output->number_of_records, 1, 'Code, field number' );

	$etl = ETL::Pipeline->new( {
		input => ['Excel',
			path => 'Excel2007.xlsx',
			no_column_names => 1,
			skipping => sub { shift->{'A'} =~ m/^Header/ ? 1 : 0 },
		],
		mapping => {One => 'A'},
		output  => 'UnitTest',
		work_in => 't/DataFiles',
	} )->process;
	is( $etl->output->number_of_records, 1, 'Code, column letter' );
};

done_testing();
