use warnings;
use Test::More;    # skip_all => 'CAS is in rebuild';
use strict;
use IO::String;
use URI;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use MIME::Base64;

BEGIN {
    require 't/test-lib.pm';
}

my $debug = 'error';
my ( $issuer, $res );

ok( $issuer = issuer(), 'Issuer portal' );
count(1);

ok(
    $res = $issuer->_get(
        '/cas/login',
        query => buildForm(
            { service => 'http://auth.sp.com/a,%22b?param1=1&param2=2' }
        ),
        accept => 'text/html'
    ),
    'Query CAS server'
);
count(1);
expectOK($res);
my $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

# Try to authenticate to IdP
my $body = $res->[2]->[0];
$body =~ s/^.*?<form.*?>//s;
$body =~ s#</form>.*$##s;
my %fields =
  ( $body =~ /<input type="hidden".+?name="(.+?)".+?value="(.*?)"/sg );
$fields{user} = $fields{password} = 'french';
use URI::Escape;
my $s = join( '&', map { "$_=" . uri_escape( $fields{$_} ) } keys %fields );
ok(
    $res = $issuer->_post(
        '/cas/login',
        IO::String->new($s),
        cookie => $pdata,
        accept => 'text/html',
        length => length($s),
    ),
    'Post authentication'
);
count(1);
my $idpId = expectCookie($res);

# Expect pdata to be cleared
$pdata = expectCookie( $res, 'lemonldappdata' );
ok( $pdata !~ 'issuerRequestsaml', 'SAML request cleared from pdata' );
count(1);

my $target =
  getHtmlElement( $res, '//form[@id="form"]' )->shift->getAttribute("action");
my $u = URI->new($target);
is( $u->host, "auth.sp.com", "Correct destination host" );
is( $u->path, "/a,%22b",     "Correct destination path" );
count(2);

# Check order of params, expectForm is not enough
my @params = map { $_->getAttribute("name") => $_->getAttribute("value") }
  getHtmlElement( $res, '//form[@id="form"]//input[@type="hidden"]' );

my $st = pop(@params);
is_deeply( [@params], [qw/param1 1 param2 2 ticket/] );
count(1);

ok(
    $res = $issuer->_get(
        '/cas/validate',
        query => buildForm( {
                service => 'http://auth.sp.com/a,%22b?param1=1&param2=2',
                ticket  => $st
            }
        ),
        accept => 'text/html'
    ),
    'Query CAS server'
);

expectOK($res);
count(1);

my @resp = split /\n/, $res->[2]->[0];

ok( $resp[0] eq 'yes', 'Ticket is valid' );
count(1);
ok( $resp[1] eq 'french', 'Username is returned' );
count(1);

clean_sessions();
done_testing( count() );

sub issuer {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel               => $debug,
                domain                 => 'idp.com',
                portal                 => 'http://auth.idp.com/',
                authentication         => 'Demo',
                userDB                 => 'Same',
                issuerDBCASActivation  => 1,
                casAttr                => 'uid',
                casAttributes          => { cn => 'cn', uid => 'uid', },
                casAccessControlPolicy => 'none',
                multiValuesSeparator   => ';',
                jsRedirect             => 1,
            }
        }
    );
}
