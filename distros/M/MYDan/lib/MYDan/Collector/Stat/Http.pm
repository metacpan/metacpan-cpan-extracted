package MYDan::Collector::Stat::Http;

use strict;
use warnings;
use Carp;
use POSIX;

use LWP::UserAgent;
use Encode;

use Data::Dumper;
use MYDan::Collector::Util;

#retry:3:time:3:host:lvscheck.xitong.mydan.net:proxy:http=127.0.0.1=9999:http://localhost:8080
#http://iface:eth0:8080

my %iface;
BEGIN{
    my $tmp;
    map{
        $tmp = $1 if $_ =~ /^(\S+)/;
        $iface{$tmp} = $1 if $tmp && $_ =~ /\baddr:(\d+\.\d+\.\d+\.\d+)\b/;
    }MYDan::Collector::Util::qx( 'ifconfig' );
};

my %option = ( 'time' => 5, retry => 1 );

sub co
{
    my ( $this, @http, @stat, %http ) = shift;

    map{ $http{$1} = 1 if $_ =~ /^\{HTTP\}\{([^}]+)\}/ }@_;

    push @http, [ 'HTTP', 'code', 'is_success', 'status_line', 'cont' ];

    for ( keys %http )
    {
        my %opt = trans( $_ );

        my ( $url, $retry, $res )  =  map{ delete $opt{$_} }qw( url retry );

        my $ua = LWP::UserAgent->new( ssl_opts => { verify_hostname => 0 } );
        $ua->proxy( [ 'http', 'https'], "$1://$2:$3"  )
            if $opt{proxy} && $opt{proxy} =~ /^(\w+)=([^:]+)=(\d+)/;

        $ua->agent('Mozilla/9 [en] (Centos; Linux)');
        
        $ua->timeout( $opt{time} );

        $ua->default_header ( 'Cache-control' => 'no-cache', 'Pragma' => 'no-cache', %opt );

        for( 1 .. $retry )
        {
            $res = $ua->get( $url );
            last if $res->is_success;
        }
        my $cont = decode( 'utf8', $res->is_success ? $res->content : '' );
        push @http, [ $_, $res->code, $res->is_success, $res->status_line, $cont ];

    }

    return \@http;
}

sub trans
{
    my ( $url, %opt ) = shift;

    if( $url =~ /^(.*)http(.+)/ )
    {
       %opt = split /:/, $1;
       $opt{url} = "http$2";
    }
    else { $opt{url} = "http://$url" }

    $opt{url} =~ s/iface:(\w+)/$iface{$1}/
        if $opt{url} =~ /http\w*:\/\/iface:(\w+)\b/ && $iface{$1};

    map{ $opt{$_} = $option{$_} unless $opt{$_} }keys %option;

    $opt{Host} = $opt{host} if $opt{host};
    return %opt;
}

1;
