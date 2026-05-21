#!/usr/bin/env perl
# NKey / credentials file authentication example
use strict;
use warnings;
use EV;
use EV::Nats;

# Method 1: credentials file (contains JWT + NKey seed).
# Apply creds_file BEFORE connect, so JWT/NKey are available during the
# initial CONNECT handshake.
if (my $creds = $ENV{NATS_CREDS}) {
    my $nats;
    $nats = EV::Nats->new(
        tls      => 1,
        on_error => sub { warn "error: @_\n" },
        on_connect => sub {
            print "connected with creds file\n";
            $nats->disconnect;
            EV::break;
        },
    );
    $nats->creds_file($creds);
    $nats->connect(
        $ENV{NATS_HOST} // 'connect.ngs.global',
        $ENV{NATS_PORT} // 4222,
    );
    EV::run;
    exit;
}

# Method 2: direct NKey seed
if (my $seed = $ENV{NATS_NKEY_SEED}) {
    my $nats;
    $nats = EV::Nats->new(
        host      => $ENV{NATS_HOST} // '127.0.0.1',
        port      => $ENV{NATS_PORT} // 4222,
        nkey_seed => $seed,
        on_error  => sub { warn "error: @_\n" },
        on_connect => sub {
            print "connected with NKey\n";
            $nats->disconnect;
            EV::break;
        },
    );
    EV::run;
    exit;
}

print "Usage:\n";
print "  NATS_CREDS=/path/to/user.creds perl $0\n";
print "  NATS_NKEY_SEED=SUAM... perl $0\n";
