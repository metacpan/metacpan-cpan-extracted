#!perl
use strict;
use warnings;
use lib 'lib';
use Devel::ebug;
use IO::Socket::INET;
use Proc::Background;
use String::Koremutake;
use Test::More tests => 11;

# A backend waiting for a frontend to attach, as under ebug_server.
sub listening_backend {
  my($secret) = @_;
  local $ENV{SECRET} = $secret;
  return Proc::Background->new({ die_upon_destroy => 1 },
    $^X, '-d:ebug::Backend', 'corpus/calc.pl');
}

my $k    = String::Koremutake->new;
my $rand = int(rand(100_000));
my $port = 3141 + ($rand % 1024);
my $key  = $k->integer_to_koremutake($rand);
my $other_key = $k->integer_to_koremutake($rand + 1024);  # same port, wrong key

my $proc = listening_backend($key);

# --- a wrong key is turned away without ending the session -----------------

{
  my $intruder = Devel::ebug->new;
  ok(!eval { $intruder->attach($port, $other_key); 1 }, 'attaching with the wrong key fails');
  like($@, qr/did not answer the handshake on port $port/, 'and says why');
}

ok($proc->alive, 'the backend survives a frontend with the wrong key');

# --- load() does not need a port, so it cannot collide with one -----------

{
  my $ebug = Devel::ebug->new;
  $ebug->program('corpus/calc.pl');
  $ebug->load;
  is($ebug->line, 3, 'load works while another session is waiting on its port');
  ok(!$ENV{DEVEL_EBUG_CONNECT}, 'load does not leave DEVEL_EBUG_CONNECT set');
}

{
  my $ebug = Devel::ebug->new;
  ok(eval { $ebug->attach($port, $key); 1 }, 'the right key can still attach afterwards')
    or diag $@;
  is($ebug->line, 3, 'to a working session');
}

# --- load() fails promptly when the program never gets as far as the backend

{
  my $ebug = Devel::ebug->new;
  $ebug->backend("$^X -e 1");   # exits at once, like a program that fails early
  $ebug->program('corpus/calc.pl');
  my $start = time;
  ok(!eval { $ebug->load; 1 }, 'load fails if the program exits before connecting');
  like($@, qr/exited before the debugger could connect/, 'and says so');
  cmp_ok(time - $start, '<', 10, 'without waiting for the timeout');
}

# --- the frontend only takes the connection that knows the secret ---------

{
  my $listener = IO::Socket::INET->new(
    Listen => 5, LocalAddr => 'localhost', LocalPort => 0, Proto => 'tcp',
  ) or die "listen: $!";
  my @clients = map {
    IO::Socket::INET->new(PeerAddr => 'localhost', PeerPort => $listener->sockport, Proto => 'tcp')
      or die "connect: $!"
  } 1 .. 3;
  $clients[0]->print("not the secret\n");
  close $clients[1];
  $clients[2]->print("sesame\nfrom the backend\n");
  $_->flush for grep { $_->opened } @clients;

  my $ebug = Devel::ebug->new;
  $ebug->program('fake');
  $ebug->proc(bless {}, 'Local::AliveProc');
  my $socket = $ebug->_accept_backend($listener, 'sesame');
  is(scalar $socket->getline, "from the backend\n", 'strays are turned away until the backend connects');
}

package Local::AliveProc;
sub alive { 1 }
