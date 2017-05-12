use strict;
use warnings;
package Device::RFXCOM::Decoder::OregonScale;
$Device::RFXCOM::Decoder::OregonScale::VERSION = '1.163170';
# ABSTRACT: Device::RFXCOM::Decoder::OregonScale decode Oregon Scale RF messages


use 5.006;
use constant DEBUG => $ENV{DEVICE_RFXCOM_DECODER_OREGON_SCALE_DEBUG};
use Carp qw/croak/;
use Device::RFXCOM::Decoder qw/hi_nibble lo_nibble/;
our @ISA = qw(Device::RFXCOM::Decoder);


sub decode {
  my ($self, $parent, $message, $bytes, $bits, $result) = @_;
  if ($bits == 64 && lo_nibble($bytes->[0]) == 3) {
    return parse_gr101($self, $parent, $message, $bytes, $bits, $result);
  }
  return unless (scalar @$bytes == 7);
  return unless (($bytes->[0]&0xf0) == ($bytes->[5]&0xf0) &&
                 ($bytes->[1]&0xf) == ($bytes->[6]&0xf));
  my $weight =
    sprintf "%x%02x%x", $bytes->[5]&0x1, $bytes->[4], hi_nibble($bytes->[3]);
  return unless ($weight =~ /^\d+$/);
  $weight /= 10;
  my $dev_str = sprintf 'bwr102.%02x', hi_nibble($bytes->[1]);
  my $unknown = sprintf "%x%x", lo_nibble($bytes->[3]), hi_nibble($bytes->[2]);
  push @{$result->{messages}},
    Device::RFXCOM::Response::Sensor->new(device => $dev_str,
                                           measurement => 'weight',
                                           value => $weight,
                                           unknown => $unknown,
                                          );
  return 1;
}


sub parse_gr101 {
  my ($self, $parent, $message, $bytes, $bits, $result) = @_;

  my $weight =
    (lo_nibble($bytes->[4])<<12) + ($bytes->[3]<<4) + ($bytes->[2]>>4);
  $weight = sprintf "%.1f", $weight/400.8;
  my $dev_str = sprintf 'gr101.%02x', $bytes->[1];
  push @{$result->{messages}},
    Device::RFXCOM::Response::Sensor->new(device => $dev_str,
                                          measurement => 'weight',
                                          value => $weight);
  return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::RFXCOM::Decoder::OregonScale - Device::RFXCOM::Decoder::OregonScale decode Oregon Scale RF messages

=head1 VERSION

version 1.163170

=head1 SYNOPSIS

  # see Device::RFXCOM::RX

=head1 DESCRIPTION

Module to recognize Oregon Scale RF messages from an RFXCOM RF receiver.

=head1 METHODS

=head2 C<decode( $parent, $message, $bytes, $bits, \%result )>

This method attempts to recognize and decode RF messages from Oregon
Scientific weighing scales.  If messages are identified, a reference
to a list of message data is returned.  If the message is not
recognized, undef is returned.

=head2 C<parse_gr101( $parent, $message, $bytes, $bits, \%result )>

This method is a helper for the main decode() method that handles the
GR101 scales only.  Parameters and return values are the same as the
decode() method.

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
