package Gearman::Glutch;
use strict;
use warnings;
use utf8;
use parent qw/Class::Accessor::Fast/;

use 5.010001;
our $VERSION = '0.02';

use POSIX ":sys_wait_h";

use Gearman::Worker;
use Gearman::Server;
use Danga::Socket;

__PACKAGE__->mk_accessors(qw/server port max_workers max_reqs_per_child on_spawn_child on_complete/);

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    my $port = $args{port} || Carp::croak "Missing mandatory parameter: port";
    return bless {
        server => Gearman::Server->new(),
        functions => [],
        max_workers => 1,
        %args
    }, $class;
}

sub register_function {
    my $self = shift;
    push @{$self->{functions}}, \@_;
}

sub run {
    my $self = shift;

    local $SIG{PIPE} = 'IGNORE'; # handled manually

    my $ssock  = $self->server->create_listening_sock($self->port);
    $self->{ssock} = $ssock;

    # great graceful shutdown support
    $Gearmand::graceful_shutdown = 0;
    local *Gearmand::shutdown_graceful = sub {
        return if $Gearmand::graceful_shutdown;
        my $ofds = Danga::Socket->OtherFds;
        delete $ofds->{fileno($ssock)};
        $ssock->close;
        $Gearmand::graceful_shutdown = 1;
        exit 0 unless $self->server->jobs_outstanding;
    };

    # spawn workers
    for my $i (1..$self->max_workers) {
        $self->spawn_worker();
    }

    local $SIG{CHLD} = sub {
        my $kid;
        do {
            $kid = waitpid(-1, WNOHANG);
            if ($kid) {
                delete $self->{pids}->{$kid};
            }
        } while $kid > 0;

        while (0+(keys %{$self->{pids}}) < $self->max_workers) {
            $self->spawn_worker();
        }
    };

    $SIG{INT} = $SIG{TERM} = sub {
        $self->shutdown();
        exit 0;
    };

    # run main loop
    Danga::Socket->EventLoop();
}

sub spawn_worker {
    my $self = shift;

    my $pid = $self->server->start_worker(sub {
        close $self->{ssock};
        $self->{child}++;

        my $worker = Gearman::Worker->new();
        for my $func (@{$self->{functions}}) {
            $worker->register_function(@$func);
        }
        my $i=0;
        $worker->work(
            stop_if => sub {
                if (defined($self->max_reqs_per_child) && $i >= $self->max_reqs_per_child) {
                    1;
                } else {
                    0
                }
            },
            on_complete => sub {
                $self->on_complete->(@_) if $self->on_complete;
                ++$i;
            },
        );
        exit 0;
    });
    $self->on_spawn_child->($pid) if $self->on_spawn_child;
    $self->{pids}->{$pid}++;
    return $pid;
}

sub DESTROY {
    my $self = shift;
    return if $self->{child};
    $self->shutdown();
}

sub shutdown :method {
    my $self = shift;

    $self->signal_all_children('TERM');
    $self->_wait_all_children();
}

sub signal_all_children {
    my ( $self, $sig ) = @_;
    for my $pid ( sort keys %{ $self->{pids} } ) {
        kill $sig, $pid;
    }
}

sub _wait_all_children {
    my $self = shift;

    my $kid;
    do {
        $kid = waitpid(-1, WNOHANG);
    } while $kid > 0;
}

1;

__END__

=encoding utf8

=head1 NAME

Gearman::Glutch - gearman casual

=head1 SYNOPSIS

    use Gearman::Glutch;

    my $worker = Gearman::Glutch->new(
        port => 9999,
        max_workers => 5,
        max_reqs_per_child => 5,
        on_spawn_child => sub {
            warn "Spawned $_[0]";
        },
        on_complete => sub {
            warn "Complete job $$";
        },
    );
    $worker->register_function("echo", sub {
        my $job = shift;
        $$.":".$job->arg;
    });
    $worker->run();

=head1 DESCRIPTION

Gearman::Glutch is all in one gearman server management library for casual use.
Glutch spawns L<Gearman::Server> and L<Gearman::Worker> automatically.

=head1 METHODS

=over 4

=item my $glutch = Gearman::Glutch->new(%args)

Create new instance of Gearman::Glutch. You can pass the following arguments.

=over 4

=item port

Port number for gearman server.

=item max_workers(Default: 1)

number of worker processes

=item max_reqs_per_child

max. number of requests to be handled before a worker process exits

=item on_spawn_child

Callback function. This will call on spawned worker process.

=item on_complete

Callback function. This will call on completed one job.

=back

=item $glutch->register_function($name, $code)

=item $glutch->register_function($name, $time, $code)

    $glutch->register_function("echo", sub {
        my $job = shift;
        # $job is instance of Gearman::Job
        $$.":".$job->arg;
    });

Register function to the worker processes.

=item $glutch->run()

Spawn the child processes and go to main loop.

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
