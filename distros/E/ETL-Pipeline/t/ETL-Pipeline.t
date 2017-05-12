use Test::More;


use_ok( 'ETL::Pipeline' );

subtest 'Simple pipeline' => sub {
	my $etl = ETL::Pipeline->new( {
		work_in   => 't',
		input     => 'UnitTest',
		constants => {constant => 'String literal'},
		mapping   => {un => 0, deux => 1, trois => 2},
		output    => 'UnitTest',
	} );
	$etl->process;

	pass( 'Script ran' );

	is( $etl->output->number_of_records, 3, 'Three records' );
	subtest 'First record' => sub {
		my $record = $etl->output->get_record( 0 );
		my @keys   = keys %$record;
		is( scalar( @keys )    , 4               , '4 fields'       );
		is( $record->{un      }, 'Header1'       , 'Found Header1'  );
		is( $record->{deux    }, 'Header2'       , 'Found Header2'  );
		is( $record->{trois   }, 'Header3'       , 'Found Header3'  );
		is( $record->{constant}, 'String literal', 'Found constant' );
	};
	subtest 'Second record' => sub {
		my $record = $etl->output->get_record( 1 );
		my @keys   = keys %$record;
		is( scalar( @keys )    , 4               , '4 fields'       );
		is( $record->{un      }, 'Field1'        , 'Found Field1'   );
		is( $record->{deux    }, 'Field2'        , 'Found Field2'   );
		is( $record->{trois   }, 'Field3'        , 'Found Field3'   );
		is( $record->{constant}, 'String literal', 'Found constant' );
	};
};

subtest 'work_in' => sub {
	my $etl = ETL::Pipeline->new;

	$etl->work_in( 't' );
	is( $etl->work_in->basename, 't', 'Fixed directory' );
	is( $etl->data_in->basename, 't', 'data_in set' );

	$etl->work_in( matching => 't' );
	is( $etl->work_in->basename, 't', 'Search current directory' );

	$etl->work_in( search => 't', matching => '*' );
	is( $etl->work_in->basename, 'DataFiles', 'File glob' );

	$etl->work_in( search => 't', matching => qr/^DataFiles$/i );
	is( $etl->work_in->basename, 'DataFiles', 'Regular expression' );

	$etl->work_in( search => 't/DataFiles', matching => '*' );
	is( $etl->work_in->basename, 'FileListing', 'Alphabetical order' );
};

subtest 'data_in' => sub {
	my $etl = ETL::Pipeline->new( {work_in => 't'} );

	$etl->data_in( 'DataFiles' );
	is( $etl->data_in->basename, 'DataFiles', 'Fixed directory' );

	$etl->data_in( qr/^DataFiles$/i );
	is( $etl->data_in->basename, 'DataFiles', 'Search for subfolder' );
};

subtest 'Fixed module names' => sub {
	unshift @INC, './t/Modules';
	my $etl = ETL::Pipeline->new;

	$etl->input( '+FileInput' );
	ok( defined( $etl->input ), 'Input' );

	$etl->output( '+Output' );
	ok( defined( $etl->output ), 'Output' );
};

subtest 'execute_code_ref' => sub {
	my $etl = ETL::Pipeline->new;
	my $x;

	$etl->execute_code_ref( sub { $x = $_ } );
	is( ref( $x ), 'ETL::Pipeline', 'Pipeline in $_' );

	$etl->execute_code_ref( sub { $x = shift } );
	is( ref( $x ), 'ETL::Pipeline', 'Pipeline in parameters' );

	$etl->execute_code_ref( sub { shift; $x = shift }, 2 );
	is( $x, 2, 'Parameters passed' );

	is( $etl->execute_code_ref( sub { 4 } ), 4, 'Return value' );
	is( $etl->execute_code_ref( 'abc' ), undef, 'Not code reference' );

	subtest 'In pipeline' => sub {
		$etl->work_in( 't' );
		$etl->input( 'UnitTest' );
		$etl->constants( constant => sub { 'String literal' } );
		$etl->mapping( un => sub { $_->get( 0 ) } );
		$etl->output( 'UnitTest' );
		$etl->process;

		subtest 'First record' => sub {
			my $record = $etl->output->get_record( 0 );
			is( $record->{un      }, 'Header1'       , 'mapping'  );
			is( $record->{constant}, 'String literal', 'constants' );
		};
		subtest 'Second record' => sub {
			my $record = $etl->output->get_record( 1 );
			is( $record->{un      }, 'Field1'        , 'mapping'   );
			is( $record->{constant}, 'String literal', 'constants' );
		};
	};
};

subtest 'is_valid' => sub {
	subtest 'No work_in' => sub {
		my $etl = ETL::Pipeline->new( {
			input   => 'UnitTest',
			mapping => {un => 1},
			output  => 'UnitTest',
		} );
		ok( !$etl->is_valid, 'Boolean return' );
		
		my @error = $etl->is_valid;
		ok( !$error[0], 'Return code' );
		is( $error[1], 'The working folder was not set' );
	};
	subtest 'No input' => sub {
		my $etl = ETL::Pipeline->new( {
			work_in => 't',
			mapping => {un => 1},
			output  => 'UnitTest',
		} );
		ok( !$etl->is_valid, 'Boolean return' );
		
		my @error = $etl->is_valid;
		ok( !$error[0], 'Return code' );
		is( $error[1], 'The "input" object was not set' );
	};
	subtest 'No output' => sub {
		my $etl = ETL::Pipeline->new( {
			work_in => 't',
			input   => 'UnitTest',
			mapping => {un => 1},
		} );
		ok( !$etl->is_valid, 'Boolean return' );
		
		my @error = $etl->is_valid;
		ok( !$error[0], 'Return code' );
		is( $error[1], 'The "output" object was not set' );
	};
	subtest 'No mapping' => sub {
		my $etl = ETL::Pipeline->new( {
			work_in => 't',
			input   => 'UnitTest',
			output  => 'UnitTest',
		} );
		ok( !$etl->is_valid, 'Boolean return' );
		
		my @error = $etl->is_valid;
		ok( !$error[0], 'Return code' );
		is( $error[1], 'The mapping was not set' );
	};
	subtest 'Valid' => sub {
		my $etl = ETL::Pipeline->new( {
			work_in => 't',
			input   => 'UnitTest',
			mapping => {un => 1},
			output  => 'UnitTest',
		} );
		ok( $etl->is_valid, 'Boolean return' );
		
		my @error = $etl->is_valid;
		ok( $error[0], 'Return code' );
		is( $error[1], '' );
	};
	subtest 'Constants, no mapping' => sub {
		my $etl = ETL::Pipeline->new( {
			work_in   => 't',
			input     => 'UnitTest',
			constants => {un => 1},
			output    => 'UnitTest',
		} );
		ok( $etl->is_valid, 'Boolean return' );
		
		my @error = $etl->is_valid;
		ok( $error[0], 'Return code' );
		is( $error[1], '' );
	};
};

subtest 'session' => sub {
	my $etl = ETL::Pipeline->new;

	subtest 'Not set' => sub {
		ok( !$etl->session_has( 'bad' ), 'exists' );
		is( $etl->session( 'bad' ), undef, 'get' );
	};
	subtest 'Single value' => sub {
		is( $etl->session( good =>, 3 ), 3, 'set' );
		is( $etl->session( 'good' ), 3, 'get' );
		ok( $etl->session_has( 'good' ), 'exists' );
	};
	subtest 'Multiple values' => sub {
		$etl->session( okay => 4, maybe => 5 );
		ok( $etl->session_has( 'okay' ), 'First exists' );
		is( $etl->session( 'okay' ), 4, 'First value' );
		ok( $etl->session_has( 'maybe' ), 'Second exists' );
		is( $etl->session( 'maybe' ), 5, 'Second value' );
	};
	subtest 'References' => sub {
		$etl->session( many => [7, 8, 9] );
		subtest 'Scalar context' => sub {
			my $scalar = $etl->session( 'many' );
			is( ref( $scalar ), 'ARRAY', 'get' );
			is_deeply( $scalar, [7, 8, 9], 'values' );
		};
		subtest 'List context' => sub {
			my @list = $etl->session( 'many' );
			is_deeply( \@list, [7, 8, 9], 'values' );
		};
	};
	subtest 'Overwrite' => sub {
		is( $etl->session( 'good', 6 ), 6, 'set' );
		is( $etl->session( 'good' ), 6, 'get' );
	};
};

subtest 'chain' => sub {
	subtest 'Everything' => sub {
		my $one = ETL::Pipeline->new( {
			work_in   => 't',
			data_in   => 'DataFiles',
			input     => 'UnitTest',
			mapping   => {un => 1},
			constants => {deux => 2},
			output    => 'UnitTest'
		} );
		$one->session( good => 1 );
		my $two = $one->chain();
		ok( !$two->is_valid, 'Not valid' );
		is( $two->work_in->basename, 't', 'work_in' );
		is( $two->data_in->basename, 'DataFiles', 'data_in' );
		is( $two->session( 'good' ), 1, 'session' );
	};
	subtest 'No work_in' => sub {
		my $one = ETL::Pipeline->new( {
			input     => 'UnitTest',
			mapping   => {un => 1},
			constants => {deux => 2},
			output    => 'UnitTest'
		} );
		$one->session( good => 1 );
		my $two = $one->chain();
		ok( !$two->is_valid, 'Not valid' );
		is( $two->work_in, undef, 'work_in' );
		is( $two->data_in, undef, 'data_in' );
		is( $two->session( 'good' ), 1, 'session' );
	};
	subtest 'No session' => sub {
		my $one = ETL::Pipeline->new( {
			work_in   => 't',
			data_in   => 'DataFiles',
			input     => 'UnitTest',
			mapping   => {un => 1},
			constants => {deux => 2},
			output    => 'UnitTest'
		} );
		my $two = $one->chain();
		ok( !$two->is_valid, 'Not valid' );
		is( $two->work_in->basename, 't', 'work_in' );
		is( $two->data_in->basename, 'DataFiles', 'data_in' );
		ok( !$two->session_has( 'good' ), 'session' );
	};
};

subtest 'Delegations' => sub {
	my $etl = ETL::Pipeline->new( {
		work_in => 't',
		input   => 'UnitTest',
		mapping => {un => sub {
			my $etl = shift;
			$etl->set( 'fake', $etl->record_number );
			return $etl->get( 1 );
		}},
		output => 'UnitTest',
	} );
	$etl->process;
	
	my $record = $etl->output->get_record( 0 );
	is( $record->{un}, 'Header2', 'get' );
	is( $record->{fake}, 1, 'record_number' );
	pass( 'set' );
};

done_testing();
