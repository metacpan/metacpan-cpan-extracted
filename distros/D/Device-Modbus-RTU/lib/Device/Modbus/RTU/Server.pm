package Device::Modbus::RTU::Server;

use parent 'Device::Modbus::Server';
use Role::Tiny::With;
use Data::Dumper;
use Carp;
use strict;
use warnings;

with 'Device::Modbus::RTU';

sub new {
    my ($class, %args) = @_;

    my $self = bless { %{$class->proto}, %args}, $class;

    $SIG{INT} = sub {
        $self->log(2, 'Server is shutting down');
        $self->exit;
    };
    
    return $self;    
}

# Simply ignore requests for other units
sub request_for_others {
    return;
}

sub start {
    my $self = shift;

    $self->log(2, 'Starting server');
    $self->open_port;
    $self->{running} = 1;

    while ($self->{running}) {

        my $req_adu;
        eval {
            $req_adu = $self->receive_request;
        };

        if ($@) {
            unless ($@ =~ /^Timeout/) {
                $self->log(2, "Error while receiving a request: $@");
                next;
            }
            else {
                next;
            }
        }

        next unless defined $req_adu && defined $req_adu->message;
        $self->log(4, "> " . Dumper $req_adu);

        # If it is an exception object, we're done
        if ($req_adu->message->isa('Device::Modbus::Exception')) {
            $self->log(3, "Exception while waiting for requests");
            $self->write_port($req_adu);
            next;
        }

        # Process request
        my $resp = $self->modbus_server($req_adu) || next;
        my $resp_adu = $self->new_adu($resp);
        $resp_adu->unit($req_adu->unit);
        $self->log(4, "< " . Dumper $resp_adu);
    
        # And send the response!
        $self->write_port($resp_adu);
    }

    $self->disconnect;
    $self->log(2, 'Server is down: Port is closed');
}

sub exit {
    my $self = shift;
    $self->{running} = 0;
}

# Logger routine. It will simply print messages on STDERR.
# It accepts a logging level and a message. If the level is equal
# or less than $self->log_level, the message is processed.
# To avoid unnecessary processing, messages that require processing can
# be sent in the form of a code reference to minimize performance hits.
# It will add a stringified level, the localtime string
# and caller information.
# It conforms to the interface provided by Net::Server; the subroutine
# idea comes from Log::Log4Perl
my %level_str = (
    0 => 'ERROR',
    1 => 'WARNING',
    2 => 'NOTICE',
    3 => 'INFO',
    4 => 'DEBUG',
);

sub log_level {
    my ($self, $level) = @_;
    if (defined $level) {
        $self->{log_level} = $level;
    }
    return $self->{log_level};
}

sub log {
    my ($self, $level, $msg) = @_;
    return unless $level <= $self->log_level;
    my $time = localtime();
    my ($package, $filename, $line) = caller;

    my $message = ref $msg ? $msg->() : $msg;
    
    print STDOUT
        "$level_str{$level} : $time -- $0 -- $package -- $message\n";
    return 1;
}

1;


__END__

=head1 NAME

Device::Modbus::RTU::Server - Perl server for Modbus RTU communications

=head1 SYNOPSIS

 #! /usr/bin/env perl
 
 use Device::Modbus::RTU::Server;
 use strict;
 use warnings;
 use v5.10;
 
 # This simple server can be tested with an Arduino with the
 # program 'arduino_client.ino' in the examples directory
 
 
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
        say "Executed server routine for address 2, 1 register";
        return 6;
    }
 }
 
 
 my $server = Device::Modbus::RTU::Server->new(
    port      =>  '/dev/ttyACM0',
    baudrate  => 9600,
    parity    => 'none',
    log_level => 4
 );
 
 my $unit = My::Unit->new(id => 3);
 $server->add_server_unit($unit);
 
 $server->start;

=head1 DESCRIPTION

This module is part of L<Device::Modbus::RTU>, a distribution which implements the Modbus RTU protocol on top of L<Device::Modbus>.

Device::Modbus::RTU::Server inherits from L<Device::Modbus::Server>, and adds the capability of communicating via the serial port. As such, Device::Modbus::RTU::Server implements the constructor and a logging method. Please see L<Device::Modbus::Server> for most of the server-related documentation.

=head1 METHODS

=head2 new

This method opens the serial port to communicate using the Modbus RTU protocol. It takes the following arguments:

=over

=item port

The serial port to open.

=item log_level

A number between 0 and 4, where 0 will log only emergencies and 4 will produce sufficient output for debugging. Default is 2.

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

This method closes the serial port, but it is called automatically for you when the server is shut down with a SIG_INT.

=head2 log, log_level

This module will log messages to STDERR. The level of logging is set with the C<log_level> argument to the constructor method. The logging level may be changed also with the method C<log_level>.

C<log> takes two arguments: The level of a message and the message itself:

 $server->log(3, 'This is the text to log');

=head1 SEE ALSO

Most of the functionality is described in L<Device::Modbus::Server>.

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
