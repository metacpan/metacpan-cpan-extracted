package LLNG::Mirror;

use strict;

our @ISA = ('Lemonldap::NG::Handler::PSGI');

our $defaultIni = {
    configStorage       => { type => 'File', dirName => 't' },
    localSessionStorage => '',
    logLevel            => 'error',
    https               => 0,
};

sub new {
    my $self = Lemonldap::NG::Handler::PSGI->new();
    $self->init($defaultIni);
    bless $self, $_[0];
}

sub handler {
    my ( $self, $req ) = @_;
    my $h = $req->headers->as_string;
    return [ 200, [ 'Content-Type' => 'text/plain' ], [$h] ];
}

package main;

BEGIN {
    use_ok('Lemonldap::NG::Handler::PSGI');
    count(1);
}
my $m   = LLNG::Mirror->new;
my $app = $m->run;

sub mirror {
    my (%args) = @_;
    return $app->( {
            'HTTP_ACCEPT' => $args{accept}
              || 'application/json, text/plain, */*',
            'HTTP_ACCEPT_LANGUAGE' => 'fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3',
            'HTTP_CACHE_CONTROL'   => 'max-age=0',
            ( $args{cookie} ? ( HTTP_COOKIE => $args{cookie} ) : () ),
            'HTTP_HOST'       => $args{host} || 'test1.example.com',
            'HTTP_USER_AGENT' =>
              'Mozilla/5.0 (VAX-4000; rv:36.0) Gecko/20350101 Firefox',
            'PATH_INFO' => $args{path} || '/',
            ( $args{referer} ? ( REFERER => $args{referer} ) : () ),
            'REMOTE_ADDR' => '127.0.0.1',
            (
                $args{remote_user}
                ? ( 'REMOTE_USER' => $args{remote_user} )
                : ()
            ),
            'REQUEST_METHOD' => $args{method} || 'GET',
            'REQUEST_URI'    => ( $args{path} || '/' )
              . ( $args{query} ? "?$args{query}" : '' ),
            ( $args{query} ? ( QUERY_STRING => $args{query} ) : () ),
            'SCRIPT_NAME'     => '',
            'SERVER_NAME'     => 'auth.example.com',
            'SERVER_PORT'     => '80',
            'SERVER_PROTOCOL' => 'HTTP/1.1',
            ( $args{custom} ? %{ $args{custom} } : () ),
        }
    );
}

1;
