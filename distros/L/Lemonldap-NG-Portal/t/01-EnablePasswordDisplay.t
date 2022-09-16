use Test::More;
use IO::String;
use strict;

require 't/test-lib.pm';

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                    => 'error',
            portalEnablePasswordDisplay => 1,
            browsersDontStorePassword   => 1
        }
    }
);

ok( $res = $client->_get( '/', accept => 'text/html' ), 'Display portal' );
ok(
    $res->[2]->[0] =~
      m%<i id="toggle_password" class="fa fa-eye-slash toggle-password">%,
    ' toggle password icon found'
) or print STDERR Dumper( $res->[2]->[0] );
count(2);

ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23,
    ),
    'Auth query'
);
count(1);
expectOK($res);
my $id = expectCookie($res);

ok(
    $res = $client->_get(
        '/',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'Get menu'
);
ok(
    $res->[2]->[0] =~
      m%<i id="toggle_oldpassword" class="fa fa-eye-slash toggle-password">%,
    ' toggle oldpassword icon found'
) or print STDERR Dumper( $res->[2]->[0] );
ok(
    $res->[2]->[0] =~
      m%<i id="toggle_newpassword" class="fa fa-eye-slash toggle-password">%,
    ' toggle newpassword icon found'
) or print STDERR Dumper( $res->[2]->[0] );
ok(
    $res->[2]->[0] =~
m%<i id="toggle_confirmpassword" class="fa fa-eye-slash toggle-password">%,
    ' toggle confirmpassword icon found'
) or print STDERR Dumper( $res->[2]->[0] );
ok(
    $res->[2]->[0] =~
m%<input id="newpassword" name="newpassword" type="text" class="form-control"%,
    ' input type text found'
) or print STDERR Dumper( $res->[2]->[0] );
count(5);

$client->logout($id);
clean_sessions();

done_testing( count() );
