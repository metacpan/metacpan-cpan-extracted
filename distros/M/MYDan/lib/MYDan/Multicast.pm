package MYDan::Multicast;

=head1 NAME

MYDan::Multicast - data distribution via multicast

=cut
use strict;
use warnings;
use Carp;

use File::Temp;
use Digest::MD5;
use IO::Socket::Multicast;
use Time::HiRes qw( sleep time );
use threads;
use Thread::Queue;
use Data::Dumper;
use File::Basename;

our $VERBOSE;

$|++;

use constant
{
    MTU => 1500, HEAD => 54, MAXBUF => 4096, REPEAT => 2, NULL => '', TIMEOUT => 3600, KNOCK => 6
};

=head1 SYNOPSIS

 use MYDan::Multicast;
 
 my $send = MYDan::Multicast ## sender
    ->new( send => '255.0.0.2:8360', iface => 'eth1' );

 $send->send            ## default
 ( 
     '/file/path',
     ttl  => 1,          ## 1
     repeat => 2,        ## 2
     buffer => 4096,     ## MAXBUF
     name => foo,
 );

 my $recv = MYDan::Multicast ## receiver
    ->new( recv => '255.0.0.2:8360', iface => 'eth1' );

 $recv->recv( '/repo/path' );

=cut
sub new
{
    my ( $class, %param ) = splice @_;
    my %addr = ( send => 'PeerAddr', recv => 'LocalPort' );
    my ( $mode ) = grep { $param{$_} } keys %addr;
    my ( $g, $p ) = split /:/, $param{$mode};

    $param{recv} = $p if $param{recv};

    my $sock = IO::Socket::Multicast
        ->new( Proto=>'udp', $addr{$mode} => $param{$mode} );

    $sock->mcast_add( $g ) if $param{recv};

    $sock->mcast_if( $param{iface} ) if $param{iface};
    bless { sock => $sock, mode => $mode }, ref $class || $class;
}

sub send
{
    my ( $self, $file, %param ) = splice @_;
    confess 'not a sender' if $self->{mode} ne 'send';
    $file ||= confess "file not defined";

    my $sock = $self->{sock};
    my $repeat = $param{repeat} || REPEAT;
    my $bufcnt = $param{buffer} || MAXBUF;
    my $knock = $param{knock} || KNOCK;
    my $buflen = MTU - HEAD;

    $sock->mcast_ttl( $param{ttl} ) if $param{ttl};
    $file = readlink $file if -l $file;
    $bufcnt = MAXBUF if $bufcnt > MAXBUF;

    confess "$file: not a file" unless -f $file;
    confess "$file: open: $!\n" unless open my $fh => $file;

    my $md5 = Digest::MD5->new()->addfile( $fh )->hexdigest();
    seek $fh, 0, 0; binmode $fh;

    map{
        $self->buff( $md5, 0, 0, \$knock );
        warn "knock.\n" if ( sleep 1 ) && $VERBOSE;
    } 1 .. $knock;

    for ( my ( $index, $cont ) = ( 0, 1 ); $cont; )
    {
        my ( $time, @buffer ) = time;

        for ( 1 .. $bufcnt )
        {
            last unless $cont = read $fh, my ( $data ), $buflen;
            push @buffer, \$data;
        }

        my ( $sleep, $len ) = ( time - $time, scalar @buffer );
        my $done = sprintf "$len:%s", $param{name} ||'';

        map{
            map { $self->buff( $md5, $index, $_, $buffer[$_] ) } 0 .. $#buffer;
            sleep $sleep;
            $self->buff( $md5, $index, $cont ? ( MAXBUF, \$len ) : (  MAXBUF + 1, \$done ) )
        }0 .. $repeat;

        warn "index:$index buf:$len\n" if $VERBOSE;
        $index ++;
    }

    close $fh;
    return $self;
}

sub buff
{
    my $self = shift;
    my $sock = $self->{sock};
    my $data = sprintf "MUCA%s%014x%04x", splice @_, 0, 3;
    my $buffer = splice @_;
    
    $data .= $$buffer if $buffer;
    $sock->send( $data );
}

sub recv
{
    local $| = 1;

    my $self = shift;
    confess 'not a receiver' if $self->{mode} ne 'recv';

    my $sock = $self->{sock};
    my $repo = shift || confess "repo not defined";

    $repo = readlink $repo if -l $repo;
    confess "$repo: not a directory" unless -d $repo;

    my @timeout = map{ Thread::Queue->new }( 0..1 );

    threads::async {
        my %timeout;
        while ( 1 ) {
            sleep 60;
            while( $timeout[0]->pending )
            {
                my ( $md5, $t ) = $timeout[0]->dequeue( 2 );
                $timeout{$md5} = $t;
            }
            for( keys %timeout )
            {
                next if $timeout{$_} > time;
                delete $timeout{$_};
                $timeout[1]->enqueue( $_ );
            }
        }
    }->detach();

    local $SIG{ALRM} = sub{ die };
    for ( my %buffer; 1; )
    {
        my $data;
        eval{
            alarm 60;
            next unless $sock->recv( $data, MTU );
            alarm 0;
        };

        if( $@ )
        {
            %buffer
                ? printf "dirty data [%d]\n", scalar keys %buffer
                : print "buffer is clean\n" if $VERBOSE;
            while( $timeout[1]->pending )
            {
                my $ttmd5 = $timeout[1]->dequeue();
                next unless my $ttbuf = delete $buffer{$ttmd5};
		print "delete $ttmd5\n" if $VERBOSE;
                unlink $ttbuf->{temp};
                close $ttbuf->{temp};
            }
            next;
        }

        next unless my ( $md5, $index, $i ) = substr( $data, 0, HEAD, NULL )
            =~ /^MUCA([0-9a-f]{32})([0-9a-f]{14})([0-9a-f]{4})$/;

        $index = hex $index; $i = hex $i;
        my $file = "$repo/$md5"; next if -f $file;

        unless ( $buffer{$md5} )
        {
            $buffer{$md5} = +{ 
                index => 0,
                temp => File::Temp->new( DIR => $repo, SUFFIX => ".$md5", UNLINK => 0 ),
            };
            $timeout[0]->enqueue( $md5, time + TIMEOUT );
        }

        my ( $buffer, $name ) = $buffer{$md5};

        my ( $ined, $temp ) = @$buffer{ qw( index temp )};
        next unless $ined == $index;

        if ( $i < MAXBUF ) { $buffer->{$index}[$i] = \$data; next }
        ( $data, $name ) = split /:/, $data if $i == MAXBUF +1;

        print "$md5 $index check\n";
        map{ next unless $buffer->{$index}[$_] }( 0 .. $data - 1 );
        print "$md5 $index check OK\n";
	map{ print $temp ${$buffer->{$index}[$_]} }( 0 .. $data - 1 );
 
        delete $buffer->{$index};
        warn "$md5 $index OK\n" if $VERBOSE;
        $buffer->{index} ++;

        next if $i == MAXBUF;
        seek $temp, 0, 0;

        if ( $md5 eq Digest::MD5->new()->addfile( $temp )->hexdigest() )
        {
            system "mv $temp $file && chmod a+r $file"; 
            system( sprintf "ln -fsn '$md5' '$repo/%s'", basename $name ) if $name;
            warn "$md5 OK\n"; 
        } 
        else { unlink $temp; warn "$md5 fail\n"; }
        close $temp;
        delete $buffer{$md5};
    }
}

1;
