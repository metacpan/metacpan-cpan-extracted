use ETL::Pipeline;
use Test::More;

push @INC, './t/Modules';

my $etl = ETL::Pipeline->new( {
	work_in   => 't/DataFiles',
	input     => ['+FileInput', matching => qr/\.txt/],
	constants => {one => 1},
	output    => 'UnitTest',
} );
is( $etl->input->file->basename, 'DelimitedText.txt', 'matching regular expression' );

my $etl = ETL::Pipeline->new( {
	work_in   => 't/DataFiles',
	input     => ['+FileInput', matching => '*.txt'],
	constants => {one => 1},
	output    => 'UnitTest',
} );
is( $etl->input->file->basename, 'DelimitedText.txt', 'matching glob' );

my $etl = ETL::Pipeline->new( {
	work_in   => 't/DataFiles',
	input     => ['+FileInput', matching => sub { shift; shift->basename =~ m/\.txt/i; }],
	constants => {one => 1},
	output    => 'UnitTest',
} );
is( $etl->input->file->basename, 'DelimitedText.txt', 'matching code reference' );

my $etl = ETL::Pipeline->new( {
	work_in   => 't/DataFiles',
	input     => ['+FileInput', file => 'DelimitedText.txt'],
	constants => {one => 1},
	output    => 'UnitTest',
} );
is( $etl->input->file->basename, 'DelimitedText.txt', 'file' );

done_testing;
