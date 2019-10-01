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
            logLevel       => 'error',
            authentication => 'Demo',
            userDB         => 'Same',
            'sfExtra'      => {
                'home' => {
                    'over' => {
                        mail2fCodeRegex => '\w{4}',
                    },
                    'logo' => 'home.jpg',
                    'label' => "Home Label",
                    'rule' => '$uid eq "dwho" or $uid eq "msmith"',
                    'type' => 'Mail2F'
                },
                'work' => {
                    'over' => {
                        mail2fCodeRegex => '\d{8}',
                    },
                    'logo' => 'work.jpg',
                    'rule' => '$uid eq "dwho" or $uid eq "rtyler"',
                    'type' => 'Mail2F'
                }
            },
        }
    }
);

# Login with rtyler
# -----------------
ok(
    my $res = $client->_post(
        '/',
        IO::String->new('user=rtyler&password=rtyler'),
        length => 27,
        accept => 'text/html',
    ),
    'Auth query'
);
count(1);

# Only "work" option is available
my ( $host, $url, $query ) =
  expectForm( $res, undef, '/work2fcheck?skin=bootstrap', 'token', 'code' );

ok(
    $res->[2]->[0] =~
qr%<input name="code" value="" class="form-control" id="extcode" trplaceholder="code" autocomplete="off" />%,
    'Found EXTCODE input'
) or print STDERR Dumper( $res->[2]->[0] );
count(1);

ok( mail() =~ m%<b>(\d{8})</b>%, 'Found 2F code in mail' )
  or print STDERR Dumper( mail() );

my $code = $1;
count(1);

$query =~ s/code=/code=${code}/;
ok(
    $res = $client->_post(
        '/work2fcheck',
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

# Login with dwho
# ---------------
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

# Expect choice page
my ( $host, $url, $query ) =
  expectForm( $res, undef, '/2fchoice', 'token', 'checkLogins' );

ok(
    $res->[2]->[0] =~
      qq%<img src="/static/bootstrap/work.jpg" alt="work2F" title="work2F" />%,
    'Found work.jpg'
) or print STDERR Dumper( $res->[2]->[0] );
count(1);

ok(
    $res->[2]->[0] =~
      qq%<img src="/static/bootstrap/home.jpg" alt="home2F" title="home2F" />%,
    'Found home.jpg'
) or print STDERR Dumper( $res->[2]->[0] );
count(1);

ok(
    $res->[2]->[0] =~ qq%<h4 class="mb-0" trspan="work2f"></h4>%, 'Found translation label'
) or print STDERR Dumper( $res->[2]->[0] );
count(1);

ok(
    $res->[2]->[0] =~ qq%<h4 class="mb-0">Home Label</h4>%, 'Found overriden label'
) or print STDERR Dumper( $res->[2]->[0] );
count(1);

$query .= '&sf=home';
ok(
    $res = $client->_post(
        '/2fchoice',
        IO::String->new($query),
        length => length($query),
        accept => 'text/html',
    ),
    'Post ext2f choice'
);
count(1);

my ( $host, $url, $query ) =
  expectForm( $res, undef, '/home2fcheck?skin=bootstrap', 'token', 'code' );

ok(
    $res->[2]->[0] =~
qr%<input name="code" value="" class="form-control" id="extcode" trplaceholder="code" autocomplete="off" />%,
    'Found EXTCODE input'
) or print STDERR Dumper( $res->[2]->[0] );
count(1);

ok( mail() =~ m%<b>(\w{4})</b>%, 'Found 2F code in mail' )
  or print STDERR Dumper( mail() );

my $code = $1;
count(1);

$query =~ s/code=/code=${code}/;
ok(
    $res = $client->_post(
        '/home2fcheck',
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

