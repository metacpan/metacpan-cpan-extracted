use ETL::Pipeline;
use Test::More;


my $etl = ETL::Pipeline->new( {
	input => ['DelimitedText', file => 't/DataFiles/DelimitedText.txt']
} );
$etl->input->configure;
pass( 'configure' );

subtest 'First record' => sub {
	ok( $etl->input->next_record, 'Record loaded' );
	ok( defined $etl->input->record, 'Record has data' );

	is( $etl->input->number_of_fields, 5, 'Five columns' );
	foreach my $field (1 .. 5) {
		my @data = $etl->input->get( $field - 1 );
		is( $data[0], "Field$field", "Found Field$field" );
	}
};

subtest 'Second record' => sub {
	ok( $etl->input->next_record, 'Whitespace allowed' );
	ok( defined $etl->input->record, 'Record has data' );

	is( $etl->input->number_of_fields, 5, 'Five columns' );
	foreach my $field (6 .. 10) {
		my $number = substr $field, -1;
		
		my @data = $etl->input->get( $field - 6 );
		is( $data[0], "Field$number", "Found Field$number" );
	}
};

is( $etl->input->next_record, 0, 'End of file reached' );
$etl->input->finish;

done_testing;
