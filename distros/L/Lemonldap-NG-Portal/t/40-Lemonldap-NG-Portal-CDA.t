# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Portal.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

package My::Portal;

use Test::More tests => 3;
BEGIN { use_ok('Lemonldap::NG::Portal::CDA') }
our @ISA = ('Lemonldap::NG::Portal::CDA');

# skipping SharedConf::getConf
sub getConf {
    return Lemonldap::NG::Portal::Simple::getConf(@_);
}

# CGI Environment
$ENV{SCRIPT_NAME}     = '/test.pl';
$ENV{SCRIPT_FILENAME} = '/tmp/test.pl';
$ENV{REQUEST_METHOD}  = 'GET';
$ENV{REQUEST_URI}     = '/';
$ENV{QUERY_STRING}    = '';

ok(
    $p = My::Portal->new(
        {
            globalStorage  => 'Apache::Session::File',
            domain         => 'example.com',
            cookieName     => 'lemonldap',
            authentication => 'Null',
            userDB         => 'Null',
            passwordDB     => 'Null',
            registerDB     => 'Null',
        }
    ),
    'Portal object'
);

ok( $p->{cda}, 'CDA is set' );

