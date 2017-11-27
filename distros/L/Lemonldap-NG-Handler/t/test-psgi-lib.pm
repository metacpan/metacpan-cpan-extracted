# Base library for tests

use strict;
use Data::Dumper;
use 5.10.0;
use POSIX 'strftime';
use_ok('Lemonldap::NG::Common::PSGI::Cli::Lib');

our $client;
our $count = 1;
$Data::Dumper::Deparse = 1;

my $module;
our $sessionId =
  'f5eec18ebb9bc96352595e2d8ce962e8ecf7af7c9a98cb9a43f9cd181cf4b545';
our $file = "t/sessions/$sessionId";

sub init {
    $module = shift;
    use_ok($module);
    ok( $client = Lemonldap::NG::Handler::PSGI::Cli::Lib->new(),
        'Client object' );
    ok( $client->app, 'App object' ) or explain( $client, '->app...' );
    count(3);
    open F, ">$file"
      or die $!;
    my $now = time;
    my $ts = strftime "%Y%m%d%H%M%S", localtime;

    print F '{"updateTime":"'
      . $ts
      . '","_timezone":"1","_session_kind":"SSO","_passwordDB":"Demo","startTime":"'
      . $ts
      . '","ipAddr":"127.0.0.1","UA":"Mozilla/5.0 (X11; VAX4000; rv:43.0) Gecko/20100101 Firefox/143.0 Iceweasel/143.0.1","_user":"dwho","_userDB":"Demo","_lastAuthnUTime":'
      . $now
      . ',"uid":"dwho","_issuerDB":"Null","_session_id":"f5eec18ebb9bc96352595e2d8ce962e8ecf7af7c9a98cb9a43f9cd181cf4b545","authenticationLevel":1,"_whatToTrace":"dwho","_auth":"Demo","_utime":'
      . $now
      . ',"loginHistory":{"successLogin":[{"ipAddr":"127.0.0.1","_utime":'
      . $now
      . '}]},"cn":"Doctor Who","mail":"dwho@badwolf.org"}';
    close F;
}

sub client {
    return $client;
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
    unlink $file;
}

package Lemonldap::NG::Handler::PSGI::Cli::Lib;

use Mouse;

extends 'Lemonldap::NG::Common::PSGI::Cli::Lib';

has app => (
    is      => 'ro',
    isa     => 'CodeRef',
    builder => sub {
        return $module->run(
            {
                configStorage       => { type => 'File', dirName => 't' },
                localSessionStorage => '',
                logLevel            => 'warn',
                cookieName          => 'lemonldap',
                securedCookie       => 0,
                https               => 0,
            }
        );
    }
);

sub _get {
    my ( $self, $path, $query, $host, $cookie ) = @_;
    $query //= '';
    $host ||= 'test1.example.com';
    return $self->app->(
        {
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
            'HTTP_USER_AGENT' =>
              'Mozilla/5.0 (VAX-4000; rv:36.0) Gecko/20350101 Firefox',
            'REMOTE_ADDR' => '127.0.0.1',
            'HTTP_HOST'   => $host,
            ( $cookie ? ( HTTP_COOKIE => $cookie ) : ( HTTP_COOKIE => '' ) )
        }
    );
}

1;
