use ETL::Pipeline;
use Test::More;

subtest 'Process files' => sub {
	my $etl = ETL::Pipeline->new( {
		input   => ['JsonFiles', iname => '*.json'],
		mapping => {One => '/PK', Two => '/Data'},
		output  => 'UnitTest',
		work_in => 't/DataFiles/JsonFiles',
	} )->process;
	is( $etl->count, 3, 'All records processed' );

	my $output = $etl->output->get_record( 0 );
	is( $output->{One}, '1234', 'Individual value' );
	is( $output->{Two}, undef , 'Repeating node'   );
};
subtest 'Records at' => sub {
	my $etl = ETL::Pipeline->new( {
		input   => ['JsonFiles', iname => '*.json', records_at => '/'],
		mapping => {One => '/PK', Two => '/Data'},
		output  => 'UnitTest',
		work_in => 't/DataFiles/JsonFiles',
	} )->process;
	is( $etl->count, 3, 'All records processed' );

	my $output = $etl->output->get_record( 0 );
	is( $output->{One}, '1234', 'Individual value' );
	is( $output->{Two}, undef , 'Repeating node'   );
};
subtest 'File search' => sub {
	my $etl = ETL::Pipeline->new( {
		input   => ['JsonFiles', iname => '*.json'],
		mapping => {One => sub { shift->input->path->basename }},
		output  => 'UnitTest',
		work_in => 't/DataFiles/JsonFiles',
	} )->process;

	my $output = $etl->output->get_record( 0 );
	is( $output->{One}, '1234.json', 'First file' );
	$output = $etl->output->get_record( 2 );
	is( $output->{One}, '5678.json', 'Second file' );
};

done_testing();
