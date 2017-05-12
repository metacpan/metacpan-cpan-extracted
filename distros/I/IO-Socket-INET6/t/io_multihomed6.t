#!/usr/bin/env perl

use strict;
use warnings;

BEGIN {
    unless(grep /blib/, @INC) {
        chdir 't' if -d 't';
        unshift @INC,'../lib';
    }
}

use Config;

BEGIN {
    if(-d "lib" && -f "TEST") {
        my $reason;
        if (! $Config{'d_fork'}) {
            $reason = 'no fork';
        }
        elsif ($Config{'extensions'} !~ /\bSocket\b/) {
            $reason = 'Socket extension unavailable';
        }
        elsif ($Config{'extensions'} !~ /\bSocket6\b/) {
            $reason = 'Socket6 extension unavailable';
        }
        elsif ($Config{'extensions'} !~ /\bIO\b/) {
            $reason = 'IO extension unavailable';
        }
        if ($reason) {
            print "1..0 # SKIP $reason\n";
            exit 0;
        }
    }
    if ($^O eq 'MSWin32') {
        print "1..0 # SKIP accept() fails for IPv6 under MSWin32\n";
        exit 0;
    }
}

# check that localhost resolves to 127.0.0.1 and ::1
# otherwise the test will not work

use Socket (qw(
    AF_INET6 PF_INET6 SOCK_RAW SOCK_STREAM INADDR_ANY SOCK_DGRAM
    AF_INET SO_REUSEADDR SO_REUSEPORT AF_UNSPEC SO_BROADCAST
    sockaddr_in unpack_sockaddr_in
    )
);

# IO::Socket and Socket already import stuff here - possibly AF_INET6
# and PF_INET6 so selectively import things from Socket6.
use Socket6 (
    qw(AI_PASSIVE getaddrinfo
    sockaddr_in6 unpack_sockaddr_in6 pack_sockaddr_in6_all in6addr_any
    inet_ntop
    )
);

{
    my %resolved_addresses;

    my @r = getaddrinfo('localhost',1);

    if (@r < 5) {
        print "1..0 # SKIP getaddrinfo('localhost',1) failed: $r[0]\n";
        exit 0;
    }

    while (@r) {
        my @values = splice(@r,0,5);
        my ($fam,$addr) = @values[0,3];
        $addr =
        (
              ($fam == AF_INET)
            ? ( (unpack_sockaddr_in($addr))[1]  )
            : ( (unpack_sockaddr_in6($addr))[1] )
        );
        $resolved_addresses{inet_ntop($fam,$addr)}++;
    }
    if (! $resolved_addresses{'127.0.0.1'} || ! $resolved_addresses{'::1'}) {
        print "1..0 # SKIP localhost does not resolve to both 127.0.0.1 and ::1\n";
        exit 0;
    }
}

# IO::Socket has an import method that is inherited by IO::Socket::INET6 ,
# and so we should instruct it not to import anything.
use IO::Socket::INET6 ();

$| = 1;
print "1..8\n";

eval {
    $SIG{ALRM} = sub { die; };
    alarm 60;
};

# find out if the host prefers inet or inet6 by offering
# both and checking where it connects
my ($port,@srv);
for my $addr ( '127.0.0.1','::1' ) {
    push @srv,
        IO::Socket::INET6->new(
            Listen => 2,
            LocalAddr => $addr,
            LocalPort => $port,
        ) or die "listen on $addr port $port: $!";
    $port ||= $srv[-1]->sockport;
}

print "ok 1\n";

if (my $pid = fork()) {
    my $vec = '';
    vec($vec,fileno($_),1) = 1 for(@srv);
    select($vec,undef,undef,5) or die $!;

    # connected to first, not second
    my ($first,$second) = vec($vec,fileno($srv[0]),1) ? @srv[0,1]:@srv[1,0];
    my $cl = $first->accept or die $!;

    # listener should not work for next connect
    # so it needs to try second
    close($first);

    # make sure established connection works
    my $fam0 = ( $cl->sockdomain == AF_INET ) ? 'inet':'inet6';
    print {$cl} "ok 2 # $fam0\n";
    print $cl->getline(); # ok 3
    # So we'll be sure ok 3 has already been printed.
    print {$cl} "Move on, will ya!\n";
    close($cl);

    # ... ok 4 comes when client fails to connect to first

    # wait for connect on second and make sure it works
    $vec = '';
    vec($vec,fileno($second),1) = 1;
    if ( select($vec,undef,undef,5)) {
        my $cl2 = $second->accept or die $!;
        my $fam1 = ( $cl2->sockdomain == AF_INET ) ? 'inet':'inet6';
        print {$cl2} "ok 5 # $fam1\n";
        print $cl2->getline(); # ok 6
        close($cl2);

        # should be different families
        print "not " if $fam0 eq $fam1;
        print "ok 7\n";
    }

    waitpid($pid,0);
    print "ok 8\n";

} elsif (defined $pid) {
    close($_) for (@srv);
    # should work because server is listening on inet and inet6
    my $cl = IO::Socket::INET6->new(
        PeerPort => $port,
        PeerAddr => 'localhost',
        Timeout => 5,
    ) or die "$@";

    print $cl->getline(); # ok 2
    print {$cl} "ok 3\n";
    # So we'll be sure ok 3 has already been printed.
    $cl->getline();
    close($cl);

    # this should not work because listener is closed
    if ( $cl = IO::Socket::INET6->new(
            PeerPort => $port,
        PeerAddr => 'localhost',
        Timeout => 5,
    )) {
        print "not ok 4\n";
        exit;
    }
    print "ok 4\n";

    # but same thing with multihoming should work because server
    # is still listening on the other family
    $cl = IO::Socket::INET6->new(
        PeerPort => $port,
        PeerAddr => 'localhost',
        Timeout => 5,
        MultiHomed => 1,
    ) or do {
        print "not ok 5\n";
        exit;
    };
    print $cl->getline(); # ok 5
    print {$cl} "ok 6\n";
    exit;

} else {
    die $!; # fork failed
}
