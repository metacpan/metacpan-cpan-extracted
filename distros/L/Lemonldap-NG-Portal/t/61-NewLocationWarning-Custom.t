use Test::More;
use strict;
use IO::String;

use POSIX qw(locale_h);
use locale;
setlocale( LC_TIME, "C" );

BEGIN {
    eval {
        require 't/test-lib.pm';
        require 't/smtp.pm';
    };
}

my $res;
my $maintests = 5;

SKIP: {
    eval 'require Email::Sender::Simple;';
    if ($@) {
        skip 'Missing dependencies', $maintests;
    }

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel             => 'error',
                useSafeJail          => 1,
                authentication       => 'Demo',
                userDB               => 'Same',
                passwordDB           => 'Demo',
                captcha_mail_enabled => 0,
                portalMainLogo       => 'common/logos/logo_llng_old.png',
                newLocationWarning   => 1,
                loginHistoryEnabled  => 1,
                newLocationWarningMailSubject => 'Test new location mail',
                newLocationWarningMailBody    => 'Test $location $date $ua',
            }
        }
    );

    ## Simple access
    ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Portal', );
    my ( $host, $url, $query ) =
      expectForm( $res, '#', undef, 'user', 'password' );

    ## Authentication #1 with IP #1 (Test 1)
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho'),
            length => 23,
            accept => 'text/html',
        ),
        'First auth query'
    );

    ## Authentication #1 with IP #2 (Test 2)
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho'),
            length => 23,
            accept => 'text/html',
            ip     => '127.0.0.2',
        ),
        'Second auth query'
    );
    like( subject(), qr#Test new location mail#, ' Subject found' );
    like(
        mail(),
qr#^Test 127\.0\.0\.2 \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} Mozilla/5\.0 \(VAX-4000; rv:36\.0\) Gecko/20350101 Firefox$#,
        ' Mail sent (IP, Date and UA found)'
    );
}

count($maintests);
clean_sessions();
done_testing( count() );
