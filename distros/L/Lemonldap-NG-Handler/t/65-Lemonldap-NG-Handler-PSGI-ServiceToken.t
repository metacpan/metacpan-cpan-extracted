use Test::More;

BEGIN {
    require 't/test-psgi-lib.pm';
}

init(
    'Lemonldap::NG::Handler::Server',
    {
        logLevel               => 'error',
        handlerServiceTokenTTL => 120,
        vhostOptions           => {
            'test1.example.com' => {
                vhostHttps           => 0,
                vhostPort            => 80,
                vhostMaintenance     => 0,
                vhostServiceTokenTTL => 180,
            },
            'test2.example.com' => {
                vhostHttps           => 0,
                vhostPort            => 80,
                vhostMaintenance     => 0,
                vhostServiceTokenTTL => 300,
            }
        },
        exportedHeaders => {
            'test2.example.com' => {
                'Auth-User' => '$uid',
                'empty'     => undef,
                'zero'      => "'0'",
            },
        }
    }
);

my $res;
my $crypt = Lemonldap::NG::Common::Crypto->new('qwertyui');
my $token = $crypt->encrypt(
    join ':',                        time,
    $sessionId,                      'test1.example.com',
    'XFromVH=app1-auth.example.com', "serviceHeader1=$sessionId",
    "serviceHeader2=$sessionId",     'test2.example.com',
    '*.example.com'
);

ok(
    $res = $client->_get(
        '/', undef, 'test1.example.com', undef,
        VHOSTTYPE           => 'ServiceToken',
        'HTTP_X_LLNG_TOKEN' => $token,
    ),
    'Query with token 1'
);
ok( $res->[0] == 200, 'Code is 200' ) or explain( $res->[0], 200 );
count(2);

my @headers = grep { /^serviceHeader\d$|^XFromVH$/ } @{ $res->[1] };
my @values  = grep { /\.example\.com|^$sessionId$/ } @{ $res->[1] };
ok( @headers == 3, 'Found 3 service headers' )
  or print STDERR Data::Dumper::Dumper( $res->[1] );
ok( @values == 3, 'Found 3 service header values' )
  or print STDERR Data::Dumper::Dumper( $res->[1] );
count(2);

# Waiting
Time::Fake->offset("+90s");

ok(
    $res = $client->_get(
        '/', undef, 'test1.example.com', undef,
        VHOSTTYPE           => 'ServiceToken',
        'HTTP_X_LLNG_TOKEN' => $token,
    ),
    'Query with token 2'
);
ok( $res->[0] == 200, 'Code is 200' ) or explain( $res->[0], 200 );
count(2);

@headers = grep { /^serviceHeader\d$|^XFromVH$/ } @{ $res->[1] };
@values  = grep { /\.example\.com|^$sessionId$/ } @{ $res->[1] };
ok( @headers == 3, 'Found 3 service headers' )
  or print STDERR Data::Dumper::Dumper( $res->[1] );
ok( @values == 3, 'Found 3 service header values' )
  or print STDERR Data::Dumper::Dumper( $res->[1] );
count(2);

# Waiting
Time::Fake->offset("+210s");

ok(
    $res = $client->_get(
        '/', undef, 'test1.example.com', undef,
        VHOSTTYPE           => 'ServiceToken',
        'HTTP_X_LLNG_TOKEN' => $token,
    ),
    'Query with token 3'
);
ok( $res->[0] == 302, 'Code is 302' ) or explain( $res->[0], 302 );
count(2);

@headers = grep { /^serviceHeader\d$|^XFromVH$/ } @{ $res->[1] };
ok( @headers == 0, 'NONE service header found' )
  or print STDERR Data::Dumper::Dumper( $res->[1] );
count(1);

# Waiting
Time::Fake->offset("+270s");

ok(
    $res = $client->_get(
        '/', undef, 'test2.example.com', undef,
        VHOSTTYPE           => 'ServiceToken',
        'HTTP_X_LLNG_TOKEN' => $token,
    ),
    'Query with token 4'
);
ok( $res->[0] == 200, 'Code is 200' ) or explain( $res->[0], 200 );
count(2);

my %headers = @{ $res->[1] };
ok( $headers{'zero'} eq '0', 'Found "zero" header with "0"' )
  or print STDERR Data::Dumper::Dumper( $res->[1] );
ok( $headers{'empty'} eq '', 'Found "empty" header without value' )
  or print STDERR Data::Dumper::Dumper( $res->[1] );
count(2);

@headers = grep { /^serviceHeader\d$|^XFromVH$/ } @{ $res->[1] };
@values  = grep { /\.example\.com|^$sessionId$/ } @{ $res->[1] };
ok( @headers == 3, 'Found 3 service headers' )
  or print STDERR Data::Dumper::Dumper( $res->[1] );
ok( @values == 3, 'Found 3 service header values' )
  or print STDERR Data::Dumper::Dumper( $res->[1] );
count(2);

# Waiting
Time::Fake->offset("+330s");

ok(
    $res = $client->_get(
        '/', undef, 'test2.example.com', undef,
        VHOSTTYPE           => 'ServiceToken',
        'HTTP_X_LLNG_TOKEN' => $token,
    ),
    'Query with token 5'
);
ok( $res->[0] == 302, 'Code is 302' ) or explain( $res->[0], 302 );
count(2);

@headers = grep { /^serviceHeader\d$|^XFromVH$/ } @{ $res->[1] };
ok( @headers == 0, 'NONE service header found' )
  or print STDERR Data::Dumper::Dumper( $res->[1] );
count(1);

ok(
    $res = $client->_get(
        '/', undef, 'test3.example.com', undef,
        VHOSTTYPE           => 'ServiceToken',
        'HTTP_X_LLNG_TOKEN' => $token,
    ),
    'Query with token 6'
);
ok( $res->[0] == 302, 'Code is 302' ) or explain( $res->[0], 302 );
count(2);

@headers = grep { /^serviceHeader\d$|^XFromVH$/ } @{ $res->[1] };
ok( @headers == 0, 'NONE service header found' )
  or print STDERR Data::Dumper::Dumper( $res->[1] );
count(1);

$token = $crypt->encrypt( join ':', time, $sessionId );
ok(
    $res = $client->_get(
        '/', undef, 'test2.example.com', undef,
        VHOSTTYPE           => 'ServiceToken',
        'HTTP_X_LLNG_TOKEN' => $token,
    ),
    'Query with token 7'
);
ok( $res->[0] == 302, 'Code is 302' ) or explain( $res->[0], 302 );
count(2);

@headers = grep { /^serviceHeader\d$|^XFromVH$/ } @{ $res->[1] };
ok( @headers == 0, 'NONE service header found' )
  or print STDERR Data::Dumper::Dumper( $res->[1] );
count(1);

done_testing( count() );

clean();
