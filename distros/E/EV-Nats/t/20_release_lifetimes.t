use strict;
use warnings;
use Test::More;
use Scalar::Util qw(weaken);
use EV;
use EV::Nats;
use EV::Nats::JetStream;
use EV::Nats::KV;

for my $reconnect (0, 1) {
    for my $method (qw(delete purge)) {
        my $nats = EV::Nats->new(reconnect => $reconnect, on_error => sub {});
        my $js = bless { nats => $nats }, 'EV::Nats::JetStream';
        my $kv = bless { js => $js, bucket => 'B' }, 'EV::Nats::KV';
        my ($calls, $error) = (0, undef);
        my $ok = eval {
            $kv->$method('key', sub { ++$calls; $error = $_[1]; EV::break });
            1;
        };
        ok $ok, "$method does not croak while disconnected (reconnect=$reconnect)";
        is $calls, 0, 'error callback is deferred';
        my $guard = EV::timer(1, 0, sub { EV::break });
        EV::run;
        is $calls, 1, 'error callback fires once';
        like $error // '', qr/not connected|disconnected/, 'callback reports the send failure';
    }
}

sub retain { my $token = shift; return sub { $token } }
for my $case ([priority => 99], [loop => 'invalid'],
              EV::Nats::HAS_NKEY() ? ([nkey_seed => 'invalid']) : ()) {
    my $token = bless {}, 'Local::Token';
    my $weak = $token;
    weaken $weak;
    eval { EV::Nats->new(on_error => retain($token), @$case) };
    ok $@, "$case->[0] rejects invalid construction";
    undef $token;
    ok !defined($weak), 'failed construction releases retained callbacks';
}
done_testing;
