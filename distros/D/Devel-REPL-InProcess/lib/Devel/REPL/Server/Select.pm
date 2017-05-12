package Devel::REPL::Server::Select;

use strict;
use warnings;

use Devel::REPL::Script;
use IO::Pty;
use IO::Select;
use IO::Socket;
use Term::ReadLine;
use Scalar::Util;

my $TERM;

sub run_repl {
    my ($class, %args) = @_;
    my $repl = $class->new(%args);

    $repl->create;

    @_ = ($repl);
    goto &{$repl->can('run')};
}

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        port        => $args{port},
        path        => $args{path},
        skip_levels => $args{skip_levels} // 0,
        profile     => $args{profile},
        rcfile      => $args{rcfile},
        socket      => undef,
        pty         => undef,
        repl        => undef,
        repl_script => undef,
    }, $class;

    return $self;
}

sub create {
    my ($self) = @_;

    $self->{pty} = IO::Pty->new;
    $self->{fds} = IO::Select->new;

    if ($self->{port}) {
        $self->{socket} = IO::Socket::INET->new(
            PeerAddr => '127.0.0.1',
            PeerPort => $self->{port},
            Blocking => 0,
        );
    } elsif ($self->{path}) {
        $self->{socket} = IO::Socket::UNIX->new(
            Peer      => $self->{path},
        );
    }

    die "Error during connect: $!" unless $self->{socket};

    $self->{fds}->add($self->{pty}, $self->{socket});

    my $term = $TERM ||= Term::ReadLine->new;
    my $weak_self = $self;

    Scalar::Util::weaken($weak_self);

    $term->newTTY($self->{pty}->slave, $self->{pty}->slave);
    $term->event_loop(sub { $weak_self->_shuttle_data });

    $self->{repl} = Devel::REPL->new(term => $term);
    $self->{repl_script} = Devel::REPL::Script->new(
        _repl   => $self->{repl},
        !$self->{profile} ? () : (
            profile     => $self->{profile},
        ),
        !$self->{rcfile} ? () : (
            rcfile      => $self->{rcfile},
        ),
    );
    $self->{repl}->load_plugin('InProcess');
    $self->{repl}->skip_levels($self->{skip_levels});
}

sub run {
    my ($self) = @_;

    $self->{repl}->run;
}

sub _shuttle_data {
    my ($self) = @_;

    eval {
        for (;;) {
            my ($rd, undef, $err) = IO::Select->select($self->{fds}, undef, $self->{fds}, 10);

            if ($err && @$err) {
                die "One of the handles became invalid";
            }

            my $got_input;
            for my $hnd (@$rd) {
                if ($hnd == $self->{socket}) {
                    # using anything > 1 here breaks (for example) control
                    # char sequences, because STDIN is buffered, and I have
                    # not found a way of either looking at the buffer or
                    # making it unbuffered
                    my $read = _from_to($self->{socket}, $self->{pty}, 1);
                    if ($read == 0) {
                        $self->{pty}->close_slave;
                        $self->{pty}->close;
                    }
                    $got_input = 1;
                }
                if ($hnd == $self->{pty}) {
                    _from_to($self->{pty}, $self->{socket}, 1000);
                }
            }
            last if $got_input;
        }

        1;
    } or do {
        warn "Error while waiting for input $@\n";
    };
}

sub _from_to {
    my ($from, $to, $max) = @_;
    my $buff;

    my $count = sysread $from, $buff, $max;
    die "Error during read: $!" if !defined $count;
    my $written = syswrite $to, $buff, $count;
    die "Error during write: $!" if !defined $written || $written != $count;
    return $count;
}

1;
