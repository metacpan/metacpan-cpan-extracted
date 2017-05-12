# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Portal.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

package My::Portal;
use strict;
use Test::More tests => 22;

BEGIN {
    use_ok( 'Lemonldap::NG::Portal::Simple', ':all' );
    sub Lemonldap::NG::Portal::Simple::lmLog { }
}

#use Lemonldap::NG::Portal::Simple;

our @ISA = 'Lemonldap::NG::Portal::Simple';
my ( $url, $result, $logout );
$logout = 0;
my @h = (

    '' => PE_OK, 'Empty',

    # 4 http://test.example.com/
    'aHR0cDovL3Rlc3QuZXhhbXBsZS5jb20v' => PE_OK, 'Protected virtual host',

    # 5 http://test.example.com
    'aHR0cDovL3Rlc3QuZXhhbXBsZS5jb20v' => PE_OK, 'Missing / in URL',

    # 6 http://test.example.com:8000/test
    'aHR0cDovL3Rlc3QuZXhhbXBsZS5jb206ODAwMC90ZXN0' => PE_OK, 'Non default port',

    # 7 http://test.example.com:8000/
    'aHR0cDovL3Rlc3QuZXhhbXBsZS5jb206ODAwMA==' => PE_BADURL,
    'Non default port with missing /',

    # 8 http://t.example2.com/test
    'aHR0cDovL3QuZXhhbXBsZTIuY29tL3Rlc3Q=' => PE_OK,
    'Undeclared virtual host in trusted domain',

    # 9 http://testexample2.com/
    'aHR0cDovL3Rlc3RleGFtcGxlMi5jb20vCg==' => PE_BADURL,
    'Undeclared virtual host in untrusted domain'
      . ' (looks like a trusted domain, but is not)',

    # 10 http://test.example3.com/
    'aHR0cDovL3Rlc3QuZXhhbXBsZTMuY29tLwo=' => PE_BADURL,
    'Undeclared virtual host in untrusted domain (domain name'
      . ' "example3.com" is trusted, but domain "*.example3.com" not)',

    # 11 http://example3.com/
    'aHR0cDovL2V4YW1wbGUzLmNvbS8K' => PE_OK,
    'Undeclared virtual host with trusted domain name',

    # 12 http://t.example.com/test
    'aHR0cDovL3QuZXhhbXBsZS5jb20vdGVzdA==' => PE_BADURL,
    'Undeclared virtual host in (untrusted) protected domain',

    # 13
    'http://test.com/' => PE_BADURL, 'Non base64 encoded characters',

    # 14 http://test.example.com:8000V
    'aHR0cDovL3Rlc3QuZXhhbXBsZS5jb206ODAwMFY=' => PE_BADURL,
    'Non number in port',

    # 15 http://t.ex.com/test
    'aHR0cDovL3QuZXguY29tL3Rlc3Q=' => PE_BADURL,
    'Undeclared virtual host in untrusted domain',

    # 16 http://test.example.com/%00
    'aHR0cDovL3Rlc3QuZXhhbXBsZS5jb20vJTAw' => PE_BADURL, 'Base64 encoded \0',

    # 17 http://test.example.com/test\0
    'aHR0cDovL3Rlc3QuZXhhbXBsZS5jb20vdGVzdAA=' => PE_BADURL,
    'Base64 and url encoded \0',

    # 18
    'XX%00' => PE_BADURL, 'Non base64 encoded \0 ',

    # 19 http://test.example.com/test?<script>alert()</script>
    'aHR0cDovL3Rlc3QuZXhhbXBsZS5jb20vdGVzdD88c2NyaXB0PmFsZXJ0KCk8L3NjcmlwdD4='
      => PE_BADURL,
    'base64 encoded HTML tags',

    # LOGOUT TESTS
    'LOGOUT',

    # 20 url=http://www.toto.com/, bad referer
    'aHR0cDovL3d3dy50b3RvLmNvbS8=',
    'http://bad.com/' => PE_BADURL,
    'Logout required by bad site',

    # 21 url=http://www.toto.com/, good referer
    'aHR0cDovL3d3dy50b3RvLmNvbS8=',
    'http://test.example.com/' => PE_OK,
    'Logout required by good site',

    # 22 url=http://www?<script>, good referer
    'aHR0cDovL3d3dz88c2NyaXB0Pg==',
    'http://test.example.com/' => PE_BADURL,
    'script with logout',
);

my $count = 0;

sub param {
    shift;
    my $p = shift;
    $count++;
    if ( $p and $p eq 'url' ) {
        return $url;
    }
    else {
        return $logout;
    }
}

my $p;

# CGI Environment
$ENV{SCRIPT_NAME}     = '/test.pl';
$ENV{SCRIPT_FILENAME} = '/tmp/test.pl';
$ENV{REQUEST_METHOD}  = 'GET';
$ENV{REQUEST_URI}     = "/test.pl";
$ENV{QUERY_STRING}    = "";

ok(
    $p = My::Portal->new(
        {
            globalStorage  => 'Apache::Session::File',
            domain         => 'example.com',
            authentication => 'LDAP test=1',
            userDB         => 'Null',
            passwordDB     => 'Null',
            registerDB     => 'Null',
            domain         => 'example.com',
            trustedDomains => '.example2.com example3.com',
            checkXSS       => 1,
        }
    ),
    'Portal object'
);

$p->{reVHosts} = '(?:test\.example\.com)';

while ( defined( $url = shift(@h) ) ) {
    last if ( $url eq 'LOGOUT' );
    $result = shift @h;
    my $text = shift @h;

    ok( $p->controlUrlOrigin() == $result, $text );
}

# LOGOUT CASES
$logout = 1;
while ( defined( $url = shift(@h) ) ) {
    my $referer = shift @h;
    $result = shift @h;
    my $text = shift @h;
    $ENV{HTTP_REFERER} = $referer;

    ok( $p->controlUrlOrigin() == $result, $text );
}
