#!perl -T

use strict;
use warnings;
use Socket;
use Test::More tests => 2;
use File::Send 'sendfile';
use Fcntl 'SEEK_SET';
use IO::Socket::INET;

alarm 2;

sub socket_pair {
	my $bound = IO::Socket::INET->new(Listen => 1, ReuseAddr => 1, LocalAddr => 'localhost') or die "Couldn't make listening socket: $!";
	my $in = IO::Socket::INET->new(PeerHost => $bound->sockhost, PeerPort => $bound->sockport) or die "Couldn't make input socket: $!";
	my $out = $bound->accept;
	return ($in, $out);
}

my ($in, $out) = socket_pair;

open my $self, '<', $0 or die "Couldn't open self: $!";
my $slurped = do { local $/; <$self> };
seek $self, 0, SEEK_SET;

sendfile $out, $self, -s $self or diag("Couldn't sendfile(): $!");
recv $in, my $read, -s $self, 0;

is($read, $slurped, "Read the same as was written");

seek $self, 0, SEEK_SET;

sendfile $out, $self or diag("Couldn't sendfile(): $!");
recv $in, $read, -s $self, 0;

is($read, $slurped, "Read the same as was written");
