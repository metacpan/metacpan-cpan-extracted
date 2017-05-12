package Device::SerialPins;
$VERSION = v0.0.2;

use warnings;
use strict;
use Carp;

=head1 NAME

Device::SerialPins - per-pin low-level serial port access

=head1 SYNOPSIS

  use Device::SerialPins;
  my $sp = Device::SerialPins->new('/dev/ttyS0');
  $sp->set_txd(1);
  $sp->set_dtr(1);
  $sp->set_rts(1);

  # aka
  $sp->set_pin3(1);
  $sp->set_pin4(1);
  $sp->set_pin7(1);

  warn "car ", $sp->car;
  warn "dsr ", $sp->dsr;
  warn "cts ", $sp->cts;
  warn "rng ", $sp->rng;

  # aka
  warn "car ", $sp->pin1;
  warn "dsr ", $sp->pin6;
  warn "cts ", $sp->pin8;
  warn "rng ", $sp->pin9;

=cut

# NOTE gnd isn't able to be manipulated

# NOTE rxd (2) could also have a getter,
#      but I'm not sure how and don't need it yet anyway.

my @pin_names = qw(
  car
  rxd
  txd
  dtr
  gnd
  dsr
  rts
  cts
  rng
);

my %pin_map = map({$pin_names[$_] => $_ + 1} 0..$#pin_names);
#use YAML; die YAML::Dump(\%pin_map);

# setter aliases
for my $n (qw(txd dtr rts)) {
  my $method = 'set_' . $n;
  my $sub = eval("sub {shift->$method(\@_)}");
  my $name = 'set_pin' . $pin_map{$n};
  no strict 'refs';
  *{$name} = $sub;
}
# getter aliases
for my $n (qw(car dsr cts rng)) {
  my $sub = eval("sub {shift->$n}");
  my $name = 'pin' . $pin_map{$n};
  no strict 'refs';
  *{$name} = $sub;
}
# and this weirdo
*dcd = sub {shift->car};

my $bits;
{
  # get the constants from the perlheader file
  # see `perldoc perlfunc` ioctl()
  # and perlfaq5, perlfaq8
  # also note:  Term::ReadLine::readline
  package Device::SerialPins::Bits;
  local $^W = 0; # suppress strange -w noise
  require 'sys/ioctl.ph';
  $bits = __PACKAGE__;
}

foreach my $n (qw(rts dtr)) {
  my $name = 'set_' . $n;
  my $thing = 'TIOCM_' . uc($n);
  my $packed = pack('L', $bits->$thing);
  my $sub = sub {
    my $self = shift;
    my ($val) = @_;

    my $which = 'TIOCMBI' . ($val ? 'S' : 'C');
    ioctl($self->{fd}, $bits->$which, $packed) or die "$!";
    $self->{$n} = $val;
  };
  no strict 'refs';
  *{$name} = $sub;
}

# getters for these in case you forget
foreach my $n (map({($_, 'pin'.$pin_map{$_})} qw(txd rts dtr))) {
  my $sub = sub {
    my $self = shift;
    return($self->{$n});
  };
  no strict 'refs';
  *{$n} = $sub;
}

for my $n (qw(car dsr cts rng)) {
  my $sym = 'TIOCM_' . uc($n);
  my $code = $bits->$sym;
  my $sub = sub {
    my $self = shift;
    my $status = pack('L', 0);
    ioctl($self->{fd}, $bits->TIOCMGET, $status) or die $!;
    my $result = unpack('L', $status);
    return($result & $code);
  };
  no strict 'refs';
  *{$n} = $sub;
}

=head1 Constructor

=head2 new

  my $sp = Device::SerialPins->new('/dev/ttyS0');

=cut

sub new {
  my $package = shift;
  my ($file) = @_;

  (-c $file) or die "'$file' is not a serial port";
  open(my $fd, '<', $file) or die "cannot open port $!";

  my $self = {fd => $fd};

  bless($self, $package);
  return($self);
} # end subroutine new definition
########################################################################

=head1 Getter Methods

Note: there is currently no rxd/pin2

=head2 pin1 / car / dcd

  my $state = $sp->pin1;

=head2 pin3 / txd

  my $state = $sp->pin3;

=head2 pin4 / dtr

  my $state = $sp->pin4;

=head2 ground pin is #5

=head2 pin6 / dsr

  my $state = $sp->pin6;

=head2 pin7 / rts

  my $state = $sp->pin7;

=head2 pin8 / cts

  my $state = $sp->pin8;

=head2 pin9 / rng

  my $state = $sp->pin9;

=head2 get

Gets the state of a named or numbered pin.

  $sp->get($pin);

=cut

{
my %valid = map({(
  $_ => $_,
  $pin_map{$_} => $_
)} qw(txd dtr rts car dsr cts rng));
sub get {
  my $self = shift;
  my ($pin) = @_;

  my $method = $valid{$pin} or croak "invalid argument '$pin'";
  return($self->$method);
} # end subroutine get definition
}
########################################################################

=head1 Setter Methods

You can only set the three output pins.

The setter methods have the three-letter pin names or the pin# numbered
aliases.  Also see the general-purpose set() method.

  $sp->set_foo(1); # on

  $sp->set_foo(0); # off

=head2 set_pin3 / set_txd

=head2 set_pin4 / set_dtr

=head2 set_pin7 / set_rts

=cut

sub set_txd {
  my $self = shift;
  my ($val) = @_;

  my $mode = ($val ?  'TIOCSBRK' : 'TIOCCBRK');

  ioctl($self->{fd}, $bits->$mode, 0) or die $!;

  $self->{txd} = $val;
} # end subroutine set_txd definition
########################################################################

=head2 set

Sets the state of a named or numbered pin.

  $sp->set($pin, $bool);

=cut

{
my %valid = map({(
  $_ => 'set_' . $_,
  $pin_map{$_} => 'set_' . $_
)} qw(txd dtr rts));
sub set {
  my $self = shift;
  my ($pin, $bool) = @_;
  my $method = $valid{$pin} or croak "invalid argument '$pin'";
  $self->$method($bool);
} # end subroutine set definition
}
########################################################################

=head1 SEE ALSO

L<Device::SerialPort> for more typical usage.

L<http://www.easysw.com/~mike/serial/serial.html>

=head1 AUTHOR

Eric Wilhelm @ <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2007 Eric L. Wilhelm, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vi:ts=2:sw=2:et:sta
1;
