package MYDan::Bootstrap;
use strict;
use warnings;
use Carp;
use YAML::XS;

use File::Basename;
use MYDan::Util::FLock;
use POSIX qw( :sys_wait_h );
use AnyEvent::Loop;
use AnyEvent;

use IPC::Open3;
use Symbol 'gensym';
use Time::TAI64 qw/unixtai64n/;
use Data::Dumper;

my %RUN =( size => 10000000, keep => 5 );
our %time;

our %proc;
sub new
{
    my ( $class, %this ) = @_;
    map{ 
        confess "$_ undef" unless $this{$_};
        system "mkdir -p '$this{$_}'" unless -d $this{$_};
    }qw( logs exec lock );
    bless \%this, ref $class || $class;
}

sub run
{
    my ( $this, %run ) = @_;

    our ( $logs, $exec, $lock ) = @$this{qw( logs exec lock )};

    my $flock = MYDan::Util::FLock->new( "$lock/lock" );
    die "Locked by other processes.\n" unless $flock->lock();
   
    my ( $i, $cv ) = ( 0, AnyEvent->condvar );

    our ( $logf, $logH ) = ( "$logs/current" );
    
    confess "open log: $!" unless open $logH, ">>$logf"; 
    $logH->autoflush;

    my $excb = sub{
        map{ kill( 9, $_->{pid} ) if $_->{pid}; }values %proc;
        die "kill.\n";
    };

    my $term = AnyEvent->signal (signal => "TERM", cb => $excb );
    my $ints = AnyEvent->signal (signal => "INT",  cb => $excb );

    my ( $rand, %time, %rand ) = int rand time;
    my $t = AnyEvent->timer(
        after => 2,
        interval => 3,
        cb => sub {
            my %name = map{ basename( $_ ) => 1  }glob "$exec/*";
            for my $name ( keys %name )
            {
                next if $proc{$name};

                if( $name =~ /^(\d+)([_\-\*\+]{1})/ )
                { 
                    my ( $i, $t, $r ) = ( $1, $2, $rand );
                    if( $t eq '*' || $t eq '_' )
                    {
                        $rand{$name} = int( rand time ) unless defined $rand{$name} ;
                        $r = $rand{$name};

                        $t = '+' if $t eq '*';
                        $t = '-' if $t eq '_';
                    }
                    
                    my $tt = int( ( time + $r ) / $i );
                    $time{$name} = $tt if $t eq '-' && ! defined $time{$name};
                    next if $time{$name} && $time{$name} eq $tt;
                    $time{$name} = $tt;
                }

                my ( $err, $wtr, $rdr ) = gensym;
                my $pid = IPC::Open3::open3( undef, $rdr, $err, "$exec/$name" );
           
     		    $proc{$name}{pid} = $pid;
                $proc{$name}{child} = AnyEvent->child ( pid => $pid, cb => sub{
                    map{ delete $proc{$_} if $proc{$_}{pid} == $pid }keys %proc;
                    } );
                $proc{$name}{rdr} = AnyEvent->io (
                    fh => $rdr, poll => "r",
                    cb => sub {
                        my $input;my $n = sysread $rdr, $input, 102400;
                        delete $proc{$name}{rdr} and return unless $n;
                        chomp $input;
                        syswrite( $logH, unixtai64n(time). " [$name] [STDOUT] $input\n" );
                    }
                );
                $proc{$name}{err} = AnyEvent->io (
                    fh => $err, poll => "r", 
                    cb => sub {
                        my $input;my $n = sysread $err, $input, 102400;
                        delete $proc{$name}{err} and return unless $n;

                        chomp $input;
                        syswrite( $logH, unixtai64n(time). " [$name] [STDERR] $input\n" ); 
                    }
                );
            }

            for my $proc ( keys %proc )
            {
                next if $name{$proc};
                kill 'KILL', $proc{$proc}{pid}; 
            }
        }
    );
    my $tt = AnyEvent->timer(
        after => 30,
        interval => 60,
        cb => sub {
            my $size= ( stat "$logs/current" )[7];
            return unless $size > $RUN{size};
            my $num = $this->_num();
            system "mv '$logs/current' '$logs/log.$num'";
            
	    confess "open log: $!" unless open $logH, ">>$logf"; 
	    $logH->autoflush;
             
        }
    );

    $cv->recv;
    return $this;
}

sub _num
{
    my ( $logs, %time ) = shift->{logs};
    for my $num ( 1 .. $RUN{keep} )
    {
       return $num unless $time{$num} = ( stat "$logs/log.$num" )[10];
    }
    return ( sort{ $time{$a} <=> $time{$b} } keys %time )[0];
}

1;
