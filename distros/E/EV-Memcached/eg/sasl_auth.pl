#!/usr/bin/env perl
use strict;
use warnings;
use EV::Memcached;

$| = 1;

# SASL PLAIN authentication example.
# Requires memcached started with: memcached -S -B binary
# And SASL credentials configured via saslpasswd2.

# Option 1: Auto-auth via constructor (recommended)
# Credentials are sent automatically on every connect/reconnect.
{
    my $mc = EV::Memcached->new(
        host     => $ENV{MC_HOST} // '127.0.0.1',
        port     => $ENV{MC_PORT} // 11211,
        username => $ENV{MC_USER} // 'testuser',
        password => $ENV{MC_PASS} // 'testpass',
        on_error => sub { warn "error: @_\n"; EV::break },
    );

    $mc->on_connect(sub {
        print "Auto-auth: connected and authenticated\n";
        $mc->set('sasl_key', 'secret_value', sub {
            my ($res, $err) = @_;
            die "set: $err" if $err;
            $mc->get('sasl_key', sub {
                my ($val, $err) = @_;
                print "Auto-auth: got '$val'\n";
                $mc->disconnect;
                EV::break;
            });
        });
    });
    EV::run;
}

# Option 2: Explicit authentication
{
    my $mc = EV::Memcached->new(
        host     => $ENV{MC_HOST} // '127.0.0.1',
        port     => $ENV{MC_PORT} // 11211,
        on_error => sub { warn "error: @_\n"; EV::break },
    );

    $mc->on_connect(sub {
        # List available mechanisms
        $mc->sasl_list_mechs(sub {
            my ($mechs, $err) = @_;
            print "Available mechanisms: $mechs\n";

            # Authenticate explicitly
            $mc->sasl_auth(
                $ENV{MC_USER} // 'testuser',
                $ENV{MC_PASS} // 'testpass',
                sub {
                    my ($res, $err) = @_;
                    if ($err) {
                        print "Auth failed: $err\n";
                        $mc->disconnect;
                        EV::break;
                        return;
                    }
                    print "Explicit auth: success\n";
                    $mc->version(sub {
                        my ($ver) = @_;
                        print "Server: $ver\n";
                        $mc->disconnect;
                        EV::break;
                    });
                },
            );
        });
    });
    EV::run;
}
