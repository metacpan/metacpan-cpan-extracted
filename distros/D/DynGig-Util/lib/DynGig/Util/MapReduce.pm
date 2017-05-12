=head1 NAME

DynGig::Util::MapReduce - A Map Reduce Job Launcher

=cut
package DynGig::Util::MapReduce;

use warnings;
use strict;
use Carp;

use threads;
use YAML::XS;
use Thread::Queue;

use constant { ERROR => 1, OK => 0 };

=head1 SYNOPOSIS

 use DynGig::Util::MapReduce;

 my $batch = sub { ..  };
 my $map = sub { .. };
 my $reduce = sub { .. };

 my $job = DynGig::Util::MapReduce->new
 (
     name => 'foo',
     batch => $batch,
     map => $map,
     reduce => $reduce,
 );

 my %batch_param = ( .. );
 my %map_param = ( .. );
 my %reduce_param = ( .. );
 my %context = ( .. );

 $job->run
 (
     context => \%context,
     batch => \%batch_param,
     map => \%map_param,
     reduce => \%reduce_param,
 );

 my $result = $job->result();

=cut
sub new
{
    my ( $class, %this ) = @_;
    my $name = $this{name};
    my $error = 'invalid config';

    croak "$error: undefined/invalid name" if ! defined $name || ref $name;

    for my $key ( qw( batch map reduce ) )
    {
        my $plugin = $this{$key}; 
        my $error = "$error '$key'";

        unless ( defined $plugin )
        {
            next if $key eq 'reduce';
            croak $error;
        }

        croak "$error: not HASH" if ref $plugin ne 'HASH';
        croak "$error: undefined/invalid code"
            if ! defined $plugin->{code} || ref $plugin->{code} ne 'CODE';

        my $time = 0;
        my $timeout = $plugin->{timeout} || 0;

        $plugin->{param} ||= {};
        $plugin->{timeout} ||= 0;
    }

    bless \%this, ref $class || $class;
}

=head1 DESCRIPTION

Map/Reduce is an approach that collects data in parallel then processes data in
serial. A Map/Reduce job has 4 components/steps. Each component is to be
defined by the user.

 Batch : divide the targets into batches.
 Map   : create threads to collect data from/for each batch in parallel.
 Sort  : aggregate collected data by status.
 Reduce: (optional) process aggregated data serially.

=head2 run( batch => HASH, map => HASH, reduce => HASH, context => HASH )

=cut
sub run
{
    local $SIG{ALRM} = sub {};

    my ( $this, %param ) = @_;
    my $error = 'invalid context';
    my $name = $this->{name};

    croak "$error: not defined" unless my $context = $param{context};
    croak "$error: not HASH" if ref $context ne 'HASH';

    for my $key ( 'global', $name )
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

    my $run = $this->{_run} = {};
    
    $run->{context} = +
    {
        transient => {},
        glocal => $context->{$name},
        global => $context->{global},
    };

    for my $key ( qw( batch map reduce ) )
    {
        my $param = $param{$key};

        if ( defined $param )
        {
            croak "invalid $key: not HASH" if ref $param ne 'HASH';
            $run->{$key} = $param;
        }
        else
        {
            $run->{$key} = {};
        }
    }

    $this->_batch()->_map()->_sort()->_reduce();
}

=head2 result()

Returns the result of the run as a HASH reference
or undef if invoked before run.

=cut
sub result
{
    my $this = shift @_;
    my $run = $this->{_run};

    return $run ? $run->{result} : undef;
}

=head2 context()

Returns the context of the run as a HASH reference
or undef if invoked before run.

=cut
sub context
{
    my $this = shift @_;
    my $run = $this->{_run};

    return $run ? $run->{context} : undef;
}

=head2 name()

Returns the name of the job.

=cut
sub name
{
    my $this = shift @_;
    return $this->{name};
}

sub _batch
{
    my $this = shift @_;
    my $run = $this->{_run};
    my $name = $this->{name};
    my %context = %{ $run->{context} };

    my ( $status, $result ) = _eval
    (
        ARRAY => $this->{batch},
        context => \%context,
        %{ $run->{batch} },
    );

    croak "$name: BATCH: $result" if $status == ERROR;

    $run->{result} = $result;
    return $this;
}

sub _map
{
    my $this = shift @_;
    my $run = $this->{_run};
    my %context = %{ $run->{context} };
    my @result;

    for my $batch ( @{ $run->{result} } )
    {
        my $queue = Thread::Queue->new();
        my $thread = threads::async
        {
            my ( $status, $result ) = _eval
            (
                HASH => $this->{map},
                context => \%context,
                batch => $batch,
                %{ $run->{map} },
            );

            $queue->enqueue
            (
                $status, ref $result ? YAML::XS::Dump $result : $result
            );
        };

        push @result, +{ queue => $queue, thread => $thread };
    }

    $run->{result} = \@result;
    return $this;
}

sub _sort
{
    my $this = shift @_;
    my $run = $this->{_run};
    my $name = $this->{name};
    my %result;

    for my $batch ( @{ $run->{result} } )
    {
        my ( $status, $result ) = $batch->{queue}->dequeue( 2 );

        croak "$name: MAP: $result" if $status == ERROR;

        $batch->{thread}->join();

        next unless $this->{reduce};

        $result = YAML::XS::Load $result;
        map { $result{$_} = $result->{$_} } keys %$result;
    }

    $run->{result} = \%result;
    return $this;
}

sub _reduce
{
    my $this = shift @_;

    return $this unless my $reduce = $this->{reduce};

    my $run = $this->{_run};
    my $name = $this->{name};
    my %context = %{ $run->{context} };

    my ( $status, $result ) = _eval
    (
        undef, $reduce,
        context => \%context,
        data => $run->{result},
        %{ $run->{reduce} },
    );

    croak "$name: REDUCE: $result" if $status == ERROR;

    $run->{result} = $result;
    return $this;
}

sub _eval
{
    my ( $wantref, $job, %param ) = @_;
    my ( $status, $result ) = ERROR;

    eval
    {
        my $timeout = $job->{timeout};
        local $SIG{ALRM} = sub { die "timeout after $timeout seconds\n" };

        alarm $timeout;
        $result = &{ $job->{code} }( %{ $job->{param} }, %param );
        alarm 0;
    };

    if ( $@ )
    {
        $result = $@;
    }
    elsif ( defined $wantref && ref $result ne $wantref )
    {
        $result = "result not $wantref";
    }
    else
    {
        $status = OK;
    }

    return $status, $result;
}

=head1 SEE ALSO

threads, Thread::Queue, and YAML::XS for data serialization.

=head1 NOTE

See DynGig::Util

=cut

1;

__END__
