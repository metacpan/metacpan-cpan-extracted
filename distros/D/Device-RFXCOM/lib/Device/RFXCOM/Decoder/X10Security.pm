use strict;
use warnings;
package Device::RFXCOM::Decoder::X10Security;
$Device::RFXCOM::Decoder::X10Security::VERSION = '1.163170';
# ABSTRACT: Device::RFXCOM::Decoder::X10Security decode X10 Security RF messages


use 5.006;
use constant DEBUG => $ENV{DEVICE_RFXCOM_DECODER_X10_SECURITY_DEBUG};
use Carp qw/croak/;
use base 'Device::RFXCOM::Decoder';
use Device::RFXCOM::Response::Security;
use Device::RFXCOM::Response::Sensor;


sub decode {
  my ($self, $parent, $message, $bytes, $bits, $result) = @_;
  ($bits == 32 || $bits == 41) or return;

  # bits are not reversed yet!
  (($bytes->[0]^0x0f) == $bytes->[1] && ($bytes->[2]^0xff) == $bytes->[3])
    or return;

  $self->reverse_bits($bytes); # TOFIX: corrupts the input data?

  my $device = sprintf 'x10sec%02x', $bytes->[0];
  my $short_device = $bytes->[0];
  my $data = $bytes->[2];

  my %not_supported_yet =
    (
     # See: http://www.wgldesigns.com/protocols/w800rf32_protocol.txt
     0x70 => 'SH624 arm home (min)',
     #0x60 => 'SH624 arm away (min)',
     0x50 => 'SH624 arm home (max)',
     0x40 => 'SH624 arm away (max)',
     0x41 => 'SH624 disarm',
     0x42 => 'SH624 sec light on',
     0x43 => 'SH624 sec light off',
     0x44 => 'SH624 panic',
    );

  my %x10_security =
    (
     0x60 => ['arm-away', 'min'],
     0x61 => 'disarm',
     0x62 => 'lights-on',
     0x63 => 'lights-off',
    );

  my $command;
  my $tamper;
  my $min_delay;
  my $low_battery;

  if (exists $x10_security{$data}) {
    my $rec = $x10_security{$data};
    if (ref $rec) {
      ($command, $min_delay) = @$rec;
    } else {
      $command = $rec;
    }
  } elsif (exists $not_supported_yet{$data}) {
    warn sprintf "Not supported: %02x %s\n", $data, $not_supported_yet{$data};
    return 1;
  } else {

    my $alert = !($data&0x1);
    $command = $alert ? 'alert' : 'normal';
    $tamper = $data&0x2;
    $min_delay = $data&0x20;
    $low_battery = $data&0x80;
  }

  my %args =
    (
     event => $command,
     device  => $device,
    );
  $args{tamper} = 1 if ($tamper);
  $args{min_delay} = 1 if ($min_delay);
  push @{$result->{messages}},
    Device::RFXCOM::Response::Security->new(%args),
    Device::RFXCOM::Response::Sensor->new(device => $device,
                                          measurement => 'battery',
                                          value => $low_battery ? 10 : 90,
                                          units => '%');
  return 1;
}


sub reverse_bits {
  my $self = shift;
  my $bytes = shift;
  foreach (@$bytes) {
    $_ = unpack 'C',(pack 'B8', (unpack 'b8', (pack 'C',$_)));
  }
  return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::RFXCOM::Decoder::X10Security - Device::RFXCOM::Decoder::X10Security decode X10 Security RF messages

=head1 VERSION

version 1.163170

=head1 SYNOPSIS

  # see Device::RFXCOM::RX

=head1 DESCRIPTION

Module to recognize X10 Security RF messages from an RFXCOM RF receiver.

=head1 METHODS

=head2 C<decode( $parent, $message, $bytes, $bits, \%result )>

This method attempts to recognize and decode RF messages from X10
Security devices.  If messages are identified, a reference to a list of
message data is returned.  If the message is not recognized,
undef is returned.

=head2 C<reverse_bits( \@bytes )>

This method reverses the bits in the bytes.

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
