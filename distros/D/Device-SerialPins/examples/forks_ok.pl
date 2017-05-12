
use Time::HiRes qw(sleep);
use Device::SerialPins;

my $n = 30;
my $s = 0.2;

my $sp = Device::SerialPins->new("/dev/ttyS0");

$sp->set_txd(1);

if(fork) {
  for(1..$n) {
    $sp->set_dtr(($_ % 2) > 0);
    warn "parent ", $sp->car;
    sleep($s);
  }
}
else {
  for(1..$n) {
    $sp->set_rts(($_ % 2) == 0);
  warn "child ", $sp->rng;
  sleep($s);
  }
  exit;
}
wait;

# vim:ts=2:sw=2:et:sta
