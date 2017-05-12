use strict;
use warnings;
package Device::RFXCOM::Encoder;
$Device::RFXCOM::Encoder::VERSION = '1.163170';
# ABSTRACT: Device::RFXCOM::Encoder base class for encoding RF messages


use 5.006;
use constant DEBUG => $ENV{DEVICE_RFXCOM_ENCODER_DEBUG};
use Carp qw/croak/;

use Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();


sub new {
  my $pkg = shift;
  bless { @_ }, $pkg;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::RFXCOM::Encoder - Device::RFXCOM::Encoder base class for encoding RF messages

=head1 VERSION

version 1.163170

=head1 SYNOPSIS

  # see Device::RFXCOM::RX

=head1 DESCRIPTION

Base class for RFXCOM encoder modules.

=head1 METHODS

=head2 C<new()>

This constructor returns a new encoder object.

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
