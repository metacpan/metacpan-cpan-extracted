use Test::More;

BEGIN {
    use_ok( 'KiokuDB::Backend::Redis' );
}

diag( "Testing KiokuDB::Backend::Redis $KiokuDB::Backend::Redis::VERSION, Perl $], $^X" );

done_testing;