=head1 NAME

DynGig::Automata::Thread - Extends DynGig::Automata::Serial.

=cut
package DynGig::Automata::Thread;

use base DynGig::Automata::Serial;

use warnings;
use strict;
use Carp;

use threads;
use Thread::Queue;

use constant CTX => 'ctx.';

our $MAX_THR = 100;

=head1 DESCRIPTION 

Process several targets simultaneously in a user specified number of threads.
Each target is processed in sequential steps specified by the user.
As a target completes the sequence, a new target takes its thread and starts
the sequence, until all targets are exhausted.

Execution pauses for a thread/target when an error is encountered in any job.
The error associated with the corresponding target is recorded in the alert
database. Other threads/targets are not affected in the mean while.
Execution resumes for a thread when all errors associated with the 
correponding target are removed from the alert database.

=cut
sub run
{
    my ( $this, %param ) = @_;
    my $error = 'invalid context';
##  context
    croak "$error: not defined" unless my $context = $param{context};
    croak "$error: not HASH" if ref $context ne 'HASH';

    my @key = qw( global );
    map { push @key, $_ if defined $this->{$_} } qw( target begin end );

    for my $key ( @key )
    {
        unless ( defined $context->{$key} )
        {
            $context->{$key} = {};
        }
        elsif ( ref $context->{$key} ne 'HASH' )
        {
            croak "$error: $key not HASH";
        }
    }

    $context->{transient} = {};
##  threads
    my $thread = $param{thread};

    croak 'invalid thread'
        if defined $thread && ( ref $thread || $thread !~ /^\d+$/ );

    $thread = $MAX_THR unless $thread && $thread < $MAX_THR;
##  shmem queue
    my $file = $this->{_file};
    my $queue = $this->{queue};
    my %shmem = map { $_ => Thread::Queue->new() } 

    my @job = ( DynGig::Automata::Serial::GLOBAL,
        map { $_->{name} } @$queue );

    my $run = $this->{_run} = { shmem => \%shmem, context => $context };
##  prepare
    $this->_prepare( %param );
##  alert db
    my $alert = $run->{alert} ||= DynGig::Automata::EZDB::Alert
        ->new( $file->{alert}, table => \@job );
##  begin
    my $name = $this->{name};
    my $logger = $run->{logger};
    my $shmem = $shmem{ $job[0] };

    $logger->write( 'START: sequence %s', $name );
    $this->_job( $this->{begin} );
##  sequence
    for ( my ( $current, %retry, %thread ) = 0; 1; sleep 1 )
    {
        my $stuck; ## pause/kill

        while ( my $pause = DynGig::Util::LockFile::Time->check( $file->{pause} ) )
        {
            if ( $pause >= DynGig::Automata::Serial::KILL )
            {
                map { $alert->truncate( $_ ) } @job;
                map { $_->kill( 'KILL' )->detach() } values %thread;

                $logger->write( 'KILL: sequence %s', $name );
                goto DONE;
            }
            elsif ( ! $stuck )
            {
                $logger->write( 'PAUSE: sequence %s', $name );
                $stuck = $pause;
            }

            sleep 10;
        }

        $this->_job_param();

        while ( $shmem->pending() ) ## done/error
        {
            my ( $job, $target, $context, $error ) = $shmem->dequeue( 4 );

            $thread{$target}->join;
            delete $thread{$target};
            $context = YAML::XS::Load $context;

            if ( $job == @$queue ) ## done
            {
                $run->{context}{ CTX.$target } = $context->{glocal};
                $logger->write( 'DONE: %s', $target );
                next;
            }

            my $name = $queue->[$job]{name};

            $retry{$target} ||= 0;

            if ( $retry{$target} ++ < $queue->[$job]{retry} ) ## retry
            {
                $thread{$target} = threads::async
                {
                    $this->_sequence( $job, $target, $context );
                };

                $logger->write( 'RETRY %d: %s @ %s << %s', $retry{$target},
                    $target, $name, $error );
            }
            else ## alert
            {
                $alert->set( $name, $target, $error );
                delete $retry{$target};

                $logger->write( 'ALERT: %s @ %s << %s',
                    $target, $name, $error );
            }
        }

        my @alert = map { $alert->dump( $_ ) } @job;

        next if @alert / 2 + keys %thread >= $thread;

        if ( my @target = $this->_job( $this->{target} ) ) ## new target
        {
            my $target = shift @target;
            my $local = CTX.$target;

            unless ( defined $context->{$local} )
            {
                $context->{$local} = {};
            }
            elsif ( ref $context->{$local} ne 'HASH' )
            {
                croak "$error: $local not HASH";
            }

            my %context = ( transient => {}, glocal => $context->{$local} );

            $thread{$target} = threads::async
            {
                $this->_sequence( 0, $target, \%context );
            };

            $logger->write( 'START: %s', $target );
        }
        else  ## all done
        {
            last unless %thread || @alert;
        }
    }
##  end
    DONE: $this->_job( $this->{end} );
    $logger->write( 'DONE: sequence %s', $name );
}

sub _sequence
{
    local $SIG{ALRM} = sub {};

    my ( $this, $job, $target, $context ) = @_;
    my $queue = $this->{queue};
    my $run = $this->{_run};
    my %logger = ( logger => sub { $run->{logger}->write( @_ ) } );
    my @result;

    for ( ; $job < @$queue; $job ++, @result = '' )
    {
        my %context = map { $_ => $run->{context}{$_} } qw( global transient );

        @result = $this->_eval
        (
            $queue->[$job], %{ $this->_job_param( $job ) }, %logger,
            context_ro => \%context,
            context => $context,
            target => $target,
        );

        last if shift @result == DynGig::Automata::Serial::ERROR;
    }

    $run->{shmem}{DynGig::Automata::Serial::GLOBAL}->enqueue
    (
        $job, $target, YAML::XS::Dump( $context ), @result
    );
}

sub _job_param  ##  two faced param override
{
    my ( $this, $job ) = @_;
    my $run = $this->{_run};
    my $queue = $this->{queue};
    my $param = $run->{param};
    my $shmem = $run->{shmem};

    if ( defined $job )  ##  child
    {
        my $name = $queue->[$job]{name};

        return {} unless my $shmem = $shmem->{$name};
        return {} unless my $time = $shmem->peek( -2 );

        my $param = $param->{$name} ||= {};

        return $param->{$time} if $param->{$time};

        map { delete $param->{$_} } keys %$param;

        my $override = eval { YAML::XS::Load $shmem->peek( -1 ) };

        return $param->{$time} = $override if ! $@ && ref $override eq 'HASH';

        $shmem->dequeue( 2 );
        return {};
    }

    local $/;

    for my $job ( @$queue )  ##  parent
    {
        my $name = $job->{name};
        my $shmem = $shmem->{$name};
        my $param = $param->{$name} ||= {};
        my $file = File::Spec->join( $this->{_dir}{param}, $name );

        goto NEXT unless -f $file && open my $handle, '<', $file;

        my $time = ( stat $handle )[9];

        if ( $param->{$time} )
        {
            close $handle;
            next;
        }

        map { delete $param->{$_} } keys %$param;
        $shmem->enqueue( $time, $param->{$time} = <$handle> );

        close $handle;
        next if $shmem->pending == 2;

        NEXT: $shmem->dequeue_nb( 2 );
    }
}

=head1 NOTE

See DynGig::Automata

=cut

1;

__END__
