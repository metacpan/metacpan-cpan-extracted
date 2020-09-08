use lib 'inc';
use Test::More;    # skip_all => 'CAS is in rebuild';
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use MIME::Base64;

BEGIN {
    require 't/test-lib.pm';
}

my $debug = 'error';
my ( $issuer, $res );

eval { require XML::Simple };
plan skip_all => "Missing dependencies: $@" if ($@);

ok( $issuer = issuer(), 'Issuer portal' );
count(1);

ok(
    $res = $issuer->_get(
        '/cas/login',
        query  => 'service=http://auth.sp.com/',
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

my ($query) =
  expectRedirection( $res, qr#^http://auth.sp.com/\?(ticket=[^&]+)$# );

ok(
    $res = $issuer->_get(
        '/cas/p3/serviceValidate',
        query  => 'service=http://auth.sp.com/&' . $query,
        accept => 'text/html'
    ),
    'Query CAS server'
);

expectOK($res);
count(1);

ok( $res->[2]->[0] =~ m#<cas:sn>Accents</cas:sn>#, "Found macro attribute" );
ok( $res->[2]->[0] =~ m#<cas:user>customfrench</cas:user>#,
    "Found cas:user macro value" );
count(2);

clean_sessions();
done_testing( count() );

sub issuer {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel              => $debug,
                domain                => 'idp.com',
                portal                => 'http://auth.idp.com',
                authentication        => 'Demo',
                userDB                => 'Same',
                issuerDBCASActivation => 1,
                casAttr               => 'uid',
                casAppMetaDataOptions => {
                    sp => {
                        casAppMetaDataOptionsService => 'http://auth.sp.com/',
                        casAppMetaDataOptionsUserAttribute => 'customname',
                    },
                },
                casAppMetaDataExportedVars => {
                    sp => {
                        cn   => 'cn',
                        sn   => 'extracted_sn',
                        mail => 'mail',
                        uid  => 'uid',
                    },
                },
                casAppMetaDataMacros => {
                    sp => {
                        extracted_sn => '(split(/\s/, $cn))[1]',
                        customname   => '"custom".$uid',
                    }
                },
                casAccessControlPolicy => 'error',
                multiValuesSeparator   => ';',
            }
        }
    );
}
