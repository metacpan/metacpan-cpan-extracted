package Gearman::Spawner;

use strict;
use warnings;

use 5.10.0;

our $VERSION = '1.11';

use Carp qw( croak );
use Gearman::Spawner::Supervisor;

sub new {
    my $this = shift;
    my $class = ref $this || $this;

    my %params = @_;

    $params{servers} // croak "need servers";
    $params{workers} // croak "need workers";

    my $pid = Gearman::Spawner::Supervisor->start(%params);

    return bless {
        pid => $pid,
    }, $class;
}

sub pid {
    my $self = shift;
    return $self->{pid};
}

sub DESTROY {
    my $self = shift;
    kill 'INT', $self->{pid};
}

1;

__END__


=head1 NAME

Gearman::Spawner - Lifecycle manager for Gearman workers

=head1 SYNOPSIS

    # Launcher code
    $spawner = Gearman::Spawner->new(
        servers => ['localhost:7003'],
        preload => ['DBI'],
        workers => {
            MyWorker => {
                data     => {value => 3},
                max_jobs => 100,
            },
        },
    );


    # Worker class
    package MyWorker;
    use base 'Gearman::Spawner::Worker';

    sub new {
        my $class = shift;
        my $self = fields::new($class)->SUPER::new(@_);

        $self->register_method('mymethod');
        return $self;
    }

    sub mymethod {
        my MethodWorker $self = shift;
        my $arg = shift;
        return $arg + $self->{data}{value}; # value is 3, from above
    }


    # Client
    $client = Gearman::Spawner::Client::Sync->new(
        job_servers => \@servers,
    );
    my $retval = $client->run_method(MyWorker => mymethod => 4); # 7

=head1 DESCRIPTION

This class has a single method C<new> which creates a subprocess that manages
the lifecycles of configured Gearman workers. The workers must conform to a
simple OO interface, typically by inheriting from Gearman::Spawner::Worker.
The Gearman::Spawner object returned by C<new> may be queried by it's C<< ->pid
>> method to discover the identity of the process supervising the workers.
Additionally, when this object is destroyed, the spawner process and the child
workers are killed.

=head2 new

C<new> takes the following parameters:

=over 4

=item servers

(Required) A list of gearmand servers with which to register the workers.  Each
item in the list should be a string in the form "host:port".

=item preload

(Optional) A list of modules to be loaded before workers are forked. The memory
used by the loaded code can then be shared between the workers.

=item workers

(Required) A mapping of worker module names to the following configuration
structure:

=over 4

=item count

(Optional) The number of workers of this class to start. If not provided, 1 is
assumed.

=item data

(Optional) An opaque structure which will be made available to workers as an
object member.

=item max_jobs

(Optional) If specified, the number of jobs a worker will be allowed to
complete before exiting cleanly. The spawner will create a new worker to
replace it. Useful if your workers leak memory and should be recycled
occasionally.

=back

=back

=head1 FEATURES

Features:

=over 4

=item * All preloaded and worker modules will be tested for loadability before
workers are spawned so that failures are apparent to the caller (as an
exception).

=item * When the object is destroyed, the spawner process is killed, and so in
turn are the workers.

=item * If a worker dies unexpectedly, one will be created to replace it.

=item * Worker code requires just a simple constructor that registers one or
more methods; object method code then has access to both worker configuration
data and parameters of the job being executed.

=item * Serialization of client arguments and worker return values is handled
transparently.

=item * A synchronous client and a Danga::Socket-based asynchronous client are
included.

=item * Server-enforced timeouts for workers is supported.

=item * Methods are automatically namespaced according to worker class.

=back

=head1 AUTHOR

Adam Thomason, E<lt>athomason@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Say Media Inc, E<lt>cpan@sixapart.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
