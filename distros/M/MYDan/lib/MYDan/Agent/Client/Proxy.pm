package MYDan::Agent::Client::Proxy;

=head1 NAME

MYDan::Agent::Client

=head1 SYNOPSIS

 use MYDan::Agent::Client;
 my $client = MYDan::Agent::Client->new( [ 'node1', 'node2' ] );
 my %result = $client->run( timeout => 300, input => '' ); 

=cut
use strict;
use warnings;

use Carp;
use YAML::XS;
use File::Spec;
use File::Basename;
use FindBin qw( $RealBin );
use YAML::XS;

use MYDan::Agent::Query;
use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket;
use Time::HiRes qw(time);

use MYDan::API::Agent;
use MYDan::Util::Percent;
use MYDan::Agent::Proxy;
use AnyEvent::Loop;
use MYDan::Agent::FileCache;
use MYDan::Util::FastMD5;

our %RUN = ( user => 'root', max => 128, timeout => 300 );

sub new
{
    my $class = shift;
    bless +{ node => \@_ }, ref $class || $class;
}


sub run
{
    my ( $this, %run, %result ) = ( shift, %RUN, @_ );

    return unless my @node = @{$this->{node}};

    my $query = $run{query};

    my $cv = AE::cv;
    AnyEvent::Loop::now_update();
    my $now_update = time;

    my ( @work, $stop );

    $SIG{TERM} = $SIG{INT} = my $tocb = sub
    {
        $stop = 1;
        for my $w ( @work )
        {
            next unless $$w && $$w->fh;
            $$w->destroy;
            $cv->end;
        }

        map{ $cv->end; } 1 .. $cv->{_ae_counter}||0;
    };

    my ( $md5, $aim, $efsize );
    if( my $ef = $ENV{MYDanExtractFile} )
    {
        $md5 = MYDan::Util::FastMD5->hexdigest( $ef );
        my $efa =  $ENV{MYDanExtractFileAim};
        $aim = $efa && $efa =~ /^[a-zA-Z0-9\/\._\-]+$/ ? $efa : '.';
        $efsize = ( stat $ef )[7];

        my $filecache = MYDan::Agent::FileCache->new();
        $filecache->fastsave( $ef, $md5 ) unless $filecache->check( $md5 );
    }

    my $percent =  MYDan::Util::Percent->new( scalar @node, 'run ..' );
    my %cut;
    my $work;$work = sub{
        return unless my $node = shift @node;
        $result{$node} = '';
        
        my $now_update_time = time - $now_update;
        $cv->begin;

        tcp_connect $node, $run{port}, sub {
             my ( $fh ) = @_;
             unless( $fh ){
                 $cv->end;
                 $result{$node} = "tcp_connect: $!";
                 $work->();
                 return;
             }
             if( $stop )
             {
                 close $fh;
                 return;
             }

             &{$run{pcb}}( $efsize, $node ) if $run{pcb};

             my $hdl;
             push @work, \$hdl;
             $hdl = new AnyEvent::Handle(
                 fh => $fh,
                 on_read => sub {
                     my $self = shift;
                     $self->unshift_read (
                         chunk => length $self->{rbuf},
                         sub { 
                             if ( defined $cut{$node} || length $result{$node} > 102400 )
                             {
                                 $cut{$node} = $_[1]; return; 
                             }
                             
			     if( $result{$node} )
			     {
				  $result{$node} .= $_[1];
			     }
			     else
			     {
				     $_[1] =~ s/^\*+//;

				     if( $_[1] =~ s/^MH_:(\d+):_MH// )
				     {
                                         if( $1 )
                                         {
                                             my $ef = $ENV{MYDanExtractFile};
                                             open my $EF, "<$ef" or die "open $ef fail:$!";
                                             my ( $n, $buf );
        
                                             $hdl->on_drain(sub {
                                                     my ( $n, $buf );
                                                     $n = sysread( $EF, $buf, 102400 );
                                                     &{$run{pcb}}( $n, $node ) if $run{pcb};
                                                     if( $n )
                                                     {
                                                         $hdl->push_write($buf);
                                                     }
                                                     else
                                                     {
                                                         $hdl->on_drain(undef);
                                                         close $EF;
                                                         $hdl->push_shutdown;
                                                     }
                                                 });
                                         }
                                         else
                                         {
                                             $hdl->push_shutdown;
                                         }
				         $_[1] =~ s/^\*+//;
				     }
				     $result{$node} = $_[1] if $_[1];
			     }
                         }
 
                     );
                  },
                  on_error => sub{
                      undef $hdl;
                      $cv->end;
                      $work->();
                  },
                  on_eof => sub{
                      undef $hdl;
                      $cv->end;
                      $work->();
                  }
             );
             if( my $ef = $ENV{MYDanExtractFile} )
             {
                 my $size = length $query;
                 $hdl->push_write("MYDanExtractFile_::${size}:${efsize}:${md5}:${aim}::_MYDanExtractFile");
                 $hdl->push_write($query);
             }
             else
             {
                 $hdl->push_write($query);
                 $hdl->push_shutdown;
             }
          }, sub{ return $now_update_time + 5; };
    };

    my $max = scalar @node > $run{max} ? $run{max} : scalar @node;
    $work->() for 1 .. $max ;


    my $w = AnyEvent->timer ( after => $run{timeout},  cb => $tocb );
    $cv->recv;
    undef $w;

    map{ 
        my $end = $cut{$_} =~ /--- (\d+)\n$/ ? "--- $1\n" : '';
         $result{$_} .= "\n==[Warn]The content was truncated\n$end";
    } keys %cut;

    map{ $_ =~ s/^\**#\*MYDan_\d+\*#//;}values %result;
    return %result;
}

1;
