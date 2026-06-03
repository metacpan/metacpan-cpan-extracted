# max_reconnect_attempts exhaustion. No gearmand needed: we point at a
# refused port and assert the reconnect loop gives up after the cap
# with "max reconnect attempts reached", and stops retrying after that.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Gearman;

# A port that refuses fast. 9 (discard) is usually closed on loopback;
# fall back to grabbing-then-closing an ephemeral port if it isn't.
my $port = 9;
{
    my $probe = IO::Socket::INET->new(
        PeerAddr => "127.0.0.1:$port", Timeout => 1,
    );
    if ($probe) {            # something is actually listening on 9
        close $probe;
        my $s = IO::Socket::INET->new(
            LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 1, ReuseAddr => 1,
        ) or plan skip_all => "cannot bind a throwaway port: $!";
        $port = $s->sockport;
        close $s;            # now nothing listens there -> refused
    }
}

my @errs;
my $cap = 2;
my $g = EV::Gearman->new(
    host                   => '127.0.0.1',
    port                   => $port,
    reconnect              => 1,
    reconnect_delay        => 30,    # ms
    max_reconnect_attempts => $cap,
    on_error => sub {
        push @errs, $_[0];
        EV::break if $_[0] =~ /max reconnect attempts reached/;
    },
);

my $guard = EV::timer 5, 0, sub { fail 'reconnect-cap timeout'; EV::break };
EV::run;

ok scalar(@errs), 'connect failures reported via on_error';
ok( (grep { /^connect failed:/ } @errs),
    'refused connect surfaces as "connect failed: ..."' );
ok( (grep { $_ eq 'max reconnect attempts reached' } @errs),
    'gives up with "max reconnect attempts reached"' );
ok !$g->is_connected, 'not connected after giving up';

# After the cap is hit, no further reconnect should be scheduled:
# give it a beat and confirm no new "max reconnect" error arrives.
my $n_before = grep { /max reconnect/ } @errs;
my $settle = EV::timer 0.2, 0, sub { EV::break };
EV::run;
my $n_after = grep { /max reconnect/ } @errs;
is $n_after, $n_before, 'no further retries after giving up';

done_testing;
