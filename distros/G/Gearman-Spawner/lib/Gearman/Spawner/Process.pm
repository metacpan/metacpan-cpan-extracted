package Gearman::Spawner::Process;

# class that encapsulates things of which there should only be one per process,
# like signal handlers

use strict;
use warnings;

use Carp qw( croak );
use Danga::Socket ();
use POSIX qw( WNOHANG );

our $CHECK_PERIOD = 5;

my $INSTANCE;
sub instance {
    my $class = shift;
    return $INSTANCE ||= $class->new();
}

sub new {
    my $class = shift;

    die "new can only be called once" if $INSTANCE;

    my $self = bless {
        next_handle => 1,
    }, $class;

    my $reaper = sub { $self->reap; 1 };

    $SIG{INT} = $SIG{TERM} = sub { $self->quit };

    # after a child dies, collect children on next pass through event loop
    $SIG{CHLD} = sub { Danga::Socket->AddTimer(0, $reaper); };

    # ... also check for dead children periodically on a timer to work around signal races
    $self->run_periodically($reaper);

    return $self;
}

sub reap {
    my $self = shift;
    while ((my $pid = waitpid(-1, WNOHANG)) > 0) {
        my $cb = delete $self->{_chld_actions}{$pid};
        $cb->() if $cb;
    }
}

sub fork {
    my $self = shift;
    my $child_name = shift;
    my $clingy = shift;

    my $parent_pid = $$;

    my $pid = CORE::fork() // croak "failed to fork: $!";
    return $pid if $pid; # parent

    # child
    $self->exit_with_parent($parent_pid) if $clingy;

    $0 = $child_name;

    return $pid;
}

sub exit_with_parent {
    my $self = shift;
    my $orig_ppid = shift;
    my $orig_pid = $$;

    if (getppid != $orig_ppid) {
        warn "Exiting immediately because parent changed\n";
        exit;
    }
    $self->run_periodically(sub {
        return 0 if $$ != $orig_pid; # stop checking if we're a child process of whichever set this
        exit if getppid != $orig_ppid;
        1;
    });
}

sub maintain_subprocess {
    my $self = shift;
    my $process_creator = shift; # subref that returns a pid

    my $handle = $self->{next_handle}++;

    my $recreator;
    $recreator = sub {
        my $pid = $process_creator->();
        $self->{_pid_for_handle}{$handle} = $pid;
        $self->{_chld_actions}{$pid} = $recreator;
    };
    $recreator->();

    return $handle;
}

# takes one or more handles returned from maintain_process and kills the associated process
sub kill_maintained {
    my $self = shift;
    my @handles = @_;

    kill 'INT', grep { defined } map { $self->{_pid_for_handle}{$_} } @handles;
}

# takes a subref and a number of seconds, and runs the sub that often. if the
# sub returns a false value, it will not be run again.
sub run_periodically {
    my $self = shift;
    my $sub = shift;
    my $recycler;
    $recycler = sub {
        my $again = $sub->();
        if ($again) {
            Danga::Socket->AddTimer($CHECK_PERIOD, $recycler);
        }
    };
    Danga::Socket->AddTimer(0, $recycler);
}

sub loop {
    my $self = shift;
    Danga::Socket->EventLoop;
}

sub quit {
    my $self = shift;
    return if $self->{_quitting}++;

    my @children = keys %{ $self->{_chld_actions} };
    kill 'INT', @children if @children;
    exit;
}

sub DESTROY {
    return unless $INSTANCE;
    $INSTANCE->quit;
}

1;
