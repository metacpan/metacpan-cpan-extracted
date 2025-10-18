use warnings;
use Test::More;
use POSIX 'strftime';
use strict;
use JSON;
use LWP::UserAgent;
use LWP::Protocol::PSGI;

BEGIN {
    require 't/test-lib.pm';
}

my $ban = 0;

my $res;
my $lastAlertTypeIsBan;

LWP::Protocol::PSGI->register(
    sub {
        my $req = Lemonldap::NG::Portal::Main::Request->new(@_);
        if ( $req->path_info eq '/v1/watchers/login' ) {
            my $obj;
            subtest 'Request to login to Crowdsec server', sub {
                ok( $obj = $req->jsonBodyToObj,    'Content is JSON' );
                ok( $obj->{machine_id} eq 'llng',  'Good machine_id' );
                ok( $obj->{password} eq 'llngpwd', 'Good machine password' );
            };
            return [
                200,
                [],
                [
                    to_json( {
                            expire => strftime( "%Y-%m-%dT%H:%M:%SZ", gmtime ),
                            token  => 'aaabbb',
                        }
                    )
                ]
            ];
        }
        elsif ( $req->path_info eq '/v1/alerts' ) {
            if ( $req->method eq 'POST' ) {
                subtest 'Request to push alert', sub {
                    ok( $req->header('Authorization') eq 'Bearer aaabbb',
                        'Authentified request' );
                    my $obj;
                    ok( $obj = $req->jsonBodyToObj, 'Content is JSON' );
                    if ($obj) {
                        ok( (
                                      defined $obj->[0]
                                  and defined $obj->[0]->{remediation}
                            ),
                            'Type of alert is '
                              . ( $obj->[0]->{remediation} ? 'ban' : 'alert' )
                        );
                        $lastAlertTypeIsBan = $obj->[0]->{remediation};
                    }
                    $ban++;
                };
            }
            else {
                subtest 'Request to get alerts list', sub {
                    pass("Ask for alert list");
                };
            }
            return [ 200, [], [] ];
        }
        elsif ( $req->path_info eq '/v1/decisions' ) {
            return [ 200, [], [''] ];
        }
        fail( 'Unknown request ' . $req->path_info );
        return [ 500, [], [] ];
    }
);

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel          => 'error',
            authentication    => 'Demo',
            userDB            => 'Same',
            crowdsecMachineId => 'llng',
            crowdsecPassword  => 'llngpwd',
            crowdsecAgent     => 1,
            crowdsecFilters   => 't/crowdsec-filters',
        }
    }
);

subtest 'Crowdsec ban function', sub {
    my $crowdsec =
      $client->p->loadedModules->{
        'Lemonldap::NG::Portal::Plugins::CrowdSecAgent'};

    ok( $crowdsec->ban( '1.2.3.4', 'Test ban' ), 'Call to ban()' );
    ok( $ban == 1,                               'Ban received' );
    ok( $lastAlertTypeIsBan,                     'Alert type is "ban"' );
};

subtest 'Report auth failures to Crowdsec', sub {
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=bad'),
            length => 22,
        ),
        'Bad auth query'
    );
    expectReject($res);
    ok( $ban == 2,            'Alert received' );
    ok( !$lastAlertTypeIsBan, 'Alert type is "alert"' );
};

subtest 'Report unknown user to Crowdsec', sub {
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=jdoe&password=bad'),
            length => 22,
        ),
        'Bad auth query'
    );
    expectReject($res);
    ok( $ban == 3,            'Alert received' );
    ok( !$lastAlertTypeIsBan, 'Alert type is "alert"' );
};

our %badUrls = (
    'Filter in a sub-directory named url1' => '/bb/.htaccess',
    'Filter type re in main directory'     => '/aa/phpmyadmin',
    'Filter type txt in main directory'    => '/config.php',
);
subtest 'Report bad urls to Crowdsec', sub {
    my $prevBan = $ban;
    foreach my $subtest ( sort keys %badUrls ) {
        my $url = $badUrls{$subtest};
        subtest $subtest => sub {
            ok( $res = $client->_get( $url, accept => 'text/html' ),
                "Test bad url $url" );
            ok( $res->[0] == 404, '404 not found' );
            ok( $res->[2]->[0] =~ /Not found/i )
              or explain( $res->[2], 'Not found' );
            ok( $ban == ++$prevBan, "Bad url detected" );
        };
    }
};

clean_sessions();

done_testing();
