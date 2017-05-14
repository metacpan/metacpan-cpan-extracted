# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Portal-AuthSsl.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 11;
BEGIN { use_ok('Lemonldap::NG::Portal::Simple') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

$ENV{"REQUEST_METHOD"} = 'GET';
my $p;
ok(
    $p = Lemonldap::NG::Portal::Simple->new(
        {
            globalStorage  => 'Apache::Session::File',
            domain         => 'example.com',
            authentication => 'OpenIDConnect',
            userDB         => 'OpenIDConnect',
            passwordDB     => 'Null',
            registerDB     => 'Null',
        }
    )
);

## JWT Signature verification
# Samples from http://jwt.io
$p->{oidcOPMetaDataOptions}->{jwtio}->{oidcOPMetaDataOptionsClientSecret} =
  "secret";
my $jwt;

# alg: none
$jwt =
"eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJzdWIiOjEyMzQ1Njc4OTAsIm5hbWUiOiJKb2huIERvZSIsImFkbWluIjp0cnVlfQ.";
ok(
    $p->verifyJWTSignature( $jwt, "jwtio" ) == 1,
    'JWT Signature verification - alg: none'
);

# alg: HS256
$jwt =
"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjEyMzQ1Njc4OTAsIm5hbWUiOiJKb2huIERvZSIsImFkbWluIjp0cnVlfQ.eoaDVGTClRdfxUZXiPs3f8FmJDkDE_VCQFXqKxpLsts";
ok(
    $p->verifyJWTSignature( $jwt, "jwtio" ) == 1,
    'JWT Signature verification - alg: HS256'
);

# alg: HS512
$jwt =
"eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjEyMzQ1Njc4OTAsIm5hbWUiOiJKb2huIERvZSIsImFkbWluIjp0cnVlfQ.fSCfxDB4cFVvzd6IqiNTuItTYiv-tAp5u5XplJWRDBGNF1rgGn1gyYK9LuHobWWpwqCzI7pEHDlyrbNHaQJmqg";
ok(
    $p->verifyJWTSignature( $jwt, "jwtio" ) == 1,
    'JWT Signature verification - alg: HS512'
);

# Sample from Google
$p->{_oidcOPList}->{google}->{jwks}->{keys}->[0]->{kid} =
  "3d007677fec656a562826f0191d0f9fcb0e595cf";
$p->{_oidcOPList}->{google}->{jwks}->{keys}->[0]->{n} =
"3I_zvpLMNY9UY-SoVm60yh3CRB0LK0CdJ7qqF_Fl07LWNrWSudWSv1q-1QQGwQyxjzuD31eOouqp6gsMgJg6kyECUj9i6zUETCePy3kc-CAPUZE4vj-sJGA0qIcIrI54RdsLL6u27TKAkqqdl-XeO0S5fcUb3AaGW8TpmZoioEU=";
$p->{_oidcOPList}->{google}->{jwks}->{keys}->[0]->{e} = "AQAB";

# alg: RS256
$jwt =
"eyJhbGciOiJSUzI1NiIsImtpZCI6IjNkMDA3Njc3ZmVjNjU2YTU2MjgyNmYwMTkxZDBmOWZjYjBlNTk1Y2YifQ.eyJpc3MiOiJhY2NvdW50cy5nb29nbGUuY29tIiwic3ViIjoiMTE1MzYxMjMwMzU3MzA0NzU0ODQ0IiwiYXpwIjoiMjg2MzA1NzI4NjUyLWxjYW5ubWRnMTdxM2VtdDFjYmtqbmZnOTVzZHM4NjJsLmFwcHMuZ29vZ2xldXNlcmNvbnRlbnQuY29tIiwiZW1haWwiOiJjbGVtZW50QG9vZG8ubmV0IiwiYXRfaGFzaCI6ImZRc0FaSHdsUUNPZXctNE84QkFWNWciLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiYXVkIjoiMjg2MzA1NzI4NjUyLWxjYW5ubWRnMTdxM2VtdDFjYmtqbmZnOTVzZHM4NjJsLmFwcHMuZ29vZ2xldXNlcmNvbnRlbnQuY29tIiwiaGQiOiJvb2RvLm5ldCIsImlhdCI6MTQxNjQwNjA0MywiZXhwIjoxNDE2NDA5OTQzfQ.NihX-7P1ogpPCmygD-A-hChIwMg9hJQ_4gzu3zmNEyHnY9rWuwXF6E2K9LF_opMQXWJxkUcI7eyo73L3yk9_51CfQLzD5NbfpR6kyctLBXud9A7wyHzJRBCB_rOU12vU4bMWGajgkGUqOmy-PFnz3akvqVgExbqas0Go4Flg7NI";
ok(
    $p->verifyJWTSignature( $jwt, 'google' ) == 1,
    'JWT Signature verification - alg: RS256'
);

# Sample from OIDC core specification (§A.7.)
$p->{_oidcOPList}->{oidccore}->{jwks}->{keys}->[0]->{kty} = "RSA";
$p->{_oidcOPList}->{oidccore}->{jwks}->{keys}->[0]->{kid} = "1e9gdk7";
$p->{_oidcOPList}->{oidccore}->{jwks}->{keys}->[0]->{n} =
"w7Zdfmece8iaB0kiTY8pCtiBtzbptJmP28nSWwtdjRu0f2GFpajvWE4VhfJAjEsOcwYzay7XGN0b-X84BfC8hmCTOj2b2eHT7NsZegFPKRUQzJ9wW8ipn_aDJWMGDuB1XyqT1E7DYqjUCEOD1b4FLpy_xPn6oV_TYOfQ9fZdbE5HGxJUzekuGcOKqOQ8M7wfYHhHHLxGpQVgL0apWuP2gDDOdTtpuld4D2LK1MZK99s9gaSjRHE8JDb1Z4IGhEcEyzkxswVdPndUWzfvWBBWXWxtSUvQGBRkuy1BHOa4sP6FKjWEeeF7gm7UMs2Nm2QUgNZw6xvEDGaLk4KASdIxRQ";
$p->{_oidcOPList}->{oidccore}->{jwks}->{keys}->[0]->{e} = "AQAB";

# ID Token from §A.2.
$jwt =
"eyJraWQiOiIxZTlnZGs3IiwiYWxnIjoiUlMyNTYifQ.ewogImlzcyI6ICJodHRwOi8vc2VydmVyLmV4YW1wbGUuY29tIiwKICJzdWIiOiAiMjQ4Mjg5NzYxMDAxIiwKICJhdWQiOiAiczZCaGRSa3F0MyIsCiAibm9uY2UiOiAibi0wUzZfV3pBMk1qIiwKICJleHAiOiAxMzExMjgxOTcwLAogImlhdCI6IDEzMTEyODA5NzAsCiAibmFtZSI6ICJKYW5lIERvZSIsCiAiZ2l2ZW5fbmFtZSI6ICJKYW5lIiwKICJmYW1pbHlfbmFtZSI6ICJEb2UiLAogImdlbmRlciI6ICJmZW1hbGUiLAogImJpcnRoZGF0ZSI6ICIwMDAwLTEwLTMxIiwKICJlbWFpbCI6ICJqYW5lZG9lQGV4YW1wbGUuY29tIiwKICJwaWN0dXJlIjogImh0dHA6Ly9leGFtcGxlLmNvbS9qYW5lZG9lL21lLmpwZyIKfQ.rHQjEmBqn9Jre0OLykYNnspA10Qql2rvx4FsD00jwlB0Sym4NzpgvPKsDjn_wMkHxcp6CilPcoKrWHcipR2iAjzLvDNAReF97zoJqq880ZD1bwY82JDauCXELVR9O6_B0w3K-E7yM2macAAgNCUwtik6SjoSUZRcf-O5lygIyLENx882p6MtmwaL1hd6qn5RZOQ0TLrOYu0532g9Exxcm-ChymrB4xLykpDj3lUivJt63eEGGN6DH5K6o33TcxkIjNrCD4XB1CKKumZvCedgHHF3IAK4dVEDSUoGlH9z4pP_eWYNXvqQOjGs-rDaQzUHl6cQQWNiDpWOl_lxXjQEvQ";

ok(
    $p->verifyJWTSignature( $jwt, 'oidccore' ) == 1,
    'JWT Signature verification - alg: RS256'
);

# ID Token and Access Token from §A.3.
my $id_token =
"eyJraWQiOiIxZTlnZGs3IiwiYWxnIjoiUlMyNTYifQ.ewogImlzcyI6ICJodHRwOi8vc2VydmVyLmV4YW1wbGUuY29tIiwKICJzdWIiOiAiMjQ4Mjg5NzYxMDAxIiwKICJhdWQiOiAiczZCaGRSa3F0MyIsCiAibm9uY2UiOiAibi0wUzZfV3pBMk1qIiwKICJleHAiOiAxMzExMjgxOTcwLAogImlhdCI6IDEzMTEyODA5NzAsCiAiYXRfaGFzaCI6ICI3N1FtVVB0alBmeld0RjJBbnBLOVJRIgp9.F9gRev0Dt2tKcrBkHy72cmRqnLdzw9FLCCSebV7mWs7o_sv2O5s6zMky2kmhHTVx9HmdvNnx9GaZ8XMYRFeYk8L5NZ7aYlA5W56nsG1iWOou_-gji0ibWIuuf4Owaho3YSoi7EvsTuLFz6tq-dLyz0dKABMDsiCmJ5wqkPUDTE3QTXjzbUmOzUDli-gCh5QPuZAq0cNW3pf_2n4zpvTYtbmj12cVcxGIMZby7TMWESRjQ9_o3jvhVNcCGcE0KAQXejhA1ocJhNEvQNqMFGlBb6_0RxxKjDZ-Oa329eGDidOvvp0h5hoES4a8IuGKS7NOcpp-aFwp0qVMDLI-Xnm-Pg";
my $access_token = "jHkWEdUXMU1BwAsC4vtUsZwnNvTIxEl0z9K3vx5KF0Y";
my $at_hash      = "77QmUPtjPfzWtF2AnpK9RQ";

ok(
    $p->createHash( $access_token, "256" ) eq $at_hash,
    'Access Token Hash creation - alg: SHA-256'
);

ok(
    $p->verifyHash( $access_token, $at_hash, $id_token ) == 1,
    'Access Token Hash verification - alg: SHA-256'
);

# ID Token and code from §A.6.
$id_token =
"eyJraWQiOiIxZTlnZGs3IiwiYWxnIjoiUlMyNTYifQ.ewogImlzcyI6ICJodHRwOi8vc2VydmVyLmV4YW1wbGUuY29tIiwKICJzdWIiOiAiMjQ4Mjg5NzYxMDAxIiwKICJhdWQiOiAiczZCaGRSa3F0MyIsCiAibm9uY2UiOiAibi0wUzZfV3pBMk1qIiwKICJleHAiOiAxMzExMjgxOTcwLAogImlhdCI6IDEzMTEyODA5NzAsCiAiY19oYXNoIjogIkxEa3RLZG9RYWszUGswY25YeENsdEEiCn0.XW6uhdrkBgcGx6zVIrCiROpWURs-4goO1sKA4m9jhJIImiGg5muPUcNegx6sSv43c5DSn37sxCRrDZZm4ZPBKKgtYASMcE20SDgvYJdJS0cyuFw7Ijp_7WnIjcrl6B5cmoM6ylCvsLMwkoQAxVublMwH10oAxjzD6NEFsu9nipkszWhsPePf_rM4eMpkmCbTzume-fzZIi5VjdWGGEmzTg32h3jiex-r5WTHbj-u5HL7u_KP3rmbdYNzlzd1xWRYTUs4E8nOTgzAUwvwXkIQhOh5TPcSMBYy6X3E7-_gr9Ue6n4ND7hTFhtjYs3cjNKIA08qm5cpVYFMFMG6PkhzLQ";
my $code   = "Qcb0Orv1zh30vL1MPRsbm-diHiMwcLyZvn1arpZv-Jxf_11jnpEX3Tgfvk";
my $c_hash = "LDktKdoQak3Pk0cnXxCltA";

ok(
    $p->createHash( $code, "256" ) eq $c_hash,
    'Code Hash creation - alg: SHA-256'
);

ok(
    $p->verifyHash( $code, $c_hash, $id_token ) == 1,
    'Code Hash verification - alg: SHA-256'
);

