use strict;
use Test::More;
use Test::TCP 2.01;
use Linux::Socket::Accept4;
use IO::Socket::INET;
use IO::Select;

my $statm_path = '/proc/self/statm';
if ($^O eq 'freebsd') {
    substr($statm_path, 0, 0, '/compat/linux');
    plan skip_all => "linproc has to be mounted in /compat/linux/proc" unless -e $statm_path;
}

test_tcp(
    client => sub {
        my ($port, $server_pid) = @_;
        my @mem_size;
        for (1..30) {
            my $client = IO::Socket::INET->new(
                Timeout => 5,
                PeerPort => $port,
                PeerAddr => '127.0.0.1',
            );
            ok($client);
            my $buf;
            eval {
                alarm(5);
                $client->syswrite('foo');
                $client->sysread($buf,1024);
            };
            diag $@ if $@;
            alarm(0);
            push @mem_size, $buf;
        }
        is $mem_size[10], $mem_size[-1];
    },
    server => sub {
        my $port = shift;
        my $server = IO::Socket::INET->new(
            Listen    => SOMAXCONN,
            LocalPort => $port,
            LocalAddr => '127.0.0.1',
            Proto     => 'tcp',
            ReuseAddr => 1,
        );
        while ( my $peer = accept4(my $conn, $server, SOCK_CLOEXEC|SOCK_NONBLOCK) ) {
            my $select = IO::Select->new($conn);
            $select->can_read(5);
            my $len = $conn->sysread(my $buf, 1024);
            next if defined $len && $len == 0;  #disconnect
            my $size;
            open(my $fh, '<', $statm_path) or die $!;
            (undef,$size) = split /\s/, scalar <$fh>;
            close $fh;
            $size = $size * 4;
            $select->can_write(5);
            $conn->syswrite($size);
        }
    },
);


done_testing;

