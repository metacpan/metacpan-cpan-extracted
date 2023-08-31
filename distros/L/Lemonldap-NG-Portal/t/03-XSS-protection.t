use warnings;
use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel       => 'error',
            useSafeJail    => 1,
            trustedDomains => 'example3.com *.example2.com'
        }
    }
);

my @tests = (

    # 1 No redirection
    '' => 0, 'Empty',

    # 2 http://test1.example.com/
    'aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tLw==' => 'http://test1.example.com/',
    'Protected virtual host',

    # 3 http://test1.example.com
    'aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29t' => 'http://test1.example.com',
    'Missing / in URL',

    # 4 http://test1.example.com:8000/test
    'aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tOjgwMDAvdGVzdA==' =>
      'http://test1.example.com:8000/test',
    'Non default port',

    # 5 http://test1.example.com:8000/
    'aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tOjgwMDAv' =>
      'http://test1.example.com:8000/',
    'Non default port with missing /',

    # 6 http://t.example2.com/test
    'aHR0cDovL3QuZXhhbXBsZTIuY29tL3Rlc3Q=' => 'http://t.example2.com/test',
    'Undeclared virtual host in trusted domain',

    # 7 http://testexample2.com/
    'aHR0cDovL3Rlc3RleGFtcGxlMi5jb20vCg==' => 0,
    'Undeclared virtual host in untrusted domain'
      . ' (looks like a trusted domain, but is not)',

    # 8 http://test.example3.com/
    'aHR0cDovL3Rlc3QuZXhhbXBsZTMuY29tLwo=' => 0,
    'Undeclared virtual host in untrusted domain (domain name'
      . ' "example3.com" is trusted, but domain "*.example3.com" not)',

    # 9 http://example3.com/
    'aHR0cDovL2V4YW1wbGUzLmNvbS8K' => 'http://example3.com/',
    'Undeclared virtual host with trusted domain name',

    # 10 http://t.example.com/test
    'aHR0cDovL3QuZXhhbXBsZS5jb20vdGVzdA==' => 0,
    'Undeclared virtual host in (untrusted) protected domain',

    # 11
    'http://test.com/' => 0, 'Non base64 encoded characters',

    # 12 http://test.example.com:8000V
    'aHR0cDovL3Rlc3QuZXhhbXBsZS5jb206ODAwMFY=' => 0,
    'Non number in port',

    # 13 http://t.ex.com/test
    'aHR0cDovL3QuZXguY29tL3Rlc3Q=' => 0,
    'Undeclared virtual host in untrusted domain',

    # 14 http://test.example.com/%00
    'aHR0cDovL3Rlc3QuZXhhbXBsZS5jb20vJTAw' => 0, 'Base64 encoded \0',

    # 15 http://test.example.com/test\0
    'aHR0cDovL3Rlc3QuZXhhbXBsZS5jb20vdGVzdAA=' => 0,
    'Base64 and url encoded \0',

    # 16
    'XX%00' => 0, 'Non base64 encoded \0 ',

    # 17 http://test.example.com/test?<script>alert()</script>
    'aHR0cDovL3Rlc3QuZXhhbXBsZS5jb20vdGVzdD88c2NyaXB0PmFsZXJ0KCk8L3NjcmlwdD4='
      => 0,
    'base64 encoded HTML tags',

    # Make sure userinfo does not confuse URL parsing (#2832)
    # https://test1.example.com:test@hacker.com
    'aHR0cHM6Ly90ZXN0MS5leGFtcGxlLmNvbTp0ZXN0QGhhY2tlci5jb20=' => 0,
    'userinfo trick',

    # 22 url=https://hacker.com\@@test1.example.com/
    'aHR0cHM6Ly9oYWNrZXIuY29tXEBAdGVzdDEuZXhhbXBsZS5jb20v' =>
      'https://hacker.com%5C@@test1.example.com/',
    'Good reencoding (2931)',

    # 23 url=https://hacker.com:\@@test1.example.com/
    'aHR0cHM6Ly9oYWNrZXIuY29tOlxAQHRlc3QxLmV4YW1wbGUuY29tLw==' =>
      'https://hacker.com:%5C@@test1.example.com/',
    'Good reencoding (2931)',

    # 24 url='https://hacker.com\anything@test1.example.com/'
    'aHR0cHM6Ly9oYWNrZXIuY29tXGFueXRoaW5nQHRlc3QxLmV4YW1wbGUuY29tLw==' =>
      'https://hacker.com%5Canything@test1.example.com/',
    'Good reencoding (2931)',

    # LOGOUT TESTS
    'LOGOUT',

    # 18 url=http://www.toto.com/, bad referer
    'aHR0cDovL3d3dy50b3RvLmNvbS8=',
    'http://bad.com/' => 0,
    'Logout required by bad site',

    # 19 url=http://www.toto.com/, good referer
    'aHR0cDovL3d3dy50b3RvLmNvbS8=',
    'http://test1.example.com/' => 'http://www.toto.com/',
    'Logout required by good site',

    # 20 url=http://www?<script>, good referer
    'aHR0cDovL3d3dz88c2NyaXB0Pg==',
    'http://test1.example.com/' => 0,
    'script with logout',

    # 21 url=http://www.toto.com/, no referer
    'aHR0cDovL3d3dy50b3RvLmNvbS8=',
    '' => 'http://www.toto.com/',
    'Logout required by good site, empty referer',
);

my $res;
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23
    ),
    'Auth query'
);
count(1);
expectOK($res);
my $id = expectCookie($res);

while ( defined( my $url = shift(@tests) ) ) {
    last if ( $url eq 'LOGOUT' );
    my $redir  = shift @tests;
    my $detail = shift @tests;
    ok(
        $res = $client->_get(
            '/',
            query  => "url=$url",
            cookie => "lemonldap=$id",
            accept => 'text/html'
        ),
        $detail
    );
    if ($redir) {
        expectRedirection( $res, $redir );
    }
    else {
        expectOK($res);
    }
    count(1);
}

while ( defined( my $url = shift(@tests) ) ) {
    my $referer = shift @tests;
    my $redir   = shift @tests;
    my $detail  = shift @tests;
    ok(
        $res = $client->_get(
            '/',
            query  => "url=$url&logout=1",
            cookie => "lemonldap=$id",

            accept  => 'text/html',
            referer => $referer,
        ),
        $detail
    );
    if ($redir) {
        expectRedirection( $res, $redir );
    }
    else {
        expectOK($res);
    }
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho'),
            length => 23
        ),
        'Auth query'
    );
    expectOK($res);
    $id = expectCookie($res);
    count(2);
}

clean_sessions();

done_testing( count() );
__END__

# LOGOUT CASES
$logout = 1;
while ( defined( $url = shift(@h) ) ) {
    my $referer = shift @h;
    $result = shift @h;
    my $text = shift @h;
    $ENV{HTTP_REFERER} = $referer;

    ok( $p->controlUrlOrigin() == $result, $text );
}
