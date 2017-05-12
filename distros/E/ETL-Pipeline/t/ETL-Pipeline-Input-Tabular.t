use ETL::Pipeline;
use Test::More;

push @INC, 't/Modules';

my $etl = ETL::Pipeline->new( {
	work_in   => 't/DataFiles',
	input     => '+TabularInput',
	constants => {one => 1},
	output    => 'UnitTest'
} );
$etl->input->configure;
is( $etl->input->number_of_columns, 4, 'number_of_columns' );
is_deeply( [$etl->input->columns], [qw/Header1 Header2 Header3 Header4/], 'columns' );
subtest 'get by header' => sub {
	sub value {
		my ($etl, @field) = @_;
		my @data = $etl->input->get( @field );
		return $data[0];
	}

	ok( $etl->input->next_record, 'Data loaded' );
	is( value( $etl, 0 ), 'Field1', 'By index' );

	is( value( $etl, qr/head(er)?1/i ), 'Field1', 'Case insensitive' );
	is( value( $etl, qr/2/i          ), 'Field2', 'Partial string'   );
	is( value( $etl, qr/he.*3/i      ), 'Field3', 'Missing middle'   );

	is( value( $etl, qr/zzzz/ ), undef, 'Unmatched regex' );
	is( value( $etl,   'zzzz' ), undef, 'Unmatched string' );
};
$etl->input->finish;

subtest 'no_column_names' => sub {
	my $etl = ETL::Pipeline->new( {
		work_in   => 't/DataFiles',
		input     => ['+TabularInput', no_column_names => 1],
		constants => {one => 1},
		output    => 'UnitTest'
	} );
	$etl->input->configure;
	is( $etl->input->record_number, 0, 'No read' );

	ok( $etl->input->next_record, 'next_record' );
	is( $etl->input->number_of_fields, 4, 'number_of_fields' );
	is_deeply( [$etl->input->fields], [qw/Header1 Header2 Header3/, '  Header4  '], 'fields' );

	$etl->input->finish;
};

subtest 'skipping' => sub {
	subtest 'Int' => sub {
		my $etl = ETL::Pipeline->new( {
			work_in => 't/DataFiles',
			input   => [
				'+TabularInput', 
				no_column_names => 1, 
				skipping        => 2
			],
			constants => {one => 1},
			output    => 'UnitTest'
		} );
		$etl->input->configure;
		is( $etl->input->record_number, 2, 'record_number' );
		$etl->input->finish;
	};
	subtest 'CodeRef' => sub {
		my $etl = ETL::Pipeline->new( {
			work_in   => 't/DataFiles',
			input     => [
				'+TabularInput', 
				no_column_names => 1, 
				skipping        => sub {
					my @data = shift->get( 0 );
					return ($data[0] eq 'Field6' ? 1 : 0);
				}
			],
			constants => {one => 1},
			output    => 'UnitTest'
		} );
		$etl->input->configure;
		is( $etl->input->record_number, 2, 'record_number' );
		$etl->input->finish;
	};
};

done_testing;
