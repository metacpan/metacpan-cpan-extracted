#!perl -T

use Test::More tests => 5;

BEGIN {
    use_ok('REST::Client');
    use_ok('URI::Escape');
    use_ok( 'XML::Simple' );
    use_ok( 'Domain::Register::DomainShare' );

    my $api = Domain::Register::DomainShare->new();
    my @res = $api->ping();
    is($res[0], 1, 'Status is OK');
}

diag( "Testing Domain::Register::DomainShare $Domain::Register::DomainShare::VERSION, Perl $], $^X" );
