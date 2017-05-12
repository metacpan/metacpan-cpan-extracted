use strict;
use warnings;
package Device::RFXCOM::Encoder::X10;
$Device::RFXCOM::Encoder::X10::VERSION = '1.163170';
# ABSTRACT: Device::RFXCOM::Encoder::X10 encode X10 RF messages


use 5.006;
use constant DEBUG => $ENV{DEVICE_RFXCOM_ENCODER_X10_DEBUG};
use Carp qw/croak carp/;
use base 'Device::RFXCOM::Encoder';
use Device::RFXCOM::Response::X10;

my %command_to_byte =
  (
   'dim' => 0x98,
   'bright' => 0x88,
   'all_lights_on' => 0x90,
   'all_lights_off' => 0x80,
   'on' => 0x0,
   'off' => 0x20,
  );
my $i = 0;
my %house_to_byte =
  map { $_ => $i++ } ('m', 'n', 'o', 'p', 'c', 'd', 'a', 'b',
                      'e', 'f', 'g', 'h', 'k', 'l', 'i', 'j');

$i = 1;
my %bytes_to_unit =
  map { $_ => $i++ } ( 0x00, 0x10, 0x08, 0x18, 0x40, 0x50, 0x48, 0x58 );
my %unit_to_bytes = reverse %bytes_to_unit;


sub encode {
  my ($self, $parent, $p) = @_;
  my @res = ();
  if ($p->{house}) {
    foreach (split //, $p->{house}) {
      push @res, $self->_encode_x10({
                                     command => $p->{command},
                                     house => $p->{house},
                                    });
    }
  } elsif ($p->{device}) {
    foreach (split /,/, $p->{device}) {
      my ($house, $unit) = /^([a-p])(\d+)$/i or next;
      push @res, $self->_encode_x10({
                                     command => $p->{command},
                                     house => $house,
                                     unit => $unit,
                                    });
    }
  } else {
    carp $self.'->encode: Invalid x10 message';
  }
  return \@res;
}

sub _encode_x10 {
  my ($self, $p) = @_;
  my @bytes = ( 0, 0, 0, 0 );
  $bytes[2] |= $command_to_byte{lc $p->{command}};
  $bytes[0] |= ($house_to_byte{lc $p->{house}})<<4;
  my $unit = $p->{unit};
  unless ($bytes[2]&0x80) {
    if ($unit > 8) {
      $unit -= 8;
      $bytes[0] |= 0x4;
    }
    $bytes[2] |= $unit_to_bytes{$unit};
  }
  $bytes[1] = $bytes[0]^0xff;
  $bytes[3] = $bytes[2]^0xff;
  return { raw => (pack 'C5', 32, @bytes),
           desc =>
           'x10: '.(join '/',
                          grep { defined $_
                               } @{$p}{qw/command house unit/})
         };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::RFXCOM::Encoder::X10 - Device::RFXCOM::Encoder::X10 encode X10 RF messages

=head1 VERSION

version 1.163170

=head1 SYNOPSIS

  # see Device::RFXCOM::RX

=head1 DESCRIPTION

This is a module for encoding RF messages for X10 devices so that they
can be dispatched to an RFXCOM RF transmitter.

=head1 METHODS

=head2 C<encode( $parent, \%params )>

This method constructs the RF message data for a message to send to
a X10 device.

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
