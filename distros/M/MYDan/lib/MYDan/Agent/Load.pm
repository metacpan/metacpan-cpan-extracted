package MYDan::Agent::Load;

=head1 NAME

MYDan::Agent::Load

   load data by agent

=head1 SYNOPSIS

 use MYDan::Agent::Load; my $load = MYDan::Agent::Load->new( 
   node => 'host1', sp=> 'srcpath', dp => 'dstpath'
 );

 my %result = $client->load( 
   timeout => 300,
   user => '',
   sudo => '',
   verbose => 1, 
   port => '',
   continue => 0,
 ); 

=cut
use strict;
use warnings;

use Carp;
use Time::HiRes qw(time);
use AnyEvent;
use AnyEvent::Impl::Perl;
use AnyEvent::Socket;
use AnyEvent::Handle;
use Digest::MD5;
use MYDan;
use MYDan::Agent::Query;
use MYDan::Util::Percent;
use MYDan::API::Agent;
use Fcntl qw(:flock SEEK_END);
use MYDan::Agent::Proxy;
use MYDan::Util::Hosts;
use MYDan::Agent::FileCache;
use File::Basename;

sub new
{
    my ( $class, %self ) = @_;
    map{ confess "$_ undef" unless $self{$_} }qw( node sp );

    $self{dp} ||= $self{sp};

    bless \%self, ref $class || $class;
}


sub run
{
    my ( $this, %run ) = @_;

    my ( $node, $sp, $dp, $query ) = @$this{qw( node sp dp )};

    my $filecache = MYDan::Agent::FileCache->new();

    my $path = "$MYDan::PATH/tmp";
    unless( -d $path ){ mkdir $path;chmod 0777, $path; }
    $path .= '/load.data.';

    for my $f ( grep{ -f } glob "$path*" )
    {
	my $t = ( stat $f )[9];
        unlink $f if $t && $t < time - 3600;
    }

    my $temp = sprintf "$dp.%stmp", $run{continue} ? '' : time.'.'.$$.'.';
    $temp  = $path. Digest::MD5->new->add( $temp )->hexdigest;


    $SIG{INT} = $SIG{TERM} = sub
    {
        unlink $temp if !$run{continue} && $temp && -f $temp;
        die "killed.\n";
    };

    my $position = -f $temp ? ( stat $temp )[7] : 0;

    open my $TEMP, '+>>', $temp or die "Can't open '$temp': $!";

    unless( $query = $run{query} )
    {
        my %query = ( code => 'load', user => $run{user}, sudo => $run{sudo}, argv => [ $sp, $position ] );

        my $isc = $run{role} && $run{role} eq 'client' ? 1 : 0;

        $query{node} = [ $node ] if $isc;

        $query = MYDan::Agent::Query->dump(\%query);
        eval{ $query = MYDan::API::Agent->new()->encryption( $query ) if $isc };

        die "encryption fail:$@" if $@;

        my %proxy;
        if( $run{proxy} )
        {
            my $proxy =  MYDan::Agent::Proxy->new( $run{proxy} );
            %proxy = $proxy->search( $node );
        }
        else { %proxy  = ( $node => undef ); }

        if( my $rnode = $proxy{$node} )
        {
            my %rquery = ( 
                code => 'proxy', 
                proxyload => 1,
                argv => [ $node, +{ query => $query, map{ $_ => $run{$_} }grep{ $run{$_} }qw( timeout max port ) } ],
	        map{ $_ => $run{$_} }grep{ $run{$_} }qw( user sudo env ) 
            );

            $rquery{node} = [ $rnode ] if $isc;

            $query = MYDan::Agent::Query->dump(\%rquery);
    
            eval{ $query = MYDan::API::Agent->new()->encryption( $query ) if $isc };
	    die "encryption fail:$@" if $@;

            $node = $rnode;
        }
    }

    my ( $cv, $len, %keepalive )
        = ( AE::cv, $position,  cont => '', save => 0 );
    
    printf "position: %d\n", $position if $run{verbose};

    my $percent =  MYDan::Util::Percent->new()->add( $position );
    
    my %hosts = MYDan::Util::Hosts->new()->match( $node );

    my ( $size, $filemd5, $own, $mode, $ok );
    tcp_connect $hosts{$node}, $run{port}, sub {
        my ( $fh ) = @_  or die "tcp_connect: $!";
        my $hdl; $hdl = new AnyEvent::Handle(
           fh => $fh,
           on_read => sub {
               my $self = shift;
               $self->unshift_read (
                   chunk => length $self->{rbuf},
                   sub {
                       if( $keepalive{save} )
                       {
                           $percent->add( length $_[1] );
                           print $TEMP $_[1];
                       }
                       else
                       {
                           $keepalive{cont} .= $_[1];
                           $keepalive{cont} =~ s/^\*+//g;

			   if( length $keepalive{cont} > 1024000 )
			   {
				   undef $hdl;
				   $cv->send;
			   }

                           if( $keepalive{cont} =~ s/\**#\*MYDan_\d+\*#(\d+):([a-z0-9]+):(\w+):(\d+):// )
                           {
                               ( $size, $filemd5, $own, $mode ) = ( $1, $2, $3, $4 );
			       if( $run{cc} )
			       {
                                   $run{chown} ||= $own;
				   $run{chmod} ||= $mode;
			       }

			       if( $filecache->check( $filemd5 ) && ! -e $dp  )
			       {
				       print "get data from filecache\n";
				       eval{ $filecache->get( $dp, $filemd5) };
				       warn "get filecache fail: $@" if $@;
			       }

			       if( -f $dp )
			       {
				   if( open my $DP, '<', $dp )
				   {
				       my $x = Digest::MD5->new()->addfile( $DP )->hexdigest();
				       if( $x && $filemd5 && $x eq $filemd5 )
				       {
				           die "chmod fail\n" if $run{chmod} && ! chmod oct($run{chmod}), $dp;
					   if( $run{chown} )
					   {
                                               die "get $run{chown} uid fail\n" unless my @pw = getpwnam $run{chown};
					       die "chown fail\n" unless chown @pw[2,3], $dp;
					   }
                                           undef $hdl; $cv->send; $ok = $size;
				       }
			           }
			       }

			       $percent->renew( $size )->add( length $keepalive{cont}  );
                               syswrite( $TEMP, delete $keepalive{cont} );
                               $keepalive{save} = 1;
                           }
                       }

                       $percent->print('Load ..') if $run{verbose};
                   }
               );
            },
            on_error => sub{
                undef $hdl;
                 $cv->send;
            },
            on_eof => sub{
                undef $hdl;
                 $cv->send;
             }
        );
        $hdl->push_write($query);
        $hdl->push_shutdown;
    };

    $cv->recv;

    if( defined $ok )
    {

	$percent->add( $ok );
	$percent->print('Load ..') if $run{verbose};
        unlink $temp;
        return;
    }

    seek $TEMP, -6, SEEK_END;
    sysread $TEMP, my $end, 6;

    unless( $end =~ /^--- 0\n$/  )
    {
        unlink $temp;
	my $err = $keepalive{cont} || '';
	$err =~ s/\**#\*MYDan_\d+\*#//;
        die "status error $err $end\n";
    }
    truncate $TEMP, $size;
    seek $TEMP, 0, 0;

    unless( $filemd5 eq Digest::MD5->new()->addfile( $TEMP )->hexdigest() )
    {
        unlink $temp;
        die "md5 nomatch\n";
    }

   
    die "chmod fail\n" if$run{chmod} && ! chmod oct($run{chmod}), $temp;
    if( $run{chown} )
    {
        die "get $run{chown} uid fail\n" unless my @pw = getpwnam $run{chown};
	die "chown fail\n" unless chown @pw[2,3], $temp;
    }

    my $dir = File::Basename::dirname( $dp );
    unless( -d $dir )
    {
        die "mkdir dir fail\n" if system "mkdir -p '$dir'";
    }
    
    die "dst path error\n"  if -e $dp && ! -f $dp;
 
    die "rename temp file\n" if system "mv '$temp' '$dp'";
    eval{ $filecache->save( $dp ); };
    warn "save filecache fail: $@" if $@;
}

1;
