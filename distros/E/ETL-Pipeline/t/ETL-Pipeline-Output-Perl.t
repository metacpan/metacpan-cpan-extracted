use ETL::Pipeline;
use Test::More;


my $run = 0;
my $etl = ETL::Pipeline->new( {
	constants => {value => 1},
	input     => 'UnitTest',
	output    => ['Perl', code => sub { $run = 1 }],
	work_in => 't/DataFiles',
} )->process;
ok( $run, 'Code executed' );

done_testing;
