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
            mail2fActivation => 1,
            mail2fCodeRegex  => '\d{4}',
            authentication   => 'Demo',
            userDB           => 'Same',
            mailSessionKey   => 'mail',
            macros           =>
              { mail2f => '"test\@example.com"', _whatToTrace => '$uid' },
            mail2fSessionKey => 'mail2f',
        }
    }
);

# Try to authenticate
# -------------------
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

my ( $host, $url, $query ) =
  expectForm( $res, undef, '/mail2fcheck?skin=bootstrap', 'token', 'code' );

ok(
    $res->[2]->[0] =~
qr%<input name="code" value="" type="text" class="form-control" id="extcode" trplaceholder="code" autocomplete="one-time-code" />%,
    'Found EXTCODE input'
) or print STDERR Dumper( $res->[2]->[0] );
count(1);

ok( envelope()->{to}->[0] eq 'test@example.com', 'Use 2F mail sessionkey' )
  or print STDERR Dumper( envelope() );
count(1);

ok( mail() =~ m%<b>(\d{4})</b>%, 'Found 2F code in mail' )
  or print STDERR Dumper( mail() );
my $code = $1;
count(1);

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
my $id = expectCookie($res);
$client->logout($id);

clean_sessions();

done_testing( count() );

