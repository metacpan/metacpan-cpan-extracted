package Lab::Connection::GPIB;
#ABSTRACT: GPIB Connection base class
$Lab::Connection::GPIB::VERSION = '3.881';
use v5.20;

#
# This is the GPIB Connection base class. It provides the interface definition for all
# connections implementing the GPIB protocol.
#
# In your scripts, use the implementing classes (e.g. Lab::Connection::LinuxGPIB).
#
# Instruments using a GPIB connection will check the inheritance tree of the provided connection
# for this class.
#
#
# TODO: Access to GPIB attributes, device clear, ...
#

use Lab::Connection;
use strict;
use Lab::Exception;

our @ISA = ("Lab::Connection");

our %fields = (
    bus_class     => undef,    # 'Lab::Bus::LinuxGPIB', 'Lab::Bus::VISA', ...
    gpib_address  => undef,
    gpib_saddress => undef,    # secondary address, if needed
    brutal        => 0,        # brutal as default?
    wait_status   => 0,        # sec;
    wait_query    => 10e-6,    # sec;
    read_length   => 1000,     # bytes
);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_)
        ;    # getting fields and _permitted from parent class
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    # 	# Parameter checking
    # 	if( !defined $self->config('gpib_address') || $self->config('gpib_address') !~ /^[0-9]*$/ ) {
    # 		Lab::Exception::CorruptParameter->throw( error => "No GPIB address specified! I can't work like this.\n" );
    # 	}

    return $self;
}

#
# These are the method stubs you have to overwrite when implementing the GPIB connection for your
# hardware/driver. See documentation for detailed description of the parameters, expected exceptions
# and expected return values.
#
# You might just be satisfied with the generic ones from Lab::Connection, take a look at them.
#

# sub Clear {	# @_ = ()
# 	return 0;
# }

# sub Write { # @_ = ( command => $cmd, wait_status => $wait_status, brutal => 1/0 )
# 	return 0; # status true/false
# }

# sub Read { # @_ = ( read_length => $read_length, brutal => 1/0 )
# 	return 0; # result
# }
# now comes GPIB-specific stuff

sub EnableTermChar {    # 0/1 off/on
    my $self   = shift;
    my $enable = shift;
    my $result = $self->bus()
        ->connection_enabletermchar( $self->connection_handle(), $enable );
    return $result;
}

sub SetTermChar {       # the character as string
    my $self     = shift;
    my $termchar = shift;
    my $result   = $self->bus()
        ->connection_settermchar( $self->connection_handle(), $termchar );
    return $result;
}

#
# perform a serial poll on the bus and return the status byte
# Returns an array with index 0=>LSB, 8=>MSB of the status byte
#
sub serial_poll {
    use bytes;
    my $self     = shift;
    my $statbyte = $self->bus()->serial_poll( $self->connection_handle() );
    my @stat     = ();

    for ( my $i = 0; $i < 8; $i++ ) {
        $stat[$i] = 0x01 & ( $statbyte >> $i );
    }
    return @stat;

    #return (split(//, unpack('b*', pack('N',$self->bus()->serial_poll($self->connection_handle())))))[-8..-1];
}

1;


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lab::Connection::GPIB - GPIB Connection base class

=head1 VERSION

version 3.881

=head1 SYNOPSIS

This is the base class for all connections providing a GPIB interface.
Every inheriting class constructor should start as follows:

	sub new {
		my $proto = shift;
		my $class = ref($proto) || $proto;
		my $self = $class->SUPER::new(@_);
		$self->_construct(__PACKAGE__); #initialize fields etc.
		...
	}

=head1 DESCRIPTION

C<Lab::Connection::GPIB> is the base class for all connections providing a GPIB interface. 
It is not usable on its own. It inherits from L<Lab::Connection>.

Its main use so far is to define the data fields common to all GPIB interfaces.

=head1 CONSTRUCTOR

=head2 new

Generally called in child class constructor:

 my $self = $class->SUPER::new(@_);

Return blessed $self, with @_ accessible through $self->Config().

=head1 METHODS

This just calls back on the methods inherited from Lab::Connection.

If you inherit this class in your own connection however, you have to provide the following methods.
Take a look at e.g. L<Lab::Connection::VISA_GPIB> and at the basic implementations 
in L<Lab::Connection> (they may even suffice).

=head3 Write()

Takes a config hash, has to at least pass the key 'command' correctly to the underlying bus.

=head3 Read()

Takes a config hash, reads back a message from the device.

=head3 Clear()

Clears the instrument.

=head2 config

Provides unified access to the fields in initial @_ to all the child classes.
E.g.

 $GPIB_PAddress=$instrument->Config(GPIB_PAddress);

Without arguments, returns a reference to the complete $self->Config aka @_ of the constructor.

 $Config = $connection->Config();
 $GPIB_PAddress = $connection->Config()->{'GPIB_PAddress'};

=head1 CAVEATS/BUGS

Probably few. Mostly because there's not a lot to be done here. Please report.

=head1 SEE ALSO

=over 4

=item * L<Lab::Connection>

=item * L<Lab::Connection::LinuxGPIB>

=item * L<Lab::Connection::VISA_GPIB>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2011       Andreas K. Huettel, Florian Olbrich
            2012       Alois Dirnaichner, Florian Olbrich, Hermann Kraus, Stefan Geissler
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
