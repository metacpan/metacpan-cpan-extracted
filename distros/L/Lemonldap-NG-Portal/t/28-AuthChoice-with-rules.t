use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';

my $res;
my $maintests = 12;

eval { unlink 't/userdb.db' };

SKIP: {
    eval { require DBI; require DBD::SQLite; };
    if ($@) {
        skip 'DBD::SQLite not found', $maintests;
    }
    my $dbh = DBI->connect("dbi:SQLite:dbname=t/userdb.db");
    $dbh->do('CREATE TABLE users (user text,password text,name text)');
    $dbh->do("INSERT INTO users VALUES ('dwho','dwho','Doctor who')");

    my $client = LLNG::Manager::Test->new(
        {
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
                },

                dbiAuthChain        => 'dbi:SQLite:dbname=t/userdb.db',
                dbiAuthUser         => '',
                dbiAuthPassword     => '',
                dbiAuthTable        => 'users',
                dbiAuthLoginCol     => 'user',
                dbiAuthPasswordCol  => 'password',
                dbiAuthPasswordHash => '',
                customAuth          => '::Auth::Apache',
                customAddParams     => {},
            }
        }
    );

    ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu' );
    ok( $res->[2]->[0] !~ /1_demo/,       '1_demo not displayed' );
    ok( $res->[2]->[0] =~ /3_demo/,       '3_demo displayed' );
    ok( $res->[2]->[0] =~ /5_ssl/,        '5_ssl displayed' );
    ok( $res->[2]->[0] =~ /6_FakeCustom/, '6_FakeCustom displayed' );
    ok( $res->[2]->[0] =~ qr%img src="/static/common/modules/Apache.png"%,
        'Found 6_FakeCustom Logo' )
      or print STDERR Dumper( $res->[2]->[0] );
    ok( $res->[2]->[0] =~ qr%<img src="/static/common/modules/SSL.png"%,
        'Found 5_ssl Logo' )
      or print STDERR Dumper( $res->[2]->[0] );
    ok( $res->[2]->[0] =~ m%<form action="https://test.example.com"%,
        ' Redirect URL found' )
      or print STDERR Dumper( $res->[2]->[0] );
    my $header = getHeader( $res, 'Content-Security-Policy' );
    ok( $header =~ m%;form-action \'self\'  https://test.example.com;%,
        ' CSP URL found' )
      or print STDERR Dumper( $res->[1] );
    ok( $res->[2]->[0] !~ /4_demo/, '4_Demo not displayed' );
    ok(
        $res->[2]->[0] =~ qr%<img src="/static/common/logos/logo_llng_old.png"%,
        'Found custom Main Logo'
    ) or print STDERR Dumper( $res->[2]->[0] );

    # Test SQL
    my $postString = 'user=dwho&password=dwho&test=2_sql';

    # Try yo authenticate
    # -------------------
    ok(
        $res = $client->_post(
            '/', IO::String->new($postString),
            length => length($postString)
        ),
        'Auth query'
    );
    expectOK($res);
    my $id = expectCookie($res);
    $client->logout($id);
    clean_sessions();
}
count($maintests);
eval { unlink 't/userdb.db' };
clean_sessions();
done_testing( count() );
