package Lemonldap::NG::Common::PSGI::Cli::Lib;

use strict;
use JSON;
use Mouse;
use Lemonldap::NG::Common::PSGI;

our $VERSION = '2.0.10';

has iniFile => ( is => 'ro', isa => 'Str' );

has app => ( is => 'ro', isa => 'CodeRef' );

sub _get {
    my ( $self, $path, $query ) = @_;
    $query //= '';
    return $self->app->( {
            'HTTP_ACCEPT'          => 'application/json, text/plain, */*',
            'SCRIPT_NAME'          => '',
            'HTTP_ACCEPT_ENCODING' => 'gzip, deflate',
            'SERVER_NAME'          => '127.0.0.1',
            'QUERY_STRING'         => $query,
            'HTTP_CACHE_CONTROL'   => 'max-age=0',
            'HTTP_ACCEPT_LANGUAGE' => 'fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3',
            'PATH_INFO'            => $path,
            'REQUEST_METHOD'       => 'GET',
            'REQUEST_URI'          => $path . ( $query ? "?$query" : '' ),
            'SERVER_PORT'          => '8002',
            'SERVER_PROTOCOL'      => 'HTTP/1.1',
            'HTTP_USER_AGENT'      =>
              'Mozilla/5.0 (VAX-4000; rv:36.0) Gecko/20350101 Firefox',
            'REMOTE_ADDR' => '127.0.0.1',
            'HTTP_HOST'   => '127.0.0.1:8002'
        }
    );
}

sub _post {
    my ( $self, $path, $query, $body, $type, $len ) = @_;
    die "$body must be a IO::Handle"
      unless ( ref($body) and $body->can('read') );
    return $self->app->( {
            'HTTP_ACCEPT'          => 'application/json, text/plain, */*',
            'SCRIPT_NAME'          => '',
            'HTTP_ACCEPT_ENCODING' => 'gzip, deflate',
            'SERVER_NAME'          => '127.0.0.1',
            'QUERY_STRING'         => $query,
            'HTTP_CACHE_CONTROL'   => 'max-age=0',
            'HTTP_ACCEPT_LANGUAGE' => 'fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3',
            'PATH_INFO'            => $path,
            'REQUEST_METHOD'       => 'POST',
            'REQUEST_URI'          => $path . ( $query ? "?$query" : '' ),
            'SERVER_PORT'          => '8002',
            'SERVER_PROTOCOL'      => 'HTTP/1.1',
            'HTTP_USER_AGENT'      =>
              'Mozilla/5.0 (VAX-4000; rv:36.0) Gecko/20350101 Firefox',
            'REMOTE_ADDR'          => '127.0.0.1',
            'HTTP_HOST'            => '127.0.0.1:8002',
            'psgix.input.buffered' => 1,
            'psgi.input'           => $body,
            'CONTENT_LENGTH'       => $len // scalar( ( stat $body )[7] ),
            'CONTENT_TYPE'         => $type,
        }
    );
}

sub _put {
    my ( $self, $path, $query, $body, $type, $len ) = @_;
    die "$body must be a IO::Handle"
      unless ( ref($body) and $body->can('read') );
    return $self->app->( {
            'HTTP_ACCEPT'          => 'application/json, text/plain, */*',
            'SCRIPT_NAME'          => '',
            'HTTP_ACCEPT_ENCODING' => 'gzip, deflate',
            'SERVER_NAME'          => '127.0.0.1',
            'QUERY_STRING'         => $query,
            'HTTP_CACHE_CONTROL'   => 'max-age=0',
            'HTTP_ACCEPT_LANGUAGE' => 'fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3',
            'PATH_INFO'            => $path,
            'REQUEST_METHOD'       => 'PUT',
            'REQUEST_URI'          => $path . ( $query ? "?$query" : '' ),
            'SERVER_PORT'          => '8002',
            'SERVER_PROTOCOL'      => 'HTTP/1.1',
            'HTTP_USER_AGENT'      =>
              'Mozilla/5.0 (VAX-4000; rv:36.0) Gecko/20350101 Firefox',
            'REMOTE_ADDR'          => '127.0.0.1',
            'HTTP_HOST'            => '127.0.0.1:8002',
            'psgix.input.buffered' => 1,
            'psgi.input'           => $body,
            'CONTENT_LENGTH'       => $len // scalar( ( stat $body )[7] ),
            'CONTENT_TYPE'         => $type,
        }
    );
}

sub _patch {
    my ( $self, $path, $query, $body, $type, $len ) = @_;
    die "$body must be a IO::Handle"
      unless ( ref($body) and $body->can('read') );
    return $self->app->( {
            'HTTP_ACCEPT'          => 'application/json, text/plain, */*',
            'SCRIPT_NAME'          => '',
            'HTTP_ACCEPT_ENCODING' => 'gzip, deflate',
            'SERVER_NAME'          => '127.0.0.1',
            'QUERY_STRING'         => $query,
            'HTTP_CACHE_CONTROL'   => 'max-age=0',
            'HTTP_ACCEPT_LANGUAGE' => 'fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3',
            'PATH_INFO'            => $path,
            'REQUEST_METHOD'       => 'PATCH',
            'REQUEST_URI'          => $path . ( $query ? "?$query" : '' ),
            'SERVER_PORT'          => '8002',
            'SERVER_PROTOCOL'      => 'HTTP/1.1',
            'HTTP_USER_AGENT'      =>
              'Mozilla/5.0 (VAX-4000; rv:36.0) Gecko/20350101 Firefox',
            'REMOTE_ADDR'          => '127.0.0.1',
            'HTTP_HOST'            => '127.0.0.1:8002',
            'psgix.input.buffered' => 1,
            'psgi.input'           => $body,
            'CONTENT_LENGTH'       => $len // scalar( ( stat $body )[7] ),
            'CONTENT_TYPE'         => $type,
        }
    );
}

sub _del {
    my ( $self, $path, $query ) = @_;
    return $self->app->( {
            'HTTP_ACCEPT'          => 'application/json, text/plain, */*',
            'SCRIPT_NAME'          => '',
            'HTTP_ACCEPT_ENCODING' => 'gzip, deflate',
            'SERVER_NAME'          => '127.0.0.1',
            'QUERY_STRING'         => $query,
            'HTTP_CACHE_CONTROL'   => 'max-age=0',
            'HTTP_ACCEPT_LANGUAGE' => 'fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3',
            'PATH_INFO'            => $path,
            'REQUEST_METHOD'       => 'DELETE',
            'REQUEST_URI'          => $path . ( $query ? "?$query" : '' ),
            'SERVER_PORT'          => '8002',
            'SERVER_PROTOCOL'      => 'HTTP/1.1',
            'HTTP_USER_AGENT'      =>
              'Mozilla/5.0 (VAX-4000; rv:36.0) Gecko/20350101 Firefox',
            'REMOTE_ADDR' => '127.0.0.1',
            'HTTP_HOST'   => '127.0.0.1:8002',
        }
    );
}

sub jsonResponse {
    my ( $self, $path, $query ) = @_;
    my $res = $self->_get( $path, $query )
      or die "PSGI lib has refused my get, aborting";
    unless ( $res->[0] == 200 ) {
        require Data::Dumper;
        $Data::Dumper::Useperl = 1;
        print STDERR "Result dump :\n" . Data::Dumper::Dumper($res);
        die "Manager lib does not return a 200 code, aborting";
    }
    my $href = from_json( $res->[2]->[0], { allow_nonref => 1 } )
      or die 'Response is not JSON';
    return $href;
}

sub jsonPostResponse {
    my ( $self, $path, $query, $body, $type, $len ) = @_;
    my $res = $self->_post( $path, $query, $body, $type, $len )
      or die "PSGI lib has refused my post, aborting";
    unless ( $res->[0] == 200 ) {
        require Data::Dumper;
        $Data::Dumper::Useperl = 1;
        print STDERR "Result dump :\n" . Data::Dumper::Dumper($res);
        die "Manager lib does not return a 200 code, aborting";
    }
    my $href = from_json( $res->[2]->[0], { allow_nonref => 1 } )
      or die 'Response is not JSON';
    return $href;
}

sub jsonPutResponse {
    my ( $self, $path, $query, $body, $type, $len ) = @_;
    my $res = $self->_put( $path, $query, $body, $type, $len )
      or die "PSGI lib has refused my put, aborting";
    unless ( $res->[0] == 200 ) {
        require Data::Dumper;
        $Data::Dumper::Useperl = 1;
        print STDERR "Result dump :\n" . Data::Dumper::Dumper($res);
        die "Manager lib does not return a 200 code, aborting";
    }
    my $href = from_json( $res->[2]->[0], { allow_nonref => 1 } )
      or die 'Response is not JSON';
    return $href;
}

1;
