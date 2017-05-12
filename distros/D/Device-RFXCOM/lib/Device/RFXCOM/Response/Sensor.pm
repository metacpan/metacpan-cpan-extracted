use strict;
use warnings;
package Device::RFXCOM::Response::Sensor;
$Device::RFXCOM::Response::Sensor::VERSION = '1.163170';
# ABSTRACT: Device::RFXCOM::Response class for Sensor message from RFXCOM receiver


use 5.006;
use constant DEBUG => $ENV{DEVICE_RFXCOM_RESPONSE_SENSOR_DEBUG};
use Carp qw/croak/;


sub new {
  my ($pkg, %p) = @_;
  bless { %p }, $pkg;
}


sub type { 'sensor' }


sub measurement { shift->{measurement} }


sub device { shift->{device} }


sub value { shift->{value} }


sub units { shift->{units} }


sub summary {
  my $self = shift;
  $self->type.'/'.
    $self->device.'['.$self->measurement.']='.$self->value.($self->units||'');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::RFXCOM::Response::Sensor - Device::RFXCOM::Response class for Sensor message from RFXCOM receiver

=head1 VERSION

version 1.163170

=head1 SYNOPSIS

  # see Device::RFXCOM::RX

=head1 DESCRIPTION

Message class for Sensor messages from an RFXCOM receiver.

=head1 METHODS

=head2 C<new(%params)>

This constructor returns a new response object.

=head2 C<type()>

This method returns 'sensor'.

=head2 C<measurement()>

This method returns a string describing the type of measurement.  For
example, C<temp>, C<humidity>, C<voltage>, C<battery>, C<uv>, etc.

=head2 C<device()>

This method returns a string representing the device that sent the
sensor RF message.

=head2 C<value()>

This method returns the value of the measurement in the sensor RF
message.

=head2 C<units()>

This method returns the units of the value() in the sensor RF message.

=head2 C<summary()>

This method returns a string summary of the sensor message.

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
