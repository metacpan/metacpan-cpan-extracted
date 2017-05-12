use ETL::Pipeline;
use Test::More;


my $check = 0;
sub code { 
	my ($pipeline, $record) = @_;
	$check = $record->{value};
}

my $etl = ETL::Pipeline->new( {output => ['Perl', code => \&code]} );

$etl->output->set( value => 1 );
ok( $etl->output->write_record, 'Code executed' );
is( $check, 1, 'Variable changed' );

$etl->output->set( value => 3, 4, 5 );
$etl->output->write_record;
is( ref( $check ), 'ARRAY', 'Values as list reference' );
is_deeply( $check, [3, 4, 5], 'All values saved' );

done_testing;
