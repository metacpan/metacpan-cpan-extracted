package Devel::REPL::Client::AnyEvent::Connection;

use strict;
use warnings;

use AnyEvent::Handle;
use Scalar::Util qw(weaken);
use Term::ReadKey;

use constant {
    EOT     => "\x04",
};

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        handle      => undef,
        input       => undef,
        on_close    => undef,
    }, $class;
    my $weak_self = $self;
    weaken($weak_self);
    my $handle = AnyEvent::Handle->new(
        fh          => $args{socket},
        on_error    => sub {
            my ($handle, $fatal, $message) = @_;

            $weak_self->{handle} = $weak_self->{watch} = undef;
            $handle->destroy;
            $weak_self->{on_close}->($weak_self)
                if $weak_self->{on_close};
        },
        on_read     => sub {
            my ($handle) = @_;

            syswrite *STDOUT, $handle->{rbuf};
            substr $handle->{rbuf}, 0, length($handle->{rbuf}), '';
        },
        on_eof      => sub {
            my ($handle) = @_;

            $weak_self->{handle} = $weak_self->{watch} = undef;
            $handle->destroy;
            $weak_self->{on_close}->($weak_self)
                if $weak_self->{on_close};
        },
    );
    my $watch = AnyEvent->io(
        fh      => \*STDIN,
        poll    => 'r',
        cb      => sub {
            while (defined(my $key = ReadKey -1, \*STDIN)) {
                $handle->push_write($key);
                if ($key eq EOT) {
                    print STDOUT "^D\n";
                    $handle->push_shutdown;
                }
            }
        },
    );

    $self->{handle} = $handle;
    $self->{watch} = $watch;

    return $self;
}

sub DESTROY {
    my ($self) = @_;

    $self->close;
}

sub on_close { $_[0]->{on_close} = $_[1] }

sub close {
    my ($self) = @_;

    $self->{handle}->destroy if $self->{handle} && !$self->{handle}->destroyed;
}

1;
