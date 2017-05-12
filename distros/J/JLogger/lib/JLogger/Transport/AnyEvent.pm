package JLogger::Transport::AnyEvent;

use strict;
use warnings;

use base 'JLogger::Transport';

use AnyEvent::XMPP::Component;

sub connect {
    my $self = shift;

    my $component = AnyEvent::XMPP::Component->new(
        domain => $self->domain,
        host   => $self->host,
        port   => $self->port,
        secret => $self->secret,
    );

    $self->{component} = $component;

    $component->reg_cb(
        error           => sub { $self->_error($_[1]) },
        recv_stanza_xml => sub {
            shift @_;
            $self->_recv_stanza_xml(@_);
        },
        disconnect => sub {
            delete $self->{component};
            $self->on_disconnect->($self);
        }
    );

    $component->connect;
}

sub disconnect {
    if (my $component = delete $_[0]->{component}) {
        $component->disconnect;
    }
}

sub _recv_stanza_xml {
    my ($self, $node, $stop) = @_;

    if ($node->eq('component' => 'route')) {
        $self->on_message->($self, $node);
        $$stop = 1;
    }
}

sub _error {
    my ($self, $error) = @_;

    warn $error->string, "\n";
}


1;
