use ETL::Pipeline;
use Test::More;

my $etl = ETL::Pipeline->new( {
	input   => ['Xml', path => 'FM-Export.XML', records_at => '/RLXML/FILES/FEEDBACK'],
	mapping => {One => '/ROW/DATA/FILESEQUENCEID/value', Two => '/ROW/SUBTABLES/PERSON'},
	output  => 'UnitTest',
	work_in => 't/DataFiles',
} )->process;
is( $etl->count, 3, 'All records processed' );

my $output = $etl->output->get_record( 0 );
is( $output->{One}, '12345', 'Individual value' );
is( $output->{Two}, undef  , 'Repeating node'   );

done_testing();
