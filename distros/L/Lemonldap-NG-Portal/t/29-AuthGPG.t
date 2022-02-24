use Test::More;
use IO::String;
use strict;

require 't/test-lib.pm';

my $mainTests = 5;

SKIP: {
    skip "Manual skip of GPG test", $mainTests if ( $ENV{LLNG_SKIP_GPG_TEST} );
    eval "use IPC::Run 'run',";
    skip "Missing dependency", $mainTests if ($@);
    my $gpg = `which gpg`;
    skip "Missing gpg", $mainTests if ($@);
    chomp $gpg;
    my $res;
    use_ok('Lemonldap::NG::Common::FormEncode');

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel       => 'error',
                authentication => 'GPG',
                userDB         => 'Null',
                gpgDb          => 't/gpghome/key.asc',
                requireToken   => 1,
            }
        }
    );
    ok( $res = $client->_get( '/', accept => 'text/html' ), 'First access' );
    my ( $host, $url, $query ) =
      expectForm( $res, '#', undef, 'user', 'token' );
    $query =~ s/user=/user=llng\@lemonldap-ng.org/;
    $query =~ /token=([^&]+)/;
    my $token = $1 or fail('No token');
    ok( $res->[2]->[0] =~ /echo -n "$token"/m, "Found instructions" );
    my ( $out, $err );
    run( [ 'gpg', '--clear-sign', '--homedir', 't/gpghome' ],
        \$token, \$out, \$err, IPC::Run::timeout(10) );

    if ( $? == 0 ) {
        pass 'Succeed to sign';
    }
    else {
        run( [ 'gpg', '--clearsign', '--homedir', 't/gpghome' ],
            \$token, \$out, \$err, IPC::Run::timeout(10) );
        unless ( $? == 0 ) {
            skip "Local GPG signature fails, aborting", 2;
        }
        pass("Succeed to sign");
    }
    $query .= '&' . build_urlencoded( password => $out );
    ok(
        $res = $client->_post(
            '/',
            IO::String->new($query),
            length => length($query),
        ),
        'Post data'
    );
    expectOK($res);
    expectCookie($res);
}

clean_sessions( count($mainTests) );
done_testing();
