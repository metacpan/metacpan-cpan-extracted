use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use Socket qw(getaddrinfo getnameinfo NI_NUMERICHOST SOCK_STREAM);

use EV;
use EV::Redis;

$SIG{PIPE} = 'IGNORE';

# an IPv4-only listener, like a redis-server on 127.0.0.1
my $listener = IO::Socket::INET->new(
    Listen => 5, LocalAddr => '127.0.0.1', LocalPort => 0,
);
plan skip_all => "cannot listen on 127.0.0.1: $!" unless $listener;
my $port = $listener->sockport;
my @held;
my $accept = EV::io $listener, EV::READ, sub { push @held, scalar $listener->accept };

# the preference falls back when the name has no address of that family, so
# localhost must resolve to both for this test to say anything
my %localhost;
{
    my ($err, @res) = getaddrinfo('localhost', 0, { socktype => SOCK_STREAM });
    if ($err) {
        plan skip_all => "cannot resolve localhost: $err";
    }
    for my $r (@res) {
        my ($nerr, $host) = getnameinfo($r->{addr}, NI_NUMERICHOST);
        $localhost{$host} = 1 unless $nerr;
    }
}
plan skip_all => 'localhost has no 127.0.0.1 here' unless $localhost{'127.0.0.1'};
plan skip_all => 'localhost has no ::1 here' unless $localhost{'::1'};

sub attempt {
    my (%opt) = @_;
    my ($up, $err);
    my $r = EV::Redis->new(%opt,
        on_connect => sub { $up = 1; EV::break },
        on_error   => sub { $err = $_[0]; EV::break });
    $r->connect('localhost', $port);
    my $guard = EV::timer 5, 0, sub { EV::break };
    EV::run;
    $r->disconnect if $r->is_connected;
    return $up ? 'connected' : 'failed';
}

is attempt(), 'connected', 'the default reaches the IPv4 listener';
is attempt(prefer_ipv4 => 1), 'connected', 'prefer_ipv4 reaches the IPv4 listener';
is attempt(prefer_ipv6 => 1), 'failed', 'prefer_ipv6 skips the IPv4-only listener';

done_testing;
