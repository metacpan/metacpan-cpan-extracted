# Test viewer API

use Test::More;
use strict;
use IO::String;
use JSON qw(from_json);

require 't/test-lib.pm';

my $struct = 't/jsonfiles/70-diff.json';

sub body {
    return IO::File->new( $struct, 'r' );
}

# Load lemonldap-ng-noDiff.ini
my $client2;
ok(
    $client2 = Lemonldap::NG::Manager::Cli::Lib->new(
        iniFile => 't/lemonldap-ng-noDiff.ini'
    ),
    'Client object'
);

# Try to compare confs 1 & 2
ok(
    my $res = $client2->_post(
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

# Test that Conf key value is sent
$res = $client2->jsonResponse('/view/2/portalDisplayOidcConsents');
ok( $res->{value} eq '$_oidcConsents && $_oidcConsents =~ /\\w+/', 'Key found' )
  or print STDERR Dumper($res);
count(1);

# Test that hidden key values are NOT sent
$res = &client->jsonResponse('/view/2/portalDisplayLogout');
ok( $res->{value} eq '_Hidden_', 'Key is hidden' )
  or explain( $res, 'value => "_Hidden_"' );
count(1);

# Browse confs is forbidden
$res = $client2->jsonResponse('/view/2');
ok( $res->{value} eq '_Hidden_', 'Key is hidden' )
  or print STDERR Dumper($res);
count(1);

# Try to display latest conf
$res = &client->jsonResponse('/view/latest');
ok( $res->{cfgNum} eq '2', 'Latest conf loaded' );
count(1);

# Try to compare confs
$res = $client2->jsonResponse('/view/diff/1/2');
ok( $res->{value} eq '_Hidden_', 'Diff is NOT allowed' )
  or print STDERR Dumper($res);
count(1);

# Try to display latest conf
$res = $client2->jsonResponse('/view/1');
ok( $res->{value} eq '_Hidden_', 'Browser is NOT allowed' )
  or print STDERR Dumper($res);
count(2);

# Remove new conf
`rm -rf t/conf/lmConf-2.json`;

done_testing( count() );

