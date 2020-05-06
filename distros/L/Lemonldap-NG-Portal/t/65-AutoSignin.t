use Test::More;
use strict;

require 't/test-lib.pm';

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel        => 'error',
            authentication  => 'Demo',
            userDB          => 'Same',
            autoSigninRules => {
                rtyler => '$env->{REMOTE_ADDR} =~ /^127',
                dwho   => '$env->{REMOTE_ADDR =~ /^127/',
                msmith => '$env->{REMOTE_ADDR} =~ /^127/',
            },
        }
    }
);

ok( $res = $client->_get( '/', ), 'Auth query' );
count(1);
expectOK($res);
my $id = expectCookie($res);

ok( $res = $client->_get( '/', ip => '192.168.1.1' ), 'Bad query' );
count(1);
expectReject($res);
clean_sessions();

done_testing( count() );
