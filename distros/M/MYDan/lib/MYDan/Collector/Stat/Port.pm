package MYDan::Collector::Stat::Port;

use strict;
use warnings;
use Carp;
use POSIX;

use IO::Select;
use IO::Socket::INET;

#use Net::SSL;
use Data::Dumper;
use MYDan::Collector::Util;

#retry:3:time:3:input:hello:tcp:22

my %option = ( 'time' => 5, retry => 1, host => '127.0.0.1' );
my %iface;
BEGIN{
    my $tmp;
    map{
        $tmp = $1 if $_ =~ /^(\S+)/;
        $iface{$tmp} = $1 if $tmp && $_ =~ /\baddr:(\d+\.\d+\.\d+\.\d+)\b/;

    }MYDan::Collector::Util::qx( 'ifconfig' );
};

sub co
{
    my ( $this, @port, %port ) = shift;

    map{ $port{$1} = 1 if $_ =~ /^\{PORT\}\{([^}]+)\}/ }@_;

    push @port, [ 'PORT', 'status', 'output' ];

    for ( keys %port )
    {
        my ( %opt, $status, $output ) = trans( $_ );

        for( 1 .. $opt{retry} )
        {
            if( defined $opt{tcp} )
            {
                ( $status, $output ) = tcp( %opt );
            }
            else
            {
                $output = '';
                $status = MYDan::Collector::Util::system( "nc -u -z -w $opt{time} $opt{host} $opt{udp} 1>/dev/null 2>&1" )
                    ? 'down' : 'alive';
            }

            last if $status eq 'alive';
        }

        push @port, [ $_, $status, $output ];
    }

    return \@port;
}

sub trans
{
    my ( $url, %opt ) = shift;

    if( $url =~ /tcp|udp/ )
    { %opt = split /:/, $url;}
    else { $opt{tcp} = $url; }

    map{ $opt{$_} = $option{$_} unless $opt{$_}; }keys %option;

    $opt{host} = $iface{$opt{host}} if $iface{$opt{host}};
    return %opt;
}

sub tcp
{
    my %param = @_;

    my ( $time, $input, $host, $tcp ) = @param{ qw( time input host tcp ) };

    my $sock = IO::Socket::INET->new(
        Blocking => 0, Timeout => $time,
        Proto => 'tcp', Type => SOCK_STREAM,
        PeerAddr => "$host:$tcp",
    );

    return ( "socket: $!", '' ) unless $sock;

    my $output = '';
    $sock->send( $input ) if defined $input;
    $sock->shutdown( 1 );
    my $select = IO::Select->new();
    $select->add( $sock );

    while(1)
    {
        my @ready = $select->can_read( $time );
        unless( scalar @ready )
        {
            eval { $sock->shutdown( 2 ) };
            return ( "alive", $output );
        }

        my $fh = shift @ready;
        my $tmp = <$fh>;
        if( $tmp ) { $output .= $tmp; }
        else
        {
            $select->remove( $fh );
            close( $fh );
            last;
        }
    }

    eval { $sock->shutdown( 2 ) };

    return ( 'alive', $output );
}

1;
