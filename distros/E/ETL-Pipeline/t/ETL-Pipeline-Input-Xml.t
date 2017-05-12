use ETL::Pipeline;
use Test::More;


sub value {
	my ($etl, $field) = @_;
	my @data = $etl->input->get( $field );
	return $data[0];
}

my $etl = ETL::Pipeline->new( {
	work_in => 't/DataFiles',
	input   => ['Xml', matching => 'FM-Export.XML', root => '/RLXML/FILES/FEEDBACK'],
} );
$etl->input->configure;
pass( 'configure' );

ok( $etl->input->next_record, 'next_record' );
is( $etl->input->attribute( 'ACTION' ), 'DELETE', 'attribute' );

subtest 'Second record' => sub {
	ok( $etl->input->next_record, 'next_record' );
	is( value( $etl, 'ROW/DATA/FILESEQUENCEID' ), '12345', 'get' );

	subtest 'Multiple values' => sub {
		my @data = $etl->input->get( 
			'ROW/SUBTABLES/PERSON', 
			'ROW/DATA/LASTNAME'
		);
		is_deeply( \@data, ['DOE', 'Smith'], 'List' );

		my @data = $etl->input->get( 
			'ROW/SUBTABLES/PERSON', 
			'ROW/DATA/LASTNAME', 
			'ROW/DATA/FIRSTNAME',
		);
		is_deeply( \@data, [['DOE', 'JOHN'], ['Smith', 'Fred']], 'Related' );
	};
};	
subtest 'Third record' => sub {
	ok( $etl->input->next_record, 'next_record' );
	is( value( $etl, 'ROW/DATA/FILESEQUENCEID' ), '67890', 'get' );
};
subtest 'Fourth record' => sub {
	ok( $etl->input->next_record, 'next_record' );
	is( value( $etl, 'ROW/DATA/FILESEQUENCEID' ), '15926', 'get' );
};

ok( !$etl->input->next_record, 'end of file' );
$etl->input->finish;

done_testing();
