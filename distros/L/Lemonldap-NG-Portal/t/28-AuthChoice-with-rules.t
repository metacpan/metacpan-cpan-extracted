use warnings;
use Test::More;
use strict;
use IO::String;

BEGIN {
    require 't/test-lib.pm';
    eval "use GSSAPI";
}

my $res;
my $maintests = 21;

my $userdb = tempdb();

SKIP: {
    eval { require DBI; require DBD::SQLite; require GSSAPI; };
    if ($@) {
        skip 'Missing dependencies', $maintests;
    }
    my $dbh = DBI->connect("dbi:SQLite:dbname=$userdb");
    $dbh->do('CREATE TABLE users (user text,password text,name text)');
    $dbh->do("INSERT INTO users VALUES ('dwho','dwho','Doctor who')");

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel       => 'error',
                useSafeJail    => 1,
                portalMainLogo => 'common/logos/logo_llng_old.png',
                authentication => 'Choice',
                userDB         => 'Same',

                authChoiceParam   => 'test',
                authChoiceModules => {
                    '1_demo' => 'Demo;Demo;Null;;0',
                    '2_sql'  => 'DBI;DBI;DBI;;1',
                    '3_demo' =>
'Demo;Demo;Null;https://test.example.com;$env->{ipAddr} =~ /127.0.0.1/',
                    '4_demo' =>
'Demo;Demo;Null;https://test.example.com;$env->{ipAddr} =~ /1.2.3.4/',
                    '5_ssl'        => 'SSL;Demo;Demo',
                    '6_FakeCustom' => 'Custom;Demo;Demo',
                    '7_Kerberos'   => 'Kerberos;Null;Null',
                },

                dbiAuthChain        => "dbi:SQLite:dbname=$userdb",
                dbiAuthUser         => '',
                dbiAuthPassword     => '',
                dbiAuthTable        => 'users',
                dbiAuthLoginCol     => 'user',
                dbiAuthPasswordCol  => 'password',
                dbiAuthPasswordHash => '',
                customAuth          => '::Auth::Apache',
                customAddParams     => {},
                sslByAjax           => 1,
                sslHost             => 'https://authssl.example.com:19876',
                krbKeytab           => '/etc/keytab',
                krbByJs             => 1,
                krbAuthnLevel       => 4,
                customPlugins       => "t::ChoiceHookPlugin",
            }
        }
    );

    ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu' );
    ok( $res->[2]->[0] !~ /1_demo/,       '1_demo not displayed' );
    ok( $res->[2]->[0] =~ /2_sql/,        '2_sql displayed' );
    ok( $res->[2]->[0] =~ /3_demo/,       '3_demo displayed' );
    ok( $res->[2]->[0] =~ /5_ssl/,        '5_ssl displayed' );
    ok( $res->[2]->[0] =~ /6_FakeCustom/, '6_FakeCustom displayed' );
    ok( $res->[2]->[0] =~ /7_Kerberos/,   '7_Kerberos displayed' );
    ok( $res->[2]->[0] =~ qr%<img src="/static/common/modules/SSL.png"%,
        'Found 5_ssl Logo' )
      or explain( $res->[2]->[0], '<img src="/static/common/modules/SSL.png' );
    ok( $res->[2]->[0] =~ qr%img src="/static/common/modules/Apache.png"%,
        'Found 6_FakeCustom Logo' )
      or
      explain( $res->[2]->[0], '<img src="/static/common/modules/Apache.png' );
    ok( $res->[2]->[0] =~ qr%<img src="/static/common/modules/Kerberos.png"%,
        'Found 7_Kerberos Logo' )
      or explain( $res->[2]->[0],
        '<img src="/static/common/modules/Kerberos.png' );
    ok(
        $res->[2]->[0] =~
          m%<form id="lformDemo" action="https://test.example.com"%,
        ' Redirect URL found'
      )
      or explain( $res->[2]->[0],
        '<form id="lformDemo" action="https://test.example.com"' );

    is(
        getJsVars($res)->{sslHost},
        "https://authssl.example.com:19876",
        "Found sslHost"
    );
    expectForm( $res, '#', undef, 'kerberos' );
    ok(
        $res->[2]->[0] =~ m%<input type="hidden" name="kerberos" value="0" />%,
        'Found hidden attribut "kerberos" with value="0"'
    ) or explain( $res->[2]->[0], '<input type="hidden" name="kerberos"' );
    ok( $res->[2]->[0] =~ /kerberosChoice\.(?:min\.)?js/,
        'Get Kerberos javascript' )
      or explain( $res->[2]->[0], 'kerberosChoice.(min.)?js' );
    ok(
        $res->[2]->[0] =~
m%<form id="lformKerberos" action="#" method="post" class="login Kerberos">%,
        ' Redirect URL found'
    ) or explain( $res->[2]->[0], '<form id="lformKerberos"' );
    ok( $res->[2]->[0] =~ /sslChoice\.(?:min\.)?js/,
        'Get sslChoice javascript' )
      or explain( $res->[2]->[0], 'sslChoice.(min.)?js' );
    ok(
        $res->[2]->[0] =~
          m%<form id="lformSSL" action="#" method="post" class="login SSL">%,
        ' Action # found'
    ) or explain( $res->[2]->[0], '<form id="lformSSL"' );
    my $header = getHeader( $res, 'Content-Security-Policy' );
    ok( $header =~ m%;form-action \* https://test.example.com;%,
        ' CSP URL found' )
      or explain( $res->[1], 'form-action * https://test.example.com;' );
    ok( $res->[2]->[0] !~ /4_demo/, '4_Demo not displayed' );
    ok(
        $res->[2]->[0] =~ qr%<img src="/static/common/logos/logo_llng_old.png"%,
        'Found custom Main Logo'
      )
      or explain( $res->[2]->[0],
        '<img src="/static/common/logos/logo_llng_old.png"' );

    ok(getHtmlElement( $res,
            '//div[@id="id_2_sql"]//input[@id="userfield"]/@autofocus' ), "User field has focus") ;
    is (getHtmlElement($res, '//input/@autofocus')->size, 1, "Only one field has focus");
    count(2);

    # Fail password
    ok(
        $res = $client->_post(
            '/',
            {
                user     => "dwho",
                password => "invalid",
                test     => "3_demo",
            },
            accept => "text/html",
        ),
        'Auth query'
    );
    count(1);
    my $n = getHtmlElement( $res,
        '//div[@id="id_3_demo"]//input[@id="userfield"]/@value' )->pop();
    is( $n->value, "dwho", "login autofilled in SQL form" );
    $n = getHtmlElement( $res,
        '//div[@id="id_2_sql"]//input[@id="userfield"]/@value' )->pop();
    is( $n->value, "", "login not autofilled in SQL form" );
    count(2);

    ok(getHtmlElement( $res,
            '//div[@id="id_3_demo"]//input[@id="passwordfield"]/@autofocus' ), "Password field has focus") ;
    is (getHtmlElement($res, '//input/@autofocus')->size, 1, "Only one field has focus");
    count(2);

    # Authenticate
    ok(
        $res = $client->_post(
            '/',
            {
                user     => "dwho",
                password => "dwho",
                test     => "2_sql",
            },
        ),
        'Auth query'
    );
    expectOK($res);
    my $id = expectCookie($res);
    $client->logout($id);

    # Test selection by hook
    ok(
        $res = $client->_post(
            '/',
            {
                user     => "dwho",
                password => "dwho",
            },
            ip => '1.2.3.4',
        ),
        'Auth query'
    );
    count(1);
    expectOK($res);
    $id = expectCookie($res);
    $client->logout($id);

    # Select by only available choice (disabled)
    $client->ini( {
            %{ $client->ini },
            authChoiceModules    => { '1_demo' => 'Demo;Demo;Null' },
            authChoiceSelectOnly => 0
        }
    );
    ok(
        $res = $client->_post(
            '/',
            {
                user     => "dwho",
                password => "dwho",
            },
            accept => "text/html",
        ),
        'Auth query'
    );
    count(1);
    expectPortalError( $res, 9 );

    # Select by only available choice (enabled)
    $client->ini( {
            %{ $client->ini },
            authChoiceModules    => { '1_demo' => 'Demo;Demo;Null' },
            authChoiceSelectOnly => 1
        }
    );
    ok(
        $res = $client->_post(
            '/',
            {
                user     => "dwho",
                password => "dwho",
            },
            accept => "text/html",
        ),
        'Auth query'
    );
    count(1);
    expectCookie($res);

    clean_sessions();
}
count($maintests);
clean_sessions();
done_testing( count() );
