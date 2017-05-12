package LWP::Protocol::connect::Socket::Base;

use strict;
use warnings;

our $VERSION = '6.09'; # VERSION

use LWP::UserAgent;
use HTTP::Request;

sub new {
    my $class = shift;
    my %args = @_;
    my $conn = $class->_proxy_connect( \%args );
    bless $conn, $class;
    
    $conn->http_configure( \%args );
    return $conn;
}

sub _proxy_connect {
    my ( $class, $args ) = @_;
    my $agent = $args->{Agent};
    my ($user, $pass);
    if( defined $args->{ProxyUserinfo} ) {
         ($user, $pass) = split(':', URI::Escape::uri_unescape( $args->{ProxyUserinfo} ), 2);
    }
    my $proxy_host_port =  $args->{'ProxyAddr'}.':'.$args->{'ProxyPort'};
    my $cur_http_proxy = $agent->proxy('http');
    $agent->proxy( http => 'http://'.
        ( defined $user ? $user.':'.$pass.'@' : '' ).
        $proxy_host_port.'/' );

    my $host_port = $args->{PeerAddr}.":".$args->{PeerPort};
    my $host = 'http://'.$host_port;
    my $request = HTTP::Request->new( CONNECT => $host );
    my $response = $agent->request( $request );
    $agent->proxy( http => $cur_http_proxy );
    
    if( $response->is_error ) {
        die('error while CONNECT thru proxy: '.$response->status_line );
    }
    my $conn = $response->{client_socket};

    delete $args->{ProxyAddr};
    delete $args->{ProxyPort};
    delete $args->{ProxyUserinfo};
    delete $args->{Agent};

    return( $conn );
}

sub http_connect {
    return 1;
}

1;
