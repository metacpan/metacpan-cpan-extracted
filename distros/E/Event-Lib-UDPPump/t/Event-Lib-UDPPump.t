#!/sw/bin/perl

use strict;
use warnings;
use Test::More tests => 15;

use IO::Socket::INET;
use Data::Dumper;
use Event::Lib;

BEGIN { use_ok('Event::Lib::UDPPump') };

my $s = IO::Socket::INET->new(Proto => 'udp', 
                              LocalAddr => '127.0.0.1',
                              LocalPort => 1974,
                             );
isa_ok($s, 'IO::Socket::INET', "Create UDP socket");

my $fired = 0;
my ($result, @args);
my $callback = sub {
  ($result, @args) = @_;
  $fired++;
};

my $pump = udppump_new($s, $callback, qw(a b c d e f));
isa_ok($pump, 'Event::Lib::UDPPump', "udppump_new");

my $fh = $pump->fh();
is($fh, $s, '$pump->fh()');
$pump->add();

my $testsock = IO::Socket::INET->new(Proto => 'udp',
                                     PeerAddr => $s->sockhost,
                                     PeerPort => $s->sockport,
                                    );
isa_ok($testsock, 'IO::Socket::INET', "Created test client socket");
syswrite($testsock, '12345', 5);
event_one_loop(1);
is($fired, 1, "callback fired");

{ # check result
  is(ref $result, 'HASH', "callback result is hash ref");
  is($result->{len}, 5, "callback result - buffer len == 1");
  is($result->{buffer}, '12345', "callback result - buffer contents == 12345");
  is($result->{errno}, 0, "callback result - errno == 0");
  is(sockaddr_family($result->{from}), AF_INET, "callback result - addr family == AF_INET");
  my ($port, $addr) = unpack_sockaddr_in($result->{from});
  $addr = inet_ntoa($addr);
  is($port, $testsock->sockport, "callback result - port == 1974");
  is($addr, '127.0.0.1', "callback result - port == 127.0.0.1");
  is_deeply(\@args, [ qw(a b c d e f) ], "callback result - args correct");
}

SKIP: {
  eval { require Devel::Leak; };
  skip "Devel::Leak not installed", 1 if $@;

  my $handle;
  my $SVcount = Devel::Leak::NoteSV($handle);
  foreach (1..1000) {
    syswrite($testsock, '1', 1);
    event_one_loop(1);
  }
  my $leaked = Devel::Leak::NoteSV($handle) - $SVcount;
  
  # I'm comparing for < 5 because I've seen issues where this varies by
  # a few one way or another with different versions of perl.  However,
  # we ran 1000 iterations, it should be much more than 5 if there is a
  # real leak in the XS.
  ok($leaked < 5, "No leaks");
#  print "leaked: $leaked\n";
}

