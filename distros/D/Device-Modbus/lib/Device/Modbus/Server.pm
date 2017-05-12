package Device::Modbus::Server;

use Device::Modbus;
use Device::Modbus::Request;
use Device::Modbus::Response;
use Device::Modbus::Exception;
use Device::Modbus::Unit;

use Try::Tiny;
use Carp;
use strict;
use warnings;

sub proto {
    return {
        units     => {},
        log_level => 2,
        timeout   => 5,
    };
}

### Unit management

sub units {
    my $self = shift;
    return $self->{units};
}

sub add_server_unit {
    my ($self, $unit, $id) = @_;

    if (ref $unit && $unit->isa('Device::Modbus::Unit')) {
        $unit->init_unit;
        $self->units->{$unit->id} = $unit;
        return $unit;
    }
    else {
        croak "Units must be subclasses of Device::Modbus::Unit";
    }
}

sub get_server_unit {
    my ($self, $unit_id) = @_;
    return $self->units->{$unit_id};
}

# To be overrided in subclasses
sub init_server {
    croak "Server must be initialized\n";
}


### Request parsing

sub receive_request {
    my $self = shift;
    $self->read_port;
    my $adu = $self->new_adu();
    $self->parse_header($adu);
    $self->parse_pdu($adu);
    $self->parse_footer($adu);
    return $adu;
}

sub parse_pdu {
    my ($self, $adu) = @_;
    my $request;
    
    my $code = $self->parse_buffer(1,'C');

    if ($code == 0x01 || $code == 0x02 || $code == 0x03 || $code == 0x04) {
        # Read coils, discrete inputs, holding registers, input registers
        my ($address, $quantity) = $self->parse_buffer(4,'nn');

        $request = Device::Modbus::Request->new(
            code       => $code,
            address    => $address,
            quantity   => $quantity
        );
    }
    elsif ($code == 0x05 || $code == 0x06) {
        # Write single coil and single register
        my ($address, $value) = $self->parse_buffer(4, 'nn');
        if ($code == 0x05 && $value != 0xFF00 && $value != 0) {
            $request = Device::Modbus::Exception->new(
                code           => $code + 0x80,
                exception_code => 3
            );
        }
        else {               
            $request = Device::Modbus::Request->new(
                code       => $code,
                address    => $address,
                value      => $value
            );
        }
    }
    elsif ($code == 0x0F) {
        # Write multiple coils
        my ($address, $qty, $bytes) = $self->parse_buffer(5, 'nnC');
        my $bytes_qty = $qty % 8 ? int($qty/8) + 1 : $qty/8;

        if ($bytes == $bytes_qty) {
            my (@values) = $self->parse_buffer($bytes, 'C*');
            @values      = Device::Modbus->explode_bit_values(@values);

            $request = Device::Modbus::Request->new(
                code       => $code,
                address    => $address,
                quantity   => $qty,
                bytes      => $bytes,
                values     => \@values
            );
        }
        else {
            $request = Device::Modbus::Exception->new(
                code           => $code + 0x80,
                exception_code => 3
            );
        }
    }
    elsif ($code == 0x10) {
        # Write multiple registers
        my ($address, $qty, $bytes) = $self->parse_buffer(5, 'nnC');

        if ($bytes == 2 * $qty) {
            my (@values) = $self->parse_buffer($bytes, 'n*');

            $request = Device::Modbus::Request->new(
                code       => $code,
                address    => $address,
                quantity   => $qty,
                bytes      => $bytes,
                values     => \@values
            );
        }
        else {
            $request = Device::Modbus::Exception->new(
                code           => $code + 0x80,
                exception_code => 3
            );
        }
    }
    elsif ($code == 0x17) {
        # Read/Write multiple registers
        my ($read_addr, $read_qty, $write_addr, $write_qty, $bytes)
            = $self->parse_buffer(9, 'nnnnC');

        if ($bytes == 2 * $write_qty) {
            my (@values) = $self->parse_buffer($bytes, 'n*');

            $request = Device::Modbus::Request->new(
                code           => $code,
                read_address   => $read_addr,
                read_quantity  => $read_qty,
                write_address  => $write_addr,
                write_quantity => $write_qty,
                bytes          => $bytes,
                values         => \@values
            );
        }
        else {
            $request = Device::Modbus::Exception->new(
                code           => $code + 0x80,
                exception_code => 3
            );
        }
    }
    else {
        # Unimplemented function
        $request = Device::Modbus::Exception->new(
            code           => $code + 0x80,
            exception_code => 1,
        );
    }

    $adu->message($request);
    return $request;        
}

### Server code

#    'Read Coils'                    => 0x01,
#    'Read Discrete Inputs'          => 0x02,
#    'Read Holding Registers'        => 0x03,
#    'Read Input Registers'          => 0x04,
#    'Write Single Coil'             => 0x05,
#    'Write Single Register'         => 0x06,
#    'Write Multiple Coils'          => 0x0F,
#    'Write Multiple Registers'      => 0x10,
#    'Read/Write Multiple Registers' => 0x17,

#my %area_and_mode_for = (
my %can_read_zone = (
    0x01 => ['discrete_coils',    'read' ],
    0x02 => ['discrete_inputs',   'read' ],
    0x03 => ['holding_registers', 'read' ],
    0x04 => ['input_registers',   'read' ],
    0x17 => ['holding_registers', 'read' ],
);

my %can_write_zone = (
    0x05 => ['discrete_coils',    'write' ],
    0x06 => ['holding_registers', 'write' ],
    0x0F => ['discrete_coils',    'write' ],
    0x10 => ['holding_registers', 'write' ],
    0x17 => ['holding_registers', 'write' ],
);

sub modbus_server {
    my ($server, $adu) = @_;

    ### Make sure the requested unit exists in this server
    unless (exists $server->units->{$adu->unit}) {
        return $server->request_for_others($adu);
    }
    
    ### Process write requests first
    if (exists $can_write_zone{ $adu->code }) {
        my ($zone, $mode) = @{$can_write_zone{$adu->code}};
        my $resp = $server->process_write_requests($adu, $zone, $mode);
        return $resp if $resp;
    }
    
    ### Process read requests last
    my ($zone, $mode) = @{$can_read_zone{$adu->code}};
    my $resp = $server->process_read_requests($adu, $zone, $mode);
    return $resp;
}

sub process_write_requests {
    my ($server, $adu, $zone, $mode) = @_;

    my $unit = $server->get_server_unit($adu->unit);
    my $code = $adu->code;

    my $address = $adu->message->{address} // $adu->message->{write_address};
    my $values  = $adu->message->{values} // [ $adu->message->{value} ];
    my $quantity = @$values;

    # Find the requested address within unit's addresses
    $server->log(4, "Routing 'write' zone: <$zone> address: <$address> qty: <$quantity>");
    my $match = $unit->route($zone, $mode, $address, $quantity);
    $server->log(4, 'Match was' . (ref $match ? ' ' : ' not ') . 'successful');

    return Device::Modbus::Exception->new(
        function       => $Device::Modbus::function_for{$code},
        exception_code => $match,
        unit           => $adu->unit
    ) unless ref $match;


    # Execute the requested route with the given parameters
    my $response;
    try {
        $match->routine->($unit, $server, $adu->message, $address, $quantity, $values);
    }
    catch {
        $server->log(4,
            "Action failed for 'write' zone: <$zone> address: <$address> quantity: <$quantity> error: $_ ");
        
        $response = Device::Modbus::Exception->new(
            function       => $Device::Modbus::function_for{$code},
            exception_code => 4,
            unit           => $adu->unit
        );
    };
    return $response if defined $response;

    # Build the response
    # Write single values
    if ($code == 0x05 || $code == 0x06) {
        $response = Device::Modbus::Response->new(
            code    => $code,
            address => $address,
            value   => $values->[0]
        );
    }
    # Write multiple values
    elsif ($code == 0x0F || $code == 0x10) {
        $response = Device::Modbus::Response->new(
            code     => $code,
            address  => $address,
            quantity => $quantity
        );
    }
    elsif ($code == 0x17) {
        # 0x17 must perform a read operation afterwards
        $response = '';
    }

    return $response;
}

sub process_read_requests {
    my ($server, $adu, $zone, $mode) = @_;

    my $unit = $server->get_server_unit($adu->unit);
    my $code = $adu->code;

    my $address  = $adu->message->{address} // $adu->message->{write_address};
    my $quantity = $adu->message->{quantity} // $adu->message->{read_quantity};

    $server->log(4, "Routing 'read' zone: <$zone> address: <$address> quantity: <$quantity>");
    my $match = $unit->route($zone, 'read', $address, $quantity);
    $server->log(4,
        'Match was' . (ref $match ? ' ' : ' not ') . 'successful');

    return Device::Modbus::Exception->new(
        function       => $Device::Modbus::function_for{$code},
        exception_code => $match,
        unit           => $adu->unit
    ) unless ref $match;
    
    my @vals;
    my $response;
    try {
        @vals = $match->routine->($unit, $server, $adu->message, $address, $quantity);
        croak 'Quantity of returned values differs from request'
            unless scalar @vals == $quantity;
    }
    catch {
        $server->log(4,
            "Action failed for 'read' zone: <$zone> address: <$address> quantity: <$quantity> -- $_");
        
        $response = Device::Modbus::Exception->new(
            function       => $Device::Modbus::function_for{$code},
            exception_code => 4,
            unit           => $adu->unit
        );
    };

    unless (defined $response) {
        $response = Device::Modbus::Response->new(
            code   => $code,
            values => \@vals
        );
    }
    
    return $response;
}

1;
__END__

=head1 NAME

Device::Modbus::Server - Base class for Device::Modbus server objects

=head1 SYNOPSIS

 #! /usr/bin/env perl
 
 use Device::Modbus::TCP::Server;
 use strict;
 use warnings;
 use v5.10;
 
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

This document describes functionalities common to both Modbus RTU and Modbus TCP servers. Constructors are documented in L<Device::Modbus::RTU::Server> and L<Device::Modbus::TCP::Server>.

First, we will briefly describe the data model inherent to the protocol. This is the base for building the functionalities that the server will expose. Then, these functionalities need to be attached to the server, which must finally be started.

=head1 THE MODBUS DATA MODEL

The Modbus protocol communicates a client with a I<unit> in a server. A unit may offer functionalities in one to four different zones of different types:

=over

=item * Discrete inputs

=item * Discrete outputs (or coils)

=item * Input registers

=item * Holding registers

=back

Client requests are sent to a particular server unit, and they specify the data zone they are directed to, the address which will be affected, and the number of data points they refer to. Write requests include also the transmitted values.

=head1 DEFINING A UNIT

In Device::Modbus, a unit is represented by an object which inherits from Device::Modbus::Unit. Each object maps requests to exposed functions. To execute a function, a request must match its address zone, its set of valid addresses, and the quantity of data that the function can take or return. For example, the unit in the synopsis responds only to requests for reading a single register in address 2 of the Holding registers zone.

To define a unit, you must start with a class that inherits from Device::Modbus::Unit. This class must implement a method called C<init_unit>, which is responsible of defining the mapping to the exposed class methods.

Requests may either I<get> data from the server or they may I<put> data into the server. C<get> and C<put> are the methods used to define the mapping to the functionality exposed by the server. Both methods receive the same arguments: a zone, an address definition, a quantity of data definition, and the name of a class method or a code reference.

I think the best explanation is an example:

 package My::Unit;
 use parent 'Device::Modbus::Unit';
 
 sub init_unit {
     my $unit = shift;
 
     #                Zone            addr qty   method
     #           -------------------  ---- ---  ---------
     $unit->get('holding_registers',    2,  1,  'get_some_data');
     $unit->put('holding_registers',    0,  1,  'save_some_data');
 }

Here, C<init_unit> exposes two methods from C<My::Unit>. C<get_some_data> reacts only to reading requests; C<save_some_data>, to writing requests. They both act on the C<holding_registers> zone. C<get_some_data> will be executed only for requests for a single register at address two; C<save_some_data> reacts to writing requests on address zero, also for a single register.

Let's go over the different arguments for C<get> and C<put>. The zones that you can use are:

=over

=item discrete_coils

Readable and writable; bit-addressable

=item discrete_inputs

Readable only; bit-addressable

=item input_registers

Readable only; register-addressable

=item holding_registers

Readable and writable; register-addressable

=back

Addresses must be between 0 and 65536. However, they can be defined in any of the following ways:

=over

=item - Using a fixed number

=item - Using two numbers separated by a hyphen to define a range

=item - Using a list of comma-separated numbers or ranges

=item - Using an asterisk. The given method responds to all addresses

=back

The next argument, the quantity of data that the class method may receive or return, is defined using the same rules as addresses.

Finally, you can either use the name of a class method, or a code reference to define the functionality exposed by the unit.

These are more examples:

 #                Zone              addr     qty       method
 #           ------------------- ---------  ------ --------------------
 $unit->get('holding_registers',     '1-5',     5,  sub { [ 6 x 5 ] });
 $unit->get('input_registers',   '6-8, 10',     4,  sub { [ 3 x 4 ] });
 $unit->put('holding_registers',        33,     1,  sub { return 19 });
 $unit->put('discrete_coils',            1,   '*',  'save_any';

=head1 CALLING OF UNIT METHODS

Once a request for a given method is received, the server will execute it with the following arguments:

=over

=item unit

A reference to the unit object

=item server

A reference to the server object

=item message

The received request object

=item address

The requested address number

=item quantity

The quantity of data requested

=back

In addition to this, write requests include the values sent by the client in an array reference. For example:

 sub write_data {
     my ($unit, $server, $req, $addr, $qty, $val) = @_;
     ...
 }
 
 sub read_single {
     my ($unit, $server, $req, $addr, $qty) = @_;
     ...
     return $value;
 }
 
 sub read_data {
     my ($unit, $server, $req, $addr, $qty) = @_;
     ...
     return @values;
 }


Note that routines which handle reading requests must return the exact number of requested registers or bits. Values are returned as arrays, not as array references. Register values must be numbers between 0 and 65536; bits are simply true and false values.

=head1 SERVER METHODS

Aside from your unit class, you must instantiate a server. Server construction methods depend on the communication channel that you will be using. L<Device::Modbus::RTU::Server> communicates via the serial port; L<Device::Modbus::TCP::Server> uses TCP/IP sockets. Please read the documentation in those modules to construct your server.

Once your unit class is defined, it must be instantiated and added to a server. Then, the server must be started. From the synopsis:

 my $unit = My::Unit->new(id => 3);
 $server->add_server_unit($unit);
 
 $server->start;

In this example, the unit object is added to the server as unit number three. You can add any number of units to a server.

And that is all it takes.

=head1 SEE ALSO

This module is part of the L<Device::Modbus> distribution. Server constructors are documented in L<Device::Modbus::RTU::Server> and L<Device::Modbus::TCP::Server>.

I have written some examples in my blog, L<http://7mavida.com/tag/Device::Modbus>.

=head1 AUTHOR

Julio Fraire, E<lt>julio.fraire@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Julio Fraire
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

