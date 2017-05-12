package Marathon::Events;

use AnyEvent::Handle;
use IO::All '-tie';

sub new {
    my ( $class, $parent ) = @_;
    return bless { callbacks => [], parent => $parent };
}

sub register {
    my ($self, $callback) = @_;
    push @{$self->callbacks}, $callback;
}

sub callbacks {
    my ($self) = @_;
    return wantarray ? @{$self->{callbacks}} : $self->{callbacks};
}

sub start {
    my $self = shift;
    my $cv = AnyEvent->condvar;
    $self->{parent}->{_url} =~ m,https?\://([^/]+),;
    my $addr = $1;

    my $io = io($addr);
    $io->print("GET /v2/events HTTP/1.1\nAccept: text/event-stream\nHost: $addr\n\n");
    while (<$io>) {
        last if /^\s*$/;
    }
    my $watcher = AE::io $io->io_handle, 0, sub {
        my $text = <$io>;
        foreach ( $self->callbacks ) {
            $_->($text);
        }
    };
    print STDERR "yield\n";
    return $io;
}

1;
