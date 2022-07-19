#!/usr/bin/env perl

use strict;
use warnings;

use Linux::WireGuard;

use Test::More;
use Test::FailWarnings;
use Test::Deep;
use Test::Fatal;

use Guard;
use Errno;
use Socket;

# Test::More uses Data::Dumper underneath.
use Data::Dumper;
$Data::Dumper::Useqq = 1;

my $devname = 't' . substr( rand, 2, 8 );

my $eperm_str = do { local $! = Errno::EPERM; "$!" };

{
    local $> = 1999;    # fails if non-root, but we don’t care
    my $err    = exception { Linux::WireGuard::add_device($devname) };
    like $err, qr<$eperm_str>, 'add_device() as non-root: error';
}

SKIP: {
    my $err = exception { Linux::WireGuard::add_device($devname) };
    if ($err) {
        skip "Failed to add device: $err", 1 if $err =~ m<$eperm_str>;
        die $err;
    }

    note "Created temporary device: $devname";

    my $guard = Guard::guard(
        sub {
            note "Deleting temporary device: $devname";
            Linux::WireGuard::del_device($devname);
        }
    );

    my @names = Linux::WireGuard::list_device_names();

    cmp_deeply( \@names, superbagof($devname),
        'list_device_names() includes newly-created device',
    );

    my $device = Linux::WireGuard::get_device($devname);

    my $uint_re          = re(qr<\A[0-9]+\z>);
    my $optional_uint_re = any( undef, $uint_re );
    my $optional_str     = any( undef, re(qr<.>) );

    my $ipv4_addr_len = length pack_sockaddr_in( 0, "\0" x 4 );
    my $ipv6_addr_len = length pack_sockaddr_in6( 0, "\0" x 16 );

    cmp_deeply(
        $device,
        {
            name        => $devname,
            ifindex     => $uint_re,
            public_key  => undef,
            private_key => undef,
            fwmark      => undef,
            listen_port => undef,
            peers       => [],
        },
        'get_device()',
    ) or diag explain $device;
}

done_testing;
