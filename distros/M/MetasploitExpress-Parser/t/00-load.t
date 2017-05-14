#!perl -T

use Test::More tests => 8;
BEGIN {
    use_ok( 'MetasploitExpress::Parser' );
    use_ok( 'MetasploitExpress::Parser::Host' );
    use_ok( 'MetasploitExpress::Parser::Service' );
    use_ok( 'MetasploitExpress::Parser::Event' );
    use_ok( 'MetasploitExpress::Parser::Task' );
    use_ok( 'MetasploitExpress::Parser::Service' );
    use_ok( 'MetasploitExpress::Parser::Session' );
    use_ok( 'MetasploitExpress::Parser::ScanDetails' );
}

