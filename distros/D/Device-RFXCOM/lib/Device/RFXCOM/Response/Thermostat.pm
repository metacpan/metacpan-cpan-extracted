use strict;
use warnings;
package Device::RFXCOM::Response::Thermostat;
$Device::RFXCOM::Response::Thermostat::VERSION = '1.163170';
# ABSTRACT: Device::RFXCOM::Response class for Thermostat RF messages


use 5.006;
use constant DEBUG => $ENV{DEVICE_RFXCOM_RESPONSE_THERMOSTAT_DEBUG};
use Carp qw/croak/;


sub new {
  my ($pkg, %p) = @_;
  bless { %p }, $pkg;
}


sub type { 'thermostat' }


sub device { shift->{device} }


sub state { shift->{state} }


sub temp { shift->{temp} }


sub set { shift->{set} }


sub mode { shift->{mode} }


sub summary {
  my $self = shift;
  sprintf('%s/%s=%d/%d/%s/%s',
          $self->type,
          $self->device,
          $self->temp,
          $self->set,
          $self->state,
          $self->mode)
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::RFXCOM::Response::Thermostat - Device::RFXCOM::Response class for Thermostat RF messages

=head1 VERSION

version 1.163170

=head1 SYNOPSIS

  # see Device::RFXCOM::RX

=head1 DESCRIPTION

Message class for Thermostat messages from an RFXCOM receiver.

=head1 METHODS

=head2 C<new(%params)>

This constructor returns a new response object.

=head2 C<type()>

This method returns 'thermostat'.

=head2 C<device()>

This method returns an identifier for the device.

=head2 C<state()>

This method returns the state of the thermostat.  Typical values include:

=over 4

=item undef

If no set point has been defined

=item demand

If heat (or cooling in 'cool' mode) is required.

=item satisfied

If no heat (or cooling in 'cool' mode) is required.

=item init

If the thermostat is being initialized.

=back

=head2 C<temp()>

This method returns the current temperature.

=head2 C<set()>

This method returns the set point for the thermostat.  It will be zero
if it has not been defined.

=head2 C<mode()>

This method returns the mode for the thermostat.  It will be 'heat'
or 'cool'.
`

=head2 C<summary()>

This method returns a string summary of the thermostat message.

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
