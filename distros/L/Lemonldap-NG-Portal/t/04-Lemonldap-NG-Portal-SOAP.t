# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Portal.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
package My::Portal;

use strict;
use IO::String;
use Test::More tests => 4;

BEGIN { use_ok( 'Lemonldap::NG::Portal::Simple', ':all' ) }
our @ISA = qw(Lemonldap::NG::Portal::Simple);

sub abort {
    shift;
    $, = '';
    print STDERR @_;
    die 'abort has been called';
}

sub quit {
    2;
}

our $param;

sub param {
    return $param;
}

sub soapfunc {
    return 'SoapOK';
}

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

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $p;

# CGI Environment
$ENV{SCRIPT_NAME}     = '/test.pl';
$ENV{SCRIPT_FILENAME} = '/tmp/test.pl';
$ENV{REQUEST_METHOD}  = 'GET';
$ENV{REQUEST_URI}     = '/';
$ENV{QUERY_STRING}    = '';

SKIP: {
    eval { require SOAP::Lite };
    skip "SOAP::Lite is not installed, so CGI SOAP functions will not work", 3
      if ($@);

    ok(
        $p = Lemonldap::NG::Portal::Simple->new(
            {
                globalStorage        => 'Apache::Session::File',
                globalStorageOptions => {
                    Directory     => '/tmp/',
                    LockDirectory => '/tmp/',
                },
                domain           => 'example.com',
                cookieName       => 'lemonldaptest',
                authentication   => 'Multi SSL;Demo',
                userDB           => 'Null',
                passwordDB       => 'Null',
                registerDB       => 'Null',
                soap             => 1,
                whatToTrace      => 'uid',
                securedCookie    => 0,
                hiddenAttributes => '_passwd',
            }
        ),
        'Portal object'
    );
    bless $p, 'My::Portal';

    open STDERR, '>/dev/null';

    $p->getCookies( "dwho", "test" );
    ok( $p->{error} != 0, 'getCookies with bad password' );

    $p = Lemonldap::NG::Portal::Simple->new(
        {
            globalStorage        => 'Apache::Session::File',
            globalStorageOptions => {
                Directory     => '/tmp/',
                LockDirectory => '/tmp/',
            },
            domain           => 'example.com',
            cookieName       => 'lemonldaptest',
            authentication   => 'Multi SSL;Demo',
            userDB           => 'Null',
            passwordDB       => 'Null',
            registerDB       => 'Null',
            soap             => 1,
            whatToTrace      => 'uid',
            securedCookie    => 0,
            hiddenAttributes => '_passwd',
        }
    );

    $p->getCookies( "dwho", "dwho" );
    ok( $p->{error} == 0, 'getCookies with good password' );
}
