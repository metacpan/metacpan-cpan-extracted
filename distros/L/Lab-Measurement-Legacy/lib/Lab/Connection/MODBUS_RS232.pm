package Lab::Connection::MODBUS_RS232;
#ABSTRACT: RS232/RS485 MODBUS RTU connection
$Lab::Connection::MODBUS_RS232::VERSION = '3.899';
use v5.20;

use strict;
use Scalar::Util qw(weaken);
use Time::HiRes qw (usleep sleep);
use Lab::Exception;

our @ISA = ("Lab::Connection");

our %fields = (
    bus_class   => 'Lab::Bus::MODBUS_RS232',
    wait_status => 0,                          # sec;
    wait_query  => 10e-6,                      # sec;
    read_length => 1000,                       # bytes
);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_)
        ;    # getting fields and _permitted from parent class
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    return $self;
}

# this does not really make sense for MODBUS, as there are no "commands" and "responses"
# disable for the time being
# maybe makes sense: write value to one address, wait, read from another address.
sub Query {
    my $self    = shift;
    my $options = undef;
    if   ( ref $_[0] eq 'HASH' ) { $options = shift }
    else                         { $options = {@_} }

    warn
        "Query is not implemented (and makes no sense) for MODBUS connections. Use Read. Ignoring.\n";
    return undef;
}

# 	return undef unless $self->slave_address($self->config()->{'slave_address'});
# 	# check the configuration hash for a valid bus object or bus type, and set the bus
# 	if( defined($self->config()->{'Bus'}) ) {
# 		if($self->_checkbus($self->config()->{'Bus'})) {
# 			$self->Bus($self->config()->{'Bus'});
# 		}
# 		else {
# 			warn('Given Bus not supported');
# 			return undef;
# 		}
# 	}
# 	else {
# 		if($self->_checkbus($self->config()->{'ConnType'})) {
# 			my $ConnType = $self->config()->{'ConnType'};
# 			my $Port = $self->config()->{'Port'};
# 			my $slave_address = $self->config()->{'slave_address'};
# 			my $Interface = "";
# 			if($ConnType eq 'MODBUS_RS232') {
# 				$self->config()->{'Interface'} = 'RS232';
# 				$self->Bus(new Lab::Bus::MODBUS_RS232( $self->config() )) || croak('Failed to create bus');
# 				#$self->Bus(eval("new Lab::Bus::$ConnType( $self->config() )")) || croak('Failed to create bus');
# 			}
# 			else {
# 				warn('Only RS232 bus type supported for now!\n');
# 				return undef;
# 			 }
# 		}
# 		else {
# 			warn('Given Bus Type not supported');
# 			return undef;
# 		}
# 	}

#
# Nothing to do, Read, Write, Query from Lab::Connection are sufficient.
#


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lab::Connection::MODBUS_RS232 - RS232/RS485 MODBUS RTU connection (deprecated)

=head1 VERSION

version 3.899

=head1 CAVEATS/BUGS

Probably few. Mostly because there's not a lot to be done here. Please report.

=head1 SEE ALSO

=over 4

=item * L<Lab::Connection>

=item * L<Lab::Bus::MODBUS_RS232>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2011       Andreas K. Huettel, Florian Olbrich
            2012       Florian Olbrich
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
