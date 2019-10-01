use lib 'inc';
use strict;
use File::Temp 'tempdir';
use IO::String;
use JSON;
use MIME::Base64;
use Test::More;

our $debug = 'error';
my ( $p, $res, $spId );
$| = 1;

$LLNG::TMPDIR = tempdir( 'tmpSessionXXXXX', DIR => 't/sessions', CLEANUP => 1 );

require 't/separate-handler.pm';

require "t/test-lib.pm";

ok( $p = issuer(), 'Issuer portal' );
count(1);

# BEGIN TESTS
ok( $res = handler( req => [ GET => 'http://test2.example.com/' ] ),
    'Simple request to handler' );
ok( getHeader( $res, 'WWW-Authenticate' ) eq 'Basic realm="LemonLDAP::NG"',
    'Get WWW-Authenticate header' );
count(2);

my $subtest = 0;
foreach my $user (qw(dwho rtyler)) {
    ok(
        $res = handler(
            req => [
                GET => 'http://test2.example.com/',
                [
                    'Authorization' => 'Basic '
                      . encode_base64( "$user:$user", '' )
                ]
            ],
            sub => sub {
                my ($res) = @_;
                $subtest++;
                subtest 'REST request to Portal' => sub {
                    plan tests => 3;
                    ok( $res->[0] eq 'POST', 'Get POST request' );
                    my ( $url, $query ) = split /\?/, $res->[1];
                    ok(
                        $res = $p->_post(
                            $url, IO::String->new( $res->[3] ),
                            length => length( $res->[3] ),
                            query  => $query,
                        ),
                        'Push request to portal'
                    );
                    ok( $res->[0] == 200, 'Response is 200' );
                    return $res;
                };
                count(1);
                return $res;
            },
        ),
        'AuthBasic request'
    );
    count(1);
    expectOK($res);
    expectAuthenticatedAs( $res, $user );
}
ok( $subtest == 2, 'REST requests were done by handler' );
count(1);

foreach my $user (qw(dwho rtyler)) {
    ok(
        $res = handler(
            req => [
                GET => 'http://test2.example.com/',
                [
                    'Authorization' => 'Basic '
                      . encode_base64( "$user:$user", '' )
                ]
            ],
            sub => sub {
                $subtest++;
                fail "Cache didn't work";
                return [ 500, [], [] ];
            },
        ),
        'New AuthBasic request'
    );
    ok( $subtest == 2, 'Handler used its local cache' );
    count(2);
    expectOK($res);
    expectAuthenticatedAs( $res, $user );
}

end_handler();
clean_sessions();
done_testing( count() );

sub issuer {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel          => $debug,
                domain            => 'idp.com',
                portal            => 'http://auth.idp.com',
                authentication    => 'Demo',
                userDB            => 'Same',
                restSessionServer => 1,
            }
        }
    );
}
