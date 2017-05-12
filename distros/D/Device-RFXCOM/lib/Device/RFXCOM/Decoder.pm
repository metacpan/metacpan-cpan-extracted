use strict;
use warnings;
package Device::RFXCOM::Decoder;
$Device::RFXCOM::Decoder::VERSION = '1.163170';
# ABSTRACT: Device::RFXCOM::Decoder base class for decoding RF messages


use 5.006;
use constant DEBUG => $ENV{DEVICE_RFXCOM_DECODER_DEBUG};
use Carp qw/croak/;

use Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(lo_nibble hi_nibble nibble_sum) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();


sub new {
  my $pkg = shift;
  bless { @_ }, $pkg;
}


sub lo_nibble {
  $_[0]&0xf;
}


sub hi_nibble {
  ($_[0]&0xf0)>>4;
}


sub nibble_sum {
  my $s = 0;
  foreach (0..$_[0]-1) {
    $s += $_[1]->[$_];
  }
  return $s;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::RFXCOM::Decoder - Device::RFXCOM::Decoder base class for decoding RF messages

=head1 VERSION

version 1.163170

=head1 SYNOPSIS

  # see Device::RFXCOM::RX

=head1 DESCRIPTION

Base class for RFXCOM decoder modules.

=head1 METHODS

=head2 C<new()>

This constructor returns a new decoder object.

=head2 C<lo_nibble($byte)>

This function returns the low nibble of a byte.  So, for example, given
0x16 it returns 6.

=head2 C<hi_nibble($byte)>

This function returns the hi nibble of a byte.  So, for example, given
0x16 it returns 1.

=head2 C<nibble_sum($count, \@nibbles)>

This function returns the sum of the nibbles of count nibbles.

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
