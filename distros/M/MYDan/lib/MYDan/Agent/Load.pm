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
use MYDan::Agent::Query;
use MYDan::Util::Percent;
use MYDan::API::Agent;
use Fcntl qw(:flock SEEK_END);
use MYDan::Agent::Proxy;

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

    my $temp = sprintf "$dp.%stmp", $run{continue} ? '' : time.'.'.$$.'.';

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
                single => 1,
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
    
    my ( $size, $filemd5, $uid, $gid, $mode );
    tcp_connect $node, $run{port}, sub {
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
                           if( $keepalive{cont} =~ s/\**#\*keepalive\*#(\d+):([a-z0-9]+):(\d+):(\d+):(\d+):// )
                           {
                               ( $size, $filemd5, $uid, $gid, $mode ) = ( $1, $2, $3, $4, $5 );
			       
			       $percent->renew( $size )->add( length $keepalive{cont}  );
                               print $TEMP delete $keepalive{cont};
                               $keepalive{save} = 1;
                           }
                       }

                       $percent->print('Load ..') if $run{verbose};
                   }
               );
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

    seek $TEMP, -6, SEEK_END;
    sysread $TEMP, my $end, 6;

    unless( $end =~ /^--- 0\n$/  )
    {
        unlink $temp;
        die "status error $end\n";
    }
    truncate $TEMP, $size;
    seek $TEMP, 0, 0;

    unless( $filemd5 eq Digest::MD5->new()->addfile( $TEMP )->hexdigest() )
    {
        unlink $temp;
        die "md5 nomatch\n";
    }

    chmod oct($mode), $temp;
    chown $uid, $gid, $temp;
    die "rename temp file\n" unless rename $temp, $dp;
}

1;
