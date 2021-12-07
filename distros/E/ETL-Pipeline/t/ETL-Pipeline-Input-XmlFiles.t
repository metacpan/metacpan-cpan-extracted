use ETL::Pipeline;
use Test::More;

subtest 'Process files' => sub {
	my $etl = ETL::Pipeline->new( {
		input   => ['XmlFiles', iname => '*.xml'],
		mapping => {
			One => '/FeedbackFile/Row/Data/PK/value',
			Two => '/FeedbackFile/Row/SubTables/Feedback/Row/SubTables/FeedbackFollowups/Row',
		},
		output  => 'UnitTest',
		work_in   => 't/DataFiles/XmlFiles',
	} )->process;
	is( $etl->count, 2, 'All records processed' );

	my $output = $etl->output->get_record( 0 );
	is( $output->{One}, '1234', 'Individual value' );
	is( $output->{Two}, undef , 'Repeating node'   );
};
subtest 'Records at' => sub {
	my $etl = ETL::Pipeline->new( {
		input   => ['XmlFiles', iname => '*.xml', records_at => '/FeedbackFile/Row'],
		mapping => {
			One => '/Data/PK/value',
			Two => '/SubTables/Feedback/Row/SubTables/FeedbackFollowups/Row',
		},
		output  => 'UnitTest',
		work_in => 't/DataFiles/XmlFiles',
	} )->process;
	is( $etl->count, 2, 'All records processed' );

	my $output = $etl->output->get_record( 0 );
	is( $output->{One}, '1234', 'Individual value' );
	is( $output->{Two}, undef , 'Repeating node'   );
};
subtest 'File search' => sub {
	my $etl = ETL::Pipeline->new( {
		input   => ['XmlFiles', iname => '*.xml'],
		mapping => {One => sub { shift->input->path->basename }},
		output  => 'UnitTest',
		work_in => 't/DataFiles/XmlFiles',
	} )->process;

	my $output = $etl->output->get_record( 0 );
	is( $output->{One}, '1234.xml', 'First file' );
	$output = $etl->output->get_record( 1 );
	is( $output->{One}, '5678.xml', 'Second file' );
};

done_testing();
