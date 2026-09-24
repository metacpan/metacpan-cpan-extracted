package Linux::Event::_Resolver;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.117';

use Hash::Util::FieldHash qw(fieldhash);
use Scalar::Util qw(weaken);

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

fieldhash my %FOR_LOOP;

sub for_loop ($class, $loop) {
    return $FOR_LOOP{$loop} //= $class->_new($loop);
}

sub _new ($class, $loop) {
    my $self = bless {
        loop     => $loop,
        native   => Linux::Event::_Resolver::_Native->new(2),
        requests => {},
    }, $class;
    weaken($self->{loop});
    my $ready = sub { $self->_ready };
    $self->{watcher} = $loop->watch(
        fd      => $self->{native}->event_fd,
        _internal => 1,
        read    => $ready,
        no_args => 1,
        lean    => 1,
    );
    return $self;
}

sub submit ($self, $recipient, $host, $port, $socktype = undef) {
    my $id = defined($socktype)
        ? $self->{native}->submit($host, "$port", $socktype)
        : $self->{native}->submit($host, "$port");
    $self->{requests}{$id} = $recipient;
    return $id;
}

sub cancel ($self, $id) {
    return defined($id) ? !!delete($self->{requests}{$id}) : 0;
}

sub _fork_prepare_loop ($class, $loop) {
    my $self = $FOR_LOOP{$loop};
    return if !$self;
    die "fork(): Loop has active resolver requests\n"
        if keys %{ $self->{requests} };
    delete $FOR_LOOP{$loop};
    if (my $watcher = delete $self->{watcher}) {
        $watcher->cancel;
    }
    delete $self->{native};
    delete $self->{loop};
    return;
}

sub _objects_for_loop ($class, $loop) {
    my $self = $FOR_LOOP{$loop};
    return [] if !$self;
    return [ values %{ $self->{requests} } ];
}

sub _ready ($self) {
    for my $result (@{ $self->{native}->drain }) {
        my $recipient = delete $self->{requests}{ $result->{id} };
        next if !$recipient;
        $recipient->_resolver_completed($result);
    }
    return;
}

sub DESTROY ($self) {
    if (my $watcher = delete $self->{watcher}) {
        eval { $watcher->cancel; 1 };
    }
    delete $self->{requests};
    delete $self->{native};
    return;
}

sub CLONE_SKIP ($class) { 1 }

package Linux::Event::_Resolver::_Native;
sub CLONE_SKIP ($class) { 1 }

package Linux::Event::_Resolver;

1;
