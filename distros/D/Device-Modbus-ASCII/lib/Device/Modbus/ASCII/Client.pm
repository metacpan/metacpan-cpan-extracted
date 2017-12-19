package Device::Modbus::ASCII::Client;

use parent 'Device::Modbus::Client';
use Device::Modbus::ASCII::ADU;
use Role::Tiny::With;

use Carp;
use strict;
use warnings;

with 'Device::Modbus::Serial';
with 'Device::Modbus::ASCII';

sub new {
    my ($class, %args) = @_;

    my $self = bless \%args, $class;
    $self->open_port;
    return $self;    
}

# Parse the Application Data Unit
# The Device::Modbus response parsing parts require a binary string,
# and thus the message has to be transformed so that it can be 
# processed. This is easier and far less risky than modifying the
# parse routine that already works correctly for Modbus TCP and RTU.
sub receive_response {
    my $self = shift;
    $self->read_port;
    my $adu = $self->new_adu();
    $self->parse_header($adu);
    
    # Convert the rest of the message to binary form
    my $buffer;
    while (length($self->{buffer}) > 4) {
        $buffer .= pack 'H*', substr $self->{buffer}, 0, 2, '';
    }
    substr $self->{buffer}, 0, -4, $buffer;
    $self->parse_pdu($adu);

    # But turn the LRC and the \r\n back to ascii
    $buffer = unpack 'H*', $self->{buffer};
    $self->parse_footer($adu);

    return $adu;
}


1;

__END__

=head1 NAME

Device::Modbus::ASCII::Client - Modbus ASCII communications for Perl

=head1 SYNOPSIS

 #! /usr/bin/env perl

 use Device::Modbus::ASCII::Client;
 use strict;
 use warnings;
 use v5.10;
 
 my $client = Device::Modbus::ASCII::Client->new(
    port     => '/dev/ttyUSB0',
    baudrate => 19200,
    parity   => 'none',
 );
 
 my $req = $client->read_holding_registers(
    unit     => 4,
    address  => 0,
    quantity => 2,
 );

 $client->send_request($req);
 my $resp = $client->receive_response;
 
 $client->disconnect;

=head1 DESCRIPTION

This module is part of L<Device::Modbus::ASCII>, a distribution which implements the Modbus ASCII protocol on top of L<Device::Modbus>.

Device::Modbus::ASCII::Client inherits from L<Device::Modbus::Client>, and adds the capability of communicating via the serial port using the ASCII version of Modbus. Please see L<Device::Modbus::Client> for most of the documentation.

=head1 METHODS

=head2 new

This method opens the serial port to communicate using the Modbus ASCII protocol. It takes the following arguments:

=over

=item port

The serial port to open.

=item baudrate

A valid baud rate. Defaults to 9600 bps.

=item databits

An integer from 5 to 8. Defaults to 8.

=item parity

Either 'even', 'odd' or 'none'. Defaults to 'even'.

=item stopbits

1 or 2. Defaults to 1.

=item timeout

Defaults to 10 (seconds).

=back

=head2 disconnect

This method closes the serial port:

 $client->disconnect;

=head1 SEE ALSO

Most of the functionality is described in L<Device::Modbus::Client>.

=head2 Other distributions

These are other implementations of Modbus in Perl which may be well suited for your application:
L<Protocol::Modbus>, L<MBclient>, L<mbserverd|https://github.com/sourceperl/mbserverd>.

=head1 GITHUB REPOSITORY

You can find the repository of this distribution in L<GitHub|https://github.com/jfraire/Device-Modbus-ASCII>.

=head1 AUTHOR

Julio Fraire, E<lt>julio.fraire@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Julio Fraire
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

