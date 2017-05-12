use Test::More tests => 4;

BEGIN {
    use_ok( 'IO::Mark' );
    use_ok( 'IO::Mark::Buffer' );
    use_ok( 'IO::Mark::Cache' );
    use_ok( 'IO::Mark::SlaveBuffer' );

}

diag( "Testing IO::Mark $IO::Mark::VERSION" );
