package MColPro::Platform;

=head1 NAME

Collect - MColPro Data collector

=cut

use strict;
use warnings;
use Data::Dumper;

use Carp;
use threads ('yield',
             'stack_size' => 1096*4096,);
use threads::shared;
use Thread::Semaphore;
use Thread::Queue;
use Time::HiRes qw( time sleep alarm );

use MColPro::Util::Serial qw( serial unserial );

sub new
{
    my ( $class, %param ) = @_;
    $param{MAXTHREAD} ||= 200;
    $param{STEP} ||= 5;

    die "plugin list is needed" unless $param{plugin};

    $param{taskq} = Thread::Queue->new();
    $param{feedbackq} = Thread::Queue->new();
    $param{alarmq} = Thread::Queue->new();

    $param{waitworks} = 0;

    $param{threads} = {};

    bless \%param, ref $class || $class;
}

sub taskq
{
    my $this = shift;
    
    return $this->{taskq};
} 
sub feedbackq
{
    my $this = shift;
    
    return $this->{feedbackq};
}

sub prepare
{
    my $this = shift;
    my $thread = $this->{STEP};
    $thread = $this->{MAXTHREAD} if $this->{MAXTHREAD} < 20;

    $this->{waitworks} += $this->{STEP};
    for( my $i=0; $i<$thread; $i++ )
    {
        my $worker = threads::async
        {
            &_worker( $this->{taskq}, $this->{feedbackq},
                $this->{alarmq}, $this->{plugin} );
        };

        $this->{threads}{$worker->tid}{handle} = $worker;
        $this->{threads}{$worker->tid}{alarm} = -1;
    }
}

sub bye
{
    my $this = shift;

    map
    {
        $_->kill( 'SIGKILL' )->detach() if $_->is_running();
    } values %{ $this->{threads} };
}

sub cstring
{
    my $this = shift;

    return sprintf( "%d/%d/%d", $this->{taskq}->pending(),
        $this->{waitworks}, scalar threads->list() );
}

sub ask
{
    my $this = shift;

    $this->_alarm();

    my $tc = threads->list();
    my $waitworks = $this->{waitworks};
    my $waittasks = $this->{taskq}->pending();

    #print "$waittasks/$waitworks/$tc",  "\n";
    if ( $waittasks > $waitworks && $tc < $this->{MAXTHREAD} )
    {
        $this->{waitworks} += $this->{STEP};
        for( my $i=0; $i<$this->{STEP}; $i++ )
        {
            my $worker = threads::async
            {
                &_worker( $this->{taskq}, $this->{feedbackq},
                    $this->{alarmq}, $this->{plugin} );
            };

            $this->{threads}{$worker->tid}{handle} = $worker;
            $this->{threads}{$worker->tid}{alarm} = -1;
        }
    }
}

sub _alarm
{
    my $this = shift;
    
    my $max = 20;
    my $tmpc = 0;
    while( $max && defined ( my $alarm = $this->{alarmq}->dequeue_nb() ) )
    {
        $this->{threads}{$alarm->[0]}{alarm} = $alarm->[1];
        $alarm->[1] == -1 ? $tmpc++ : $tmpc--;
    }

    $this->{waitworks} += $tmpc;

    my $now = time;
    while(  my ( $tid, $thr ) = each %{ $this->{threads} } )
    {
        if( $thr->{alarm} != 0 && $thr->{alarm} != -1 &&
            $thr->{alarm} < $now )
        {
            $thr->{handle}->kill( 'SIGALRM' );
            next;
        }
    }
}

sub _worker
{
    my ( $taskq, $feedbackq, $alarmq, $plugin ) = @_;

    ## wait set alarm
    sleep 0.5;

    local $SIG{KILL} = sub{ threads->exit(); };

    my $init;
    if ( defined $plugin->{INIT} && ref $plugin->{INIT} eq 'CODE' )
    {
        $init = $plugin->{INIT}();
    }

    while( 1 )
    {
        if( defined ( my $taskstring = $taskq->dequeue_nb() ) )
        {
            my $task = unserial( $taskstring );

            ## for timeout 
            $alarmq->enqueue( [ threads->tid(), $task->{due} || 0 ] );

            my $result = undef;
            eval
            {
                local $SIG{ALRM} = sub{ die "timeout" };
                my %param = %{ $task->{param} };
                $result = $plugin->{$task->{plugin}}( %param, %$init );
            };

            if ( $@ )
            {
                my $dumper = Dumper( $task );
                warn( "Platform: thread erorr $@:".$dumper );
            }

            $feedbackq->enqueue( serial( $task) ) if $task->{feedback};

            $alarmq->enqueue( [ threads->tid(), -1 ] );
        }

        sleep 0.5;
    }
}

1;
