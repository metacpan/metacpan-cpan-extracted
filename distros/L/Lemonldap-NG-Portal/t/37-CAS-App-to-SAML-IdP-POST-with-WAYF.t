use lib 'inc';
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use MIME::Base64;

BEGIN {
    require 't/test-lib.pm';
    require 't/saml-lib.pm';
}

my $maintests = 13;
my $debug     = 'error';
my ( $idp, $proxy, $app, $res );
my %handlerOR = ( idp => [], proxy => [], app => [] );

# Redefine LWP methods for tests
LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);
        ok( $req->uri =~ m#http://auth.(app|proxy).com([^\?]*)(?:\?(.*))?$#,
            'SOAP request' );
        my $host  = $1;
        my $url   = $2;
        my $query = $3;
        my $res;
        my $client = ( $host eq 'app' ? $app : $proxy );
        if ( $req->method eq 'POST' ) {
            my $s = $req->content;
            ok(
                $res = $client->_post(
                    $url, IO::String->new($s),
                    length => length($s),
                    query  => $query,
                    type   => 'application/xml',
                ),
                "Execute POST request to $url"
            );
        }
        else {
            ok(
                $res = $client->_get(
                    $url,
                    type  => 'application/xml',
                    query => $query,
                ),
                "Execute request to $url"
            );
        }
        expectOK($res);
        ok( getHeader( $res, 'Content-Type' ) =~ m#xml#, 'Content is XML' )
          or explain( $res->[1], 'Content-Type => application/xml' );
        count(3);
        return $res;
    }
);

SKIP: {
    eval "use Lasso;use XML::Simple";
    if ($@) {
        skip 'Lasso or XML::Simple not found', $maintests;
    }

    # Initialization
    switch ('idp');
    ok( $idp = idp(), 'IdP portal' );
    $handlerOR{idp} = \@Lemonldap::NG::Handler::Main::_onReload;

    switch ('proxy');
    &Lemonldap::NG::Handler::Main::cfgNum( 0, 0 );
    ok( $proxy = proxy(), 'Proxy portal' );
    $handlerOR{proxy} = \@Lemonldap::NG::Handler::Main::_onReload;

    switch ('app');
    &Lemonldap::NG::Handler::Main::cfgNum( 0, 0 );
    ok( $app = app(), 'CAS app portal' );
    $handlerOR{app} = \@Lemonldap::NG::Handler::Main::_onReload;

    # Query RP for auth
    ok( $res = $app->_get( '/', accept => 'text/html' ),
        'Unauth CAS app request' );
    ok( expectCookie( $res, 'llngcasserver' ) eq 'proxy',
        'Get CAS server cookie' );
    my ( $url, $query ) =
      expectRedirection( $res, qr#http://auth.proxy.com(/cas/login)\?(.*)$# );

    # Push request to Proxy
    switch ('proxy');
    ok(
        $res = $proxy->_get(
            $url,
            query  => $query,
            accept => 'text/html',
        ),
        "Push request to proxy"
    );
    my $proxyPdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

    ( $url, $query ) =
      expectRedirection( $res, qr#^http://discovery.example.com/# );

    # Return from WAYF
    ok(
        $res = $proxy->_get(
            "/",
            query  => "idp=" . uri_escape("http://auth.idp.com/saml/metadata"),
            accept => 'text/html',
            cookie => $proxyPdata,
        ),
        "Return from WAYF"
    );

    $proxyPdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

    my ( $host, $tmp );
    ( $host, $url, $query ) =
      expectAutoPost( $res, 'auth.idp.com', '/saml/singleSignOn',
        'SAMLRequest' );

    switch ('idp');
    ok(
        $res = $idp->_post(
            $url,
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Launch SAML request to IdP'
    );
    my $idpPdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

    # Try to authenticate to IdP
    my $body = $res->[2]->[0];
    $body =~ s/^.*?<form.*?>//s;
    $body =~ s#</form>.*$##s;
    my %fields =
      ( $body =~ /<input type="hidden".+?name="(.+?)".+?value="(.*?)"/sg );
    $fields{user} = $fields{password} = 'french';
    use URI::Escape;
    $query =
      join( '&', map { "$_=" . uri_escape( $fields{$_} ) } keys %fields );
    ok(
        $res = $idp->_post(
            $url,
            IO::String->new($query),
            accept => 'text/html',
            length => length($query),
            cookie => $idpPdata,
        ),
        'Post authentication'
    );

    ( $host, $url, $query ) = expectAutoPost($res);
    $query =~ s/\+/%2B/g;
    my $idpId = expectCookie($res);

    # Expect pdata to be cleared
    $idpPdata = expectCookie( $res, 'lemonldappdata' );
    ok( $idpPdata !~ 'issuerRequestsaml', 'SAML request cleared from pdata' );

    # Post SAML response
    switch ('proxy');
    ok(
        $res = $proxy->_post(
            $url, IO::String->new($query),
            length => length($query),
            accept => 'text/html',
            cookie =>
              "lemonldapidp=http://auth.idp.com/saml/metadata;$proxyPdata",
        ),
        'POST SAML response'
    );
    my $spId = expectCookie($res);
    ($url) = expectRedirection( $res, qr#http://auth.proxy.com([^?]*)# );
    ok(
        $res = $proxy->_get(
            $url,
            accept => 'text/html',
            cookie =>
"lemonldapidp=http://auth.idp.com/saml/metadata;lemonldap=$spId;$proxyPdata",
        ),
        'Follow internal redirection'
    );

    ($query) =
      expectRedirection( $res, qr#^http://auth.app.com/\?(ticket.*)$# );

    # Follow redirection to App
    switch ('app');
    ok( $res = $app->_get( '/', query => $query, accept => 'text/html' ),
        'Follow redirection to RP' );
    my $appId = expectCookie($res);
}

count($maintests);
clean_sessions();
done_testing( count() );

sub switch {
    my $type = shift;
    pass( '==> Switching to ' . uc($type) . ' <==' );
    count(1);
    @Lemonldap::NG::Handler::Main::_onReload = @{
        $handlerOR{$type};
    };
}

sub idp {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel               => $debug,
                domain                 => 'idp.com',
                portal                 => 'http://auth.idp.com',
                authentication         => 'Demo',
                userDB                 => 'Same',
                issuerDBSAMLActivation => 1,
                samlSPMetaDataOptions  => {
                    'proxy.com' => {
                        samlSPMetaDataOptionsEncryptionMode           => 'none',
                        samlSPMetaDataOptionsSignSSOMessage           => 1,
                        samlSPMetaDataOptionsSignSLOMessage           => 1,
                        samlSPMetaDataOptionsCheckSSOMessageSignature => 1,
                        samlSPMetaDataOptionsCheckSLOMessageSignature => 1,
                    }
                },
                samlSPMetaDataExportedAttributes => {
                    'proxy.com' => {
                        cn =>
'1;cn;urn:oasis:names:tc:SAML:2.0:attrname-format:basic',
                        uid =>
'1;uid;urn:oasis:names:tc:SAML:2.0:attrname-format:basic',
                    }
                },
                samlOrganizationDisplayName => "IDP",
                samlOrganizationName        => "IDP",
                samlOrganizationURL         => "http://www.idp.com/",
                samlServicePrivateKeyEnc    => "-----BEGIN RSA PRIVATE KEY-----
MIIEogIBAAKCAQEAnfKBDG/K0TnGT7Xu8q1N45sNWvIK91SqNg8nvN2uVeKoHADT
csus5Xn3id5+8Q9TuMFsW9kIEeXiaPKXQa9ryfSNDhWDWloNkpGEeWif2BnHUu46
Abu1UBWb0mH6VwcG1PR4qHruLis1odjQ1qnVDNfSEASVIppEBYjDX203ypmURIzU
6h53GRRRlf1BLWkbVn9ysmDeR57Xw5Rsx/+tBlcnMrkv/40DSUkehQIl2JmlFrl2
Caik+gU4pd20apA/pNLjBZF0OmGoS08AIR5NMd0KFa6CwZUUSHJqH5GFy5Y2yl4l
g8K0klAS9q7L7aXI+eFQZhkwidjpxXnHPyxIGQIDAQABAoIBAHnfqjX3eO8SfnP5
NURp90Td2mNHirCn0qLd9NKl1ySMPR1GgeH9SQ7Umu32EcteAUL5dOw2PiTZVmeW
cKINgsWVftXUQcOQ4xIqWKb51QUBdy0FhxrZRSFjWxXt5iYK1PmzHfsax/g1/S9C
RnqtFyjOy1bywkSt9jiy+9YBR2B7BDhLHlILbijWn5zaecaV4YA+L1UK4M/mehdb
+0FVPavbGpnlqBRTY+7YXfZ/mRPCfn5DvO9lW1O0pJMmNdBh9kmm3DxHf6AkK47a
43gO/dRWiWo2rZ/+Jw7uyqOb23U0MydP7kia0p3tzCUBPsrlgnichYG5RNFp0wqy
3VT1TYECgYEA0Y9vENy1jJd+s7WbGrsRtSKxfZgtJr0yjSlQVYrIlwbZSGn+ndxq
V2vVlwIgLX3pz6T40BMfk6SNx08jjy0Sgn6OAM0ILrinno8yWcSAMCmfCU0S/3O1
55bqtcnk4XTHBHzJ5OrnrPaW5ourvJz0lcWEKMg3BXxLzaF6ZRy85nECgYEAwPMD
LNAKLCDrUMyYFOpPyPLe7wvszcFvPipGgerSgFP1c6N7xaMUdHDYqBfuis1khPGF
YcMHeNBYmzX6yEGbp3lrB4PHpUySmTU3mv3u9I05aahInK21gXum3uRkCWyyIF6V
T/qeszl9mVOCp0CC4eG3IMVpaD0UKDEHVhERYCkCgYAjuTPRyA4a3Wh38ilysRkf
q75eDqcDx5Tqg3RyYKo5NK2troP9HSnzpSpQB8i8eI53G0RfFCN5479XjqIdMi3J
mRFUCZ+vd0L7wKVwsBK6Ix49U6o9adhElnGEc9pUpLeYiD1SjMjZr1+iBYVNLeRz
86vH1/mpMbsqXrCis/dvwQKBgGttomHr/w3s0jftget7PirrFrbP0+wHfDGHhjRF
kyhCFtJovrwefYALaIXGtVjw3LusYZA570oT7pGUb2naJZkMYEwR0jG1vZWx7KDO
K6JbkxDB0pPxn7JVL2bAkPYyX8boAohCSOQO6WBZ/8+xem3bp4OGhpa0EyoBik0g
OaVpAoGATj4SyYsE10hGT676iie8zy3fi5IPC3E+x4QlVuusaLtuY8LJA50stjtx
gUa/JAKlZZL+gvzvOviQIxyfIChXOdTt5uiOYkdHJDbAF3NSrji7hrXq4v8UZv75
8hBrwJZIpy6y01dRlrriHmPRtEq1pk7JX2uUg0sP5g4BEcsaCbc=
-----END RSA PRIVATE KEY-----
",
                samlServicePrivateKeySig => "-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAtR/wgDqWB4Maho5V6TjcL/NbNfjgIh7GcgkrB5RZcVT1GTej
JlMjUQdgBKBuZXQN+7/29P6UcGq1kYalURq6S8SpeJ1ofp5rBEoD/TIkvU0JOcid
65wp+fdzXGXsfiZvHraU74jSCgjP/wqfVGRyBIQzB0SIxSpnrsigqNsE1E94toDM
x4wovjHu/9ABAImREV7Sz83OeFF00/sghrjTEJOD/gHf04JCn9MgNOqvSTysr9LX
Wg/oUKQDEYeTq9ux6pq/oqv1MxwONbSZPtN5yD41mi+hT8Rh+W8Je8rsiML4VMxz
sb1l9303asw6suo5bLTISKNSbu1nt1NkpNxzywIDAQABAoIBAQCQkbvPPfP+bwC/
IeEk1IO7qkzFWa7czR+safD0jc6OjTdNN4F716Q6yt4zEzLKu8VliiW+C23EBQiD
7asKf4DvdTun0ExVtHDK7aEdeealSlXwz1ZtdypyILbtq1UGo/rR0v4x601rQPl0
IrBmFf6D6FkqleNtLJmxguXpoVfLdYKNwkxH2ux+GOA9r2o5pUCQmJGDap5YWRuQ
uB71ewJjVWujaL3e1ac/5cP7/tqWmgAiOaN8sYdD6+oWOR47bHj8JKcMBSl4y2QC
dL31cGmmf5KqBbtISki3RXfHHjT7E3Z85CbESkKTZlEb1ar3XmepY6Z7V5UO16oz
fFE5R6khAoGBAOl9Qb+qYVVO5ugE65ORjYVeuXykANhM9ssiY5a6zuAakWzw7Zv3
k6PXm9p7azlEXAlTnTXVwHYMyuuzZDvQ8LRV1iBOdPuIkUAmaQ5K9ASD7VcoHexh
k8DAKf9Ln7sTRaMdvgceRNczOmJOBIEpTZkssA/jVGXZsoyTWYl1en/ZAoGBAMaW
RnNbSNprEV2b8UeAJ6i77c4SXwu1I8X2NLtiLScb1ETBjfrdHmdlJglfyd/0gmhH
p/43Ku2iGUoY5KtuOI6QmahrJYQscRQhoj252VXadG6fNWWAlpgdCm9houhHb5BF
3zge/bTr0anUe9EA7Z/ymav12rEouoNjIlhI9C5DAoGATR85a2SMt8/TB0owwdJu
62GpZNkLCmcJkXkvaecUVAOSi2hdI4o4MwMRkK35cbX5rH74y4JqCtQY5pefgP53
sykzDAK+MyMdzxGg2764MRGegI5Yq+5jDmSquo+xF+q6srEtRk6iMG7UVwosBLmu
zuxqzySoiOfKSRKWnYe3SakCgYEAwWMkVkAmETXE4oDzFSsS8/mW2l//mPocTTK3
JWe1CunJ6+8FYbAlZJEW2ngismp8+CoXybNVpbZ+pC7buKoMf6EHUgCNt0pEEFO0
mCG9KSMk0XlPWXpArP9S4yaUq1itpzSz7QYZES+4rIcU0HLz9RgeWFyCTJWaFErc
7laVG9sCgYBKOtk5WlIOP4BxSd2y4cYzohgwTZIs1/2kTEn1u4eH73M1xvAlHHFB
wSF5QXgDKJ8pPAOhNWpdLO/PdtnQn91nOvTNc+ShJZzjdbneUdQVpWpoBf72uA+N
6rIVf1JBUL2p7HFHaGdUZC7KGQ+yv6ZHrE1+7202nuDvJdvGEEdFsQ==
-----END RSA PRIVATE KEY-----
",
                samlServicePublicKeyEnc => "-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAnfKBDG/K0TnGT7Xu8q1N
45sNWvIK91SqNg8nvN2uVeKoHADTcsus5Xn3id5+8Q9TuMFsW9kIEeXiaPKXQa9r
yfSNDhWDWloNkpGEeWif2BnHUu46Abu1UBWb0mH6VwcG1PR4qHruLis1odjQ1qnV
DNfSEASVIppEBYjDX203ypmURIzU6h53GRRRlf1BLWkbVn9ysmDeR57Xw5Rsx/+t
BlcnMrkv/40DSUkehQIl2JmlFrl2Caik+gU4pd20apA/pNLjBZF0OmGoS08AIR5N
Md0KFa6CwZUUSHJqH5GFy5Y2yl4lg8K0klAS9q7L7aXI+eFQZhkwidjpxXnHPyxI
GQIDAQAB
-----END PUBLIC KEY-----
",
                samlServicePublicKeySig => "-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAtR/wgDqWB4Maho5V6Tjc
L/NbNfjgIh7GcgkrB5RZcVT1GTejJlMjUQdgBKBuZXQN+7/29P6UcGq1kYalURq6
S8SpeJ1ofp5rBEoD/TIkvU0JOcid65wp+fdzXGXsfiZvHraU74jSCgjP/wqfVGRy
BIQzB0SIxSpnrsigqNsE1E94toDMx4wovjHu/9ABAImREV7Sz83OeFF00/sghrjT
EJOD/gHf04JCn9MgNOqvSTysr9LXWg/oUKQDEYeTq9ux6pq/oqv1MxwONbSZPtN5
yD41mi+hT8Rh+W8Je8rsiML4VMxzsb1l9303asw6suo5bLTISKNSbu1nt1NkpNxz
ywIDAQAB
-----END PUBLIC KEY-----
",
                samlSPMetaDataXML => {
                    "proxy.com" => {
                        samlSPMetaDataXML =>
                          samlSPMetaDataXML( 'proxy', 'HTTP-POST' )
                    },
                },
            }
        }
    );
}

sub proxy {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel              => $debug,
                domain                => 'proxy.com',
                portal                => 'http://auth.proxy.com',
                authentication        => 'SAML',
                userDB                => 'Same',
                issuerDBCASActivation => 1,
                casAttr               => 'uid',
                casAttributes => { cn => 'cn', uid => 'uid', mail => 'mail', },
                casAccessControlPolicy   => 'none',
                multiValuesSeparator     => ';',
                samlDiscoveryProtocolURL => 'http://discovery.example.com/',
                samlDiscoveryProtocolActivation   => 1,
                samlIDPMetaDataExportedAttributes => {
                    idp => {
                        mail => "0;mail;;",
                        uid  => "1;uid",
                        cn   => "0;cn"
                    },
                    idp2 => {
                        mail => "0;mail;;",
                        uid  => "1;uid",
                        cn   => "0;cn"
                    }
                },
                samlIDPMetaDataOptions => {
                    idp => {
                        samlIDPMetaDataOptionsEncryptionMode => 'none',
                        samlIDPMetaDataOptionsSSOBinding     => 'post',
                        samlIDPMetaDataOptionsSLOBinding     => 'post',
                        samlIDPMetaDataOptionsSignSSOMessage => 1,
                        samlIDPMetaDataOptionsSignSLOMessage => 1,
                        samlIDPMetaDataOptionsCheckSSOMessageSignature => 1,
                        samlIDPMetaDataOptionsCheckSLOMessageSignature => 1,
                        samlIDPMetaDataOptionsForceUTF8                => 1,
                    },
                    idp2 => {
                        samlIDPMetaDataOptionsEncryptionMode => 'none',
                        samlIDPMetaDataOptionsSSOBinding     => 'post',
                        samlIDPMetaDataOptionsSLOBinding     => 'post',
                        samlIDPMetaDataOptionsSignSSOMessage => 1,
                        samlIDPMetaDataOptionsSignSLOMessage => 1,
                        samlIDPMetaDataOptionsCheckSSOMessageSignature => 1,
                        samlIDPMetaDataOptionsCheckSLOMessageSignature => 1,
                        samlIDPMetaDataOptionsForceUTF8                => 1,
                    }
                },
                samlIDPMetaDataExportedAttributes => {
                    idp => {
                        "uid" => "0;uid;;",
                        "cn"  => "1;cn;;",
                    },
                    idp2 => {
                        "uid" => "0;uid;;",
                        "cn"  => "1;cn;;",
                    },
                },
                samlIDPMetaDataXML => {
                    idp => {
                        samlIDPMetaDataXML =>
                          samlIDPMetaDataXML( 'idp', 'HTTP-POST' )
                    },
                    idp2 => {
                        samlIDPMetaDataXML =>
                          samlIDPMetaDataXML( 'idp2', 'HTTP-POST' )
                    }
                },
                samlOrganizationDisplayName => "SP",
                samlOrganizationName        => "SP",
                samlOrganizationURL         => "http://www.proxy.com",
                samlServicePublicKeySig     => "-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAu4iToYAEmWQxgZDihGVz
MMql1elPn37domWcvXeU2E4yt2hh5jkQHiFjgodfOlNeRIw5QJVlUBwr+CQvbaKR
FXd7BrOhQIDC0TZPRVB0XHarUtsCuDekN4/2GKSzHsoToKUVPWq9thsuek3xkpsJ
GZNX7bglfEc9+QQpYTqN1rkdN1PVU0epNMokFFGho5pLRqLUV5+I/QXAL49jfTja
Sxsp4UndTI8/+mGSRSq+nrT2zyQRM/vkj5vR9ZVz67HO/+Wk3Mx6RAwkVcMdgMAq
Cq8odmbI0yCRZiTL9ybKWRKqWJoKJ0p5+Q2fPEBPupQZR09Jt/JPuLVSsGfCxi9N
qwIDAQAB
-----END PUBLIC KEY-----
",
                samlServicePrivateKeyEnc => "-----BEGIN RSA PRIVATE KEY-----
MIIEogIBAAKCAQEAsRaod2RZ8hMFBl+VhsnhyPM8l/Fj1obnBxfQIaWuHFIFfXiG
e/CYHuZ5QJQLnZxHMJX6LL3Sh+Usog3p0jpijpcg0QgfBSEkfopKTgReYN8DiDIl
l0rV1XdTni7E85Nd1YyNy3ui/ZD+UShWwqu6jLVLR+QUm+/1LIKYb3OCBTvOlY7x
HoP6NSU1+Mr+YzGBUacdO2vnNxe/PQhxIeP1zO0njuqGHkwEpy8rUWRZbbDn31Tm
Kjqlhgtsz5HPhbRaYEExhyepKgBiNz+RyxtYXVhuG8OrWQDoS5gYHSjdw1CTJyix
eJwyoqA9RGYguG5nh9zndi3LWAh7Z0lx+tIz+wIDAQABAoIBAEkZrk8iiJKJ0WAx
IrsyKNbXuWKLTYgnxcRCyzKofrfID+YcU39j8JeI0fKbajQUZ7qhnlTLwtU//+2h
SqzyVu6/add/v7ZRWQw3L7cGzKK2THHzKVtLk/t7N3QroDdf1LMrQvkFP2HmcWS0
/yN62hXtXHb/qpY4Nn+6JQyUpM5dkv8S/QjDl2NTdyWrXKzWp+4I3QLQ20f4zym+
ir7RennziMc0HlQNcTjGAUbFULtdqEfSFWhNK7UjiRY+S0XV2xJIbGjnxUQH62fS
w1ZzYsF7sBtoSckvfL4WfGbylhOVnliU05RLU2c67PRjj1Gskoslq1Ow/3DHR7rI
BSBpV8ECgYEA1eHfcog7xQGDkW+cshJtFPFx+9MegB58gFW1rl0rn+tfbexvoSEA
7G7EOTyaU6OAI+8StiRT6AYTgEU7PMM9zDykdGIWj3h0OpHGA86xhEiiaaM2DDRv
/DEKRVlEdmRLLLY28pJVHOMYomia3mb2VKZGg2VfGtSfjg1GXD3I8OECgYEA0/X0
U55KjZ1JQTPUgFc1WK1NxX9MaH+NcpDaolEUy3Qf3QTbfws+a9K3vwCn7EpQhrfs
I6RVUtwFdCyfl/jzBY9Gykkg03sMgW7Qw2SCCsSt05M+jDtBbNJ7esP6PAeKFvXZ
ZWhdeiAa4kM/P6gtvZXQ4tY4LkSbcd6b0SzzFFsCgYBjMsusFzuBd95JyfZnMNye
5gzzu0teKMWd0CLfqB7foQ81sH9lwCTpg8ZGtbDuMdrwz6ViDR9NceQBjhqXaAZ1
f3rW79d+22Ms9wdcJLV4oSeSzzv2FSwLT8NvvqNeNc4YArshbnVDXKDEUrfhhueh
Ay2ZK58clpkaDVYg2hckgQKBgG3KuhtSI/YE4fwXN9yez7A2XNGPZem/IGqWo9lu
PGJCrXqT2IqPLW82gB083r6jo+CUhonTxqqb82tA7g4PUvqvQ5Dmnk1NMKYe255K
gp3HUO8GF2EWFIak5Hcr6oOLuDi6cjh3/euTk7ld8fYsTD0mzEOjiQhWW1p5X6bT
LLp/AoGAHvkxA1NM1HJ3myAREbwNXxRy/nhNt4mwMkZ6hPQsW/Eg/3r7j6MJOFrm
U8AJJjDGKe6nlXhhnMoQfJzAc0cYNgjktmJXW27fHGIwt/2QwYNFHPK3s7HTrfH6
7T4XKT3yGeeeyC2soKJQPlGB+ETdIUnXa7eo9KVWtMTgISyx1Qk=
-----END RSA PRIVATE KEY-----
",
                samlServicePrivateKeySig => "-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAu4iToYAEmWQxgZDihGVzMMql1elPn37domWcvXeU2E4yt2hh
5jkQHiFjgodfOlNeRIw5QJVlUBwr+CQvbaKRFXd7BrOhQIDC0TZPRVB0XHarUtsC
uDekN4/2GKSzHsoToKUVPWq9thsuek3xkpsJGZNX7bglfEc9+QQpYTqN1rkdN1PV
U0epNMokFFGho5pLRqLUV5+I/QXAL49jfTjaSxsp4UndTI8/+mGSRSq+nrT2zyQR
M/vkj5vR9ZVz67HO/+Wk3Mx6RAwkVcMdgMAqCq8odmbI0yCRZiTL9ybKWRKqWJoK
J0p5+Q2fPEBPupQZR09Jt/JPuLVSsGfCxi9NqwIDAQABAoIBABE0Cjb6g3F+23vD
SsRSeiqzrFrfOEqtXK+VGrfWzHS7V7Ozg6eW/H+HGJXUzUuQcklfg7EFA3JB41a0
GxW3oA+UElkfCV/dcAG5NbRqGQKScEz9glZb5FikgDLqiPP+HabS/gvQSu71t2HI
3KxSRJdwCNTp26Z28pxxYUpmELTtxd9vlHjffit2Mnt2uc8hOtFHdNavfYwvYH7o
bmlckp7b/JVOy2Yy21O94ZWkE498jXyn71Gr+V1cnJ0RrmYbhQqIvFpFHj98Pf4O
if3c4YmBcZ4t7PUsZUYF3ooWt8k/mdigQC3D6p80OKe+wUTYKcCN0ZdFbiURv9pg
CsqLh+ECgYEA9vA+9QfzvXC7S5yXgTkuRiusPlNye/AiyA/0oGjmjFZ1YNsT7awH
6BjW6WE+rS4elKJu1GaefM/cDguH4ZmJc+eKgi4LDCqYw9rr9les3aneBc8demd3
O/Ej1Pud1QxXArBNfBYo08vEqwST9P89clJC5090U6bGK2E0rTVu1w0CgYEAwmpG
9LbOFeGCPmwX7Avuk7tQQfRSV6q9TFZo+HxDfKYvxec846l1vBenY2rrgYhtolYJ
YS795LYgbSWRxGfgr1GuIbP5GsjHy6/1o6bS8M++GJ7KHArb0QLAYyQweqqb164A
NvHJkveueWnxzeOlD9j2fcjEnBHwTnqjG+17CZcCgYEAqMXawa4FsNxzpmIISpHC
RsNindZ60Kp3mzUMhPYtXI1a/C+/lxmU7dTMTgXgyIxU6lF6XkEk4TlPtWm8HTzK
7SS7Te4aLt6OOo5N57hUtct7q4y7IQXGQHm3e8HdRdeBQJ0u2Dhs/xSt/hTK6w/n
91Kx11Y+s02w88UkM53pe6ECgYAF/UYwVc1liSv9BlF6WSfBb1zam09KGh1405Sq
SxG9LlV8cFJE5TyWTdg/TNTyiaRvAt2JG+yAdkfrdOPXvCeE3yxRJ30+IP9evA4C
O6p19sBxe7rYQFFjUAVjSIMh1E22yEqDZtGB8JV0chob8K5uHY4CdAPylu7jTA3o
V1maAwKBgQCSGQ3yzsk4EGN2xd/JdgGDzhKyTZTQKMWYqQcsYxRAQ7Paj7u+Wkgv
dBeKcI0HwgpLy5ZohSd2erqieIsW0pEbJWCmos4IcO8tgNfEOa5WXYdyLbj5tFwt
ctu4/BJdijqfpMAtG8pv6k09gYjfASVytXmydGcs/0rVKYCRQA8Tow==
-----END RSA PRIVATE KEY-----
",
                samlServicePublicKeyEnc => "-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsRaod2RZ8hMFBl+Vhsnh
yPM8l/Fj1obnBxfQIaWuHFIFfXiGe/CYHuZ5QJQLnZxHMJX6LL3Sh+Usog3p0jpi
jpcg0QgfBSEkfopKTgReYN8DiDIll0rV1XdTni7E85Nd1YyNy3ui/ZD+UShWwqu6
jLVLR+QUm+/1LIKYb3OCBTvOlY7xHoP6NSU1+Mr+YzGBUacdO2vnNxe/PQhxIeP1
zO0njuqGHkwEpy8rUWRZbbDn31TmKjqlhgtsz5HPhbRaYEExhyepKgBiNz+RyxtY
XVhuG8OrWQDoS5gYHSjdw1CTJyixeJwyoqA9RGYguG5nh9zndi3LWAh7Z0lx+tIz
+wIDAQAB
-----END PUBLIC KEY-----
",
                samlSPSSODescriptorAuthnRequestsSigned => 1,
            },
        }
    );
}

sub app {
    my ( $jwks, $metadata ) = @_;
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel                   => $debug,
                domain                     => 'app.com',
                portal                     => 'http://auth.app.com',
                authentication             => 'CAS',
                userDB                     => 'Same',
                multiValuesSeparator       => ';',
                casSrvMetaDataExportedVars => {
                    proxy => {
                        cn   => 'cn',
                        mail => 'mail',
                        uid  => 'uid',
                    }
                },
                casSrvMetaDataOptions => {
                    proxy => {
                        casSrvMetaDataOptionsUrl => 'http://auth.proxy.com/cas',
                        casSrvMetaDataOptionsGateway => 0,
                    }
                },
            }
        }
    );
}
