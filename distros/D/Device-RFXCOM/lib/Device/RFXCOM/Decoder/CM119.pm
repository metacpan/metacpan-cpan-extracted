use strict;
use warnings;
package Device::RFXCOM::Decoder::CM119;
$Device::RFXCOM::Decoder::CM119::VERSION = '1.163170';
# ABSTRACT: Device::RFXCOM::Decoder::CM119 decode OWL CM119 RF messages


use 5.006;
use constant DEBUG => $ENV{DEVICE_RFXCOM_DECODER_CM119_DEBUG};
use Carp qw/croak/;
use Device::RFXCOM::Decoder qw/hi_nibble lo_nibble nibble_sum/;
use base 'Device::RFXCOM::Decoder';
use Device::RFXCOM::Response::Sensor;


sub decode {
  my ($self, $parent, $message, $bytes, $bits, $result) = @_;
  $bits == 108 or return;
  ($bytes->[0]&0xf)==0xa or return;

  my $s = _ns(1, 10, $bytes);
  $s += lo_nibble($bytes->[11]);
  $s -= (lo_nibble($bytes->[12])<<4) + hi_nibble($bytes->[11]);
  $s == 0 or return;

  my $ch = $bytes->[0]>>4;
  if ($ch < 1 || $ch > 3) {
    warn "CM119 channel not 1 - 3?\n";
  }
  my $device = sprintf "%02x", $bytes->[2];
  my $counter = lo_nibble($bytes->[1]);
  my $now = (lo_nibble($bytes->[5])<<16) + ($bytes->[4]<<8) + $bytes->[3];
  my $total =
    ($bytes->[10] << 36) + ($bytes->[9] << 28) + ($bytes->[8] << 20) +
      ($bytes->[7] << 12) + ($bytes->[6] << 4) + hi_nibble($bytes->[5]);
  $total /= 223000; # kWh
  my $dev = $device.'.'.$ch;
  printf "cm119 d=%s power=%dW\n", $dev, $now if DEBUG;
  push @{$result->{messages}},
    Device::RFXCOM::Response::Sensor->new(device => 'cm119.'.$dev,
                                          measurement => 'power',
                                          value => $now);
  return 1;
}

sub _ns {
  my ($s, $e, $b) = @_;
  my $sum = 0;
  foreach ($s .. $e) {
    $sum += lo_nibble($b->[$_]) + hi_nibble($b->[$_]);
  }
  $sum;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::RFXCOM::Decoder::CM119 - Device::RFXCOM::Decoder::CM119 decode OWL CM119 RF messages

=head1 VERSION

version 1.163170

=head1 SYNOPSIS

  # see Device::RFXCOM::RX

=head1 DESCRIPTION

Module to recognize OWL CM119 energy monitor RF messages from an
RFXCOM RF receiver.

=head1 METHODS

=head2 C<decode( $parent, $message, $bytes, $bits, \%result )>

This method attempts to recognize and decode RF messages from OWL
CM119 devices.  If a suitable message is identified, a reference to a
list of readings is returned.  If the message is not recognized, undef
is returned.

=head1 THANKS

Special thanks to RFXCOM, L<http://www.rfxcom.com/>, for their
excellent documentation and for giving me permission to use it to help
me write this code.  I own a number of their products and highly
recommend them.

=head1 SEE ALSO

RFXCOM website: http://www.rfxcom.com/

=head1 AUTHOR

Mark Hindess <soft-cpan@temporalanomaly.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mark Hindess.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
