#!/usr/bin/env perl
#---AUTOPRAGMASTART---
use v5.42;
use strict;
use diagnostics;
use mro 'c3';
use English;
use Carp qw[carp croak confess cluck longmess shortmess];
our $VERSION = 0.1;
use autodie qw( close );
use Array::Contains;
use utf8;
use Data::Dumper;
use Data::Printer;
#---AUTOPRAGMAEND---


use IO::Socket::INET;

# Set UTF-8 encoding for output to handle Unicode characters
binmode(STDOUT, ':utf8');

# Quick connectivity test for payment terminal

my $TERMINAL_IP = '192.168.1.163';
my $TERMINAL_PORT = 20008;  # GP PAY ZVT port

print "=== Payment Terminal Connection Test ===\n" . "\n";
print "Testing: $TERMINAL_IP:$TERMINAL_PORT" . "\n";
print "\n";

# Test 1: ICMP ping
print "[1/3] Testing network connectivity (ping)..." . "\n";
my $ping_result = system("ping -c 2 -W 2 $TERMINAL_IP >/dev/null 2>&1");
if($ping_result == 0) {
    print "  ✓ Terminal responds to ping" . "\n";
} else {
    print "  ✗ Terminal does not respond to ping" . "\n";
    print "    This may be normal if ICMP is blocked" . "\n";
}

# Test 2: TCP connection
print "\n[2/3] Testing TCP connection to port $TERMINAL_PORT..." . "\n";
my $socket = IO::Socket::INET->new(
    PeerAddr => $TERMINAL_IP,
    PeerPort => $TERMINAL_PORT,
    Proto    => 'tcp',
    Timeout  => 5,
);

if($socket) {
    print "  ✓ TCP connection successful!" . "\n";
    print "    Terminal is listening on port $TERMINAL_PORT" . "\n";
    close($socket);
} else {
    print "  ✗ TCP connection failed: $@" . "\n";
    print "    Possible causes:" . "\n";
    print "      - Terminal is not powered on" . "\n";
    print "      - Wrong IP address" . "\n";
    print "      - Terminal not in ZVT mode" . "\n";
    print "      - Firewall blocking port $TERMINAL_PORT" . "\n";
}

# Test 3: Common ZVT ports scan
print "\n[3/3] Scanning common ZVT ports..." . "\n";
my @common_ports = (20008, 20007, 20000, 5000, 9001);
my @open_ports;

for my $port (@common_ports) {
    my $test_socket = IO::Socket::INET->new(
        PeerAddr => $TERMINAL_IP,
        PeerPort => $port,
        Proto    => 'tcp',
        Timeout  => 2,
    );
    if($test_socket) {
        push @open_ports, $port;
        close($test_socket);
    }
}

if(@open_ports) {
    print "  ✓ Found open ports: " . join(", ", @open_ports) . "\n";
    if(!grep { $_ == $TERMINAL_PORT } @open_ports) {
        print "    WARNING: Default port $TERMINAL_PORT not in list!" . "\n";
        print "    You may need to update the terminal configuration." . "\n";
    }
} else {
    print "  ✗ No common ZVT ports are open" . "\n";
}

# Summary
print "\n" . ("=" x 50) . "\n";
print "SUMMARY" . "\n";
print "=" x 50 . "\n";

if($socket) {
    print "✓ Terminal is reachable and ready for testing" . "\n";
    print "\nNext step: Run real_terminal_test.pl to perform a transaction" . "\n";
} else {
    print "✗ Terminal connection failed" . "\n";
    print "\nTroubleshooting steps:" . "\n";
    print "1. Verify terminal is powered on" . "\n";
    print "2. Check IP address (currently: $TERMINAL_IP)" . "\n";
    print "3. Verify terminal is on same network" . "\n";
    print "4. Check terminal is in ZVT/payment mode" . "\n";
    print "5. Try: ping $TERMINAL_IP" . "\n";
}

print "\n";

__END__

=head1 NAME

check_terminal_connection.pl - Test payment terminal connectivity

=head1 SYNOPSIS

    perl check_terminal_connection.pl

=head1 DESCRIPTION

Quick connectivity test for the GP PAY payment terminal at 192.168.1.163.

Tests:
1. ICMP ping
2. TCP connection to ZVT port 20007
3. Scan for other common ZVT ports

=cut
