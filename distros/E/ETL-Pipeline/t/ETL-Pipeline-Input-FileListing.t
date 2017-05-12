use ETL::Pipeline;
use Test::More;


sub value {
	my ($etl, $field) = @_;
	my @data = $etl->input->get( $field );
	return $data[0];
}

subtest 'Simple case' => sub {
	my $etl = ETL::Pipeline->new( {
		work_in => 't/DataFiles/FileListing',
		input   => ['FileListing'],
	} );
	$etl->input->configure;
	pass( 'configure' );

	ok( $etl->input->next_record, 'next_record' );
	is  ( value( $etl, 'File'      ), 'Skip 1.htm'                            , 'get File'      );
	is  ( value( $etl, 'Extension' ), 'htm'                                   , 'get Extension' );
	like( value( $etl, 'Folder'    ), qr|t/DataFiles/FileListing$|i           , 'get Folder'    );
	is  ( value( $etl, 'Inside'    ), '.'                                     , 'get Inside'    );
	is  ( value( $etl, 'Relative'  ), 'Skip 1.htm'                            , 'get Relative'  );
	like( value( $etl, 'Path'      ), qr|t/DataFiles/FileListing/Skip 1.htm$|i, 'get Path'      );

	subtest 'Second file' => sub {
		ok( $etl->input->next_record, 'next_record' );
		is( value( $etl, 'File' ), 'Test 1.txt', 'get File' );
	};

	subtest 'Third file' => sub {
		ok( $etl->input->next_record, 'next_record' );
		is( value( $etl, 'File' ), 'Test 2.txt', 'get File' );
	};

	ok( !$etl->input->next_record, 'end of file' );
	$etl->input->finish;
};

subtest 'File filter' => sub {
	my $etl = ETL::Pipeline->new( {
		work_in => 't/DataFiles/FileListing',
		input   => ['FileListing', name => qr/^Test\s\d\.txt$/i],
	} );
	$etl->input->configure;
	pass( 'configure' );

	subtest 'First file' => sub {
		ok( $etl->input->next_record, 'next_record' );
		is( value( $etl, 'File' ), 'Test 1.txt', 'get File' );
	};

	subtest 'Second file' => sub {
		ok( $etl->input->next_record, 'next_record' );
		is( value( $etl, 'File' ), 'Test 2.txt', 'get File' );
	};

	ok( !$etl->input->next_record, 'end of file' );
	$etl->input->finish;
};

subtest 'Named subdirectory' => sub {
	my $etl = ETL::Pipeline->new( {
		work_in => 't/DataFiles',
		input   => ['FileListing', from => 'FileListing'],
	} );
	$etl->input->configure;
	pass( 'configure' );

	subtest 'First file' => sub {
		ok( $etl->input->next_record, 'next_record' );
		is( value( $etl, 'File' ), 'Skip 1.htm', 'get File' );
	};

	subtest 'Second file' => sub {
		ok( $etl->input->next_record, 'next_record' );
		is( value( $etl, 'File' ), 'Test 1.txt', 'get File' );
	};

	subtest 'Third file' => sub {
		ok( $etl->input->next_record, 'next_record' );
		is( value( $etl, 'File' ), 'Test 2.txt', 'get File' );
	};

	ok( !$etl->input->next_record, 'end of file' );
	$etl->input->finish;
};

subtest 'Search subdirectory' => sub {
	my $etl = ETL::Pipeline->new( {
		work_in => 't/DataFiles',
		input   => ['FileListing', from => qr/Listing$/],
	} );
	$etl->input->configure;
	pass( 'configure' );

	subtest 'First file' => sub {
		ok( $etl->input->next_record, 'next_record' );
		is( value( $etl, 'File' ), 'Skip 1.htm', 'get File' );
	};

	subtest 'Second file' => sub {
		ok( $etl->input->next_record, 'next_record' );
		is( value( $etl, 'File' ), 'Test 1.txt', 'get File' );
	};

	subtest 'Third file' => sub {
		ok( $etl->input->next_record, 'next_record' );
		is( value( $etl, 'File' ), 'Test 2.txt', 'get File' );
	};

	ok( !$etl->input->next_record, 'end of file' );
	$etl->input->finish;
};

done_testing();
