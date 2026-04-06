package IPC::Manager::Spawn;
use strict;
use warnings;

our $VERSION = '0.000011';

use POSIX();

use Carp qw/croak/;
use IPC::Manager::Serializer::JSON();

use overload(
    fallback => 1,

    '""' => sub { $_[0]->info },
);

use Object::HashBase qw{
    <protocol
    <route
    <serializer
    <guard
    <stash
    <pid
    <signal

    do_sanity_check
};

sub init {
    my $self = shift;

    $self->{+PID}   //= $$;
    $self->{+GUARD} //= 1;

    croak "'protocol' is a required attribute"   unless $self->{+PROTOCOL};
    croak "'route' is a required attribute"      unless $self->{+ROUTE};
    croak "'serializer' is a required attribute" unless $self->{+SERIALIZER};
}

sub cleave {
    my $self = shift;

    my ($rh, $wh);
    pipe($rh, $wh) or die "Could not open a pipe: $!";

    my $pid = fork() // die "Could not fork: $!";

    if ($pid) {
        close($wh);
        chomp(my $out = <$rh>);
        close($rh);
        return $self->{+PID} = $out;
    }

    close($rh);
    POSIX::setsid() or die "Can't start a new session: $!";

    $pid = fork() // die "Could not fork: $!";

    if ($pid) {
        close($wh);
        POSIX::_exit(0);
    }

    print $wh "$$\n";
    close($wh);

    $self->{+PID} = $$;
    return 0;
}

sub info {
    my $self = shift;
    return IPC::Manager::Serializer::JSON->serialize([@{$self}{PROTOCOL(), SERIALIZER(), ROUTE()}]);
}

sub connect {
    my $self = shift;
    my ($id) = @_;
    return $self->{+PROTOCOL}->connect($id, $self->{+SERIALIZER}, $self->{+ROUTE});
}

sub terminate {
    my $self = shift;
    my ($con) = @_;
    $con //= $self->connect('spawn');

    # Send the signal before the broadcast so services can act on it
    # before the terminate message arrives and ends the event loop.
    if ($self->{+SIGNAL()}) {
        for my $peer ($con->peers) {
            my $pid;
            unless (eval { $pid = $con->peer_pid($peer); 1 }) { warn $@; next }
            next unless $pid;
            next                           if $pid == $$;
            kill($self->{+SIGNAL()}, $pid) if $self->{+SIGNAL()};
        }
    }

    $con->broadcast({terminate => 1});
}

sub wait {
    my $self = shift;
    my ($con) = @_;
    $con //= $self->connect('spawn');

    for my $client (IPC::Manager::Client->local_clients($self->{+ROUTE})) {
        eval { $client->disconnect; 1 } or warn $@;
    }

    while (1) {
        my @found;
        for my $peer ($con->peers) {
            next if $peer eq $con->id;
            unless (eval { $con->peer_pid($peer); 1 }) { warn $@; next }
            push @found => $peer;
        }

        last unless @found;

        print "Waiting for clients to go away: " . join(', ' => sort @found) . "\n";
        sleep 1;
    }
}

sub sanity_delta {
    my $self = shift;
    my ($con) = @_;
    $con //= $self->connect('spawn');

    my $stats = $con->all_stats;

    my $deltas = {};
    for my $peer1 (keys %$stats) {
        my $stat = $stats->{$peer1};
        my $sent = $stat->{sent} // {};
        my $read = $stat->{read} // {};

        for my $peer2 (keys %$sent) {
            $deltas->{"$peer1 -> $peer2"} += $sent->{$peer2};
        }

        for my $peer2 (keys %$read) {
            $deltas->{"$peer2 -> $peer1"} -= $read->{$peer2};
        }
    }

    delete $deltas->{$_} for grep { /(:spawn|spawn:)/ || !$deltas->{$_} } keys %$deltas;

    return undef unless keys %$deltas;
    return $deltas;
}

sub sanity_check {
    my $self = shift;

    my $delta = $self->sanity_delta(@_) or return;

    die "\nMessages sent vs received mismatch:\n  Positive means sent and not recieved.\n  negative means recieved more messages than were sent\n" . join("\n" => map { "    $delta->{$_} $_" } sort keys %$delta) . "\n\n";
}

sub DESTROY {
    my $self = shift;
    return unless $self->{+GUARD};

    $self->shutdown();
}

sub unspawn {
    my $self = shift;

    $self->{+PROTOCOL}->unspawn($self->{+ROUTE}, delete $self->{+STASH});
}

sub shutdown {
    my $self = shift;

    return unless $self->{+PID} == $$;

    my $con = $self->connect('spawn');

    $self->terminate($con);
    $self->wait($con);

    my $sanity_err;
    if ($self->do_sanity_check) {
        local $@;
        eval { $self->sanity_check($con); 1 } or $sanity_err = $@;
    }

    $con->disconnect;
    $con = undef;

    $self->unspawn;

    die $sanity_err if $sanity_err;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Manager::Spawn - Encapsulation of a newly initiated message store.

=head1 DESCRIPTION

This object encapsualtes a newly initialized message store. It also provides
methods for acting on the message store.

=head1 SYNOPSIS

    use IPC::Manager;

    my $spawn = ipcm_spawn();

    my $con = $spawn->connect('con1');

    ...

    $spawn->shutdown;

=head1 METHODS

=over 4

=item $con = $spawn->connect($name)

Establish a client connection with the given client name.

=item $bool = $spawn->guard()

Check if this instance is a guard. If it is then C<< $spawn->shutdown >> will
be called when the object falls out of scope.

=item $info = $spawn->info()

Get the JSON string with connection information.

=item $pid = $spawn->pid()

Get the PID the spawn object was created it.

=item $protocol = $spawn->protocol()

Get the protocol of the IPC system.

=item $route = $spawn->route()

Get the route information for the IPC system.

=item $spawn->sanity_check()

=item $spawn->sanity_check($con)

Should only be used once the IPC system is no longer in use. Used to verify all
messages that were sent were also recieved.

Will throw an exception if there is a difference between messages sent and
recieved.

=item %delta = $spawn->sanity_delta()

Get a list of message mismatches. This is used by C<< sanity_check() >>, but
can also be used independently if you want to avoid exceptions.

=item $serializer = $spawn->serializer()

Get the serializer used by the IPC system.

=item $pid_or_0 = $spawn->cleave()

Uses double-fork and setsid to create a new process. The ownership of the spawn
will be transferred away from the current process and into the new one. The
original process can exit without ending the IPC state or terminating the new
process.

Returns a pid in the parent, 0 in the new process.

This is essentially daemonize logic except that the parent does not exit, and
IO is not disconnected.

=item $spawn->shutdown()

Shuts down the IPC system:

    my $con = $spawn->connect('spawn');

    $spawn->terminate($con);
    $spawn->wait($con);
    $spawn->sanity_check($con);

    $con->disconnect;
    $con = undef;

    $spawn->unspawn;

=item $sig = $spawn->signal()

Get the signal that will be sent to all processes when terminate is called.

Default in undef, which means no signal is sent.

=item $stash = $spawn->stash()

Get the stash the protocol provided when it spawned a new store.

=item $spawn->terminate()

=item $spawn->terminate($con)

Terminate the IPC system. This will send a termination message to all clients,
and will send signals to all their processes if a signal is set.

=item $spawn->unspawn()

Teardown/destroy the IPC data store. This usually means deleting a directory or
temporary database.

=item $spawn->wait()

=item $spawn->wait($con)

Wait for all clients to disconnect.

=back

=head1 SOURCE

The source code repository for IPC::Manager can be found at
L<https://github.com/exodist/IPC-Manager>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
