use Test::More tests => 34;

use_ok('Device::SerialPins') or BAIL_OUT('cannot load Device::SerialPins');

my $package = 'Device::SerialPins';
eval {require version};
diag("Testing $package ", $package->VERSION );

can_ok('Device::SerialPins::Bits', $_) for(qw(
  TIOCMBIC
  TIOCMBIS
  TIOCMGET
  TIOCM_RTS
  TIOCM_DTR
  TIOCM_CAR
  TIOCM_DSR
  TIOCM_CTS
  TIOCM_RNG
  TIOCSBRK
  TIOCCBRK
));

can_ok('Device::SerialPins', $_) for(qw(
  get
  set
  car
  txd
  dtr
  dsr
  rts
  cts
  rng
  pin1
  pin3
  pin4
  pin6
  pin7
  pin8
  pin9
  set_txd
  set_dtr
  set_rts
  set_pin3
  set_pin4
  set_pin7
));

# vi:syntax=perl:ts=2:sw=2:et:sta
