use warnings;
use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';

use lib 't/lib';

my $res;

no warnings 'once';

SKIP: {
    skip('LLNGTESTLDAP is not set') unless ( $ENV{LLNGTESTLDAP} );
    require 't/test-ldap.pm';

    use Lemonldap::NG::Portal::Main::Constants qw(
      PE_PP_GRACE
      PE_PASSWORD_OK
      PE_BADOLDPASSWORD
      PE_PP_ACCOUNT_LOCKED
      PE_PP_PASSWORD_EXPIRED
      PE_PP_PASSWORD_EXPIRES_SOON
      PE_PP_CHANGE_AFTER_RESET
      PE_PP_PASSWORD_TOO_SHORT
    );

    my %ini = (
        portal      => 'http://auth.example.com/',
        useSafeJail => 1,
        whatToTrace => 'uid',
        macros      => {
            _whatToTrace => ''    # Test 2377
        },
        ldapServer      => $main::slapd_url,
        ldapBase        => 'ou=users,dc=example,dc=com',
        managerDn       => 'cn=lemonldapng,ou=dsa,dc=example,dc=com',
        managerPassword => 'lemonldapng',
        ldapAllowResetExpiredPassword            => 1,
        ldapForcePasswordChangeExpirationWarning => 2 * 86400,
        ldapPpolicyControl                       => 1,
        passwordPolicyMinDigit                   => 1,
        passwordPolicyMinLower                   => 1,
        passwordPolicyMinSize                    => 4,
        passwordPolicyMinSpeChar                 => 1,
        passwordPolicyMinUpper                   => 1,
        passwordPolicySpecialChar                => '__ALL__',
        portalRequireOldPassword                 => 1,
    );

    subtest "Run tests with local policy display" => sub {
        my $client = LLNG::Manager::Test->new( {
                ini => {
                    %ini,
                    authentication              => 'LDAP',
                    passwordDB                  => 'LDAP',
                    hideOldPassword             => 0,
                    portalDisplayPasswordPolicy => 1,
                    userDB                      => 'Same',
                }
            }
        );
        runTests($client);
    };

    resetLdapData();
    subtest
      "Run tests without password policy enabled and with password hiding" =>
      sub {
        my $client = LLNG::Manager::Test->new( {
                ini => {
                    %ini,
                    authentication           => 'LDAP',
                    hideOldPassword          => 1,
                    passwordDB               => 'LDAP',
                    passwordPolicyActivation => 0,
                    userDB                   => 'Same',
                }
            }
        );
        runTests($client);
      };

    resetLdapData();
    subtest "Run tests with Combination and local policy display" => sub {
        my $client = LLNG::Manager::Test->new( {
                ini => {
                    %ini,
                    authentication => 'Combination',
                    userDB         => 'Same',
                    passwordDB     => 'LDAP',
                    combModules    => {
                        'LDAP' => { 'for' => 0, 'type' => 'LDAP' },
                        'Demo' => { 'for' => 0, 'type' => 'Demo' }
                    },
                    combination     => '[LDAP, LDAP] or [Demo, Demo]',
                    hideOldPassword => 0,
                    portalDisplayPasswordPolicy => 1,
                }
            }
        );
        runTests($client);
    };
}

sub runTests {
    my ($client) = @_;
    my ( $user, $code, $postString, $match );

    # 1 - TEST PE_PP_CHANGE_AFTER_RESET AND PE_PP_PASSWORD_EXPIRED
    # ------------------------------------------------------------
    foreach my $tpl (
        [ 'reset',  PE_BADOLDPASSWORD ],
        [ 'reset',  PE_PP_CHANGE_AFTER_RESET ],
        [ 'expire', PE_PP_PASSWORD_EXPIRED ]
      )
    {
        $user       = $tpl->[0];
        $code       = $tpl->[1];
        $postString = "user=$user&password=$user";

        # Try to authenticate
        # -------------------
        ok(
            $res = $client->_post(
                '/', IO::String->new($postString),
                length => length($postString),
                accept => 'text/html',
            ),
            'Auth query'
        );

        if ( $code == PE_BADOLDPASSWORD ) {
            $match = 'trmsg="' . PE_PP_CHANGE_AFTER_RESET . '"';
            ok( $res->[2]->[0] =~ /$match/,
                'Code is ' . PE_PP_CHANGE_AFTER_RESET );

            my ( $host, $url, $query ) =
              expectForm( $res, '#', undef, 'user', 'oldpassword',
                'newpassword', 'confirmpassword' );
            $query =~ s/((?:confirm|new)password)=/$1=Newp1@/g;
            if ( $client->p->conf->{hideOldPassword} ) {
                $query =~ s/(oldpassword)=\d{10}_\d+/$1=1234567890_12345/;
            }
            else {
                $query =~ s/(oldpassword)=$user/$1=xxxx/;
            }
            ok(
                $res = $client->_post(
                    '/', IO::String->new($query),
                    length => length($query),
                    accept => 'text/html',
                ),
                'Post new password'
            );
            $match = 'trmsg="' . $code . '"';
            ok( $res->[2]->[0] =~ /$match/, 'Password is not changed' );
            ( $host, $url, $query ) =
              expectForm( $res, '#', undef, 'user', 'oldpassword',
                'newpassword', 'confirmpassword' );
        }
        else {
            $match = 'trmsg="' . $code . '"';
            ok( $res->[2]->[0] =~ /$match/, "Code is $code" );

            my ( $host, $url, $query ) =
              expectForm( $res, '#', undef, 'user', 'oldpassword',
                'newpassword', 'confirmpassword' );
            ok(
                $res->[2]->[0] =~
                  m%<input name="user" type="hidden" value="$user" />%,
                ' Hidden user input found'
            ) or print STDERR Dumper( $res->[2]->[0], 'Hidden user input' );

            if ( $client->p->conf->{hideOldPassword} ) {
                ok(
                    $res->[2]->[0] =~
m%<input id="oldpassword" name="oldpassword" type="hidden" value="\d{10}_\d+" aria-required="true">%,
                    ' oldpassword token found'
                  )
                  or print STDERR Dumper( $res->[2]->[0], 'oldpassword token' );
            }
            else {
                ok(
                    $res->[2]->[0] =~
m%<input id="oldpassword" name="oldpassword" type="password" value="$user"%,
                    ' oldpassword input found'
                  )
                  or print STDERR Dumper( $res->[2]->[0], 'oldpassword input' );
            }

            ok(
                $res->[2]->[0] =~
m%<input id="staticUser" type="text" readonly class="form-control" value="$user" />%,
                ' staticUser found'
            ) or print STDERR Dumper( $res->[2]->[0], 'staticUser' );
            if ( $client->p->conf->{portalDisplayPasswordPolicy} ) {
                ok(
                    $res->[2]->[0] =~ m%<span trspan="passwordPolicyMinSize">%,
                    ' passwordPolicyMinSize'
                  )
                  or print STDERR Dumper( $res->[2]->[0],
                    'passwordPolicyMinSize' );
                ok(
                    $res->[2]->[0] =~ m%<span trspan="passwordPolicyMinLower">%,
                    ' passwordPolicyMinLower'
                  )
                  or print STDERR Dumper( $res->[2]->[0],
                    'passwordPolicyMinLower' );
                ok(
                    $res->[2]->[0] =~ m%<span trspan="passwordPolicyMinUpper">%,
                    ' passwordPolicyMinUpper'
                  )
                  or print STDERR Dumper( $res->[2]->[0],
                    'passwordPolicyMinUpper' );
                ok(
                    $res->[2]->[0] =~ m%<span trspan="passwordPolicyMinDigit">%,
                    ' passwordPolicyMinDigit'
                  )
                  or print STDERR Dumper( $res->[2]->[0],
                    'passwordPolicyMinDigit' );
                ok(
                    $res->[2]->[0] =~
                      m%<span trspan="passwordPolicyMinSpeChar">%,
                    ' passwordPolicyMinSpeChar'
                  )
                  or print STDERR Dumper( $res->[2]->[0],
                    'passwordPolicyMinSpeChar' );
                ok(
                    $res->[2]->[0] !~
                      m%<span trspan="passwordPolicySpecialChar">%,
                    ' passwordPolicySpecialChar'
                  )
                  or print STDERR Dumper( $res->[2]->[0],
                    'passwordPolicySpecialChar' );
            }
            else {
                ok(
                    $res->[2]->[0] !~ m%<span trspan="passwordPolicyMinSize">%,
                    ' passwordPolicyMinSize'
                );
            }
            ok( $query =~ /user=$user/, "User is $user" )
              or explain( $query, "user=$user" );

            $query =~ s/((?:confirm|new)password)=/$1=Newp1@/g;

            ok(
                $res = $client->_post(
                    '/', IO::String->new($query),
                    length => length($query),
                    accept => 'text/html',
                ),
                'Post new password'
            );
            $match = 'trmsg="' . PE_PASSWORD_OK . '"';
            ok( $res->[2]->[0] =~ /$match/, 'Password is changed' );

            $postString = "user=$user&password=Newp1@";
            ok(
                $res = $client->_post(
                    '/',
                    IO::String->new($postString),
                    length => length($postString),
                ),
                'Auth query'
            );
            expectCookie($res) or print STDERR Dumper($res);
        }
    }

    # 2 - TEST PE_PP_GRACE
    # -------------------------
    $user       = 'grace';
    $code       = "ppGrace";
    $postString = "user=$user&password=$user";

    # Try to authenticate
    # -------------------
    ok(
        $res = $client->_post(
            '/', IO::String->new($postString),
            length => length($postString),
            accept => 'text/html',
        ),
        'Auth query'
    );
    $match = 'trspan="' . $code . '"';
    ok( $res->[2]->[0] =~ /$match/, 'Grace remaining' );

    # Try again to make sur "0 grace logins left" is properly handled
    ok(
        $res = $client->_post(
            '/', IO::String->new($postString),
            length => length($postString),
            accept => 'text/html',
        ),
        'Auth query'
    );
    $match = 'trspan="' . $code . '"';
    ok( $res->[2]->[0] =~ /$match/, 'Grace remaining' );

    # 3 - TEST PE_PP_ACCOUNT_LOCKED
    # -------------------------
    $user       = 'lock';
    $code       = PE_PP_ACCOUNT_LOCKED;
    $postString = "user=$user&password=$user";

    # Try to authenticate
    # -------------------
    ok(
        $res = $client->_post(
            '/', IO::String->new($postString),
            length => length($postString),
            accept => 'text/html',
        ),
        'Auth query'
    );
    $match = 'trmsg="' . $code . '"';
    ok( $res->[2]->[0] =~ /$match/, 'Account is locked' );

    # Try to change anyway
    my $query;
    if ( $client->p->conf->{hideOldPassword} ) {
        $query =
'user=lock&oldpassword=1234567890_12345&newpassword=newp&confirmpassword=newp';
    }
    else {
        $query =
          'user=lock&oldpassword=lock&newpassword=newp&confirmpassword=newp';
    }
    ok(
        $res = $client->_post(
            '/', IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Post new password'
    );
    $match = 'trmsg="' . PE_PASSWORD_OK . '"';
    ok( $res->[2]->[0] !~ /$match/s, 'Password is not changed' );

    # 4 - TEST PE_PP_PASSWORD_TOO_SHORT
    # ---------------------------------
    $user       = 'short';
    $code       = PE_PP_PASSWORD_TOO_SHORT;
    $postString = "user=$user&password=passwordnottooshort";

    # Try to authenticate
    # -------------------
    ok(
        $res = $client->_post(
            '/', IO::String->new($postString),
            length => length($postString),
            accept => 'text/html',
        ),
        'Auth query'
    );
    my $id = expectCookie($res);
    $query =
      'oldpassword=passwordnottooshort&newpassword=Te1@&confirmpassword=Te1@';
    ok(
        $res = $client->_post(
            '/',
            IO::String->new($query),
            cookie => "lemonldap=$id",
            accept => 'text/html',
            length => length($query),
        ),
        'Change password'
    );
    $match = 'trmsg="' . PE_PP_PASSWORD_TOO_SHORT . '"';
    ok( $res->[2]->[0] =~ /$match/s, 'Password is not changed' );

    # Verify that password isn't changed
    $client->logout($id);
    ok(
        $res = $client->_post(
            '/', IO::String->new($postString),
            length => length($postString),
            accept => 'text/html',
        ),
        'Auth query'
    );
    $id = expectCookie($res);
    $query =
'oldpassword=passwordnottooshort&newpassword=Testmore1@&confirmpassword=Testmore1@';
    ok(
        $res = $client->_post(
            '/',
            IO::String->new($query),
            cookie => "lemonldap=$id",
            accept => 'text/html',
            length => length($query),
        ),
        'Change password'
    );
    $match = 'trmsg="' . PE_PASSWORD_OK . '"';
    ok( $res->[2]->[0] =~ /$match/s, 'Password is changed' );

    # 5 - Password is expiring soon
    # -----------------------------
    {
        $user       = 'expiresoon';
        $postString = "user=$user&password=$user";

        # Try to authenticate
        # -------------------
        ok(
            $res = $client->_post(
                '/', IO::String->new($postString),
                length => length($postString),
                accept => 'text/html',
            ),
            'Auth query'
        );
        like( $res->[2]->[0],
            qr/trspan="pwdWillExpire,/, "Found password expiration warning" );

        expectCookie($res) or print STDERR Dumper($res);
    }

    # 6 - Password is expiring very soon and must be changed now
    # ----------------------------------------------------------
    {
        $user       = 'expireverysoon';
        $code       = PE_PP_PASSWORD_EXPIRES_SOON;
        $postString = "user=$user&password=$user";

        # Try to authenticate
        # -------------------
        ok(
            $res = $client->_post(
                '/', IO::String->new($postString),
                length => length($postString),
                accept => 'text/html',
            ),
            'Auth query'
        );
        $match = 'trmsg="' . $code . '"';
        ok( $res->[2]->[0] =~ /$match/, "Code is $code" );

        my ( $host, $url, $query ) =
          expectForm( $res, '#', undef, 'user', 'oldpassword', 'newpassword',
            'confirmpassword' );
        ok(
            $res->[2]->[0] =~
              m%<input name="user" type="hidden" value="$user" />%,
            ' Hidden user input found'
        ) or print STDERR Dumper( $res->[2]->[0], 'Hidden user input' );

        if ( $client->p->conf->{hideOldPassword} ) {
            ok(
                $res->[2]->[0] =~
m%<input id="oldpassword" name="oldpassword" type="hidden" value="\d{10}_\d+" aria-required="true">%,
                ' oldpassword token found'
            ) or print STDERR Dumper( $res->[2]->[0], 'oldpassword token' );
        }
        else {
            ok(
                $res->[2]->[0] =~
m%<input id="oldpassword" name="oldpassword" type="password" value="$user"%,
                ' oldpassword input found'
            ) or print STDERR Dumper( $res->[2]->[0], 'oldpassword input' );
        }
        ok(
            $res->[2]->[0] =~
m%<input id="staticUser" type="text" readonly class="form-control" value="$user" />%,
            ' staticUser found'
        ) or print STDERR Dumper( $res->[2]->[0], 'staticUser' );

        if ( $client->p->conf->{portalDisplayPasswordPolicy} ) {
            ok( $res->[2]->[0] =~ m%<span trspan="passwordPolicyMinSize">%,
                ' passwordPolicyMinSize' )
              or print STDERR Dumper( $res->[2]->[0], 'passwordPolicyMinSize' );
            ok( $res->[2]->[0] =~ m%<span trspan="passwordPolicyMinLower">%,
                ' passwordPolicyMinLower' )
              or
              print STDERR Dumper( $res->[2]->[0], 'passwordPolicyMinLower' );
            ok( $res->[2]->[0] =~ m%<span trspan="passwordPolicyMinUpper">%,
                ' passwordPolicyMinUpper' )
              or
              print STDERR Dumper( $res->[2]->[0], 'passwordPolicyMinUpper' );
            ok( $res->[2]->[0] =~ m%<span trspan="passwordPolicyMinDigit">%,
                ' passwordPolicyMinDigit' )
              or
              print STDERR Dumper( $res->[2]->[0], 'passwordPolicyMinDigit' );
            ok( $res->[2]->[0] =~ m%<span trspan="passwordPolicyMinSpeChar">%,
                ' passwordPolicyMinSpeChar' )
              or
              print STDERR Dumper( $res->[2]->[0], 'passwordPolicyMinSpeChar' );
            ok(
                $res->[2]->[0] !~ m%<span trspan="passwordPolicySpecialChar">%,
                ' passwordPolicySpecialChar'
              )
              or print STDERR Dumper( $res->[2]->[0],
                'passwordPolicySpecialChar' );
        }
        else {
            ok( $res->[2]->[0] !~ m%<span trspan="passwordPolicyMinSize">%,
                ' passwordPolicyMinSize' );
        }
        ok( $query =~ /user=$user/, "User is $user" )
          or explain( $query, "user=$user" );

        $query =~ s/((?:confirm|new)password)=/$1=Newp1@/g;

        ok(
            $res = $client->_post(
                '/', IO::String->new($query),
                length => length($query),
                accept => 'text/html',
            ),
            'Post new password'
        );
        $match = 'trmsg="' . PE_PASSWORD_OK . '"';
        ok( $res->[2]->[0] =~ /$match/, 'Password is changed' );

        $postString = "user=$user&password=Newp1@";
        ok(
            $res = $client->_post(
                '/', IO::String->new($postString),
                length => length($postString),
            ),
            'Auth query'
        );
        expectCookie($res) or print STDERR Dumper($res);
    }
}

clean_sessions();
done_testing();
