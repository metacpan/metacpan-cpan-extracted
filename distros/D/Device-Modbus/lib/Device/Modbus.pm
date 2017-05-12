package Device::Modbus;

use Carp;
use strict;
use warnings;

our $VERSION = '0.021';

our %code_for = (
    'Read Coils'                    => 0x01,
    'Read Discrete Inputs'          => 0x02,
    'Read Holding Registers'        => 0x03,
    'Read Input Registers'          => 0x04,
    'Write Single Coil'             => 0x05,
    'Write Single Register'         => 0x06,
    'Write Multiple Coils'          => 0x0F,
    'Write Multiple Registers'      => 0x10,
    'Read/Write Multiple Registers' => 0x17,
);

our %function_for = reverse %code_for;

#### Helper methods

# Receives an array reference of bit values and builds an array
# of 8-bit numbers. Each number starts with the lower address
# in the LSB.
# Returns the quantity of bits packed and a reference to the array
# of 8-bit numbers
sub flatten_bit_values {
    my ($self, $values) = @_;

    # Values must be either 1 or 0
    my @values = map { $_ ? 1 : 0 } @{$values};

    # Turn the values array into an array of binary numbers
    my @values_binary;
    while (@values) {
        push @values_binary, pack 'b*', join '', splice @values, 0, 8;
    }
    return \@values_binary;
}

# Receives a quantity of bits and an array of 8-bit numbers.
# The numbers are exploded into an array of bit values.
# The numbers start with the lower address in the LSB,
# and the first number contains the lower address.
# Returns an array of ones and zeros.
sub explode_bit_values {
    my ($self, @values) = @_;
    @values = map {split //, unpack 'b8', pack 'v', $_} @values;
    return @values;
}

1;

__END__

=head1 NAME

Device::Modbus - Perl distribution to implement Modbus communications

=head1 SYNOPSIS

A Modbus RTU client:

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

A Modbus TCP client:

 my $client = Device::Modbus::TCP::Client->new(
     host => '192.168.1.34',
 );

 my $req = $client->read_holding_registers(
     unit     => 3,
     address  => 2,
     quantity => 1
 );

 $client->send_request($req) || die "Send error: $!";
 my $response = $client->receive_response;

A Modbus server:

 use Device::Modbus::TCP::Server;
 
 {
     package My::Unit;
     our @ISA = ('Device::Modbus::Unit');
 
     sub init_unit {
         my $unit = shift;
 
         #                Zone            addr qty   method
         #           -------------------  ---- ---  ---------
         $unit->get('holding_registers',    2,  1,  'get_addr_2');
     }
 
     sub get_addr_2 {
         my ($unit, $server, $req, $addr, $qty) = @_;
         $server->log(4,"Executed server routine for address 2");
         return 6;
     }
 }

 my $server = Device::Modbus::TCP::Server->new(
     log_level => 4,
     log_file  => 'logfile'
 );

 my $unit = My::Unit->new(id => 3);
 $server->add_server_unit($unit);

 $server->start;

=head1 DESCRIPTION

Modbus is an industrial communication protocol. It is implemented by many industrial devices such as servo motors, temperature controllers, force monitors, and Programmable Logic Controllers. Device::Modbus is a set of Perl modules that should allow for writing both Modbus clients and servers.

=head2 The Modbus data model

With Modbus, a I<client> sends I<requests> to a I<server> device, which returns I<responses>. We'll use the term I<unit> when referring a device capable of processing Modbus requests. Most of the time, a unit is one physical device, but a physical device may contain several units. For example, a gateway between different communication protocols may provide several units, and each of these units could represent a physical device down the line. In practice, a unit may be defined as an entity which provides an addressable space.

Data within a unit is accessible through the following addressable tables:

=over

=item * Discrete inputs

=item * Discrete outputs (or coils)

=item * Input registers

=item * Holding registers

=back

Note that discrete outputs are called coils as well. This name makes reference to the automation origin of the protocol, where a coil is the actuator of an electro-mechanical relay.

Tables may even overlay each other. For example, it is not uncommon to address a particular discrete input as a bit of a register address: bit 34 may be the 3rd bit of the 3rd input register. In this distribution, addressable tables are called I<zones>.

To summarize, the Modbus data model breaks a I<unit> into I<zones> in which data is addressable.

Now, Modbus uses Protocol Data Units. The PDUs are the basic blocks defined by the protocol; they are the binary messages that flow between clients and servers. PDUs encapsulate a request from a client or a response from a server. They are independent from the underlying communication layers.

PDUs are further encapsulated into Application Data Units, which add a header and (in the RTU case) a footer with further information as needed for the communication layer. Device::Modbus handles the RTU and the TCP variants of the protocol through L<Device::Modbus::RTU> and L<Device::Modbus::TCP>.

Finally, clients produce requests which are sent to servers, and they receive requests in return. This distribution provides the tools to build both servers and clients.

=head2 Request generalities

Let's talk now about requests. Requests have basically four parameters. The first is implicit in the request code itself, sice each kind of request is directed at a particular zone. The other parameters are the starting address, the number of registers or bits to work on, and, in the case of requests that send information, the data.

For example, we have Read Coil, Write Single Coil and Write Multiple Coils, which refer to the Discrete Outputs zone. As for addresses, a read request for multiple registers that starts at address 1 and demands 5 registers will fetch regiesters 1, 2, 3, 4 and 5. This is true in the vast majority of cases, but see L<Device::Modbus::Unit> for a more general interpretation.

=head1 GUIDE TO THE DOCUMENTATION

The main protocol is described in the following documents:

=over

=item L<Device::Modbus::Client>

=item L<Device::Modbus::Server>

=back

The RTU and TCP variants are implemented in two separate distributions, L<Device::Modbus::RTU> and L<Device::Modbus::TCP>. This way you can install only what is needed for your application.

=head2 Documentation for writing clients

A client must be able to:

=over

=item 1. Open a connection to a server

=item 2. Create request objects

=item 3. Send requests to a server

=item 4. Receive responses to its requests

=item 5. Close the connection to the server

=back

The first point, which depends on the communication layer, is described in L<Device::Modbus::RTU::Client> and L<Device::Modbus::TCP::Client>. Items 2, 3, 4 and 5 are common to all clients, and therefore, they are documented in L<Device::Modbus::Client>. 

=head2 Writing servers

Servers are more complex. They must:

=over

=item 1. Define one or more units, their addressable zones, and implement their functionalities

=item 2. Add those units to a Modbus server

=item 3. Define the interface where the server will listen for connections

=item 4. Start the server

=back

Points 1, 2, and 4 are independent of the communication layer and are documented in L<Device::Modbus::Server>. The documentation for point 3 is in either L<Device::Modbus::RTU::Server> or L<Device::Modbus::TCP::Server>.

=head1 SEE ALSO

You will find some articles and examples in my blog, L<http://7mavida.com/tag/Device::Modbus>.

=head2 Other distributions

These are other implementations of Modbus in Perl which may be well suited for your application:
L<Protocol::Modbus>, L<MBclient>, L<mbserverd|https://github.com/sourceperl/mbserverd>. The first two implement Modbus clients; the third, implements servers.

=head1 GITHUB REPOSITORY

You can find the repository of this distribution in L<GitHub|https://github.com/jfraire/Device-Modbus>.

=head1 AUTHOR

Julio Fraire, E<lt>julio.fraire@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Julio Fraire
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
