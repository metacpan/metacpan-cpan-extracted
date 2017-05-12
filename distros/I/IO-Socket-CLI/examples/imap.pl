#!/usr/bin/perl

use IO::Socket::CLI::IMAP;

my $imap = IO::Socket::CLI::IMAP->new(HOST => '::1');

$imap->debug(0);

unless ($imap->is_open()) {
    sleep 1;
    $imap->is_open() || die "Connection not open at " . $imap->socket->peerhost . " port " . $imap->socket->peerport . "\n";
}

$imap->read();

do {
    $imap->prompt();
    $imap->read();
} while ($imap->is_open());
