package Devel::REPL::Client::Select;

use strict;
use warnings;

use IO::Select;
use IO::Socket;
use Term::ReadKey;

use constant {
    EOT     => "\x04",
};

my $RESTORE_READMODE;

END {
    ReadMode 0, \*STDIN if $RESTORE_READMODE;
}

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        port    => $args{port},
        path    => $args{path},
        mode    => $args{mode},
        socket  => undef,
    }, $class;

    return $self;
}

sub listen {
    my ($self) = @_;

    if ($self->{port}) {
        $self->{socket} = IO::Socket::INET->new(
            Listen    => 1,
            LocalAddr => '127.0.0.1',
            LocalPort => $self->{port},
            Proto     => 'tcp',
            ReuseAddr => 1,
        );
    } elsif ($self->{path}) {
        if (-S $self->{path}) {
            unlink $self->{path} or die "Unable to unlink stale socket: $!";
        }

        $self->{socket} = IO::Socket::UNIX->new(
            Local     => $self->{path},
        );
        if ($self->{socket} && defined $self->{mode}) {
            chmod $self->{mode}, $self->{path}
                or $self->{socket} = undef;
        }
        if ($self->{socket}) {
            $self->{socket}->listen(1)
                or $self->{socket} = undef;
        }
    }

    die "Unable to start listening: $!" unless $self->{socket};
}

sub accept_and_process {
    my ($self) = @_;
    my $client = $self->{socket}->accept;

    $RESTORE_READMODE = 1;
    ReadMode 3, \*STDIN;

    my $fds = IO::Select->new;

    $fds->add($client, \*STDIN);
    $client->blocking(0);

    for (;;) {
        my ($rd, undef, $err) = IO::Select->select($fds, undef, $fds, 10);

        if ($err && @$err) {
            die "One of the handles became invalid";
        }

        for my $hnd (@$rd) {
            if ($hnd == $client) {
                _from_to($client, \*STDOUT);
            }
            if ($hnd == \*STDIN) {
                while (defined(my $key = ReadKey -1, \*STDIN)) {
                    my $ok = do {
                        local $SIG{PIPE} = 'IGNORE';
                        syswrite $client, $key;
                    };
                    die "Error during write: $!" if !defined $ok;
                    if ($key eq EOT) {
                        syswrite *STDOUT, "^D\n";
                        return;
                    }
                }
            }
        }
    }
}

sub _from_to {
    my ($from, $to) = @_;
    my $buff;

    my $count = sysread $from, $buff, 1000;
    die "Error during read: $!" if !defined $count;
    my $written = syswrite $to, $buff, $count;
    die "Error during write: $!" if !defined $written || $written != $count;
}

sub close {
    my ($self) = @_;

    $self->{socket}->close if $self->{socket};
}

1;
