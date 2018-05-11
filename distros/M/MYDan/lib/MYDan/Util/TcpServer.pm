package MYDan::Util::TcpServer;

use warnings;
use strict;
use Carp;

use Data::Dumper;

use Tie::File;
use Fcntl 'O_RDONLY';
use POSIX ":sys_wait_h";
use Time::HiRes qw(time);
use AnyEvent;
use AnyEvent::Impl::Perl;
use AnyEvent::Socket;
use AnyEvent::Handle;
use Fcntl qw(:flock SEEK_END);
use Filesys::Df;
use Digest::MD5;

use MYDan;
use MYDan::Agent::FileCache;

my %index;

sub new
{
    my ( $class, %this ) = @_;

    map{ die "$_ unkown" unless $this{$_} && $this{$_} =~ /^\d+$/ }
        qw( port max ReservedSpaceCount ReservedSpaceSize );

    $0 = 'mydan.tcpserver.'.$this{port};

    die "no file:$this{'exec'}\n" unless $this{'exec'} && -e $this{'exec'};

    map{ 
        $this{$_} ||= "$MYDan::PATH/var/run/tcpserver.$this{port}/$_";
        system( "mkdir -p '$this{$_}'" ) unless -d $this{$_};
        map{ unlink $_ if $_ =~ /\/\d+$/ || $_ =~ /\/\d+\.out$/ || $_ =~ /\/\d+\.ext$/ }glob "$this{$_}/*";
     }qw( tmp ReservedSpace );


    my ( $c, $s, $r ) = map{ $this{$_} }qw( ReservedSpaceCount ReservedSpaceSize ReservedSpace );
    $c = $this{max} if $c > $this{max};

    open my $H, '>', "$r/tmp" or die "Can't open '$r/tmp': $!";
    map{ syswrite( $H, "\0" x 1024 ); } 1 .. $s;
    close $H;

    for my $i ( 1 .. $c )
    {
        map{ system "cp '$r/tmp' '$r/$i$_'"; }('', '.out');
    }

    map{ $this{$_} ||= $this{buf} }qw( rbuf wbuf );

    bless \%this, ref $class || $class;
}

sub run
{
    my $this = shift;
    my ( $port, $max, $exec, $tmp, $rbuf, $wbuf ) = @$this{qw( port max exec tmp rbuf wbuf )};

    my $filecache = MYDan::Agent::FileCache->new();
    my $version = $MYDan::VERSION; $version =~ s/\./0/g;

    my $excb = sub{
        map{ kill 'TERM', $_->{pid} if $_->{pid}; }values %index;
        die "kill.\n";
    };

    my $term = AnyEvent->signal (signal => "TERM", cb => $excb );
    my $ints = AnyEvent->signal (signal => "INT",  cb => $excb );
    my $usr1 = AnyEvent->signal (signal => "USR1", cb => sub{ print Dumper \%index; } );

    my %savecb;
    my $childcb = sub
    {
        my ( $pid, $code ) = @_;
        print "chld: $pid exit $code.\n";

        my ( $index ) = grep{ $index{$_}{pid}  && $index{$_}{pid} eq $pid  }keys %index;
        return unless my $data = delete $index{$index};

        kill( 15, $data->{savecbpid} ) if $data->{savecbpid} && $savecb{$data->{savecbpid}};

        if( $data->{handle}->fh )
        {
            $data->{handle}->push_write( "*#*MYDan_$version*#" );

            my $size = ( stat "$tmp/$index.out" )[7];

            if ( ( ! $wbuf || ( $wbuf && $size <= $wbuf ) ) && open my $tmp_handle, '<', "$tmp/$index.out" )
            {
                $data->{fh} = $tmp_handle;
                $data->{handle}->on_drain(
                    sub{
                        my ( $n, $buf );
                        if( $n = sysread( $data->{fh}, $buf, 102400 ) )
                        {
                            if( ! $data->{body} && $buf =~ s/MYDanExtractFile_::(.+)::_MYDanExtractFile// )
                            {
                                $data->{file} = $1;
                            }
                            $data->{body} = 1;
                            $data->{handle}->push_write($buf);
                        }
                        else
                        {
                            close $data->{fh};

                            if( my $f = delete $data->{file} )
                            {
                                if( open my $tmp_handle, '<', $f )
                                {
                                    $data->{fh} = $tmp_handle;
                                    if( $n = sysread( $data->{fh}, $buf, 102400 ) )
                                    {
                                        $data->{handle}->push_write($buf);
                                        return;
                                    }

                                }
                                else
                                {
                                    $code ||= 110;
                                    warn "open MYDanExtractFile fail: $!";
                                }
                            }

                            $data->{handle}->on_drain(undef);
                            $data->{handle}->push_write("--- $code\n");
                            $data->{handle}->push_shutdown;
                        }
                    }
                );
            }
            else
            {
                $data->{handle}->push_shutdown;
            }
        }

        map{ unlink "$tmp/$_" if -e "$tmp/$_" }( $index, "$index.out", "$index.ext" );
    };

    my ( $i, $cv ) = ( 0, AnyEvent->condvar );

    my $whitelist;
   
    tcp_server undef, $port, sub {
       my ( $fh, $tip, $tport ) = @_ or die "tcp_server: $!";

       printf "index: %s\n", ++ $i;
       my $index = $i;

       my $len = keys %index;
       printf "tcpserver: status: $len/$max\n";

       if( $this->{whitelist} && ! $whitelist->{$tip} )
       {
           printf "connection not allow, from %s:%s\n", $tip, $tport;
           close $fh;   
           return;
       }


       if( $len >= $max )
       {
           printf "connection limit reached, from %s:%s\n", $tip, $tport;
           close $fh;   
           return;
       }

       my $tmp_handle;

       if( $this->dfok() )
       {
           unless( open $tmp_handle, '>', "$tmp/$index" )
           {
	       print "open '$tmp/$index' fail:$!\n";
               close $fh;
               return;
           }
       }
       else
       {
           my $rs = $this->space();
           unless( $rs ) { close $fh; return; }

           map{ system "ln '$this->{ReservedSpace}/$rs$_' '$tmp/$index$_'" }( '', '.out' );
           unless( open $tmp_handle, '+<', "$tmp/$index" )
           {
	       print "open '$tmp/$index' fail:$!\n";
               map{ unlink "$tmp/$rs$_" if -e "$tmp/$rs$_" }( '', '.out' );
               close $fh;
               return;
           }
       }

       my $EF;
       my $handle; $handle = new AnyEvent::Handle( 
           fh => $fh,
           keepalive => 1,
           rbuf_max => 1024000,
           wbuf_max => 1024000,
           autocork => 1,
           on_eof => sub{
               close $tmp_handle;

               if ( my $pid = fork() )
               {
                   $index{$index}{pid} = $pid;
                   $index{$index}{child} = AnyEvent->child ( pid => $pid, cb => $childcb );
               }
               else
               {
    	           $tip = '0.0.0.0' unless $tip && $tip =~ /^\d+\.\d+\.\d+\.\d+$/;
                   $tport = '0' unless $tport && $tport =~ /^\d+$/;

                   $ENV{TCPREMOTEIP} = $tip;
                   $ENV{TCPREMOTEPORT} = $port;
		   if( defined $index{$index}{extfile} )
		   {
                       $ENV{MYDanExtractFile} = $index{$index}{extfile};
		       $ENV{MYDanExtractFileAim} = $index{$index}{aim};
		   }
      
                   open STDIN, '<', "$tmp/$index" or die "Can't open '$tmp/$index': $!";
                   my $m = -f "$tmp/$index.out" ? '+<' : '>';
                   open STDOUT, $m, "$tmp/$index.out" or die "Can't open '$tmp/$index.out': $!";
                   $ENV{UseReservedSpace} = 1 if $m eq '+<';
                   exec $exec;
               }
           },
           on_read => sub {
               my $self = shift;

               if( ! $index{$index}{rbuf} && $self->{rbuf} =~ s/^MYDanExtractFile_::(\d+):(\d+):([a-zA-Z0-9]{32}):([a-zA-Z0-9\/\._\-]+)::_MYDanExtractFile// )
               {
                    my ( $qsize, $esize, $md5, $aim  ) = ( $1, $2, $3, $4 );
                    $index{$index}{querysize} = $qsize;
		    $index{$index}{aim} = $aim;

                    my $cb = sub{
                        return unless $index{$index};
                        if( $index{$index}{extfile} = $filecache->check( $md5 ) )
                        {
                            $handle->push_write("MH_:0:_MH") if $handle->fh;
                        }
                        else
                        {
                            $handle->push_write("MH_:1:_MH") if $handle->fh;
                            $index{$index}{extfile} = "$tmp/$index.ext";
                            open $EF, ">$tmp/$index.ext" or die "Can't open $tmp/$index.ext";
                        }
                    };
 
                    if( ! $filecache->check( $md5 ) && -f $aim )
                    {
                        my $size = ( stat $aim )[7];
                        if( $size eq $esize )
                        {
                            if ( my $pid = fork() )
                            {
                                $index{$index}{savecbpid} = $pid;
                                $savecb{$pid} = AnyEvent->child (pid => $pid, cb => sub
                                    {
                                        delete $savecb{$pid};
                                        &$cb();
                                    }
                                );
                            }
                            else
                            {
                                $0 = "mydan.filecache $aim";
                                die "save aim $aim fail\n" unless $filecache->save( $aim );
                                exit 0;
                            }
                        }
                        else { &$cb(); }
                    }
                    else { &$cb(); }

                    $index{$index}{rbuf} = 1;
               }

	       my $len = length $self->{rbuf};

               $index{$index}{querysize} = $rbuf unless defined $index{$index}{querysize};
	       if( $index{$index}{querysize} )
	       {
		   if( $len < $index{$index}{querysize} )
		   {
                       $index{$index}{rbuf} += $len;
                       $self->push_read (
                           chunk => $len,
			   sub { syswrite( $tmp_handle, $_[1] ) }
		       );
		       $index{$index}{querysize} -= $len;
		       $len = 0;
		   }
		   else
		   {
                       $index{$index}{rbuf} += $index{$index}{querysize};
                       $self->push_read(
			    chunk => $index{$index}{querysize},
			   sub { syswrite( $tmp_handle, $_[1] ) }
		       );
		       $len -= $index{$index}{querysize};
                       $index{$index}{querysize} = 0;
		   }
	       }

               return unless $len;
               $self->push_read (
                   chunk => $len,
                   sub { 
                       if( $EF )
                       {
                           syswrite( $EF, $_[1] );
                       }
                       else
                       {
                           $handle->push_shutdown;
                       }
                   }
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
		    map{ unlink "$tmp/$_" if -e "$tmp/$_" }( $index, "$index.out", "$index.ext" );
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

    my $mtime = 0;
    my $wl = AnyEvent->timer(
        after => 1, 
        interval => 30,
        cb => sub { 
            if( -f $this->{whitelist} )
            {
                my ( $mt, @ip ) = ( stat $this->{whitelist} )[9];
                return if $mtime == $mt;
                unless( tie @ip, 'Tie::File', $this->{whitelist}, mode => O_RDONLY )
                {
                    print "tie fail: $!\n";
                    return;
                }
                $whitelist = +{ map{ $_ => 1 }@ip };
                $mtime = $mt;
            }

        }
    ) if $this->{whitelist}; 
 
    $cv->recv;
}

sub space
{
    my $path = shift->{ReservedSpace};

    for ( glob "$path/*" )
    {
        next unless $_ =~ /\/(\d+)$/;
        my $id = $1;

        next unless rsok( $_ ) && rsok( "$_.out" );
        map{ system "cp '$path/tmp' '$path/$id$_'" }( '', '.out' );
        return $id;
    }
    return undef;
}

sub rsok
{
    my $file = shift;
    return ( $file && -f $file && ( stat $file )[3] == 1 ) ? 1 : 0;
}

sub dfok
{
    my $F;
    unless ( open( $F, shift->{tmp} ) )
    {
        print "df open tmp fail\n";
        return undef;
    }

    my $df = df($F);
    close $F;

    return undef unless $df && ref $df eq 'HASH' && defined $df->{bfree} && defined $df->{ffree};
    return ( $df->{bfree} > 102400 && $df->{ffree} > 4000 ) ? 1 : 0;
}

1;
