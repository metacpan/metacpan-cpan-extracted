use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';

use lib 't/lib';

my $res;
my $maintests = 42;

SKIP: {
    skip( 'LLNGTESTLDAP is not set', $maintests ) unless ( $ENV{LLNGTESTLDAP} );
    require 't/test-ldap.pm';

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel                 => 'error',
                useSafeJail              => 1,
                authentication           => 'LDAP',
                portal                   => 'http://auth.example.com/',
                userDB                   => 'Same',
                passwordDB               => 'LDAP',
                portalRequireOldPassword => 1,
                ldapServer               => $main::slapd_url,
                ldapBase                 => 'ou=users,dc=example,dc=com',
                managerDn       => 'cn=lemonldapng,ou=dsa,dc=example,dc=com',
                managerPassword => 'lemonldapng',
                ldapAllowResetExpiredPassword => 1,
                ldapPpolicyControl            => 1,
                passwordPolicyMinSize         => 4,
                passwordPolicyMinLower        => 1,
                passwordPolicyMinUpper        => 1,
                passwordPolicyMinDigit        => 1,
                passwordPolicyMinSpeChar      => 1,
                passwordPolicySpecialChar     => '__ALL__',
                portalDisplayPasswordPolicy   => 1,
                whatToTrace                   => 'uid',
                macros                        => {
                    _whatToTrace => ''    # Test 2377
                },
            }
        }
    );
    use Lemonldap::NG::Portal::Main::Constants qw(
      PE_PASSWORD_OK
      PE_PP_ACCOUNT_LOCKED
      PE_PP_PASSWORD_EXPIRED
      PE_PP_CHANGE_AFTER_RESET
      PE_PP_PASSWORD_TOO_SHORT PE_PP_GRACE
    );

    my ( $user, $code, $postString, $match );

    # 1 - TEST PE_PP_CHANGE_AFTER_RESET AND PE_PP_PASSWORD_EXPIRED
    # ------------------------------------------------------------
    foreach my $tpl (
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
        $match = 'trmsg="' . $code . '"';
        ok( $res->[2]->[0] =~ /$match/, "Code is $code" );

        #open F, '>../e2e-tests/conf/portal/result.html' or die $!;
        #print F $res->[2]->[0];
        #close F;
        my ( $host, $url, $query ) =
          expectForm( $res, '#', undef, 'user', 'oldpassword', 'newpassword',
            'confirmpassword' );
        ok(
            $res->[2]->[0] =~
              m%<input name="user" type="hidden" value="$user" />%,
            ' Hidden user input found'
        ) or print STDERR Dumper( $res->[2]->[0], 'Hidden user input' );
        ok(
            $res->[2]->[0] =~
m%<input id="oldpassword" name="oldpassword" type="password" value="$user"%,
            ' oldpassword input found'
        ) or print STDERR Dumper( $res->[2]->[0], 'oldpassword input' );
        ok(
            $res->[2]->[0] =~
m%<input id="staticUser" type="text" readonly class="form-control" value="$user" />%,
            ' staticUser found'
        ) or print STDERR Dumper( $res->[2]->[0], 'staticUser' );
        ok( $res->[2]->[0] =~ m%<span trspan="passwordPolicyMinSize">%,
            ' passwordPolicyMinSize' )
          or print STDERR Dumper( $res->[2]->[0], 'passwordPolicyMinSize' );
        ok( $res->[2]->[0] =~ m%<span trspan="passwordPolicyMinLower">%,
            ' passwordPolicyMinLower' )
          or print STDERR Dumper( $res->[2]->[0], 'passwordPolicyMinLower' );
        ok( $res->[2]->[0] =~ m%<span trspan="passwordPolicyMinUpper">%,
            ' passwordPolicyMinUpper' )
          or print STDERR Dumper( $res->[2]->[0], 'passwordPolicyMinUpper' );
        ok( $res->[2]->[0] =~ m%<span trspan="passwordPolicyMinDigit">%,
            ' passwordPolicyMinDigit' )
          or print STDERR Dumper( $res->[2]->[0], 'passwordPolicyMinDigit' );
        ok( $res->[2]->[0] =~ m%<span trspan="passwordPolicyMinSpeChar">%,
            ' passwordPolicyMinSpeChar' )
          or print STDERR Dumper( $res->[2]->[0], 'passwordPolicyMinSpeChar' );
        ok( $res->[2]->[0] !~ m%<span trspan="passwordPolicySpecialChar">%,
            ' passwordPolicySpecialChar' )
          or print STDERR Dumper( $res->[2]->[0], 'passwordPolicySpecialChar' );
        ok( $query =~ /user=$user/, "User is $user" )
          or explain( $query, "user=$user" );

    #$query =~ s/(oldpassword)=/$1=$user/g; -> Now old password is defined #2377
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
    my $query =
      'user=lock&oldpassword=lock&newpassword=newp&confirmpassword=newp';
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
}
count($maintests);
clean_sessions();
done_testing( count() );
