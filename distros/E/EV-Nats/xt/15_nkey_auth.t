use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use lib 'xt/lib';
use EVNatsHelpers qw(nats_bin_or_skip free_port spawn_nats);
use EV;
use EV::Nats;

plan skip_all => 'NKey auth requires OpenSSL build' unless EV::Nats::HAS_NKEY();

my $nats_bin = nats_bin_or_skip();

# Generate fresh User NKey pair for this test run (no hardcoded fixtures).
my $SEED   = EV::Nats->nkey_generate_user_seed;
my $PUBKEY = EV::Nats->nkey_public_from_seed($SEED);
my $WRONG  = EV::Nats->nkey_generate_user_seed;

plan tests => 4;

my $tmp  = tempdir(CLEANUP => 1);
my $port = free_port();
my $conf = "$tmp/nats.conf";
open my $fh, '>', $conf or die "write: $!";
print $fh <<"CONF";
listen: 127.0.0.1:$port
authorization {
  users = [
    { nkey: $PUBKEY }
  ]
}
CONF
close $fh;

my $pid = spawn_nats($nats_bin, '-c', $conf);

# 1. correct seed -> connects
{
    my ($connected, $err) = (0, undef);
    my $nats;
    $nats = EV::Nats->new(
        host       => '127.0.0.1',
        port       => $port,
        nkey_seed  => $SEED,
        on_error   => sub { $err = $_[0]; EV::break },
        on_connect => sub { $connected = 1; EV::break },
    );
    EV::timer(5, 0, sub { EV::break });
    EV::run;
    ok $connected, 'connect with valid NKey seed' or diag "err: $err";
    ok !$err, 'no error with valid NKey' or diag "got: $err";
    $nats->disconnect if $connected;
}

# 2. wrong seed -> auth error, no connect
{
    my ($connected, $err) = (0, undef);
    my $nats;
    $nats = EV::Nats->new(
        host       => '127.0.0.1',
        port       => $port,
        nkey_seed  => $WRONG,
        on_error   => sub { $err = $_[0]; EV::break },
        on_connect => sub { $connected = 1; EV::break },
    );
    EV::timer(5, 0, sub { EV::break });
    EV::run;
    ok !$connected, 'wrong NKey: no connection';
    like $err, qr/auth/i, 'wrong NKey: server reports auth error'
        or diag "err: " . ($err // '<none>');
}

kill 'TERM', $pid;
waitpid $pid, 0;
