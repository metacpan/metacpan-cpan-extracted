# Base library for tests

use strict;
use 5.10.0;
use POSIX 'strftime';
use Data::Dumper;
use Time::Fake;
use_ok('Lemonldap::NG::Common::PSGI::Cli::Lib');

our $client;
our $count = 1;

no warnings 'redefine';

my $module;
our $sessionId =
  'f5eec18ebb9bc96352595e2d8ce962e8ecf7af7c9a98cb9a43f9cd181cf4b545';
our $file = "t/sessions/$sessionId";

sub init {
    my ( $arg, $prms ) = @_;
    if ($arg) {
        $module = $arg;
        use_ok($module);
    }
    $prms ||= {};
    %$prms = (
        configStorage       => { type => 'File', dirName => 't' },
        localSessionStorage => '',
        logLevel            => 'error',
        cookieName          => 'lemonldap',
        securedCookie       => 0,
        https               => 0,
        hiddenAttributes    => 'mail cn',
        logger              => 'Lemonldap::NG::Common::Logger::Std',
        %$prms
    );
    ok(
        $client =
          Lemonldap::NG::Handler::PSGI::Cli::Lib->new( { ini => $prms } ),
        'Client object'
    );
    ok( $client->app, 'App object' ) or explain( $client, '->app...' );
    count(3);

    my $now = time;
    my $ts  = strftime "%Y%m%d%H%M%S", localtime;

    my $sessionData = {
        '_timezone'     => '1',
        'groups'        => 'users; timelords',
        'uid'           => 'dwho',
        '_loginHistory' => {
            'successLogin' => [ {
                    '_utime' => $now,
                    'ipAddr' => '127.0.0.1'
                }
            ]
        },
        'cn'              => 'Doctor Who',
        '_lastAuthnUTime' => $now,
        '_whatToTrace'    => 'dwho',
        '_issuerDB'       => 'Null',
        '_startTime'      => "$ts",
        '_user'           => 'dwho',
        '_updateTime'     => "$ts",
        '_userDB'         => 'Demo',
        'hGroups'         => {
            'users'     => {},
            'timelords' => {}
        },
        'ipAddr'              => '127.0.0.1',
        'mail'                => 'dwho@badwolf.org',
        'authenticationLevel' => 1,
        '_utime'              => $now,
        '_passwordDB'         => 'Demo',
        '_auth'               => 'Demo',
        'UA'                  =>
'Mozilla/5.0 (X11; VAX4000; rv:43.0) Gecko/20100101 Firefox/143.0 Iceweasel/143.0.1'
    };

    my $as = Lemonldap::NG::Common::Session->new( {
            storageModule        => 'Apache::Session::File',
            storageModuleOptions => { Directory => 't/sessions' },
            id                   => $sessionId,
            force                => 1,
            kind                 => 'SSO',
            info                 => $sessionData,
        }
    );

}

sub client {
    return $client;
}

sub module {
    if ( my $arg = shift ) {
        $module = $arg;
    }
    return $module;
}

sub count {
    my $c = shift;
    $count += $c if ($c);
    return $count;
}

sub explain {
    my ( $get, $ref ) = @_;
    $get = Dumper($get) if ( ref $get );
    print STDERR "Expect $ref, get $get\n";
}

sub clean {
    unlink glob 't/sessions/*';
    unlink glob 't/sessions/lock/*';
}

package Lemonldap::NG::Handler::PSGI::Cli::Lib;

use Mouse;

extends 'Lemonldap::NG::Common::PSGI::Cli::Lib';

has ini => ( is => 'rw' );

has app => (
    is      => 'ro',
    isa     => 'CodeRef',
    builder => sub {
        return $module->run( $_[0]->{ini} );
    }
);

sub _get {
    my ( $self, $path, $query, $host, $cookie, %custom ) = @_;
    $query //= '';
    $host ||= 'test1.example.com';
    return $self->app->( {
            'HTTP_ACCEPT'          => 'text/html',
            'SCRIPT_NAME'          => 'lmAuth',
            'SERVER_NAME'          => '127.0.0.1',
            'QUERY_STRING'         => $query,
            'HTTP_CACHE_CONTROL'   => 'max-age=0',
            'HTTP_ACCEPT_LANGUAGE' => 'fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3',
            'PATH_INFO'            => $path,
            'REQUEST_METHOD'       => 'GET',
            'REQUEST_URI'          => '/lmauth',
            'X_ORIGINAL_URI'       => $path . ( $query ? "?$query" : '' ),
            'SERVER_PORT'          => '80',
            'SERVER_PROTOCOL'      => 'HTTP/1.1',
            'HTTP_USER_AGENT'      =>
              'Mozilla/5.0 (VAX-4000; rv:36.0) Gecko/20350101 Firefox',
            'REMOTE_ADDR' => '127.0.0.1',
            'HTTP_HOST'   => $host,
            ( $cookie ? ( HTTP_COOKIE => $cookie ) : ( HTTP_COOKIE => '' ) ),
            %custom,
        }
    );
}

1;
