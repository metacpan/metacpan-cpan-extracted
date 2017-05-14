package Mesos::Test::Channel;
use strict;
use warnings;
use parent 'Tie::Handle';
use IO::Handle;
use Symbol;

sub new {
    my ($class) = @_;
    my $sym = gensym;
    tie *$sym, $class;
    return bless \*$sym, $class;
}

sub TIEHANDLE {
    my ($class) = @_;
    my ($read, $write);
    pipe($read, $write);
    $_->blocking(0), $_->autoflush(1) for $read, $write;
    my $self = {
        in  => $read,
        out => $write,
    };
    return bless $self, $class;
}

sub in  { shift->{in} }
sub out { shift->{out} }

sub FILENO {
    my ($self) = @_;
    return fileno $self->in;
}

sub READLINE {
    return shift->in->getline;
}

sub PRINT {
    my ($self, @args) = @_;
    return $self->print(@args);
}

sub queue {
    return shift->{queue} ||= [];
}


sub recv {
    my ($self, $event, @args) = @_;
    push @{$self->queue}, [$event, @args];
    $self->out->print("$event\n");
}

sub send {
    my ($self) = @_;
    $self->in->getline or return;
    my $sent = shift @{$self->queue} or return;
    return @$sent;
}


1;
