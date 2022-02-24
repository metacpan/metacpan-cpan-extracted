# Test viewer API

use Test::More;
use strict;
use IO::String;
use JSON qw(from_json);

require 't/test-lib.pm';

my $struct = 't/jsonfiles/70-diff.json';

# Remove new conf
unlink 't/conf/lmConf-2.json';

sub body {
    return IO::File->new( $struct, 'r' );
}

# Test that key value is sent
my $res = &client->jsonResponse('/view/1/portalDisplayOidcConsents');
ok( $res->{value} eq '$_oidcConsents && $_oidcConsents =~ /\\w+/',
    'Key found' );
count(1);

# Test that hidden key values are NOT sent
$res = &client->jsonResponse('/view/1/portalDisplayLogout');
ok( $res->{value} eq '_Hidden_', 'Key is hidden' )
  or explain( $res, 'value => "_Hidden_"' );
$res = &client->jsonResponse('/view/1/samlIDPMetaDataNodes');
ok( ref($res) eq 'HASH' and $res->{value} eq '_Hidden_', 'Key is hidden' )
  or explain( $res, 'value => "_Hidden_"' );
count(2);

# Try to display latest conf
$res = &client->jsonResponse('/view/latest');
ok( $res->{cfgNum} eq '1', 'Latest conf loaded' )
  or explain( $res, "cfgNum => 1" );
count(1);

ok(
    $res = &client->_post(
        '/confs/', 'cfgNum=1&force=1', &body, 'application/json'
    ),
    "Request succeed"
);
ok( $res->[0] == 200, "Result code is 200" );
my $resBody;
ok( $resBody = from_json( $res->[2]->[0] ), "Result body contains JSON text" );
count(3);

foreach my $i ( 0 .. 1 ) {
    ok(
        $resBody->{details}->{__changes__}->[$i]->{key} =~
          /\b(captcha_login_enabled|captcha_mail_enabled)\b/,
        "Details with captcha 'login' or 'mail' found"
    ) or print STDERR Dumper($resBody);
}
count(2);

# Try to compare confs 1 & 2
$res = &client->jsonResponse('/view/diff/1/2');

ok( $res->[1]->{captcha_login_enabled} eq '1', 'Key found' );
ok( $res->[1]->{captcha_mail_enabled} eq '0',  'Key found' );
ok( 7 == keys %{ $res->[1] },                  'Right number of keys found' )
  or print STDERR Dumper($res);
count(3);

# Try to display previous conf
$res = &client->jsonResponse('/view/1');
ok( $res->{cfgNum} eq '1', 'Browser is allowed' )
  or print STDERR Dumper($res);
count(1);

# Remove new conf
unlink 't/conf/lmConf-2.json';

done_testing( count() );

