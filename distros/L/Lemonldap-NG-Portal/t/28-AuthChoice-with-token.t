use Test::More;
use IO::String;
use strict;

require 't/test-lib.pm';

my $res;
my $maintests = 6;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel          => 'error',
            useSafeJail       => 1,
            authentication    => 'Choice',
            userDB            => 'Same',
            passwordDB        => 'Choice',
            requireToken      => 1,
            authChoiceParam   => 'test',
            authChoiceModules => {
                '1_demo' => 'Demo;Demo;Null',
                '2_ssl'  => 'SSL;Demo;Null',
            },
        }
    }
);

# Try to authenticate with an unknown user
# -------------------
ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get menu' );
my ( $host, $url, $query ) =
  expectForm( $res, '#', undef, 'user', 'password', 'token' );
my @form = ( $res->[2]->[0] =~ m#<form.*?</form>#sg );
ok( @form == 2, 'Display 2 choices' );
foreach (@form) {
    expectForm( [ $res->[0], $res->[1], [$_] ], undef, undef, 'test' );
}

$query =~ s/user=/user=dalek/;
$query =~ s/password=/password=dwho/;
$query =~ s/test=\w*\b/test=1_demo/;

ok(
    $res = $client->_post(
        '/', IO::String->new($query),
        length => length($query),
        accept => 'text/html',
    ),
    'Auth query with an unknown user'
);
( $host, $url, $query ) =
  expectForm( $res, '#', undef, 'user', 'password', 'token' );

ok(
    $res->[2]->[0] =~ /<span trmsg="5">/,
    'dalek rejected with PE_BADCREDENTIALS'
) or print STDERR Dumper( $res->[2]->[0] );

# Try to authenticate
# -------------------
@form = ( $res->[2]->[0] =~ m#<form.*?</form>#sg );
ok( @form == 2, 'Display 2 choices' );
foreach (@form) {
    expectForm( [ $res->[0], $res->[1], [$_] ], undef, undef, 'test' );
}

$query =~ s/user=[^&]*/user=dwho/;
$query =~ s/password=/password=dwho/;
$query =~ s/test=\w*\b/test=1_demo/;

ok(
    $res = $client->_post(
        '/', IO::String->new($query),
        length => length($query),
        accept => 'text/html',
    ),
    'Auth query'
);
my $id = expectCookie($res);
$client->logout($id);

count($maintests);
clean_sessions();
done_testing( count() );
