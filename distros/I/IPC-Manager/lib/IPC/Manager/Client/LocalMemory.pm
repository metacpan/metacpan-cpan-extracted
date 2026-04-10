package IPC::Manager::Client::LocalMemory;
use strict;
use warnings;

our $VERSION = '0.000015';

use Carp qw/croak/;

use parent 'IPC::Manager::Client';
use Object::HashBase;

use IPC::Manager::Message;

# Global in-memory store keyed by route.
# Each route contains:
#   clients => { id => { pid => $$, messages => [] } }  -- active clients
#   stats   => { id => { read => {}, sent => {} } }     -- persisted after disconnect
my %STORES;

sub _viable { 1 }

sub spawn {
    my $class  = shift;
    my %params = @_;

    my $route = "localmemory-" . ++$IPC::Manager::Client::LocalMemory::_COUNTER;

    $STORES{$route} = { clients => {}, stats => {} };

    return $route;
}

sub unspawn {
    my $class = shift;
    my ($route) = @_;
    delete $STORES{$route};
}

sub peer_exists_in_store {
    my $class = shift;
    my ($route) = @_;
    return exists $STORES{$route} ? 1 : 0;
}

sub _store {
    my $self = shift;
    return $STORES{$self->{route}} // croak "Route '$self->{route}' does not exist";
}

sub _client_data {
    my $self = shift;
    my $store = $self->_store;
    return $store->{clients}{$self->{id}} // croak "Client '$self->{id}' not registered";
}

sub init {
    my $self = shift;

    $self->SUPER::init();

    my $store = $self->_store;
    my $id    = $self->{id};

    if ($self->{reconnect}) {
        unless ($store->{clients}{$id}) {
            $self->{disconnected} = 1;
            croak "Client '$id' does not exist";
        }
        my $data = $store->{clients}{$id};
        if ($data->{pid} && $data->{pid} != $$ && kill(0, $data->{pid})) {
            $self->{disconnected} = 1;
            croak "Connection already running in pid $data->{pid}";
        }
    }
    else {
        if ($store->{clients}{$id}) {
            $self->{disconnected} = 1;
            croak "Client '$id' already exists";
        }
        $store->{clients}{$id} = {
            pid      => $$,
            messages => [],
        };
    }

    $store->{clients}{$id}{pid} = $$;
}

sub pending_messages { 0 }

sub ready_messages {
    my $self = shift;
    my $data;
    unless (eval { $data = $self->_client_data; 1 }) { warn $@; return 0 }
    return @{$data->{messages}} ? 1 : 0;
}

sub get_messages {
    my $self = shift;
    $self->pid_check;
    my $data = $self->_client_data;
    my @raw  = splice @{$data->{messages}};
    my @out;
    for my $msg (@raw) {
        $self->{stats}{read}{$msg->{from}}++;
        push @out, $msg;
    }
    return sort { $a->stamp <=> $b->stamp } @out;
}

sub send_message {
    my $self = shift;
    my $msg  = $self->build_message(@_);
    $self->pid_check;

    my $peer_id = $msg->to or croak "Message has no peer";
    my $store   = $self->_store;

    croak "Client '$peer_id' does not exist"
        unless $store->{clients}{$peer_id};

    push @{$store->{clients}{$peer_id}{messages}}, $msg;
    $self->{stats}{sent}{$peer_id}++;
}

sub peers {
    my $self  = shift;
    my $store = $self->_store;
    return sort grep { $_ ne $self->{id} } keys %{$store->{clients}};
}

sub peer_exists {
    my $self = shift;
    my ($peer_id) = @_;
    croak "'peer_id' is required" unless $peer_id;
    my $store = $self->_store;
    return $store->{clients}{$peer_id} ? 1 : undef;
}

sub peer_pid {
    my $self = shift;
    my ($peer_id) = @_;
    my $store = $self->_store;
    my $data  = $store->{clients}{$peer_id} or return undef;
    return $data->{pid};
}

sub write_stats {
    my $self  = shift;
    my $store;
    unless (eval { $store = $self->_store; 1 }) { warn $@; return }
    $store->{stats}{$self->{id}} = $self->{stats};
}

sub read_stats {
    my $self  = shift;
    my $store = $self->_store;
    return $store->{stats}{$self->{id}} // {read => {}, sent => {}};
}

sub all_stats {
    my $self  = shift;
    my $store = $self->_store;
    my %out;
    for my $id (keys %{$store->{stats}}) {
        $out{$id} = $store->{stats}{$id};
    }
    return \%out;
}

sub post_disconnect_hook {
    my $self  = shift;
    my $store;
    unless (eval { $store = $self->_store; 1 }) { warn $@; return }
    delete $store->{clients}{$self->{id}};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Manager::Client::LocalMemory - Process-local in-memory message store for testing only

=head1 DESCRIPTION

B<This client is intended for testing only.> It stores all state in a
process-local Perl hash and B<does not work across multiple processes>.
Messages, peer information, and statistics exist only within the memory of
the process that created them.

Use this protocol when you need a lightweight client for unit tests that
exercise the L<IPC::Manager::Client> interface without touching the
filesystem or requiring external IPC resources.

=head1 SYNOPSIS

    use IPC::Manager::Client::LocalMemory;
    use IPC::Manager::Serializer::JSON;

    my $route = IPC::Manager::Client::LocalMemory->spawn();
    my $con1  = IPC::Manager::Client::LocalMemory->connect('c1', 'IPC::Manager::Serializer::JSON', $route);
    my $con2  = IPC::Manager::Client::LocalMemory->connect('c2', 'IPC::Manager::Serializer::JSON', $route);

    $con1->send_message(c2 => {hello => 'world'});
    my @msgs = $con2->get_messages;

    $con1->disconnect;
    $con2->disconnect;
    IPC::Manager::Client::LocalMemory->unspawn($route);

=head1 LIMITATIONS

=over 4

=item *

B<Single-process only.> The backing store is a package-scoped Perl hash.
Forked children inherit a copy but do not share it with the parent or
siblings.  For cross-process IPC use L<IPC::Manager::Client::MessageFiles>,
L<IPC::Manager::Client::AtomicPipe>, L<IPC::Manager::Client::JSONFile>,
or L<IPC::Manager::Client::SharedMem>.

=item *

C<have_handles_for_select> and C<have_handles_for_peer_change> both return
false.  There are no file descriptors to poll.

=back

=head1 METHODS

See L<IPC::Manager::Client> for inherited methods.

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
