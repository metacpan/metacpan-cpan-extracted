use strict;
use warnings;
use Test::More;
use Test::Exception;
use LWP::UserAgent::Tor;
use Net::EmptyPort qw(empty_port check_port);
use File::Which qw(which);

if (which 'tor') {
    plan tests => 10;
}
else {
    plan skip_all => 'need tor available for testing';
}

SKIP: { # default values
    skip 'One or both ports used: 9050, 9051', 4 if check_port(9050) || check_port(9051);

    my $ua = LWP::UserAgent::Tor->new;

    isa_ok $ua, 'LWP::UserAgent::Tor', 'created object (default args)';

    isa_ok $ua->{_tor_proc}, 'Proc::Background', 'started tor proc (default args)';

    isa_ok $ua->{_tor_socket}, 'IO::Socket::INET', 'connected to tor (default args)';

    # 5 tries
    my $suc = 0;
    for (0 .. 4) {
        $suc = $ua->rotate_ip;
        last if $suc;
    }

    ok $suc, 'Changed ip (default args)';
}

{
    my $empty_port_1 = empty_port();
    my $empty_port_2 = empty_port($empty_port_1 + 1);

    my $ua = LWP::UserAgent::Tor->new(
        tor_control_port => $empty_port_1,
        tor_port         => $empty_port_2,
        tor_cfg          => 't/torrc',
    );

    isa_ok $ua, 'LWP::UserAgent::Tor', 'created object';

    isa_ok $ua->{_tor_proc}, 'Proc::Background', 'started tor proc (default args)';

    isa_ok $ua->{_tor_socket}, 'IO::Socket::INET', 'connected to tor';

    # 5 tries
    my $suc = 0;
    for (1 .. 4) {
        $suc = $ua->rotate_ip;
        last if $suc;
    }

    ok $suc, 'changed ip';
}

# exceptions
throws_ok {
    LWP::UserAgent::Tor->new(
        tor_control_port => -1,
        tor_port         => 0,
    );
} qr/error running tor/, 'die if socket cannot connect to tor';

throws_ok {
    LWP::UserAgent::Tor->new(
        tor_control_port => 9051,
        tor_port         => 9050,
        tor_cfg          => 'not_existing',
    );
} qr/tor config file does not exist/, "die if tor cfg doesn't exist";
