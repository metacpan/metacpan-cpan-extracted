# Verify that a modified configuration can be saved and that all changes are
# detected

use Test::More;
use strict;
use JSON;
require 't/test-lib.pm';

my $struct    = 't/jsonfiles/11-modified-with-confirmation.json';
my $confFiles = [ 't/conf/lmConf-1.json', 't/conf/lmConf-2.json' ];

sub body {
    return IO::File->new( $struct, 'r' );
}

# Delete lmConf-2.json if exists
eval { unlink $confFiles->[1]; };
mkdir 't/sessions';

my ( $res, $resBody );
ok( $res = &client->_post( '/confs/', 'cfgNum=1', &body, 'application/json' ),
    "Request succeed" );
ok( $res->[0] == 200,                       "Result code is 200" );
ok( $resBody = from_json( $res->[2]->[0] ), "Result body contains JSON text" );

ok( $resBody->{result} == 0, "JSON response contains \"result:0\"" )
  or print STDERR Dumper($resBody);
ok( $resBody->{needConfirm} == 1, "JSON response contains \"needConfirm:1\"" )
  or print STDERR Dumper($resBody);
ok(
    @{ $resBody->{details}->{__warnings__} } == 4,
    'JSON response contains 4 warnings'
) or print STDERR Dumper($resBody);
count(6);

foreach my $i ( 0 .. 3 ) {
    ok(
        $resBody->{details}->{__warnings__}->[$i]->{message} =~
/\b(unprotected|cross-domain-authentication|retries|__badExpressionAssignment__)\b/,
        "Warning with 'unprotect', 'CDA', 'assignment' or 'retries' found"
    ) or print STDERR Dumper($resBody);
    count(1);
}
ok(
    @{ $resBody->{details}->{__needConfirmation__} } == 1,
    'JSON response contains 1 needConfirmation'
) or print STDERR Dumper($resBody);
ok(
    @{ $resBody->{details}->{__changes__} } == 24,
    'JSON response contains 24 changes'
) or print STDERR Dumper($resBody);

#print STDERR Dumper($resBody);
ok(
    $res = &client->_post(
        '/confs/', 'cfgNum=1&force=1', &body, 'application/json'
    ),
    "Request succeed"
);
ok( -f $confFiles->[1], 'File is created' );
count(4);

my @changes = @{&changes};
my @cmsg    = @{ $resBody->{details}->{__changes__} };
my $bug;

while ( my $c = shift @{ $resBody->{details}->{__changes__} } ) {
    my $cmp1 = @changes;
    my $cmp2 = @cmsg;

    @changes = grep { ( $_->{key} || '' ) ne ( $c->{key} || '' ) } @changes;
    @cmsg    = grep { ( $_->{key} || '' ) ne ( $c->{key} || '' ) } @cmsg;
    if ( $c->{key} and $c->{key} eq 'applicationList' ) {
        pass qq("$c->{key}" found);
        count(1);
    }
    elsif ( $c->{key} ) {
        ok( ( $cmp1 - @changes ) == ( $cmp2 - @cmsg ), qq("$c->{key}" found) )
          or print STDERR 'Expect: '
          . ( $cmp1 - @changes )
          . ', got: '
          . ( $cmp2 - @cmsg )
          . "\nChanges "
          . Dumper( \@changes )
          . "Cmsg: "
          . Dumper( \@cmsg );
        count(1);
    }
}
ok( !@changes, 'All changes detected' ) or $bug = 1;
count(1);
if ($bug) {
    print STDERR 'Expected not found: '
      . Dumper( \@changes )
      . 'Changes announced and not found: '
      . Dumper( \@cmsg );
}

#print STDERR Dumper(\@changes,\@cmsg);

# TODO: check result of this
ok( $res = &client->jsonResponse('/diff/1/2'), 'Diff called' );
my ( @c1, @c2 );
ok( ( @c1 = sort keys %{ $res->[0] } ), 'diff() detects changes in conf 1' );
ok( ( @c2 = sort keys %{ $res->[1] } ), 'diff() detects changes in conf 2' );
ok( @c1 == 12, '12 keys changed in conf 1' )
  or print STDERR "Expect: 12 keys, get: " . join( ', ', @c1 ) . "\n";
ok( @c2 == 17, '17 keys changed or created in conf 2' )
  or print STDERR "Expect: 17 keys, get: " . join( ',', @c2 ) . "\n";
count(5);

unlink $confFiles->[1];

#eval { rmdir 't/sessions'; };
done_testing( count() );

# Remove sessions directory
`rm -rf t/sessions`;

sub changes {
    return [ {
            'key' => 'portal',
            'new' => 'http://auth2.example.com/',
            'old' => 'http://auth.example.com/'
        },
        {
            'new' => 0,
            'old' => 1,
            'key' => 'portalDisplayLogout'
        },
        {
            'key' =>
              'applicationList, Sample applications, Application Test 1, uri',
            'old' => 'http://test1.example.com/',
            'new' => 'http://testex.example.com/'
        },
        {
            'new' => 'Application Test 3',
            'key' => 'applicationList, Sample applications'
        },
        {
            'new' => 'Changes in cat(s)/app(s)',
            'key' => 'applicationList',
        },
        {
            'key' => 'applicationList',
            'old' => 'Documentation',
            'new' => 'Administration',
        },
        {
            'key' => 'applicationList',
            'old' => 'Administration',
            'new' => 'Sample applications',
        },
        {
            'key' => 'applicationList',
            'old' => 'Sample applications',
            'new' => 'Documentation',
        },
        {
            'key' => 'userDB',
            'new' => 'LDAP',
            'old' => 'Demo'
        },
        {
            'key' => 'passwordDB',
            'new' => 'LDAP',
            'old' => 'Demo'
        },
        {
            'key' => 'openIdSPList',
            'new' => '1;bad.com'
        },
        {
            'new' => 'Uid',
            'key' => 'exportedVars'
        },
        {
            'key' =>
              'locationRules, test1.example.com, (?#Logout comment)^/logout',
            'new' => 'logout_sso',
            'old' => undef
        },
        {
            'old' => '^/logout',
            'key' => 'locationRules, test1.example.com'
        },
        {
            'key' => 'locationRules, test3.example.com, ^/logout',
            'new' => 'logout_sso',
            'old' => undef
        },
        {
            'key' => 'locationRules, test3.example.com, default',
            'old' => undef,
            'new' => 'accept'
        },
        {
            'key' => 'locationRules',
            'new' => 'test3.example.com'
        },
        {
            'key' => 'exportedHeaders, test3.example.com, Auth-User',
            'old' => undef,
            'new' => '$uid'
        },
        {
            'new' => 'test3.example.com',
            'key' => 'exportedHeaders'
        },
        {
            'key' => 'locationRules, test.ex.com, default',
            'old' => undef,
            'new' => 'deny'
        },
        {
            'key' => 'locationRules',
            'new' => 'test.ex.com'
        },
        {
            'key' => 'virtualHosts',
            'new' => 'test3.example.com',
            'old' => 'test2.example.com'
        },
        {
            'key' => 'virtualHosts',
            'old' => 'test2.example.com'
        },
        {
            'new' => 1,
            'key' => 'portalDisplayResetPassword',
            'old' => 0
        },
        {
            'new' => 0,
            'key' => 'captcha_mail_enabled',
            'old' => '1'
        },
        {
            'confCompacted' => '1',
            'removedKeys'   => 'some; keys'
        },
        {
            'new' => 1,
            'key' => 'avoidAssignment',
            'old' => '0'
        }
    ];
}
