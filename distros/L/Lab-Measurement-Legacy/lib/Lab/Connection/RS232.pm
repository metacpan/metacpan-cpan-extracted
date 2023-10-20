#
# This is the RS232 Connection base class. It provides the interface definition for all
# connections implementing access via a RS232 line with its typical properties
# (baud rate, stop bits, ...)
#
# In your scripts, use the implementing classes (e.g. Lab::Connection::VISA_RS232).
#
# Instruments using a RS232 connection will check the inheritance tree of the provided connection
# for this class.
#

# TODO: a lot, ...

package Lab::Connection::RS232;
#ABSTRACT: RS232 Connection base class
$Lab::Connection::RS232::VERSION = '3.899';
use v5.20;

use Lab::Connection;
use strict;
use Lab::Exception;

our @ISA = ("Lab::Connection");

our %fields = (
    bus_class   => 'Lab::Bus::RS232',
    port        => undef,
    brutal      => 0,
    read_length => 1000,                # bytes
);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_)
        ;    # getting fields and _permitted from parent class
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    # Parameter checking
    if ( !defined $self->config('port') ) {
        Lab::Exception::CorruptParameter->throw(
            error => "No RS232 port specified! I can't work like this.\n" );
    }

    return $self;
}

#
# These are the method stubs you have to overwrite when implementing the RS232 connection for your
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

# now comes RS232-specific stuff

# Initialization is handled by default by the bus (see e.g. Bus::RS232).
# In some cases when this is not possible it can be done by a derived connection class.

1;


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lab::Connection::RS232 - RS232 Connection base class (deprecated)

=head1 VERSION

version 3.899

=head1 SYNOPSIS

This is the base class for all connections providing a RS232 interface.
Every inheriting class constructor should start as follows:

	sub new {
		my $proto = shift;
		my $class = ref($proto) || $proto;
		my $self = $class->SUPER::new(@_);
		$self->_construct(__PACKAGE__); #initialize fields etc.
		...
	}

=head1 DESCRIPTION

This module belongs to a deprecated legacy module stack, frozen and not under development anymore. Please port your code to the new API; its documentation can be found on the Lab::Measurement homepage, L<https://www.labmeasurement.de/>.

C<Lab::Connection::RS232> is the base class for all connections providing a GPIB interface. 
It is not usable on its own. It inherits from L<Lab::Connection>.

=head1 NAME

Lab::Connection::RS232 - RS232 connection base class

=head1 CONSTRUCTOR

=head2 new

Generally called in child class constructor:

 my $self = $class->SUPER::new(@_);

Return blessed $self, with @_ accessible through $self->Config().

=head1 METHODS

This just calls back on the methods inherited from Lab::Connection.

If you inherit this class in your own connection however, you have to provide the following methods.
Take a look at e.g. L<Lab::Connection::VISA_RS232> and at the basic implementations 
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

=head1 CAVEATS/BUGS

Probably few. Mostly because there's not a lot to be done here. Please report.

=head1 SEE ALSO

=over 4

=item * L<Lab::Connection>

=item * L<Lab::Connection::System_RS232>

=item * L<Lab::Connection::VISA_RS232>

=back

=head1 AUTHOR/COPYRIGHT

 Copyright 2011      Florian Olbrich
           2012      Andreas K. Hüttel

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2012       Andreas K. Huettel
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
