use warnings;
use Test::More;
use strict;
use IO::String;
use JSON;

require 't/test-lib.pm';
my $maintests = 9;

no warnings 'once';

SKIP: {
    eval { require Convert::Base32 };
    if ($@) {
        skip 'Convert::Base32 is missing', $maintests;
    }
    skip 'LLNGTESTLDAP is not set', $maintests unless ( $ENV{LLNGTESTLDAP} );
    require 't/test-ldap.pm';

    require Lemonldap::NG::Common::TOTP;

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel               => 'error',
                totp2fSelfRegistration => 1,
                restSessionServer      => 1,
                totp2fActivation       => 1,
                totp2fRange            => 2,
                totp2fAuthnLevel       => 5,
                authentication         => 'LDAP',
                userDB                 => 'Same',
                passwordDB             => 'LDAP',
                ldapServer             => $main::slapd_url,
                ldapBase               => 'ou=users,dc=example,dc=com',
                ldapGroupBase          => 'ou=groups,dc=example,dc=com',
                managerDn              => 'cn=admin,dc=example,dc=com',
                managerPassword        => 'admin',
                ldapPpolicyControl     => 1,
            }
        }
    );
    my $res;

    # Register TOTP
    my $key = "dx3e34svy6jag5jtgdn2e6y7xyzmti6z";

    $client->p->getPersistentSession(
        "grace",
        {
            _2fDevices => to_json [ {
                    "epoch"   => "1640015033",
                    "name"    => "MyTOTP",
                    "type"    => "TOTP",
                    "_secret" => $key,
                },
            ],
        }
    );

    ok(
        $res = $client->_post(
            '/',
            { user => "grace", password => "grace" },
            accept => 'text/html',
        ),
        'Auth query'
    );
    my ( $host, $url, $query ) = expectForm( $res, undef, '/totp2fcheck' );

    ok(
        my $code = Lemonldap::NG::Common::TOTP::_code(
            undef, Convert::Base32::decode_base32($key),
            0,     30, 6
        ),
        'Code'
    );
    $query =~ s/code=/code=$code/;
    ok(
        $res = $client->_post(
            '/totp2fcheck', IO::String->new($query),
            length => length($query),
            accept => "text/html",
        ),
        'Post code'
    );

    # Some OpenLDAP versions incorrectly report the number of grace logins
    # https://bugs.openldap.org/show_bug.cgi?id=7596
    like(
        $res->[2]->[0],
        qr,<h3>(?:2|1) <span trspan="ppGrace">,,
        "Found grace info message"
    );

    my $id   = expectCookie($res);
    my $attr = getSessionAttributes( $client, $id );
    is( $attr->{_auth}, "LDAP" );
    is( $attr->{_2f},   "totp" );
    is( $attr->{uid},   "grace" );
    is( $attr->{_dn},   "uid=grace,ou=users,dc=example,dc=com" );
    is( $attr->{hGroups}->{mygroup}->{name}, "mygroup" );
    $client->logout($id);
}
count($maintests);
clean_sessions();
done_testing( count() );

