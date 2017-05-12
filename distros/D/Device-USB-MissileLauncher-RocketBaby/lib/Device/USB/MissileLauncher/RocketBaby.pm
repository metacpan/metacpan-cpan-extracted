package Device::USB::MissileLauncher::RocketBaby;
use strict;
use warnings;
use Device::USB;

our $VERSION = '1.01';

sub new
{
    my ($class) = @_;

    my $usb = Device::USB->new;
    my $dev = $usb->find_device(0xA81, 0x701);
    $dev->open;
    $dev->detach_kernel_driver_np(0);
    $dev->set_configuration(1);
    $dev->claim_interface(0);

    bless { dev => $dev }, $class;
}

sub _send
{
    my ($self, $val) = @_;
    $self->{dev}->control_msg(0x21, 0x09, 0x02, 0, chr($val), 1, 1000);
}

sub _stat
{
    my ($self) = @_;
    $self->_send(0x40);
    $self->{dev}->bulk_read(1, my $buf = "\0", 1, 1000);
    ord($buf);
}

sub _cando
{
    my ($self, $val) = @_;
    not $self->_stat & $val;
}

my %VAL = (
    down  => 0x01,
    up    => 0x02,
    left  => 0x04,
    right => 0x08,
    fire  => 0x10,
    stop  => 0x20,
);

sub _val { $VAL{$_[1]} }

sub cando
{
    my ($self, $cmd) = @_;
    my $val = $self->_val($cmd) or return;
    $self->_cando($val);
}

sub do
{
    my ($self, $cmd) = @_;
    my $val = $self->_val($cmd) or return -1;
    $self->_send($val);
}

1;

__END__

=head1 NAME

Device::USB::MissileLauncher::RocketBaby - interface to toy missile launchers from Dream Cheeky

=head1 SYNOPSIS

  use Device::USB::MissileLauncher::RocketBaby;
  my $ml = Device::USB::MissileLauncher::RocketBaby->new;
  while (<>) {
      /j/ && $ml->do("down");
      /k/ && $ml->do("up");
      /h/ && $ml->do("left");
      /l/ && $ml->do("right");
      /f/ && $ml->do("fire");
      /s/ && $ml->do("stop");
  }

=head1 DESCRIPTION

This provides a basic interface to the toy USB missile launchers produced by Dream Cheeky.  The device name of USB protocol is "Rocket Baby Rocket Baby".

=head1 METHODS

=over 4

=item new ()

Creates an instance.

=item do ( STRING )

send command string to the launcher.  commands are following:

  left
  right
  up
  down
  fire
  stop

=item cando ( STRING )

returns whether the command is executable.

=back

=head1 NOTE

cando("fire") returns false at only moment of launching.
You can launch rockets one by one like this:

  use Time::Hires qw( sleep );

  sub fire1
  {
      my $ml = shift;
      if ($ml->cando("fire")) {
          $ml->do('fire');
          eval {
              local $SIG{ALRM} = sub { die "alarm" };
              alarm 5;
              while ($ml->cando("fire")) {
                  sleep 0.15;
              }
              sleep 0.5;
              alarm 0;
          }
          $ml->do("stop");
      }
  }

You might have to adjust sleep figures.

=head1 SEE ALSO

Device::USB::MissileLauncher

http://www.dreamcheeky.com/product/missile-launcher.php

=head1 AUTHOR

Abe Masahiro, E<lt>pen@thcomp.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Abe Masahiro

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

