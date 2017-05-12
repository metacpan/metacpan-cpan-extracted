#!env perl

use strict;
use warnings;
use Email::Sender::Simple qw{sendmail};
use Email::Sender::Transport::QMQP;
use IO::Socket::INET;
use Test::Exception;
use Test::More tests => 10;
use Test::TCP;
use Try::Tiny;

my $email = <<'EMAIL';
From: Michael Alan Dorman <mdorman@ironicdesign.com>
To: Some Random Person <random@example.com>
Subject: Test message

This is a test message.  It is woefully incomplete, but we're just
trying to do the most basic testing, so that's OK.
EMAIL

sub _unnetstring ($) {
    my ($input) = @_;
    return () unless $input;
    my ($length, $remainder) = split /:/, $input, 2;
    my $string = substr $remainder, 0, $length, "";
    die "Netstring is wrong length\n" unless length ($string) == $length;
    die "Netstring does not end in a comma\n" unless ',' eq substr $remainder, 0, 1, "";
    ($string, $remainder);
}

ok (my $server = Test::TCP->new (code => \&server), 'Instantiate Test::TCP server');
for my $port (qw{/hello 1092938}) {
    throws_ok {
        sendmail ($email, {transport => Email::Sender::Transport::QMQP->new ({port => $port})});
    } qr/^Couldn't connect to qmqp socket at/, "Test bogus port $port";
}
ok (my $transport = Email::Sender::Transport::QMQP->new ({port => $server->port}), 'Create our working transport');
ok (sendmail ($email, {transport => $transport}), 'Test an implicit address');
ok (sendmail ($email, {to => 'mdorman@ironicdesign.com', transport => $transport}), 'Test an explicit address');
ok (sendmail ($email, {to => ['mdorman@ironicdesign.com', 'foo@bar.com'], transport => $transport}), 'Testing multiple addresses');
throws_ok {sendmail ($email, {to => 'llamas@are.cool', transport => $transport})} qr/^Bad response from server:/, 'Test transient error handling';
throws_ok {sendmail ($email, {to => 'explosions@pyrotechnics.failure', transport => $transport})} qr/^Transmission failed:/, 'Test incomprehensible response';
throws_ok {sendmail ($email, {to => 'permanent@failure.fate', transport => $transport})} qr/^Transmission failed:/, 'Test permanent error handling';

sub server {
    my ($port) = @_;
    my $socket = IO::Socket::INET->new (LocalAddr => '127.0.0.1', LocalPort => $port, Listen => 1);
    while (my $client = $socket->accept) {
        # my ($buffer, $message);
        # Only smart enough to handle messages < 4K
        my $response = try {
            if (my $result = sysread ($client, my $buffer, 4096)) {
                my ($payload, $remainder) = _unnetstring $buffer;
                # This should consume all input
                die "Garbage after QMQP payload\n" if $remainder;
                my ($message, $sender, $recipient, @recipients);
                ($message, $remainder) = _unnetstring $payload;
                die "Message contains CR\n" if ($message =~ m/\015/);
                die "No sender after message\n" unless $remainder;
                ($sender, $remainder) = _unnetstring $remainder;
                die "No recipient after message\n" unless $remainder;
                push @recipients, $recipient while (($recipient, $remainder) = _unnetstring ($remainder));
                die "Just testing failure\n" if grep {$_ eq 'llamas@are.cool'} @recipients;
                if (grep {$_ eq 'explosions@pyrotechnics.failure'} @recipients) {
                    'This makes no sense at all';
                } elsif (grep {$_ eq 'permanent@failure.fate'} @recipients) {
                    'DTesting permanent failure check'
                } else {
                    'KOK';
                }
            } else {
                die "Error reading: $!\n" unless (defined $result);
            }
        } catch {
            'Z' . $_;
        };
        if ($response) {
            $client->printf ("%d:%s,", length $response, $response);
            $client->flush;
        }
    }
}

done_testing;
