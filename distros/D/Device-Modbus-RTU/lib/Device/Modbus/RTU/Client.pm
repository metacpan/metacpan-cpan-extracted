package Device::Modbus::RTU::Client;

use parent 'Device::Modbus::Client';
use Device::Modbus::RTU::ADU;
use Role::Tiny::With;

use Carp;
use strict;
use warnings;

with 'Device::Modbus::RTU';

sub new {
    my ($class, %args) = @_;

    my $self = bless \%args, $class;
    $self->open_port;
    return $self;    
}

1;

__END__

=head1 NAME

Device::Modbus::RTU::Client - Perl client for Modbus RTU communications

=head1 SYNOPSIS

 #! /usr/bin/env perl

 use Device::Modbus::RTU::Client;
 use strict;
 use warnings;
 use v5.10;
 
 my $client = Device::Modbus::RTU::Client->new(
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

This module is part of L<Device::Modbus::RTU>, a distribution which implements the Modbus RTU protocol on top of L<Device::Modbus>.

Device::Modbus::RTU::Client inherits from L<Device::Modbus::Client>, and adds the capability of communicating via the serial port. As such, Device::Modbus::RTU::Client implements the constructor only. Please see L<Device::Modbus::Client> for most of the documentation.

=head1 METHODS

=head2 new

This method opens the serial port to communicate using the Modbus RTU protocol. It takes the following arguments:

=over

=item port

The serial port to open.

=item baudrate

A valid baud rate. Defaults to 9600 bps.

=item databits

An integer from 5 to 8. Defaults to 8.

=item parity

Either 'even', 'odd' or 'none'. Defaults to 'none'.

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

You can find the repository of this distribution in L<GitHub|https://github.com/jfraire/Device-Modbus-RTU>.

=head1 AUTHOR

Julio Fraire, E<lt>julio.fraire@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Julio Fraire
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
