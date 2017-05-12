#!perl -T

use Test::More tests => 6;

BEGIN {
        use_ok( 'XML::Simple' );
        use_ok( 'LWP' );
        use_ok( 'Domain::Register::TK' );

        my $api = Domain::Register::TK->new();

        my $res = $api->ping();
        is($api->status(), 'OK', 'Status is OK');
        is($api->errstr(), undef, 'errstr not defined');
        is($res->{status}, 'PING REPLY', 'Ping reply');

}

diag( "Testing Domain::Register::TK $Domain::Register::TK::VERSION, Perl $], $^X" );
