package Linux::Event::HTTP::_UpgradedStream;
use v5.36;
use parent 'Linux::Event::HTTP::_Transport';

# The socket, TLS state and ordered write queue survive transition_to().
# The successor is the only protocol input owner after HTTP1 Upgrade.
sub on_data ($self, $bytes) {
    my $successor = $self->{http_successor} or return;
    my $ok = eval { $successor->input($bytes); 1 };
    unless ($ok) {
        $successor->transport_error("$@");
        $self->close unless $self->is_closed;
    }
    return;
}

sub on_eof ($self) {
    my $successor = $self->{http_successor};
    $successor->input_eof
        if $successor && (!$successor->can('want_read') || $successor->want_read);
    return;
}

sub on_drain ($self) {
    $self->{http_output_blocked} = 0;
    my $successor = $self->{http_successor};
    $successor->resume_output if $successor;
    return;
}

sub on_error ($self, $error) {
    my $successor = $self->{http_successor};
    $successor->transport_error("$error") if $successor;
    return;
}

sub on_close ($self) {
    my $successor = delete $self->{http_successor};
    $successor->transport_error('Upgraded transport closed')
        if $successor && (!$successor->can('is_closed') || !$successor->is_closed);
    if (my $server = $self->data->{server}) {
        $server->_closed($self);
    }
    return;
}

1;
