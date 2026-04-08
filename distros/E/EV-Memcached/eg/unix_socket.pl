#!/usr/bin/env perl
use strict;
use warnings;
use EV::Memcached;

$| = 1;

# Unix socket connection — lower latency than TCP for local servers.
# Start memcached with: memcached -s /tmp/memcached.sock -a 0777

my $path = $ENV{MC_SOCK} // '/tmp/memcached.sock';

unless (-S $path) {
    die "No Unix socket at $path\n"
      . "Start memcached with: memcached -s $path -a 0777\n";
}

my $mc = EV::Memcached->new(
    path     => $path,
    on_error => sub { warn "error: @_\n" },
);

$mc->on_connect(sub {
    print "Connected via Unix socket: $path\n";

    $mc->version(sub {
        my ($ver, $err) = @_;
        print "Server version: $ver\n";

        $mc->set('unix_test', 'hello from Unix socket', sub {
            $mc->get('unix_test', sub {
                my ($val, $err) = @_;
                print "Got: $val\n";
                $mc->disconnect;
            });
        });
    });
});

EV::run;
