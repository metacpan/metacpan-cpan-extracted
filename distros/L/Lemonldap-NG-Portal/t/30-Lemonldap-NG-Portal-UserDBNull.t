# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Portal-AuthSsl.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('Lemonldap::NG::Portal::Simple') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Fake ENV
$ENV{"REQUEST_METHOD"} = 'GET';
$ENV{"TEST_STRING"}    = 'OK';
$ENV{"REMOTE_ADDR"}    = '127.0.0.1';

my $p;

ok(
    $p = Lemonldap::NG::Portal::Simple->new(
        {
            globalStorage  => 'Apache::Session::File',
            domain         => 'example.com',
            authentication => 'Null',
            userDB         => 'Null',
            passwordDB     => 'Null',
            registerDB     => 'Null',
            exportedVars   => { uid => "TEST_STRING", },
        }
    )
);

ok( $p->setSessionInfo() == PE_OK, 'Run setSessionInfo' );

ok( $p->{sessionInfo}->{"uid"} eq "OK", 'Read info in session' );

