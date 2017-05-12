use strict;
use warnings;
package Device::RFXCOM::Decoder::RFXMeter;
$Device::RFXCOM::Decoder::RFXMeter::VERSION = '1.163170';
# ABSTRACT: Device::RFXCOM::Decoder::RFXMeter decode RFXMeter RF messages


use 5.006;
use constant DEBUG => $ENV{DEVICE_RFXCOM_DECODER_RFXMETER_DEBUG};
use Carp qw/croak/;
use Device::RFXCOM::Decoder qw/nibble_sum/;
our @ISA = qw(Device::RFXCOM::Decoder);


sub decode {
  my ($self, $parent, $message, $bytes, $bits, $result) = @_;

  $bits == 48 or return;

  ($bytes->[0] == ($bytes->[1]^0xf0)) or return;

  my $device = sprintf "%02x%02x", $bytes->[0], $bytes->[1];
  my @nib = map { hex $_ } split //, unpack "H*", $message;
  my $type = $nib[10];
  my $check = $nib[11];
  my $nibble_sum = nibble_sum(11, \@nib);
  my $parity = 0xf^($nibble_sum&0xf);
  unless ($parity == $check) {
    warn "RFXMeter parity error $parity != $check\n";
    return;
  }

  my $time =
    { 0x01 => '30s',
      0x02 => '1m',
      0x04 => '5m',
      0x08 => '10m',
      0x10 => '15m',
      0x20 => '30m',
      0x40 => '45m',
      0x80 => '60m',
    };
  my $type_str =
      [
       'normal data packet',
       'new interval time set',
       'calibrate value',
       'new address set',
       'counter value reset to zero',
       'set 1st digit of counter value integer part',
       'set 2nd digit of counter value integer part',
       'set 3rd digit of counter value integer part',
       'set 4th digit of counter value integer part',
       'set 5th digit of counter value integer part',
       'set 6th digit of counter value integer part',
       'counter value set',
       'set interval mode within 5 seconds',
       'calibration mode within 5 seconds',
       'set address mode within 5 seconds',
       'identification packet',
      ]->[$type];
  unless ($type == 0) {
    warn "Unsupported rfxmeter message $type_str\n",
         "Hex: ", unpack("H*",$message), "\n";
   return [];
  }
  my $count = ($bytes->[4]<<16) + ($bytes->[2]<<8) + ($bytes->[3]);
  #print "rfxmeter: ", $count, "count\n";
  push @{$result->{messages}},
    Device::RFXCOM::Response::Sensor->new(device => 'rfxmeter.'.$device,
                                          measurement => 'count',
                                          value => $count);
  return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::RFXCOM::Decoder::RFXMeter - Device::RFXCOM::Decoder::RFXMeter decode RFXMeter RF messages

=head1 VERSION

version 1.163170

=head1 SYNOPSIS

  # see Device::RFXCOM::RX

=head1 DESCRIPTION

Module to recognize RFXMeter RF messages from an RFXCOM RF receiver.

=head1 METHODS

=head2 C<decode( $parent, $message, $bytes, $bits, \%result )>

This method attempts to recognize and decode RF messages from RFXMeter
and RFXPower devices.  If messages are identified, a reference to a
list of message data is returned.  If the message is not recognized,
undef is returned.

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
