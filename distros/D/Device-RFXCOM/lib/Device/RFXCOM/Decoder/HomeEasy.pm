use strict;
use warnings;
package Device::RFXCOM::Decoder::HomeEasy;
$Device::RFXCOM::Decoder::HomeEasy::VERSION = '1.163170';
# ABSTRACT: Device::RFXCOM::Decoder::HomeEasy decode HomeEasy RF messages


use 5.006;
use constant DEBUG => $ENV{DEVICE_RFXCOM_DECODER_HOMEEASY_DEBUG};
use Carp qw/croak/;
use base 'Device::RFXCOM::Decoder';
use Device::RFXCOM::Response::HomeEasy;


sub decode {
  my ($self, $parent, $message, $bytes, $bits, $result) = @_;

  $bits == 34 or $bits == 38 or return;

  # HomeEasy devices seem to send duplicates with different byte[4] high nibble
  my @b = @{$bytes};
  my $b4 = $b[4];
  $b[4] &= 0xf;
  if ($b[4] != $b4) {
    $result->{key} = $bits.'!'.(pack "C*", @b);
    my $entry = $parent->_cache_get($result);
    if ($entry) {
      $result->{messages} = $entry->{result}->{messages};
      $result->{duplicate} = $parent->_cache_is_duplicate($entry);
      return 1;
    }
    $b[4] = $b4;
  }

  my $res = from_rf($bits, $bytes);

  printf "homeeasy c=%s u=%s a=%x\n",
    $res->{command}, $res->{unit}, $res->{address} if DEBUG;
  my %body = (
              address => (sprintf "%#x",$res->{address}),
              unit => $res->{unit},
              command => $res->{command},
             );

  $body{level} = $res->{level} if ($res->{command} eq 'preset');

  push @{$result->{messages}}, Device::RFXCOM::Response::HomeEasy->new(%body);
  return 1;
}


sub from_rf {
  my $length = shift;
  my $bytes = shift;
  my %p = ();
  $p{address} = ($bytes->[0] << 18) + ($bytes->[1] << 10) +
    ($bytes->[2] << 2) + ($bytes->[3] >> 6);
  my $command = ($bytes->[3] >> 4) & 0x3;
  $p{unit} = ($command & 0x2) ? 'group' : ($bytes->[3] & 0xf);
  if ($length == 38) {
    $p{command} =  'preset';
    $p{level} = $bytes->[4] >> 4;
  } else {
    $p{command} = ($command & 0x1) ? 'on' : 'off';
  }
  return \%p;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::RFXCOM::Decoder::HomeEasy - Device::RFXCOM::Decoder::HomeEasy decode HomeEasy RF messages

=head1 VERSION

version 1.163170

=head1 SYNOPSIS

  # see Device::RFXCOM::RX

=head1 DESCRIPTION

This is a module for decoding RF messages from HomeEasy
(L<http://www.homeeasy.eu/>) devices that have been received by an
RFXCOM RF receiver.

=head1 METHODS

=head2 C<decode( $parent, $message, $bytes, $bits, \%result )>

This method attempts to recognize and decode RF messages from HomeEasy
devices.  If messages are identified, a reference to a list of message
data is returned.  If the message is not recognized, undef is
returned.

=head2 C<from_rf( $bits, $bytes )>

Takes an array reference of bytes from an RF message and converts it
in to an hash reference with the details.

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
