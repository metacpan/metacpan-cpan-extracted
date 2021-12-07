use ETL::Pipeline;
use Test::More;
use Try::Tiny;

my $etl = ETL::Pipeline->new( {
	input   => ['DelimitedText', iname => 'Test 2.txt'],
	mapping => {One => '0'},
	output  => 'UnitTest',
	work_in => 't/DataFiles/FileListing',
} )->process;
is( $etl->input->path->basename, 'Test 2.txt', 'Exact name' );

my $etl = ETL::Pipeline->new( {
	input   => ['DelimitedText', iname => '*.txt'],
	mapping => {One => '0'},
	output  => 'UnitTest',
	work_in => 't/DataFiles/FileListing',
} )->process;
is( $etl->input->path->basename, 'Test 1.txt', 'Wildcard' );

my $etl = ETL::Pipeline->new( {
	input   => ['DelimitedText', iname => qr/\.txt$/],
	mapping => {One => '0'},
	output  => 'UnitTest',
	work_in => 't/DataFiles/FileListing',
} )->process;
is( $etl->input->path->basename, 'Test 1.txt', 'Regular expression' );

try {
	my $etl = ETL::Pipeline->new( {
		input   => ['DelimitedText', iname => 'Invalid.jpg'],
		mapping => {One => '0'},
		output  => 'UnitTest',
		work_in => 't/DataFiles/FileListing',
	} )->process;
	fail( 'No match' );
} catch { pass( 'No match' ) };

done_testing;
