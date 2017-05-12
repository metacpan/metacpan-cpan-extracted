# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Portal.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

package My::Portal;
use Test::More tests => 3;
use IO::String;
use strict;

BEGIN { use_ok( 'Lemonldap::NG::Portal::Simple', ':all' ) }
our @ISA = qw(Lemonldap::NG::Portal::Simple);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

our $buf;

tie *STDOUT, 'IO::String', $buf;
our $lastpos = 0;

sub diff {
    my $str = $buf;
    $str =~ s/^.{$lastpos}//s if ($lastpos);
    $str =~ s/\r//gs;
    $lastpos = length $buf;
    return $str;
}

sub abort {
    shift;
    local $, = ' ';
    print STDERR @_;
}

sub goToPortal {
    PE_BADCREDENTIALS;
}

my $p;

# CGI Environment
$ENV{SCRIPT_NAME}     = '/test.pl';
$ENV{SCRIPT_FILENAME} = '/tmp/test.pl';
$ENV{REQUEST_METHOD}  = 'GET';
$ENV{REQUEST_URI}     = '/';
$ENV{QUERY_STRING}    = '';

ok(
    $p = My::Portal->new(
        {
            globalStorage   => 'Apache::Session::File',
            domain          => 'example.com',
            authentication  => 'Proxy',
            userDB          => 'Null',
            passwordDB      => 'Null',
            registerDB      => 'Null',
            cookieName      => 'lemonldap',
            portal          => 'http://abc',
            soapAuthService => 'https://lm.com',
        }
    ),
    'Portal object'
);

ok( ( $p->process() == 0 and $p->{error} == PE_FIRSTACCESS ), 'Init succeed' );

