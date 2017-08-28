package MYDan::Util::TcpServer;

use warnings;
use strict;
use Carp;

use Data::Dumper;

use POSIX ":sys_wait_h";
use Time::HiRes qw(time);
use AnyEvent;
use AnyEvent::Impl::Perl;
use AnyEvent::Socket;
use AnyEvent::Handle;
use Fcntl qw(:flock SEEK_END);

use MYDan;

our %index;

sub new
{
    my ( $class, %this ) = @_;

    map{ die "$_ unkown" unless $this{$_} && $this{$_} =~ /^\d+$/ }qw( port max );
    die "no file:$this{'exec'}\n" unless $this{'exec'} && -e $this{'exec'};

    $this{tmp} ||= sprintf "%s/var/run/agent", $MYDan::PATH;      

    system( "mkdir -p '$this{tmp}'" ) unless -d $this{tmp};
    map{ unlink $_ if $_ =~ /\/\d+$/ || $_ =~ /\/\d+\.out$/ }glob "$this{tmp}/*";

    bless \%this, ref $class || $class;
}

sub run
{
    my $this = shift;
    my ( $port, $max, $exec, $tmp ) = @$this{qw( port max exec tmp )};

    $SIG{'USR1'} = sub {
        print Dumper \%index;
    };

    $SIG{INT} = $SIG{TERM} = sub { 
        map{ kill 'TERM', $_->{pid} if $_->{pid}; }values %index;
        die "kill.\n";
    };

    $SIG{'CHLD'} = sub {
        while((my $pid = waitpid(-1, WNOHANG)) >0)
        {
            my $code = ( $? == -1 || $? & 127 ) ? 110 : $? >> 8;

            
            print "chld: $pid exit $code.\n";;

            my ( $index ) = grep{ $index{$_}{pid}  && $index{$_}{pid} eq $pid  }keys %index;
            next unless my $data = delete $index{$index};

            if( $data->{handle}->fh )
            {
                $data->{handle}->push_write('*#*keepalive*#');
                if ( open my $tmp_handle, '<', "$tmp/$index.out" )
                {
                    #seek( $tmp_handle, -16384, SEEK_END );
                    while(<$tmp_handle>)
                    {
                        $data->{handle}->push_write($_) if $data->{handle}->fh;
                    }
                    $data->{handle}->push_write("--- $code\n") if $data->{handle}->fh;
                }
                $data->{handle}->destroy() if $data->{handle}->fh;
            }

            map{ unlink "$tmp/$_" }( $index, "$index.out" );
        }
    };

    my ( $i, $cv ) = ( 0, AnyEvent->condvar );

   
    tcp_server undef, $port, sub {
       my ( $fh, $tip, $tport ) = @_ or die "tcp_server: $!";

       printf "index: %s\n", ++ $i;
       my $index = $i;

       my $len = keys %index;
       printf "tcpserver: status: $len/$max\n";

       if( $len >= $max )
       {
           printf "connection limit reached, from %s:%s\n", $tip, $tport;
           close $fh;   
           return;
       }

       my $tmp_handle;
       unless( open $tmp_handle, '>', "$tmp/$index" )
       {
           print "open '$tmp/$index' fail:$!\n";
           close $fh;
           return;
       }

       my $handle; $handle = new AnyEvent::Handle( 
           fh => $fh,
           keepalive => 1,
           on_eof => sub{
               close $tmp_handle;

               if ( my $pid = fork() )
               {
                   $index{$index}{pid} = $pid;
               }
               else
               {
    	           $tip = '0.0.0.0' unless $tip && $tip =~ /^\d+\.\d+\.\d+\.\d+$/;
                   $tport = '0' unless $tport && $tport =~ /^\d+$/;

                   $ENV{TCPREMOTEIP} = $tip;
                   $ENV{TCPREMOTEPORT} = $port;
      
                   open STDIN, '<', "$tmp/$index" or die "Can't open '$tmp/$index': $!";
                   open STDOUT, '>', "$tmp/$index.out" or die "Can't open '$tmp/$index.out': $!";
                   exec $exec;
               }
           },
           on_read => sub {
               my $self = shift;
               printf "read len:%s\n",  length $self->{rbuf};
               $self->unshift_read (
                   chunk => length $self->{rbuf},
                   sub { print $tmp_handle $_[1]; }
               );
            },
            on_error => sub {
               close $tmp_handle;

               close $fh;
               delete $handle->{fh};

               $handle->destroy();

               my $pid = $index{$index}{pid} if $index{$index};
               if( $pid ) { kill 15, $pid; }
               else
               {
                   unlink "$tmp/$index";
               }
            },
        );
       $index{$index}{handle} = $handle;
    
    };
    my $t = AnyEvent->timer(
        after => 1, 
        interval => 1,
        cb => sub { 
            map{ 
                $_->{handle}->push_write('*') if $_->{handle} && $_->{handle}->fh;
            }values %index; 
        }
    ); 
 
    $cv->recv;
}

1;
