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
	pass 'Script ran';

	is $etl->count, 2, 'Two records';
	subtest 'First record' => sub {
		my $record = $etl->output->get_record( 0 );
		my @keys   = keys %$record;

		is scalar( @keys )    , 4               , '4 fields'      ;
		is $record->{un      }, 'Field1'        , 'Found Field1'  ;
		is $record->{deux    }, 'Field2'        , 'Found Field2'  ;
		is $record->{trois   }, 'Field3'        , 'Found Field3'  ;
		is $record->{constant}, 'String literal', 'Found constant';
	};
	subtest 'Second record' => sub {
		my $record = $etl->output->get_record( 1 );
		my @keys   = keys %$record;

		is scalar( @keys )    , 4               , '4 fields'      ;
		is $record->{un      }, 'Field11'       , 'Found Field11' ;
		is $record->{deux    }, 'Field12'       , 'Found Field12' ;
		is $record->{trois   }, 'Field13'       , 'Found Field13' ;
		is $record->{constant}, 'String literal', 'Found constant';
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

		ok !$two->is_valid                     , 'Not valid';
		is $two->work_in->basename, 't'        , 'work_in'  ;
		is $two->data_in->basename, 'DataFiles', 'data_in'  ;
		is $two->session( 'good' ), 1          , 'session'  ;
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

		ok !$two->is_valid               , 'Not valid';
		is $two->work_in          , undef, 'work_in'  ;
		is $two->data_in          , undef, 'data_in'  ;
		is $two->session( 'good' ), 1    , 'session'  ;
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

		ok !$two->is_valid                          , 'Not valid';
		is $two->work_in->basename     , 't'        , 'work_in'  ;
		is $two->data_in->basename     , 'DataFiles', 'data_in'  ;
		ok !$two->session_has( 'good' )             , 'session'  ;
	};
};

subtest 'data_in' => sub {
	my $etl = ETL::Pipeline->new( {work_in => 't'} );

	$etl->data_in( 'DataFiles' );
	is $etl->data_in->basename, 'DataFiles', 'Fixed directory';

	$etl->data_in( qr/^DataFiles$/i );
	is $etl->data_in->basename, 'DataFiles', 'Search for subfolder';
};

subtest 'Fixed module names' => sub {
	unshift @INC, './t/Modules';
	my $etl = ETL::Pipeline->new;

	$etl->input( '+Input' );
	ok defined( $etl->input ), 'Input';

	$etl->output( '+Output' );
	ok defined( $etl->output ), 'Output';
};

subtest 'is_valid' => sub {
	subtest 'No work_in' => sub {
		my $etl = ETL::Pipeline->new( {
			input   => 'UnitTest',
			mapping => {un => 1},
			output  => 'UnitTest',
		} );
		ok !$etl->is_valid, 'Boolean return';

		my @error = $etl->is_valid;
		ok !$error[0], 'Return code'                   ;
		is  $error[1], 'The working folder was not set';
	};
	subtest 'No input' => sub {
		my $etl = ETL::Pipeline->new( {
			work_in => 't',
			mapping => {un => 1},
			output  => 'UnitTest',
		} );
		ok !$etl->is_valid, 'Boolean return';

		my @error = $etl->is_valid;
		ok !$error[0], 'Return code'                   ;
		is  $error[1], 'The "input" object was not set';
	};
	subtest 'No output' => sub {
		my $etl = ETL::Pipeline->new( {
			work_in => 't',
			input   => 'UnitTest',
			mapping => {un => 1},
		} );
		ok !$etl->is_valid, 'Boolean return';

		my @error = $etl->is_valid;
		ok !$error[0], 'Return code'                    ;
		is  $error[1], 'The "output" object was not set';
	};
	subtest 'No mapping' => sub {
		my $etl = ETL::Pipeline->new( {
			work_in => 't',
			input   => 'UnitTest',
			output  => 'UnitTest',
		} );
		ok !$etl->is_valid, 'Boolean return';

		my @error = $etl->is_valid;
		ok !$error[0], 'Return code'            ;
		is  $error[1], 'The mapping was not set';
	};
	subtest 'Valid' => sub {
		my $etl = ETL::Pipeline->new( {
			work_in => 't',
			input   => 'UnitTest',
			mapping => {un => 1},
			output  => 'UnitTest',
		} );
		ok $etl->is_valid, 'Boolean return';

		my @error = $etl->is_valid;
		ok $error[0]       , 'Return code';
		is $error[1], undef, 'No message' ;
	};
	subtest 'Constants, no mapping' => sub {
		my $etl = ETL::Pipeline->new( {
			work_in   => 't',
			input     => 'UnitTest',
			constants => {un => 1},
			output    => 'UnitTest',
		} );
		ok $etl->is_valid, 'Boolean return';

		my @error = $etl->is_valid;
		ok $error[0]       , 'Return code';
		is $error[1], undef, 'No message' ;
	};
};

subtest 'mapping' => sub {
	my $etl = ETL::Pipeline->new( {
		work_in => 't',
		input   => 'UnitTest',
		mapping => {un => '/*[0]'},
		output  => 'UnitTest',
	} )->process;
	my $output = $etl->output->get_record( 0 );
	is $output->{un}, 'Field1', 'Data path';

	$etl = ETL::Pipeline->new( {
		work_in => 't',
		input   => 'UnitTest',
		mapping => {un => qr/1/},
		output  => 'UnitTest',
	} )->process;
	$output = $etl->output->get_record( 0 );
	is $output->{un}, 'Field1', 'Regular expression';

	$etl = ETL::Pipeline->new( {
		work_in => 't',
		input   => 'UnitTest',
		mapping => {un => 0},
		output  => 'UnitTest',
	} )->process;
	$output = $etl->output->get_record( 0 );
	is $output->{un}, 'Field1', 'Bare field number';

	$etl = ETL::Pipeline->new( {
		work_in => 't',
		input   => 'UnitTest',
		mapping => {un => 'Header1'},
		output  => 'UnitTest',
	} )->process;
	$output = $etl->output->get_record( 0 );
	is $output->{un}, 'Field1', 'Bare field name';

	subtest 'Multiple fields' => sub {
		my $etl = ETL::Pipeline->new( {
			work_in => 't',
			input   => 'UnitTest',
			mapping => {un => 'Header6'},
			output  => 'UnitTest',
		} )->process;
		my $output = $etl->output->get_record( 0 );
		is $output->{un}, 'Field6; Field7', 'Bare field name';

		$etl = ETL::Pipeline->new( {
			work_in => 't',
			input   => 'UnitTest',
			mapping => {un => qr/der6/},
			output  => 'UnitTest',
		} )->process;
		$output = $etl->output->get_record( 0 );
		is $output->{un}, 'Field6; Field7', 'Regular expression';
	};

	subtest 'Code reference' => sub {
		my ($pipeline, $record);
		my $etl = ETL::Pipeline->new( {
			work_in => 't',
			input   => 'UnitTest',
			mapping => {un => sub { ($pipeline, $record) = @_; return 'abc'; }},
			output  => 'UnitTest',
		} )->process;

		is ref( $pipeline ), 'ETL::Pipeline', 'Pipeline in parameters';
		is ref( $record   ), 'ARRAY'        , 'Record in parameters'  ;

		my $output = $etl->output->get_record( 0 );
		is $output->{un}, 'abc', 'Return value';
	};

	$etl = ETL::Pipeline->new( {
		work_in => 't',
		input   => 'UnitTest',
		mapping => {un => '/invalid'},
		output  => 'UnitTest',
	} )->process;
	$output = $etl->output->get_record( 0 );
	is $output->{un}, undef, 'Not found';

	subtest 'Custom mapping' => sub {
		$etl = ETL::Pipeline->new( {
			work_in => 't',
			input   => 'UnitTest',
			mapping => sub { {un => 'string'} },
			output  => 'UnitTest',
		} )->process;
		$output = $etl->output->get_record( 0 );
		is $output->{un}, 'string', 'Returns HASH reference';
		
		$etl = ETL::Pipeline->new( {
			work_in => 't',
			input   => 'UnitTest',
			mapping => sub { undef },
			output  => 'UnitTest',
		} )->process;
		$output = $etl->output->get_record( 0 );
		is scalar( %$output ), 0, 'Empty record';

		subtest 'With constants' => sub {
			$etl = ETL::Pipeline->new( {
				work_in   => 't',
				input     => 'UnitTest',
				constants => {deux => 'other'},
				mapping   => sub { {un => 'string'} },
				output    => 'UnitTest',
			} )->process;
			$output = $etl->output->get_record( 0 );
			is $output->{un  }, 'string', 'Returns HASH reference';
			is $output->{deux}, 'other' , 'Constant set';

			$etl = ETL::Pipeline->new( {
				work_in   => 't',
				input     => 'UnitTest',
				constants => {deux => 'other'},
				mapping   => sub { undef },
				output    => 'UnitTest',
			} )->process;
			$output = $etl->output->get_record( 0 );
			is $output->{un  }, undef  , 'Empty record';
			is $output->{deux}, 'other', 'Constant still set';
		};
	};
};

subtest 'on_record' => sub {
	subtest 'Skip records' => sub {
		my $etl = ETL::Pipeline->new( {
			work_in   => 't',
			input     => 'UnitTest',
			mapping   => {un => 0},
			on_record => sub { return (shift->count == 1 ? 1 : 0); },
			output    => 'UnitTest',
		} )->process;

		is $etl->output->number_of_records, 1, 'Loaded 1 of 2 records';
		is $etl->count                    , 2, 'Count bypassed record';

		my $output = $etl->output->get_record( 0 );
		is $output->{un}, 'Field1', 'Record 1';
	};
	subtest 'Change record content' => sub {
		my $etl = ETL::Pipeline->new( {
			work_in   => 't',
			input     => 'UnitTest',
			mapping   => {un => 0},
			on_record => sub { my ($p, $r) = @_; $r->[0] = uc( $r->[0] ); },
			output    => 'UnitTest',
		} )->process;
		is $etl->count, 2, 'Loaded 2 of 2 records';

		my $output = $etl->output->get_record( 0 );
		is $output->{un}, 'FIELD1', 'Value changed';
	};
};

subtest 'session' => sub {
	my $etl = ETL::Pipeline->new;

	subtest 'Not set' => sub {
		ok !$etl->session_has( 'bad' )       , 'exists';
		is  $etl->session( 'bad' )    , undef, 'get'   ;
	};
	subtest 'Single value' => sub {
		is $etl->session( good => 3 ), 3, 'set'   ;
		is $etl->session( 'good' )   , 3, 'get'   ;
		ok $etl->session_has( 'good' )  , 'exists';
	};
	subtest 'Multiple values' => sub {
		$etl->session( okay => 4, maybe => 5 );
		ok $etl->session_has( 'okay' )    , 'First exists' ;
		is $etl->session( 'okay' )     , 4, 'First value'  ;
		ok $etl->session_has( 'maybe' )   , 'Second exists';
		is $etl->session( 'maybe' )    , 5, 'Second value' ;
	};
	subtest 'References' => sub {
		$etl->session( many => [7, 8, 9] );
		subtest 'Scalar context' => sub {
			my $scalar = $etl->session( 'many' );
			is  ref( $scalar ), 'ARRAY'  , 'get'   ;
			is_deeply $scalar , [7, 8, 9], 'values';
		};
		subtest 'List context' => sub {
			my @list = $etl->session( 'many' );
			is_deeply \@list, [7, 8, 9], 'values';
		};
	};
	subtest 'Overwrite' => sub {
		is $etl->session( 'good', 6 ), 6, 'set';
		is $etl->session( 'good' )   , 6, 'get';
	};
};

subtest 'work_in' => sub {
	my $etl = ETL::Pipeline->new;

	$etl->work_in( 't' );
	is $etl->work_in->basename, 't', 'Fixed directory';
	is $etl->data_in->basename, 't', 'data_in set'    ;

	$etl->work_in( iname => 't' );
	is $etl->work_in->basename, 't', 'Search current directory';

	$etl->work_in( root => 't', iname => 'DataFiles' );
	is $etl->work_in->basename, 'DataFiles', 'Search other directory';

	$etl->work_in( root => 't', iname => 'Data*' );
	is $etl->work_in->basename, 'DataFiles', 'File glob';

	$etl->work_in( root => 't', iname => qr/^DataFiles$/i );
	is $etl->work_in->basename, 'DataFiles', 'Regular expression';

	$etl->work_in( root => 't/DataFiles', iname => 'F*' );
	is $etl->work_in->basename, 'FileListing', 'Alphabetical order';
};

subtest 'Utility functions' => sub {
	subtest 'coalesce' => sub {
		my $etl = ETL::Pipeline->new( {
			work_in => 't',
			input   => 'UnitTest',
			mapping => {
				One   => sub { shift->coalesce( '/*[0]' , '/*[1]'     ) },
				Two   => sub { shift->coalesce( '/*[16]', '/*[1]'     ) },
				Three => sub { shift->coalesce( '/*[16]', \'constant' ) },
				Four  => sub { shift->coalesce( \'   '  , \'constant' ) },
			},
			output  => 'UnitTest',
		} )->process;
		my $output = $etl->output->get_record( 0 );

		is $output->{One  }, 'Field1'  , 'No NULL fields'       ;
		is $output->{Two  }, 'Field2'  , 'First non-NULL field' ;
		is $output->{Three}, 'constant', 'String constant'      ;
		is $output->{Four }, 'constant', 'First non-space field';
	};
	subtest 'format' => sub {
		my $etl = ETL::Pipeline->new( {
			work_in => 't',
			input   => 'UnitTest',
			mapping => {
				One   => sub { shift->format( '-'     , 0, 1                   ) },
				Two   => sub { shift->format( '-'     , 0, 22, 1               ) },
				Three => sub { shift->format( \'%s+%s', 0, 1                   ) },
				Four  => sub { shift->format( '-'     , 0, ['+'     , 1, 2], 3 ) },
				Five  => sub { shift->format( '-'     , 0, [\'%s+%s', 1, 2], 3 ) },
				Six   => sub { shift->format( sub { $_ eq 'Field3' }, '-', 0, 1, 2, 3 ) },
				Seven => sub { shift->format( '-', 0, [sub { $_ eq 'Field3' }, '+', 1, 2, 3], 4 ) },
			},
			output  => 'UnitTest',
		} )->process;
		my $output = $etl->output->get_record( 0 );

		is $output->{One  }, 'Field1-Field2'              , 'Combine'             ;
		is $output->{Two  }, 'Field1-Field2'              , 'Leave out blanks'    ;
		is $output->{Three}, 'Field1+Field2'              , 'Format'              ;
		is $output->{Four }, 'Field1-Field2+Field3-Field4', 'Sub-combine'         ;
		is $output->{Five }, 'Field1-Field2+Field3-Field4', 'Sub-format'          ;
		is $output->{Six  }, 'Field1-Field2'              , 'Conditional stop'    ;
		is $output->{Seven}, 'Field1-Field2-Field5'       , 'Sub-conditional stop';
	};
	subtest 'from' => sub {
		my %test = (Field2 => [8, 9], Field3 => 1, Field4 => {A => 2});
		my $etl = ETL::Pipeline->new( {
			work_in => 't',
			input   => 'UnitTest',
			mapping => {
				One   => sub { shift->from( \%test, '/*[2]'       ) },
				Two   => sub { shift->from( \%test, '/*[3]', \'A' ) },
				Three => sub { join ' ', shift->from( \%test, '/*[1]' ) },
			},
			output  => 'UnitTest',
		} )->process;
		my $output = $etl->output->get_record( 0 );

		is $output->{One  }, 1    , 'Single key'       ;
		is $output->{Two  }, 2    , 'Multiple key'     ;
		pass                        'Constant key'     ;
		is $output->{Three}, '8 9', 'List dereferenced';
	};
	subtest 'name' => sub {
		my $etl = ETL::Pipeline->new( {
			work_in => 't',
			input   => 'UnitTest',
			mapping => {
				One   => sub { shift->name(           0 , 1  ) },
				Two   => sub { shift->name(           18, 19 ) },
				Three => sub { shift->name( \'%s+%s', 0 , 1  ) },
				Four  => sub { shift->name( 0, 1, [2]                ) },
				Five  => sub { shift->name( 0, 1, [2, 3]             ) },
				Six   => sub { shift->name( 0, 1, [\'(%s/%s)', 2, 3] ) },
				Seven => sub { shift->name( 0, 1, [['+', 2, 3]]      ) },
				Eight => sub { shift->name( 0                        ) },
			},
			output  => 'UnitTest',
		} )->process;
		my $output = $etl->output->get_record( 0 );

		is $output->{One  }, 'Field1, Field2'                , 'last, first'            ;
		is $output->{Two  }, ''                              , 'No names'               ;
		is $output->{Three}, 'Field1+Field2'                 , 'Formatted name'         ;
		is $output->{Four }, 'Field1, Field2 (Field3)'       , 'last, first (role)'     ;
		is $output->{Five }, 'Field1, Field2 (Field3)'       , 'Multiple roles'         ;
		is $output->{Six  }, 'Field1, Field2 (Field3/Field4)', 'Formatted role'         ;
		is $output->{Seven}, 'Field1, Field2 (Field3+Field4)', 'Pass through to "build"';
		is $output->{Eight}, 'Field1'                        , 'No dangling comma'      ;
	};
	subtest 'piece' => sub {
		my $etl = ETL::Pipeline->new( {
			work_in => 't',
			input   => 'UnitTest',
			mapping => {
				One   => sub { shift->piece( 0, qr/l/, 1                 ) },
				Two   => sub { shift->piece( 0, qr/l/, 2                 ) },
				Three => sub { shift->piece( 0, qr/l/, -1                ) },
				Four  => sub { shift->piece( 0, qr/l/, '1,2'             ) },
				Five  => sub { shift->piece( 0, qr/l/, '1,2,-'           ) },
				Six   => sub { shift->piece( 0, qr/l/, '1,,-'            ) },
				Seven => sub { shift->piece( 0, qr/l/, 1      , qr/i/, 1 ) },
				Eight => sub { shift->piece( 0, qr/l/, 20                ) },
			},
			output  => 'UnitTest',
		} )->process;
		my $output = $etl->output->get_record( 0 );

		is $output->{One  }, 'Fie'   , 'First'                      ;
		is $output->{Two  }, 'd1'    , 'Second'                     ;
		is $output->{Three}, 'd1'    , 'Last'                       ;
		is $output->{Four }, 'Fie d1', 'First and second'           ;
		is $output->{Five }, 'Fie-d1', 'Seperator'                  ;
		is $output->{Six  }, 'Fie-d1', 'First to end with seperator';
		is $output->{Seven}, 'F'     , 'First of the first'         ;
		is $output->{Eight}, ''      , 'Non-existent'               ;
	};
	subtest 'replace' => sub {
		my $etl = ETL::Pipeline->new( {
			work_in => 't',
			input   => 'UnitTest',
			mapping => {
				One => sub { shift->replace( 0, qr/e/, 'z' ) },
				Two => sub { shift->replace( 0, 'i'  , 'z' ) },
			},
			output  => 'UnitTest',
		} )->process;
		my $output = $etl->output->get_record( 0 );

		is $output->{One}, 'Fizld1', 'Regular expression';
		is $output->{Two}, 'Fzeld1', 'String'            ;
	};

	my $etl = ETL::Pipeline->new( {
		work_in => 't',
		input   => '+Input',
		mapping => {One => sub { shift->foreach( sub { shift->get( '/b' ) }, '/sub' ) }},
		output  => 'UnitTest',
	} )->process;
	my $output = $etl->output->get_record( 0 );
	is $output->{One}, '2', 'foreach';
};


done_testing();
