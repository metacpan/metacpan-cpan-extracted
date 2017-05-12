# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Portal.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

package My::Portal;
use Test::More tests => 14;
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

sub lmLog {
    my ( $self, $mess, $level ) = @_;
    print STDERR "$mess\n" unless ( $level =~ /^(?:debug|info)$/ );
}

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

    #print STDERR @_;
}

sub goToPortal {
    PE_BADCREDENTIALS;
}

#sub _sub {
#    my $self = shift;
#    print STDERR "DEBUG: $_[0]\n";
#    return $self->SUPER::_sub(@_);
#}

my $p;

# CGI Environment
$ENV{SCRIPT_NAME}          = '/test.pl';
$ENV{SCRIPT_FILENAME}      = '/tmp/test.pl';
$ENV{REQUEST_METHOD}       = 'GET';
$ENV{REQUEST_URI}          = '/';
$ENV{QUERY_STRING}         = '';
$ENV{REMOTE_ADDR}          = '127.0.0.1';
$ENV{HTTP_ACCEPT_LANGUAGE} = 'en';

my ( $test, $testU );
{
    $INC{'Lemonldap/NG/Portal/Auth1.pm'}   = 't/25-Lemonldap-NG-Portal-Multi.t';
    $INC{'Lemonldap/NG/Portal/Auth2.pm'}   = 't/25-Lemonldap-NG-Portal-Multi.t';
    $INC{'Lemonldap/NG/Portal/UserDB1.pm'} = 't/25-Lemonldap-NG-Portal-Multi.t';
    $INC{'Lemonldap/NG/Portal/UserDB2.pm'} = 't/25-Lemonldap-NG-Portal-Multi.t';
    $INC{'Lemonldap/NG/Portal/UserDB3.pm'} = 't/25-Lemonldap-NG-Portal-Multi.t';
    $INC{'Lemonldap/NG/Portal/UserDB4.pm'} = 't/25-Lemonldap-NG-Portal-Multi.t';

    ok(
        $p = My::Portal->new(
            {
                globalStorage        => 'Apache::Session::File',
                domain               => 'example.com',
                authentication       => 'Multi 1;2',
                userDB               => 'Multi 1;2',
                passwordDB           => 'Null',
                registerDB           => 'Null',
                cookieName           => 'lemonldap',
                whatToTrace          => 'dummy',
                multiValuesSeparator => '; ',
                securedCookie        => 0,
                hiddenAttributes     => '',
                getUser              => sub { PE_OK },
                setSessionInfo       => sub { PE_OK },
                portal               => 'http://abc',
                sessionInfo          => { uid => 't', },
                userNotice           => sub { },
                user                 => 'jdoe',
            }
        ),
        'Portal object'
    );

    $test = 0;

    ok( ( $p->process() == 1 and $p->{error} == PE_OK and $test == 1 ),
        'Second module was called' );

    ok(
        ( $p->getDisplayType() eq "display2" ),
        'Display type from module 2 was found'
    );

    ok(
        $p = My::Portal->new(
            {
                globalStorage        => 'Apache::Session::File',
                domain               => 'example.com',
                authentication       => 'Multi 1;2',
                userDB               => 'Multi 1;2',
                passwordDB           => 'Null',
                registerDB           => 'Null',
                cookieName           => 'lemonldap',
                whatToTrace          => 'dummy',
                multiValuesSeparator => '; ',
                securedCookie        => 0,
                hiddenAttributes     => '',
                portal               => 'http://abc',
                sessionInfo          => { uid => 't', },
                userNotice           => sub { },
                user                 => 'jdoe',
            }
        ),
        'Portal object'
    );

    $test  = 0;
    $testU = 0;

    ok( ( $p->process() == 1 and $p->{error} == PE_OK and $testU == 1 ),
        'Second userDB module was called' );

    ok(
        $p = My::Portal->new(
            {
                globalStorage        => 'Apache::Session::File',
                domain               => 'example.com',
                authentication       => 'Multi 1;2',
                userDB               => 'Multi 3;4',
                passwordDB           => 'Null',
                registerDB           => 'Null',
                cookieName           => 'lemonldap',
                whatToTrace          => 'dummy',
                multiValuesSeparator => '; ',
                securedCookie        => 0,
                hiddenAttributes     => '',
                portal               => 'http://abc',
                sessionInfo          => { uid => 't', },
                userNotice           => sub { },
                user                 => 'jdoe',
            }
        ),
        'Portal object'
    );

    $test  = 0;
    $testU = 0;

    ok( ( $p->process() == 1 and $p->{error} == PE_OK and $testU == 1 ),
        'Second userDB module was not called' );

    ok(
        $p = My::Portal->new(
            {
                globalStorage        => 'Apache::Session::File',
                domain               => 'example.com',
                authentication       => 'Multi 1 1==0;2 1==0',
                userDB               => 'Multi 3;4',
                passwordDB           => 'Null',
                registerDB           => 'Null',
                cookieName           => 'lemonldap',
                whatToTrace          => 'dummy',
                multiValuesSeparator => '; ',
                securedCookie        => 0,
                hiddenAttributes     => '',
                portal               => 'http://abc',
                sessionInfo          => { uid => 't', },
                userNotice           => sub { },
                user                 => 'jdoe',
            }
        ),
        'Portal object'
    );

    ok( ( $p->process() == 0 and $p->{error} == PE_NOSCHEME ),
        'No scheme available' );

    ok(
        $p = My::Portal->new(
            {
                globalStorage        => 'Apache::Session::File',
                domain               => 'example.com',
                authentication       => 'Multi 1;2 1==0',
                userDB               => 'Multi 3;4',
                passwordDB           => 'Null',
                registerDB           => 'Null',
                cookieName           => 'lemonldap',
                whatToTrace          => 'dummy',
                multiValuesSeparator => '; ',
                securedCookie        => 0,
                hiddenAttributes     => '',
                portal               => 'http://abc',
                sessionInfo          => { uid => 't', },
                userNotice           => sub { },
                user                 => 'jdoe',
            }
        ),
        'Portal object'
    );

    ok( ( $p->process() == 0 and $p->{error} == PE_ERROR ),
        'Error from previous module' );

    ok(
        $p = My::Portal->new(
            {
                globalStorage        => 'Apache::Session::File',
                domain               => 'example.com',
                authentication       => 'Multi 1;2 1==1',
                userDB               => 'Multi 3;4',
                passwordDB           => 'Null',
                registerDB           => 'Null',
                cookieName           => 'lemonldap',
                whatToTrace          => 'dummy',
                multiValuesSeparator => '; ',
                securedCookie        => 0,
                hiddenAttributes     => '',
                portal               => 'http://abc',
                sessionInfo          => { uid => 't', },
                userNotice           => sub { },
                user                 => 'jdoe',
            }
        ),
        'Portal object'
    );

    ok( ( $p->process() == 1 ), '1 failed, 2 succeed' );
}

package Lemonldap::NG::Portal::Auth1;

sub authInit {
    Lemonldap::NG::Portal::Simple::PE_OK;
}

sub extractFormInfo {
    Lemonldap::NG::Portal::Simple::PE_OK;
}

sub setAuthSessionInfo {
    Lemonldap::NG::Portal::Simple::PE_OK;
}

sub authenticate {
    $test = 1;
    Lemonldap::NG::Portal::Simple::PE_ERROR;
}

sub getDisplayType {
    return "display1";
}

package Lemonldap::NG::Portal::Auth2;

sub authInit {
    Lemonldap::NG::Portal::Simple::PE_OK;
}

sub extractFormInfo {
    Lemonldap::NG::Portal::Simple::PE_OK;
}

sub setAuthSessionInfo {
    Lemonldap::NG::Portal::Simple::PE_OK;
}

sub authenticate {
    Lemonldap::NG::Portal::Simple::PE_OK;
}

sub getDisplayType {
    return "display2";
}

package Lemonldap::NG::Portal::UserDB1;

sub userDBInit {
    Lemonldap::NG::Portal::Simple::PE_OK;
}

sub getUser {
    Lemonldap::NG::Portal::Simple::PE_OK;
}

sub setSessionInfo {
    Lemonldap::NG::Portal::Simple::PE_OK;
}

sub setGroups {
    Lemonldap::NG::Portal::Simple::PE_OK;
}

package Lemonldap::NG::Portal::UserDB2;

sub userDBInit {
    Lemonldap::NG::Portal::Simple::PE_OK;
}

sub getUser {
    Lemonldap::NG::Portal::Simple::PE_OK;
}

sub setSessionInfo {
    $testU = 1;
    Lemonldap::NG::Portal::Simple::PE_OK;
}

sub setGroups {
    Lemonldap::NG::Portal::Simple::PE_OK;
}

package Lemonldap::NG::Portal::UserDB3;

sub userDBInit {
    Lemonldap::NG::Portal::Simple::PE_OK;
}

sub getUser {
    Lemonldap::NG::Portal::Simple::PE_OK;
}

sub setSessionInfo {
    $testU = 1;
    Lemonldap::NG::Portal::Simple::PE_OK;
}

sub setGroups {
    Lemonldap::NG::Portal::Simple::PE_OK;
}

package Lemonldap::NG::Portal::UserDB4;

sub userDBInit {
    Lemonldap::NG::Portal::Simple::PE_OK;
}

sub getUser {
    Lemonldap::NG::Portal::Simple::PE_OK;
}

sub setSessionInfo {
    Lemonldap::NG::Portal::Simple::PE_OK;
}

sub setGroups {
    Lemonldap::NG::Portal::Simple::PE_OK;
}

