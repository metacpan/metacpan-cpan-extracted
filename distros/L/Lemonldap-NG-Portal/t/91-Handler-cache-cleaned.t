use Test::More;
use strict;
use IO::String;
use Data::Dumper;

require 't/test-lib.pm';
require 't/smtp.pm';

use_ok('Lemonldap::NG::Common::FormEncode');
count(1);

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel         => 'error',
            mail2fActivation => '$uid eq "msmith"',
            mail2fAuthnLevel => 3,
            mail2fCodeRegex  => '\d{4}',
            authentication   => 'Demo',
            userDB           => 'Same',
        }
    }
);

# Login as dwho
ok(
    my $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23,
        accept => 'text/html',
    ),
    'Auth query'
);
count(1);
my $dwho_id = expectCookie($res);

ok(
    $res = $client->_get(
        '/', cookie => "lemonldap=$dwho_id",
    ),
    'Get portal'
);
expectAuthenticatedAs( $res, 'dwho' );
count(1);

# Start logging in as msmith
my $s = buildForm( {
        user     => 'msmith',
        password => 'msmith',
    }
);
ok(
    $res = $client->_post(
        '/',
        IO::String->new($s),
        length => length($s),
        accept => 'text/html',
    ),
    'Auth query'
);
count(1);

my ( $host, $url, $query ) =
  expectForm( $res, undef, '/mail2fcheck?skin=bootstrap', 'token', 'code' );

ok(
    $res->[2]->[0] =~
qr%<input name="code" value="" type="text" class="form-control" id="extcode" trplaceholder="code" autocomplete="one-time-code" />%,
    'Found EXTCODE input'
) or print STDERR Dumper( $res->[2]->[0] );
count(1);

ok( mail() =~ m%<b>(\d{4})</b>%, 'Found 2F code in mail' )
  or print STDERR Dumper( mail() );

my $code = $1;
count(1);

# Fill the handler cache with dwho session info
ok(
    $res = $client->_get(
        '/', cookie => "lemonldap=$dwho_id",
    ),
    'Get portal'
);
count(1);

# Finish logging in as msmith,
# this corrupts the dwho cache with msmith macros
$query =~ s/code=/code=${code}/;
ok(
    $res = $client->_post(
        '/mail2fcheck',
        IO::String->new($query),
        length => length($query),
        accept => 'text/html',
    ),
    'Post code'
);
count(1);

# Reuse the corrupted cache
ok(
    $res = $client->_get(
        '/', cookie => "lemonldap=$dwho_id",
    ),
    'Get portal'
);
count(1);

expectAuthenticatedAs( $res, 'dwho' );

clean_sessions();

done_testing( count() );

