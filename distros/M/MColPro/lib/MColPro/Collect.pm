package MColPro::Collect;

=head1 NAME

Collect - MColPro Data collector

=cut

use strict;
use warnings;

use Carp;
use threads ('yield',
             'stack_size' => 1096*4096,);
use threads::shared;
use Thread::Semaphore;
use Thread::Queue;
use Sys::Hostname;
use Time::HiRes qw( time sleep alarm stat );
use DynGig::Range::Cluster;

use MColPro::Util::Logger;
use MColPro::Util::Plugin;
use MColPro::Util::Serial qw( serial unserial deepcopy );
use MColPro::SqlBase;
use MColPro::Record;
use MColPro::Exclude;
use MColPro::CollectConf;

use MColPro::Platform;
use MColPro::Claim;
use MColPro::Dispatch;
use Data::Dumper;

sub new
{
    my ( $class, %param ) = @_;
    my %self;

    confess "invaild conf" 
        unless $param{colconf} && $param{config};

    $self{conf} = MColPro::CollectConf->new( $param{colconf} );
    $self{type} = $self{conf}{type};
    $self{confname} =$param{colconf};

    ## db
    $self{config} = MColPro::SqlBase::conf_check( $param{config} );

    $self{targets} = $self{conf}->parse();

    $self{plugin} = MColPro::Util::Plugin->new( $self{conf}{plugin} );

    $self{waitq} = [];
    $self{disp} = Thread::Queue->new();
    $self{taskcount} = 0;

    ## locate
    $self{locate} = hostname;

    $self{log} = MColPro::Util::Logger->new( \*STDERR );

    bless \%self, ref $class || $class;
}

sub run
{
    my $self = shift;

    my $log = $self->{log};
    my $logsub = sub { $log->say( @_ ) };
    $self->{heartbeat} = time;

    my $run_plugin = sub
    {
        my %param = @_;

        my $tmphc = MColPro::SqlBase->new( $self->{config}{hostconfig} );
        my $hc = MColPro::Claim->new(
            { claim => $self->{config}{hostconfig}{claim} }, $tmphc );

        my $result = $self->{plugin}( %param, hc => $hc );

        if ( $result && @$result )
        {
            my @result = @$result;
            $result = undef;

            my $task = 
            {
                plugin => 'record_result',
                start  => $param{RECORD},
                due    => $param{RECORD} + 25,
                param  => { result => \@result },
            };

            $self->{disp}->enqueue( [ $task->{start}, serial( $task ) ] );
        }

        return undef;
    };

    my $record_result = sub
    {
        my %param = @_;

        my $ms = MColPro::SqlBase->new( $self->{config} );
        my $data = MColPro::Record->new( $self->{config}, $ms );
        my $exclude = MColPro::Exclude->new( $self->{config}, $ms );
        my $exclude_hash = $exclude->dump( ) || {};

        for my $result ( @{ $param{result} } )
        {   
            next if( ( $exclude_hash->{cluster} &&
                $exclude_hash->{cluster}{$result->{cluster}} ) ||
                ( $exclude_hash->{$result->{cluster}} &&
                $exclude_hash->{$result->{cluster}}{$result->{node}} ) );
           
            $result->{locate} = $self->{locate};

            $data->insert( %$result );
        }

        $ms->close();
    };

    my $plat = MColPro::Platform->new (
        plugin =>
        {
            run_plugin => $run_plugin,
            record_result => $record_result,
        } );
    $plat->prepare();

    my $taskq = $plat->taskq();
    my $feedbackq = $plat->feedbackq();
    my $disp = $self->{disp};

    ## dispatch thread
    threads::async { MColPro::Dispatch::dispatch( $disp, $taskq ) };
    
    $log->say( '###########collect: started.###############' );

    ## init task
    $self->range();
    for my $i ( @{ $self->{targets} } )
    {
        $self->refresh_task(
            { plugin => 'run_plugin', param => $i, feedback => 1 },
            rand( $self->{conf}{interval} ) );
    }
    my $conftaskcount = @{ $self->{targets} };

    for( my $now; $now = time; )
    {
        while( my $fdb = $feedbackq->dequeue_nb() )
        {
            $self->{taskcount} --;
            $self->refresh_task( unserial( $fdb ) );
        }

        $plat->ask();

        $self->range( $now );

        if( $now > $self->{heartbeat} )
        {
            my $task = 
            {
                plugin => 'record_result',
                start  => $now + $self->{conf}{interval},
                due    => $now + $self->{conf}{interval} + 25,
                param  =>{ result => [ {
                    type => 'MWHB',
                    cluster => 'MWatcher',
                    node => $self->{locate},
                    detail => $self->{confname}.": "
                        .$self->{taskcount}."/".$conftaskcount
                        .", ".$plat->cstring(),
                    label => $self->{confname},
                    level => '0',
                    locate => $self->{locate},
                } ] },
            };
            $self->{disp}->enqueue( [ $task->{start}, serial( $task ) ] );
            $self->{heartbeat} += $self->{config}{heartbeat};
        }

        sleep 1;   
    }
}

sub range
{
    my ( $self, $now ) = @_;

    if( ! defined $self->{range} || $self->{range}{due} < $now )
    {
        my $c = 2;
        while ( $c-- )
        {
            my $range = eval
            {
                DynGig::Range::Cluster->setenv (   
                    server => $self->{config}{range}{server}
                        || 'localhost:65431',
                    timeout => $self->{config}{range}{timeout} || 30,
                ); 
            };
            if ( !$@ && $range )
            {
                $self->{range}{range} = $range;
                last;
            }
            else
            {
                warn "get range error $@";
            }
            sleep 0.5;
        }

        print "range once\n";

        $self->{range}{due} = time + 60;
    }
}

sub refresh_task
{
    my ( $self, $i, $stime ) = @_;

    if ( defined $i->{start} && defined $i->{due} )
    {
        $i->{start} = $i->{start} + $self->{conf}{interval};
        $i->{due} = $i->{due} + $self->{conf}{interval};
    }
    else
    {
        $i->{start} = time + $stime;
        $i->{due} = $i->{start} + $self->{conf}{timeout};
    }
    $i->{param}{RECORD} = $i->{due};

    my $j = $i->{param};
    if ( $j->{range} )
    {
        $j->{range} =~ s/\s//g;
        $j->{range} =~ /(.+?)\((.+?)[:=%](.+?)\)/;

        my @nodes = $self->{range}{range}->expand( $j->{range} );
        my $first = 1;

        while ( 1 )
        {
            delete $j->{targets};
            $j->{targets}{nodes} = [ splice( @nodes, 0 ,
                $self->{conf}{maxnodes} || 60 ) ];
            $j->{targets}{cluster} = $2;
            $j->{targets}{table} = $1;
            $i->{feedback} = $first;

            $self->{disp}->enqueue( [ $i->{start}, serial( $i ) ] );

            $self->{taskcount} += $first;
            $first = 0;

            last if @nodes == 0;
        }
    }
    else
    {
        $self->{disp}->enqueue( [ $i->{start}, serial( $i ) ] );
        $self->{taskcount} += 1;
    }
}

1;
