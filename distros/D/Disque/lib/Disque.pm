package Disque;

# ABSTRACT: Perl binding for Disque message broker
# VERSION
# AUTHORITY

our $VERSION = '0.04';

use strict;
use warnings;

use IO::Socket::INET;
use IO::Socket::UNIX;
use List::Util qw(shuffle);
use Carp qw( croak confess );
#use Data::Dump qw(dump);

use Redis;

use constant DEBUG => $ENV{DISQUE_DEBUG};
use constant BUFSIZE => 4096;

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;
    my $default = '127.0.0.1:7711';
    my $servers = $args{servers} || [$default];
    my $len = scalar @{$servers};
    my @my_servers = '';
    my $hello = '';
    my $n = 1;

    $self->{sock_timeout} = $args{sock_timeout} || 0;
    $self->{conn_timeout} = $args{conn_timeout} || 0;
    $self->{read_timeout} = $args{read_timeout} || 0;
    $self->{write_timeout} = $args{write_timeout} || 0;
    $self->{debug} = $args{debug} || $ENV{DISQUE_DEBUG};
    $self->{unixsock} = $args{unixsock} || undef;
    $self->{num_servers} = $len;
    $self->{disable_random_connect} = $args{disable_random_connect} || 0;
    if ($self->{disable_random_connect}) { @my_servers = @{$servers};} 
    else { @my_servers = shuffle(@{$servers}); }

    $self->{arr_servers} = \@my_servers;

    foreach my $server (@my_servers) {
        $self->{server} = $server || $default;

        if (exists $args{unixsock}) {
            $self->{conn} = sub {
                my ($self) = @_;
                $self->{sock} = IO::Socket::UNIX->new(
                    Type => SOCK_STREAM,
                    Peer => $self->{unixsock},
                    Timeout  => $self->{sock_timeout},
                );
            };
        } else {
            $self->{conn} = sub {
                my ($self) = @_;
                $self->{sock} = IO::Socket::INET->new(
                    PeerAddr => $self->{server},
                    Timeout  => $self->{sock_timeout},
                    Proto    => 'tcp',
                );
            };
        }

        $self->__init;
        last if $self->{sock};

        if ($n == $len) {
            croak "there isn't any Disque instance available to connect";
        }
        $n++;
    }

    return $self;
}

sub __sock_end {
    my ($self) = @_;
    
    if (not defined($self->{sock})) {
        croak "the socket we are trying to close is not set";
    }

    return close(delete $self->{sock});
}

sub __init {
    my ($self) = @_;

    delete $self->{sock};
    $self->{pid} = $$;

    $self->__sock_connect;

    if (defined $self->{unixsock}) {
        $self->{disque} = Redis->new(
            server => $self->{server},
            debug => $self->{debug},
            sock => $self->{unixsock},
        ) if $self->{sock};
    } else {
        $self->{disque} = Redis->new(
            server => $self->{server},
            debug => $self->{debug},
            read_timeout => $self->{read_timeout},
            write_timeout => $self->{write_timeout},
            cnx_timeout => $self->{sock_timeout},
        ) if $self->{sock};
    }

    $self->__hello if $self->{sock};

    return $self;
}

# The current connection has failed 
# and we must reconnect to another Disque instance
sub __disque_reconnect {
    my $self = shift;
    my $errn = shift;
    my $from = shift;
    my $flag = 0;

    if ($errn =~ m/Not connected to any server/) { $flag = 1; } 
    elsif ($errn =~ m/Error while reading from Redis/) { $flag = 1; }

    if ($flag == 0) {
        croak $errn;
    } else {
        warn "lost connection from $self->{server} $!\n";
    }

    if ($self->{num_servers} <= 1) {
        croak "there isn't any Disque instance available to connect";        
    }

    shift @{$self->{arr_servers}};
    $self->{num_servers}--; # Decrease available servers
    $self->{server} = @{$self->{arr_servers}}[0];
    $self->__init;
    $self->$from(@_);
}

sub __hello {
    my $self = shift;
    $self->__sock_connect unless exists $self->{sock};
    $self->{hello} = $self->{disque}->__std_cmd('HELLO');
}

sub qlen {
    my $self = shift;
    my $resp = eval {$self->{disque}->__std_cmd('QLEN', @_)};
    $self->__disque_reconnect($@, 'qlen', @_) if $@;
    return $resp;
}

sub qpeek {
    my $self = shift;
    my $resp = eval {$self->{disque}->__std_cmd('QPEEK', @_)};
    $self->__disque_reconnect($@, 'qpeek', @_) if $@;
    return $resp;
}

sub enqueue {
    my $self = shift;
    my $resp = eval {$self->{disque}->__std_cmd('ENQUEUE', @_)};
    $self->__disque_reconnect($@, 'enqueue', @_) if $@;
    return $resp;
}

sub dequeue {
    my $self = shift;
    my $resp = eval {$self->{disque}->__std_cmd('DEQUEUE', @_)};
    $self->__disque_reconnect($@, 'dequeue', @_) if $@;
    return $resp;
}

sub qscan {
    my $self = shift;
    my $resp = eval {$self->{disque}->__std_cmd('QSCAN', @_)};
    $self->__disque_reconnect($@, 'qscan', @_) if $@;
    return $resp;
}

sub qstat {
    my $self = shift;
    my $resp = eval {$self->{disque}->__std_cmd('QSTAT', @_)};
    $self->__disque_reconnect($@, 'qstat', @_) if $@;
    return $resp;
}

sub jscan {
    my $self = shift;
    my $resp = eval {$self->{disque}->__std_cmd('JSCAN', @_)};
    $self->__disque_reconnect($@, 'jscan', @_) if $@;
    return $resp;
}

sub show {
    my $self = shift;
    my @resp = eval {$self->{disque}->__std_cmd('SHOW', @_)};
    $self->__disque_reconnect($@, 'show', @_) if $@;
    return @resp;
}

sub del_job {
    my $self = shift;
    my $resp = eval {$self->{disque}->__std_cmd('DELJOB', @_)};
    $self->__disque_reconnect($@, 'del_job', @_) if $@;
    return $resp;
}

sub add_job {
    my $self = shift;
    my $resp = eval {$self->{disque}->__std_cmd('ADDJOB', @_)};
    $self->__disque_reconnect($@, 'add_job', @_) if $@;
    return $resp;
}

sub get_job {
    my $self = shift;
    my @resp = eval {$self->{disque}->__std_cmd('GETJOB', 'FROM', @_)};
    $self->__disque_reconnect($@, 'get_job', @_) if $@;
    return @resp;
}

sub ack_job {
    my $self = shift;
    my $resp = eval {$self->{disque}->__std_cmd('ACKJOB', @_)};
    $self->__disque_reconnect($@, 'ack_job', @_) if $@;
    return $resp;
}

sub fast_ack {
    my $self = shift;
    my $resp = eval {$self->{disque}->__std_cmd('FASTACK', @_)};
    $self->__disque_reconnect($@, 'fast_ack', @_) if $@;
    return $resp;
}

sub __sock_connect {
    my ($self) = @_;
    $self->{conn}->($self) || warn "unable to connect to disque server at $self->{server}: $!\n";
}

sub __end_command {
    my ($self, $cmd) = @_;
    $self->__sock_connect unless exists $self->{sock};
    $self->__run_command($cmd);
    $self->__sock_end();
    $self->{disque}->__close_sock();
    return;
}

sub shutdown {
    my $self = shift;
    $self->__end_command('SHUTDOWN');
}

sub quit {
    my $self = shift;
    $self->__end_command('QUIT');
}

sub info {
    my $self = shift;

    $self->__sock_connect unless exists $self->{sock};

    my $cb = @_ && ref $_[-1] eq 'CODE' ? pop : undef;
    my $info = $self->{disque}->__run_cmd('INFO', 0, $cb, @_) 
        unless $self->{disque}->{reconnect};
    
    return $info;
}

sub ping {
    my $self = shift;
    $self->__sock_connect unless exists $self->{sock};
    $self->{disque}->__std_cmd('PING');
}

sub __run_command {
    my ($self, $command, $handle_recv, @args) = @_;
    $self->__send_command($command, @args);
    return $self->__recv_response($self->{sock}) unless !defined $handle_recv;
}

sub __send_command {
    my $self = shift;
    my $command = shift;

    if ($self->{pid} != $$) {
        warn "process id is different from main";
    }

    warn "[SEND CMD] $command\n" if DEBUG;

    my @command = split /_/, $command;
    my $n_elems = scalar(@_) + scalar(@command);
    my $buffer  = "\*$n_elems\r\n";

    for my $bin (@command, @_) {
        $buffer .= defined($bin) ? '$' . length($bin) . "\r\n$bin\r\n" : "\$-1\r\n";
    }

    while ($buffer) {
        my $len = syswrite $self->{sock}, $buffer, length $buffer;
        substr $buffer, 0, $len, "";
    }

    return;
}

sub __recv_response {
    my ($self, $sock) = @_;
    my $data = '';

    my $len = sysread($sock, $data, BUFSIZE, length($data));
    my $recv = substr($data, 0, $len, '');
    chomp($recv);
    warn "[RECV RAW] $recv\n" if DEBUG;
    return $recv;
}

1;

__END__

=encoding utf-8

=for stopwords

=head1 NAME

Disque - Perl client for Disque, an in-memory, distributed job queue

=head1 CONNECTION

    ## Connection:
    ## perl-disque will try to connect to any available server in the order
    ## is have been set, if there is any disque instance available,
    ## the client will generate a connection error and will abort.
    ## if you not spicify any server in conection `new()`
    ## by default will only connect to '127.0.0.1:7711'.

    use Disque;

    # Defaults disque connects to 127.0.0.1:7711
    my $disque = Disque->new;
    my $disque = Disque->new(servers => '127.0.0.1:7711');

    # Disque connects to multiple instances by default behaviour
    my $disque = Disque->new(servers => ["localhost:7711", "localhost:7712"]);

    # Use UNIX domain socket
    my $disque = Disque->new(unixsock => '/tmp/disque.sock');

    # Enable connection timeout (in seconds)
    my $disque = Disque->new(sock_timeout => 10);

    # Enable read timeout (in seconds)
    my $disque = Disque->new(read_timeout => 0.5);

    # Enable write timeout (in seconds)
    my $disque = Disque->new(write_timeout => 1.2);


=head1 ClUSTER

    #You can use this library with single or multi-node clusters.

    ## Connection:

    # When you invoke "new()" you can choose in which method you will connect to the cluster,
    # of course, this only will happen if ther is more than 1 node spicified.

    # By default, as Salvatore [specified](https://github.com/antirez/disque#client-libraries)
    # in the doc, the lib will try to connect to any available server in a randomly way.

    # But also if you won't to connect to the server randomly you can specify
    # the param "disable_random_connect => 1" in new() sub, for example:

    my $disque = Disque->new(
        servers => ['localhost:7711', 'localhost:7712', 'localhost:7713'],
        disable_random_connect => 1
    );

    # So you will connect into the cluster in the order that you have set the nodes.


=head1 STATUS

The commands that are allready available are:
add_job get_job ack_job fast_ack qlen qpeek enqueue dequeue del_job show


=head1 DESCRIPTION

Disque is a client to Disque client library.
This module must works on top of Redis lib, and uses
some of the internal subs in Redis lib.

=head1 REPOSITORY

L<https://github.com/lovelle/perl-disque>
