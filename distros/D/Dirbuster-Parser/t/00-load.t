#!perl -T

use Test::More tests => 4;
BEGIN {
    use_ok( 'Dirbuster::Parser' );
    use_ok( 'Dirbuster::Parser::Result' );
    use_ok( 'Dirbuster::Parser::Session' );
    use_ok( 'Dirbuster::Parser::ScanDetails' );
}
