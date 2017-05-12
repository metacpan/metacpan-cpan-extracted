#!/usr/bin/perl

use IO::Socket::CLI::SMTP;

my $smtp = IO::Socket::CLI::SMTP->new(HOST => '192.168.1.3');

$smtp->debug(0);

unless ($smtp->is_open()) {
    sleep 1;
    $smtp->is_open() || die "Connection not open at " . $smtp->socket->peerhost . " port " . $smtp->socket->peerport . "\n";
}

$smtp->read();

do {
    $smtp->prompt();
    $smtp->read();
} while ($smtp->is_open());
