package Lab::Connection;
$Lab::Connection::VERSION = '3.899';
#ABSTRACT: Connection base class

use v5.20;

use strict;

#use POSIX; # added for int() function
use Lab::Generic;
use Time::HiRes qw (usleep sleep);

use Carp;
use Data::Dumper;
our $AUTOLOAD;

our @ISA = ('Lab::Generic');

our %fields = (
    connection_handle => undef,
    bus => undef,    # set default here in child classes, e.g. bus => "GPIB"
    bus_class => undef,
    config    => undef,
    type      => undef,    # e.g. 'GPIB'
    ins_debug => 0,        # do we need additional output?
    timeout   => 1,        # in seconds
);

sub new {
    my $proto  = shift;
    my $class  = ref($proto) || $proto;
    my $config = undef;
    if ( ref $_[0] eq 'HASH' ) {
        $config = shift;
    }                      # try to be flexible about options as hash/hashref
    else { $config = {@_} }
    my $self = $class->SUPER::new(@_);
    bless( $self, $class );
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    $self->config($config);

    return $self;
}

#
# generic methods - interface definition
#

sub Clear {
    my $self = shift;

    # do nothing if connection is blocked
    if ( $self->{blocked} ) {
        return undef;
    }

    return $self->bus()->connection_clear( $self->connection_handle() )
        if ( $self->bus()->can('connection_clear') );

    # error message
    warn "Clear function is not implemented in the bus "
        . ref( $self->bus() ) . "\n";
}

sub Write {
    my $self    = shift;
    my $options = undef;
    if   ( ref $_[0] eq 'HASH' ) { $options = shift }
    else                         { $options = {@_} }

    # do nothing if connection is blocked
    if ( $self->{connection_blocked} ) {
        return undef;
    }

    return $self->bus()
        ->connection_write( $self->connection_handle(), $options );
}

sub Read {
    my $self    = shift;
    my $options = undef;
    if   ( ref $_[0] eq 'HASH' ) { $options = shift }
    else                         { $options = {@_} }

    # do nothing if connection is blocked
    if ( $self->{connection_blocked} ) {
        return undef;
    }

    my $result = $self->bus()
        ->connection_read( $self->connection_handle(), $options );

    # cut off all termination characters:
    my $temp = $/;
    if ( ref( $self->config('termchar') ) eq "ARRAY" ) {
        foreach my $term ( @{ $self->config('termchar') } ) {
            $/ = $term;
            chomp($result);
        }
    }
    else {
        $/ = $self->config('termchar');
        chomp($result);
    }
    $/ = $temp;

    return $result;
}

sub BrutalRead {
    my $self    = shift;
    my $options = undef;
    if   ( ref $_[0] eq 'HASH' ) { $options = shift }
    else                         { $options = {@_} }
    $options->{'brutal'} = 1;

    return $self->Read($options);
}

sub Query {
    my $self    = shift;
    my $options = undef;
    if   ( ref $_[0] eq 'HASH' ) { $options = shift }
    else                         { $options = {@_} }

    my $wait_query = $options->{'wait_query'} || $self->wait_query();

    $self->Write($options);
    sleep($wait_query);
    return $self->Read($options);
}

sub LongQuery {
    my $self    = shift;
    my $options = undef;
    if   ( ref $_[0] eq 'HASH' ) { $options = shift }
    else                         { $options = {@_} }

    $options->{read_length} = 10240;
    return $self->Query($options);
}

sub BrutalQuery {
    my $self    = shift;
    my $options = undef;
    if   ( ref $_[0] eq 'HASH' ) { $options = shift }
    else                         { $options = {@_} }

    $options->{brutal} = 1;
    return $self->Query($options);
}

sub timeout {
    my $self = shift;
    my $timo = shift;

    return $self->{'timeout'} if ( !defined $timo );

    $self->{'timeout'} = $timo;
    $self->bus()->timeout( $self->connection_handle(), $timo )
        if defined( $self->bus() )
        ;    # if called by $self->configure() before the bus is created.
}

sub block_connection {
    my $self = shift;

    $self->{connection_blocked} = 1;

}

sub unblock_connection {
    my $self = shift;

    $self->{connection_blocked} = undef;

}

sub is_blocked {
    my $self = shift;

    if ( $self->{connection_blocked} == 1 ) {
        return 1;
    }
    else {
        return 0;
    }

}

#
# infrastructure stuff below
#

#
# Fill $self->device_settings() from config parameters
#
sub configure {
    my $self   = shift;
    my $config = shift;

    if ( ref($config) ne 'HASH' ) {
        Lab::Exception::CorruptParameter->throw(
            error => 'Given Configuration is not a hash.' );
    }
    else {
        #
        # fill matching fields definded in %fields from the configuration hash ($self->config )
        #
        for my $fields_key ( keys %{ $self->{_permitted} } ) {
            {    # restrict scope of "no strict"
                no strict 'refs';
                $self->$fields_key( $config->{$fields_key} )
                    if exists $config->{$fields_key};
            }
        }
    }
}

#
# Call this in inheriting class's constructors to conveniently initialize the %fields object data
#
sub _construct {    # _construct(__PACKAGE__);
    ( my $self, my $package ) = ( shift, shift );
    my $class  = ref($self);
    my $fields = undef;
    {
        no strict 'refs';
        $fields = *${ \( $package . '::fields' ) }{HASH};
    }

    foreach my $element ( keys %{$fields} ) {
        $self->{_permitted}->{$element} = $fields->{$element};
    }
    @{$self}{ keys %{$fields} } = values %{$fields};

    if ( $class eq $package ) {
        $self->configure( $self->config() )
            ;    # so that _setbus has access to all the fields
        $self->_setbus();
        $self->configure( $self->config() )
            ;    # for configuration that needs the bus to be set (timeout())
    }
}

#
# Method to handle bus creation generically. This is called by _construct().
# If the following (rather simple code) doesn't suit your child class, or your need to
# introduce more thorough parameter checking and/or conversion, overwrite it - _construct()
# calls it only if it is called by the topmost class in the inheritance hierarchy itself.
#
# set $self->connection_handle
#
sub _setbus {    # $self->setbus() create new or use existing bus
    my $self      = shift;
    my $bus_class = $self->bus_class();

    $self->bus(
        eval("require $bus_class; new $bus_class(\$self->config());") )
        || Lab::Exception::Error->throw(
              error => "Failed to create bus $bus_class in "
            . __PACKAGE__
            . "::_setbus. Error message was:"
            . "\n\n----------------------------------------------\n\n"
            . "$@\n----------------------------------------------\n" );

    # again, pass it all.
    $self->connection_handle(
        $self->bus()->connection_new( $self->config() ) );
}

sub _configurebus {
    my $self = shift;

    return;
}

#
# config gets it's own accessor - convenient access like $self->config('GPIB_Paddress') instead of $self->config()->{'GPIB_Paddress'}
# with a hashref as argument, set $self->{'config'} to the given hashref.
# without an argument it returns a reference to $self->config (just like AUTOLOAD would)
#
sub config {    # $value = self->config($key);
    ( my $self, my $key ) = ( shift, shift );

    if ( !defined $key ) {
        return $self->{'config'};
    }
    elsif ( ref($key) =~ /HASH/ ) {
        return $self->{'config'} = $key;
    }
    else {
        return $self->{'config'}->{$key};
    }
}

sub AUTOLOAD {

    my $self = shift;
    my $type = ref($self) or croak "$self is not an object";

    my $name = $AUTOLOAD;
    $name =~ s/.*://;    # strip fully qualified portion

    unless ( exists $self->{_permitted}->{$name} ) {
        Lab::Exception::Error->throw( error => "AUTOLOAD in "
                . __PACKAGE__
                . " couldn't access field '${name}'.\n" );
    }

    if (@_) {
        return $self->{$name} = shift;
    }
    else {
        return $self->{$name};
    }
}

# needed so AUTOLOAD doesn't try to call DESTROY on cleanup and prevent the inherited DESTROY
sub DESTROY {
    my $self = shift;
    $self->SUPER::DESTROY if $self->can("SUPER::DESTROY");
}

1;


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lab::Connection - Connection base class (deprecated)

=head1 VERSION

version 3.899

=head1 SYNOPSIS

This is the base class for all connections.
Every inheriting classes constructors should start as follows:

	sub new {
		my $proto = shift;
		my $class = ref($proto) || $proto;
		my $self = $class->SUPER::new(@_);
		$self->_construct(__PACKAGE__); #initialize fields etc.
		...
	}

=head1 DESCRIPTION

This module belongs to a deprecated legacy module stack, frozen and not under development anymore. Please port your code to the new API; its documentation can be found on the Lab::Measurement homepage, L<https://www.labmeasurement.de/>.

C<Lab::Connection> is the base class for all connections and implements a generic set of 
access methods. It doesn't do anything on its own.

A connection in general is an object which is created by an instrument and provides it 
with a generic set of methods to talk to its hardware counterpart.
For example L<Lab::Instrument::HP34401A> can work with any connection of the type GPIB, 
that is, connections derived from Lab::Connection::GPIB.

That would be, for example
  Lab::Connection::LinuxGPIB
  Lab::Connection::VISA_GPIB

Towards the instrument, these look the same, but they work with different drivers/backends.

=head1 CONSTRUCTOR

=head2 new

Generally called in child class constructor:

 my $self = $class->SUPER::new(@_);

Return blessed $self, with @_ accessible through $self->Config().

=head1 METHODS

=head2 Clear

Try to clear the connection, if the bus supports it.

=head2 Read

  my $result = $connection->Read();
  my $result = $connection->Read( timeout => 30 );

  configuration hash options:
   brutal => <1/0>   # suppress timeout errors if set to 1
   read_length => <int>   # how many bytes/characters to read
   ...see bus documentation

Reads a string from the connected device. In this basic form, its merely a wrapper to the
method connection_read() of the used bus.
You can give a configuration hash, which options are passed on to the bus.
This hash is also meant for options to Read itself, if need be.

=head2 Write

  $connection->Write( command => '*CLS' );

  configuration hash options:
   command => <command string>
   ...more (see bus documentation)

Write a command string to the connected device. In this basic form, its merely a wrapper to the
method connection_write() of the used bus.
You need to supply a configuration hash, with at least the key 'command' set.
This hash is also meant for options to Read itself, if need be.

=head2 Query

  my $result = $connection->Query( command => '*IDN?' );

  configuration hash options:
   command => <command string>
   wait_query => <wait time between read and write in seconds>   # overwrites the connection default
   brutal => <1/0>   # suppress timeout errors if set to true
   read_length => <int>   # how many bytes/characters to read
   ...more (see bus documentation)

Write a command string to the connected device, and immediately read the response.

You need to supply a configuration hash with at least the 'command' key set.
The wait_query key sets the time to wait between read and write in usecs.
The hash is also passed along to the used bus methods.

=head2 BrutalRead

The same as read with the 'brutal' option set to 1.

=head2 BrutalQuery

The same as Query with the 'brutal' option set to 1.

=head2 LongQuery

The same as Query with 'read_length' set to 10240.

=head2 config

Provides unified access to the fields in initial @_ to all the cild classes.
E.g.

 $GPIB_Address=$instrument->Config(gpib_address);

Without arguments, returns a reference to the complete $self->Config aka @_ of the constructor.

 $Config = $connection->Config();
 $GPIB_Address = $connection->Config()->{'gpib_address'};

=head1 CAVEATS/BUGS

Probably few. Mostly because there's not a lot to be done here. Please report.

=head1 SEE ALSO

=over 4

=item * L<Lab::Connection::GPIB>

=item * L<Lab::Connection::VISA_GPIB>

=item * L<Lab::Connection::MODBUS>

=item * and all the others...

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2010-2011  Andreas K. Huettel, Florian Olbrich
            2012       Florian Olbrich, Hermann Kraus, Stefan Geissler
            2013       Alois Dirnaichner, Christian Butschkow, Stefan Geissler
            2014       Alexei Iankilevitch
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2019       Simon Reinhardt
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
