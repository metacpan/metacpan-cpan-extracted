#line 1
package Test::TCP;
use strict;
use warnings;
use 5.00800;
our $VERSION = '0.08';
use base qw/Exporter/;
use IO::Socket::INET;
use Test::SharedFork;
use Test::More ();
use Config;
use POSIX;

our @EXPORT = qw/ empty_port test_tcp wait_port /;

sub empty_port {
    my $port = shift || 10000;
    $port = 19000 unless $port =~ /^[0-9]+$/ && $port < 19000;

    while ( $port++ < 20000 ) {
        my $sock = IO::Socket::INET->new(
            Listen    => 5,
            LocalAddr => '127.0.0.1',
            LocalPort => $port,
            Proto     => 'tcp',
            ReuseAddr => 1,
        );
        return $port if $sock;
    }
    die "empty port not found";
}

sub test_tcp {
    my %args = @_;
    for my $k (qw/client server/) {
        die "missing madatory parameter $k" unless exists $args{$k};
    }
    my $port = $args{port} || empty_port();

    if ( my $pid = Test::SharedFork->fork() ) {
        # parent.
        wait_port($port);

        $args{client}->($port, $pid);

        kill TERM => $pid;
        waitpid( $pid, 0 );
        if (WIFSIGNALED($?) && (split(' ', $Config{sig_name}))[WTERMSIG($?)] eq 'ABRT') {
            Test::More::diag("your server received SIGABRT");
        }
    }
    elsif ( $pid == 0 ) {
        # child
        $args{server}->($port);
    }
    else {
        die "fork failed: $!";
    }
}

sub _check_port {
    my ($port) = @_;

    my $remote = IO::Socket::INET->new(
        Proto    => 'tcp',
        PeerAddr => '127.0.0.1',
        PeerPort => $port,
    );
    if ($remote) {
        close $remote;
        return 1;
    }
    else {
        return 0;
    }
}

sub wait_port {
    my $port = shift;

    my $retry = 10;
    while ( $retry-- ) {
        return if _check_port($port);
        sleep 1;
    }
    die "cannot open port: $port";
}

1;
__END__

=encoding utf8

#line 175
