# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Portal.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
use strict;

BEGIN { use_ok( 'Lemonldap::NG::Portal::Simple', ':all' ) }
our @ISA = qw(Lemonldap::NG::Portal::Simple);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $p;

# CGI Environment
$ENV{REQUEST_METHOD} = 'GET';
$ENV{REQUEST_URI}    = '/';
$ENV{QUERY_STRING}   = '';
$ENV{REMOTE_ADDR}    = '127.0.0.1';

ok(
    $p = Lemonldap::NG::Portal::Simple->new(
        {
            globalStorage     => 'Apache::Session::File',
            domain            => 'example.com',
            authentication    => 'Choice',
            userDB            => 'Null',
            passwordDB        => 'Null',
            registerDB        => 'Null',
            getUser           => sub { PE_OK },
            setSessionInfo    => sub { PE_OK },
            portal            => 'http://abc',
            sessionInfo       => { uid => 't', },
            userNotice        => sub { },
            authChoiceModules => {
                '1_LDAP_Directory' => 'LDAP|LDAP|LDAP',
                '2_CIA_Backdoor'   => 'Null|Null|Null'
            },
        }
    ),
    'Portal object'
);

my $authLoop = $p->_buildAuthLoop();
ok( ref $authLoop eq "ARRAY", "Authentication loop is an array reference" );

ok( $authLoop->[0]->{key} =~ /(1_LDAP|2_CIA_Backdoor)/,
    "Key registered in auth loop" );
ok(
    $authLoop->[0]->{name} =~ /(LDAP|CIA\sBackdoor)/,
    "Name parsed and registered in auth loop"
);
