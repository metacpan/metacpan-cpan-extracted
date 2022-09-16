use Lemonldap::NG::Common::JWT qw/getJWTPayload/;

sub oidc_key_op_private_sig {
    "-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAs2jsmIoFuWzMkilJaA8//5/T30cnuzX9GImXUrFR2k9EKTMt
GMHCdKlWOl3BV+BTAU9TLz7Jzd/iJ5GJ6B8TrH1PHFmHpy8/qE/S5OhinIpIi7eb
ABqnoVcwDdCa8ugzq8k8SWxhRNXfVIlwz4NH1caJ8lmiERFj7IvNKqEhzAk0pyDr
8hubveTC39xREujKlsqutpPAFPJ3f2ybVsdykX5rx0h5SslG3jVWYhZ/SOb2aIzO
r0RMjhQmsYRwbpt3anjlBZ98aOzg7GAkbO8093X5VVk9vaPRg0zxJQ0Do0YLyzkR
isSAIFb0tdKuDnjRGK6y/N2j6At2HjkxntbtGQIDAQABAoIBADYq6LxJd977LWy3
0HT9nboFPIf+SM2qSEc/S5Po+6ipJBA4ZlZCMf7dHa6znet1TDpqA9iQ4YcqIHMH
6xZNQ7hhgSAzG9TrXBHqP+djDlrrGWotvjuy0IfS9ixFnnLWjrtAH9afRWLuG+a/
NHNC1M6DiiTE0TzL/lpt/zzut3CNmWzH+t19X6UsxUg95AzooEeewEYkv25eumWD
mfQZfCtSlIw1sp/QwxeJa/6LJw7KcPZ1wXUm1BN0b9eiKt9Cmni1MS7elgpZlgGt
xtfGTZtNLQ7bgDiM8MHzUfPBhbceNSIx2BeCuOCs/7eaqgpyYHBbAbuBQex2H61l
Lcc3Tz0CgYEA4Kx/avpCPxnvsJ+nHVQm5d/WERuDxk4vH1DNuCYBvXTdVCGADf6a
F5No1JcTH3nPTyPWazOyGdT9LcsEJicLyD8vCM6hBFstG4XjqcAuqG/9DRsElpHQ
yi1zc5DNP7Vxmiz9wII0Mjy0abYKtxnXh9YK4a9g6wrcTpvShhIcIb8CgYEAzGzG
lorVCfX9jXULIznnR/uuP5aSnTEsn0xJeqTlbW0RFWLdj8aIL1peirh1X89HroB9
GeTNqEJXD+3CVL2cx+BRggMDUmEz4hR59meZCDGUyT5fex4LIsceb/ESUl2jo6Sw
HXwWbN67rQ55N4oiOcOppsGxzOHkl5HdExKidycCgYEAr5Qev2tz+fw65LzfzHvH
Kj4S/KuT/5V6He731cFd+sEpdmX3vPgLVAFPG1Q1DZQT/rTzDDQKK0XX1cGiLG63
NnaqOye/jbfzOF8Z277kt51NFMDYhRLPKDD82IOA4xjY/rPKWndmcxwdob8yAIWh
efY76sMz6ntCT+xWSZA9i+ECgYBWMZM2TIlxLsBfEbfFfZewOUWKWEGvd9l5vV/K
D5cRIYivfMUw5yPq2267jPUolayCvniBH4E7beVpuPVUZ7KgcEvNxtlytbt7muil
5Z6X3tf+VodJ0Swe2NhTmNEB26uwxzLe68BE3VFCsbSYn2y48HAq+MawPZr18bHG
ZfgMxwKBgHHRg6HYqF5Pegzk1746uH2G+OoCovk5ylGGYzcH2ghWTK4agCHfBcDt
EYqYAev/l82wi+OZ5O8U+qjFUpT1CVeUJdDs0o5u19v0UJjunU1cwh9jsxBZAWLy
PAGd6SWf4S3uQCTw6dLeMna25YIlPh5qPA6I/pAahe8e3nSu2ckl
-----END RSA PRIVATE KEY----- ";
}

sub oidc_key_op_public_sig {
    "-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAs2jsmIoFuWzMkilJaA8/
/5/T30cnuzX9GImXUrFR2k9EKTMtGMHCdKlWOl3BV+BTAU9TLz7Jzd/iJ5GJ6B8T
rH1PHFmHpy8/qE/S5OhinIpIi7ebABqnoVcwDdCa8ugzq8k8SWxhRNXfVIlwz4NH
1caJ8lmiERFj7IvNKqEhzAk0pyDr8hubveTC39xREujKlsqutpPAFPJ3f2ybVsdy
kX5rx0h5SslG3jVWYhZ/SOb2aIzOr0RMjhQmsYRwbpt3anjlBZ98aOzg7GAkbO80
93X5VVk9vaPRg0zxJQ0Do0YLyzkRisSAIFb0tdKuDnjRGK6y/N2j6At2Hjkxntbt
GQIDAQAB
-----END PUBLIC KEY-----";
}

sub id_token_payload {
    my $token = shift;
    JSON::from_json( decode_base64( [ split /\./, $token ]->[1] ) );
}

sub login {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $op, $uid ) = @_;
    my $res;
    my $query = buildForm( {
            user     => $uid,
            password => $uid,
        }
    );
    $res = $op->_post(
        "/",
        IO::String->new($query),
        accept => 'text/html',
        length => length($query),
    );
    return expectCookie($res);
}

sub authorize {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $op, $id, $params ) = @_;
    my $query = buildForm($params);
    my $res   = $op->_get(
        "/oauth2/authorize",
        query  => "$query",
        accept => 'text/html',
        cookie => "lemonldap=$id",
    );
    my ($code) = expectRedirection( $res, qr#http://.*code=([^\&]*)# );
    return $code;
}

sub codeGrant {
    my ( $op, $clientid, $code, $redirect_uri ) = @_;
    my $query = buildForm( {
            grant_type   => "authorization_code",
            code         => $code,
            redirect_uri => $redirect_uri,
        }
    );

    my $res = $op->_post(
        "/oauth2/token",
        IO::String->new($query),
        accept => 'application/json',
        length => length($query),
        custom => {
            HTTP_AUTHORIZATION => "Basic "
              . encode_base64("$clientid:$clientid"),
        },
    );
    return $res;
}

sub getUserinfo {
    my ( $op, $access_token ) = @_;
    my $res = $op->_post(
        "/oauth2/userinfo",
        IO::String->new(''),
        accept => 'application/json',
        length => 0,
        custom => {
            HTTP_AUTHORIZATION => "Bearer " . $access_token,
        },
    );
    return $res;
}

sub refreshGrant {
    my ( $op, $client_id, $refresh_token ) = @_;

    $query = buildForm( {
            grant_type    => 'refresh_token',
            refresh_token => $refresh_token,
        }
    );

    $res = $op->_post(
        "/oauth2/token",
        IO::String->new($query),
        accept => 'application/json',
        length => length($query),
        custom => {
            HTTP_AUTHORIZATION => "Basic "
              . encode_base64("$client_id:$client_id"),
        }
    );
    return $res;
}

sub introspect {
    my ( $op, $client_id, $token ) = @_;
    my $query = buildForm( {
            client_id     => $client_id,
            client_secret => $client_id,
            token         => $token,
        }
    );
    my $res = $op->_post(
        "/oauth2/introspect",
        IO::String->new($query),
        accept => 'application/json',
        length => length($query),
    );
    return $res;
}

sub expectJWT {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $token, %claims ) = @_;
    my $payload = getJWTPayload($token);
    ok( $payload, "Token is a JWT" );
    count(1);
    for my $claim ( keys %claims ) {
        is( $payload->{$claim}, $claims{$claim}, "Found claim in JWT" );
        count(1);
    }
    return $payload;
}

1;
