use ETL::Pipeline;
use Test::More;

my $etl = ETL::Pipeline->new( {input => 'UnitTest'} );
ok( defined( $etl->input ), 'Object created' );

$etl->input->configure;
pass( 'configure' );

is( $etl->input->record_number, 0, 'No records loaded' );
$etl->input->next_record;
is( $etl->input->record_number, 1, 'Record count incremented' );

subtest 'stop_if' => sub {
	my $etl = ETL::Pipeline->new( {
		work_in => 't',
		input   => ['UnitTest', stop_if => sub { 
			my @data = shift->get( 0 );
			$data[0] eq 'Field1';
		}],
		mapping => {un => 0, deux => 1, trois => 2},
		output  => 'UnitTest',
	} );
	$etl->process;
	is( $etl->output->record_number, 1, 'Stopped on first record' );
};

subtest 'skip_if' => sub {
	my $etl = ETL::Pipeline->new( {
		work_in => 't',
		input   => ['UnitTest', skip_if => sub { 
			my @data = $_->get( 0 );
			$data[0] eq 'Field1';
		}],
		mapping => {un => 0, deux => 1, trois => 2},
		output  => 'UnitTest',
	} );
	$etl->process;

	is( $etl->output->record_number, 2, 'Loaded 2 of 3 records' );

	my @data = $etl->output->get_record( 0 );
	is( $data[0]->{un}, 'Header1', 'Record 1' );
	
	@data = $etl->output->get_record( 1 );
	is( $data[0]->{un}, 'Field6', 'Record 2' );
};

done_testing;
