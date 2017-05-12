use ETL::Pipeline;
use Test::More;


my $etl = ETL::Pipeline->new( {output => 'UnitTest'} );
ok( defined( $etl->output ), 'Object created' );

$etl->output->configure;
ok( defined( $etl->output->current ), 'new_record after configure' );

is( $etl->output->record_number, 0, 'No records saved' );
$etl->output->write_record;
is( $etl->output->record_number, 1, 'Record count incremented' );
is( scalar( %{$etl->output->current} ), 0, 'new_record after write_record' );

ok( !$etl->output->error( 'Message' ), 'error returns false' );

done_testing;
