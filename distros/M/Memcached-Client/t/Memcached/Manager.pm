package t::Memcached::Manager;

use strict;
use warnings;
use IO::Socket::INET qw{};
use Memcached::Client::Log qw{DEBUG LOG};
use POSIX qw{:sys_wait_h};
use Test::More;

sub new {
    my ($class, @args) = @_;
    my %args = 1 == scalar @args ? %{$args[0]} : @args;
    my $self = bless {}, $class;
    $self->{memcached} = $args{memcached};
    chomp $self->{memcached};
    note "Using memcached $self->{memcached}";
    map {$self->{servers}->{(ref $_ ? $_->[0] : $_)} = {}} @{$args{servers}};
    # Remove any old logs so they don't confuse things
    unlink for (glob "t/memcached-*.log");
    map {$self->start ($_)} keys %{$self->{servers}};
    $self;
}

sub start {
    my ($self, $server) = @_;

    my ($host, $port) = split /:/, $server;

    $self->log ("Checking port %s for existing process", $port) if DEBUG;
    if (my $remote = IO::Socket::INET->new (Proto => 'tcp', PeerAddr => $host, PeerPort => $port)) {
        close $remote;
        $self->log ("Already server on %s:%s", $host, $port) if DEBUG;
        exit;
    }

    $self->log ("Using port %s", $port) if DEBUG;

    my $pid = fork;

    # Fork a new process
    if ($pid) {
        $self->{servers}->{$server} = $pid;
        $self->log ("Fork successful, pid %s", $self->{servers}->{$server}) if DEBUG;
        $self->wait ($host, $port);
        sleep 0.1;
    } elsif (defined $pid) {
        open STDIN, '/dev/null' or die ("Couldn't redirect STDIN");
        open STDOUT, ">>t/memcached-$port.log" or die ("Couldn't redirect STDOUT");
        open STDERR, '>&STDOUT' or die ("Couldn't redirect STDERR");

        exec $self->{memcached}, "-l", $host, "-p", $port, "-vv";

        die "Failed to exec: $!";
    } else {
        die "Couldn't fork: $!\n"
    }
}

sub wait {
    my ($self, $host, $port) = @_;

    my $retry = 100;

    while ($retry--) {
        $self->log ("Checking %s:%s", $host, $port) if DEBUG;
        if (my $remote = IO::Socket::INET->new (Proto => 'tcp', PeerAddr => $host, PeerPort => $port)) {
            close $remote;
            $self->log ("Connected to %s:%s", $host, $port) if DEBUG;
            return 1;
        }
        else {
            return 0;
        }
        sleep(0.1);
    }

    die "Can't connect to server on $host:$port";
}

sub stop {
    my ($self, $id) = @_;

    my $pid = delete $self->{servers}->{$id} or die "No server $id";
    $self->log ("Pid is %s", $pid) if DEBUG;

    my $result = 0;

    # Confine what waitpid does to this var to this routine
    local $?;

    for my $sig (qw{TERM HUP QUIT INT KILL}) {
        $self->log ("Trying %s", $sig) if DEBUG;
        kill ($sig, $pid);
        my $wp = waitpid ($pid, 0);
        $self->log ("Waitpid returned %s", $wp) if DEBUG;
        if ($wp == $pid or $wp == -1) {
            $result = 1;
            last;
        }
        sleep 1;
    }

    return $result;
}

sub version {
    my ($self) = @_;
    unless ($self->{version}) {
        my $output = qx{$self->{memcached} -i};
        if ($output =~ m/^memcached\s+([0123456789.]+)\s$/m) {
            $self->{version} = $1;
        }
    }
    return $self->{version};
}

sub vstring {
    my ($self) = @_;
    my $version = $self->version;
    $version =~ s/[^0-9.]//g;
    return join "", map {sprintf "%03d", $_} split /\./, $version;
}

sub DESTROY {
    my ($self) = @_;
    for my $server (keys %{$self->{servers}}) {
        $self->log ("Stopping $server\n") if DEBUG;
        $self->stop ($server);
    };
}

=method log

=cut

sub log {
    my ($self, $format, @args) = @_;
    LOG ("Manager> " . $format, @args);
}

1;

