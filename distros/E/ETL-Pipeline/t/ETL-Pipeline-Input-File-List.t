use ETL::Pipeline;
use Test::More;
use Try::Tiny;

unshift @INC, './t/Modules';

subtest 'Single level' => sub {
	subtest 'Exact name' => sub {
		my $etl = ETL::Pipeline->new( {
			input   => ['+Input', iname => 'Test 2.txt'],
			mapping => {One => 'base'},
			output  => 'UnitTest',
			work_in => 't/DataFiles/FileListing',
		} )->process;
		is( $etl->output->number_of_records, 1, '1 file matched' );

		my $record = $etl->output->get_record( 0 );
		is( $record->{One}, 'Test 2.txt', 'Correct file' );
	};
	subtest 'Wildcard' => sub {
		my $etl = ETL::Pipeline->new( {
			input   => ['+Input', iname => '*.txt'],
			mapping => {One => 'base'},
			output  => 'UnitTest',
			work_in => 't/DataFiles/FileListing',
		} )->process;
		is( $etl->output->number_of_records, 2, '2 files matched' );

		my $record = $etl->output->get_record( 0 );
		is( $record->{One}, 'Test 1.txt', 'First file' );

		my $record = $etl->output->get_record( 1 );
		is( $record->{One}, 'Test 2.txt', 'Second file' );
	};
	subtest 'Regular expression' => sub {
		my $etl = ETL::Pipeline->new( {
			input   => ['+Input', iname => qr/\.txt$/],
			mapping => {One => 'base'},
			output  => 'UnitTest',
			work_in => 't/DataFiles/FileListing',
		} )->process;
		is( $etl->output->number_of_records, 2, '2 files matched' );

		my $record = $etl->output->get_record( 0 );
		is( $record->{One}, 'Test 1.txt', 'First file' );

		my $record = $etl->output->get_record( 1 );
		is( $record->{One}, 'Test 2.txt', 'Second file' );
	};

	my $etl = ETL::Pipeline->new( {
		input   => ['+Input', iname => '*.jpg'],
		mapping => {One => 'base'},
		output  => 'UnitTest',
		work_in => 't/DataFiles/FileListing',
	} )->process;
	is( $etl->output->number_of_records, 0, 'No matches' );
};
subtest 'Recursive search' => sub {
	subtest 'Exact name' => sub {
		my $etl = ETL::Pipeline->new( {
			input   => ['+Input', iname => 'Test 3.txt'],
			mapping => {One => 'base'},
			output  => 'UnitTest',
			work_in => 't/DataFiles/FileListingDepth',
		} )->process;
		is( $etl->output->number_of_records, 1, '1 file matched' );

		my $record = $etl->output->get_record( 0 );
		is( $record->{One}, 'Test 3.txt', 'Correct file' );
	};
	subtest 'Wildcard' => sub {
		my $etl = ETL::Pipeline->new( {
			input   => ['+Input', iname => '*.txt'],
			mapping => {One => 'base'},
			output  => 'UnitTest',
			work_in => 't/DataFiles/FileListingDepth',
		} )->process;
		is( $etl->output->number_of_records, 5, '5 files matched' );

		foreach my $count (1 .. 5) {
			my $record = $etl->output->get_record( $count - 1 );
			is( $record->{One}, "Test $count.txt", "File $count" );
		}
	};
	subtest 'Regular expression' => sub {
		my $etl = ETL::Pipeline->new( {
			input   => ['+Input', iname => qr/\.txt$/],
			mapping => {One => 'base'},
			output  => 'UnitTest',
			work_in => 't/DataFiles/FileListingDepth',
		} )->process;
		is( $etl->output->number_of_records, 5, '5 files matched' );

		foreach my $count (1 .. 5) {
			my $record = $etl->output->get_record( $count - 1 );
			is( $record->{One}, "Test $count.txt", "File $count" );
		}
	};

	my $etl = ETL::Pipeline->new( {
		input   => ['+Input', iname => '*.jpg'],
		mapping => {One => 'base'},
		output  => 'UnitTest',
		work_in => 't/DataFiles/FileListingDepth',
	} )->process;
	is( $etl->output->number_of_records, 0, 'No matches' );
};

done_testing;
