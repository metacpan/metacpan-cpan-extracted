package Lab::Bus::VISA;
#ABSTRACT: National Instruments VISA bus
$Lab::Bus::VISA::VERSION = '3.881';
use v5.20;

use strict;
use Lab::VISA;
use Scalar::Util qw(weaken);
use Time::HiRes qw (usleep sleep);
use Lab::Bus;
use Data::Dumper;
use Carp;

our @ISA = ("Lab::Bus");

our %fields = (
    default_rm        => undef,
    type              => 'VISA',
    brutal            => 0,        # brutal as default?
    wait_status       => 10e-6,    # sec;
    wait_query        => 10e-6,    # sec;
    query_length      => 300,      # bytes
    query_long_length => 10240,    #bytes
    read_length       => 1000      # bytes

);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $twin  = undef;
    my $self  = $class->SUPER::new(@_)
        ;    # getting fields and _permitted from parent class
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    # search for twin in %Lab::Bus::BusList. If there's none, place $self there and weaken it.
    if ( $class eq __PACKAGE__ )
    {        # careful - do only if this is not a parent class constructor
        if ( $twin = $self->_search_twin() ) {
            undef $self;
            return $twin;    # ...and that's it.
        }
        else {
            # no distinction between VISA resource managers yet - need more than one?
            $Lab::Bus::BusList{ $self->type() }->{'default'} = $self;
            weaken( $Lab::Bus::BusList{ $self->type() }->{'default'} );
        }
    }

    my ( $status, $rm ) = Lab::VISA::viOpenDefaultRM();
    if ( $status != $Lab::VISA::VI_SUCCESS ) {
        Lab::Exception::VISAError->throw(
            error => 'Cannot open resource manager: $status\n' );
    }
    $self->default_rm($rm);

    return $self;
}

sub _check_resource_name {    # @_ = ( $resource_name )
    my ( $self, $resname ) = ( shift, shift );
    my $found = undef;

    # check for a valid resource name. let's start with GPIB INSTR (NI-VISA Programmer Reference Manual, P. 276)
    if (
        $resname =~ /^GPIB[0-9]*::[0-9]+(::[0-9]+)?(::INSTR)?$/   # GPIB INSTR
        ) {
        return 1;
    }
    elsif (
        $resname =~ /^ASRL[0-9]+(::INSTR)?$/    # RS232 INSTR
        ) {
        return 1;
    }
    elsif (
        $resname =~ /^TCPIP0?::[0-9\.]*(::INSTR)?$/    # TCP/IP INSTR
        ) {
        return 1;
    }

    return 0;
}

sub connection_new {    # @_ = ({ resource_name => $resource_name })
    my $self              = shift;
    my $args              = undef;
    my $status            = undef;
    my $connection_handle = undef;
    if ( ref $_[0] eq 'HASH' ) {
        $args = shift;
    }                   # try to be flexible about options as hash/hashref
    else { $args = {@_} }
    $self->{config} = $args;

    my $resource_name = $args->{'resource_name'};

    Lab::Exception::CorruptParameter->throw( error =>
            'No resource name given to Lab::Bus::VISA::connection_new().\n' )
        if ( !exists $args->{'resource_name'} );
    Lab::Exception::CorruptParameter->throw( error =>
            'Invalid resource name given to Lab::Bus::VISA::connection_new().\n'
    ) if ( !$self->_check_resource_name( $args->{'resource_name'} ) );

    ( $status, $connection_handle ) = Lab::VISA::viOpen(
        $self->default_rm(), $args->{'resource_name'},
        $Lab::VISA::VI_NULL, $Lab::VISA::VI_NULL
    );
    if ( $status != $Lab::VISA::VI_SUCCESS ) {
        Lab::Exception::VISAError->throw(
            error =>
                "Cannot open VISA instrument \"$resource_name\". Status: $status",
            status => $status
        );
    }

    return $connection_handle;
}

sub connection_read
{    # @_ = ( $connection_handle, $args = { read_length, brutal }
    my $self              = shift;
    my $connection_handle = shift;
    my $args              = undef;
    if ( ref $_[0] eq 'HASH' ) {
        $args = shift;
    }    # try to be flexible about options as hash/hashref
    else { $args = {@_} }

    my $command = $args->{'command'} || undef;
    my $brutal  = $args->{'brutal'}  || $self->brutal();
    my $result_conv       = undef;
    my $read_length       = $args->{'read_length'} || $self->read_length();
    my $timeout           = $args->{'timeout'} || undef;
    my $old_timeout_value = undef;

    my $result   = undef;
    my $status   = undef;
    my $read_cnt = undef;

    if ( defined $timeout ) {
        $self->set_visa_attribute(
            $connection_handle,
            $Lab::VISA::VI_ATTR_TMO_VALUE, $timeout * 1e3
        );
    }

    ( $status, $result, $read_cnt )
        = Lab::VISA::viRead( $connection_handle, $read_length );

    #print "$status,$result,$read_cnt\n";
    #exit;

    if (
        !(
               $status == $Lab::VISA::VI_SUCCESS
            || $status == $Lab::VISA::VI_SUCCESS_TERM_CHAR
            || $status == $Lab::VISA::VI_ERROR_TMO
            || $status > 0
        )
        ) {
        Lab::Exception::VISAError->throw(
            error =>
                "Error in Lab::Bus::VISA::connection_read() while executing $command, Status $status",
            status => $status,
        );
    }
    elsif ( $status == $Lab::VISA::VI_ERROR_TMO && !$brutal ) {
        Lab::Exception::VISATimeout->throw(
            error =>
                "Timeout in Lab::Bus::VISA::connection_read() while executing $command\n",
            status  => $status,
            command => $command,
            data    => $result,
        );
    }

    if ( defined $timeout ) {
        $self->set_visa_attribute(
            $connection_handle,
            $Lab::VISA::VI_ATTR_TMO_VALUE, $self->config('timeout') * 1e3
        );
    }

    $result = substr( $result, 0, $read_cnt );

    return $result;
}

sub connection_write
{    # @_ = ( $connection_handle, $args = { command, wait_status }
    my $self              = shift;
    my $connection_handle = shift;
    my $args              = undef;
    if ( ref $_[0] eq 'HASH' ) {
        $args = shift;
    }    # try to be flexible about options as hash/hashref
    else { $args = {@_} }

    my $command     = $args->{'command'}     || undef;
    my $brutal      = $args->{'brutal'}      || $self->brutal();
    my $read_length = $args->{'read_length'} || $self->read_length();
    my $wait_status = $args->{'wait_status'} || $self->wait_status();

    my $result    = undef;
    my $status    = undef;
    my $write_cnt = 0;
    my $read_cnt  = undef;

    if ( !defined $command ) {
        Lab::Exception::CorruptParameter->throw(
                  error => "No command given to "
                . __PACKAGE__
                . "::connection_write().\n", );
    }
    else {
        ( $status, $write_cnt ) = Lab::VISA::viWrite(
            $connection_handle, $command,
            length($command)
        );

        sleep($wait_status);

        if ( $status != $Lab::VISA::VI_SUCCESS ) {
            Lab::Exception::VISAError->throw(
                error =>
                    "Error in Lab::Bus::VISA::connection_write() while executing $command, Status $status",
                status => $status,
            );
        }

        return $write_cnt;
    }
}

sub connection_query
{ # @_ = ( $connection_handle, $args = { command, read_length, wait_status, wait_query, brutal }
    my $self              = shift;
    my $connection_handle = shift;
    my $args              = undef;
    if ( ref $_[0] eq 'HASH' ) {
        $args = shift;
    }    # try to be flexible about options as hash/hashref
    else { $args = {@_} }

    my $command     = $args->{'command'}     || undef;
    my $brutal      = $args->{'brutal'}      || $self->brutal();
    my $read_length = $args->{'read_length'} || $self->read_length();
    my $wait_status = $args->{'wait_status'} || $self->wait_status();
    my $wait_query  = $args->{'wait_query'}  || $self->wait_query();

    my $result    = undef;
    my $status    = undef;
    my $write_cnt = 0;
    my $read_cnt  = undef;

    $write_cnt = $self->connection_write($args);

    usleep($wait_query)
        ;    #<---ensures that asked data presented from the device

    $result = $self->connection_read($args);
    return $result;
}

sub connection_clear {
    my $self              = shift;
    my $connection_handle = shift;

    while (1) {
        my $result = $self->connection_read(
            $connection_handle,
            { timeout => 0.1, brutal => 1 }
        );
        if ( $result == 0 ) { last; }
    }

}

sub serial_poll {
    my $self              = shift;
    my $connection_handle = shift;

    my ( $ibstatus, $sbyte ) = Lab::VISA::viReadSTB($connection_handle);

    #
    # TODO: VISA status evaluation
    #
    # my $ib_bits=$self->ParseIbstatus($ibstatus);
    #
    # if($ib_bits->{'ERR'}==1) {
    # 	Lab::Exception::GPIBError->throw(
    #		error => sprintf("ibrsp (serial poll) failed with status %x\n", $ibstatus) . Dumper($ib_bits),
    #		ibsta => $ibstatus,
    #		ibsta_hash => $ib_bits,
    #	);
    # }

    return $sbyte;
}

sub timeout {

    my $self              = shift;
    my $connection_handle = shift;
    my $timeout           = shift;

    my $result = Lab::VISA::viSetAttribute(
        $connection_handle,
        $Lab::VISA::VI_ATTR_TMO_VALUE, $timeout * 1e3
    );
    if ( $result != $Lab::VISA::VI_SUCCESS ) {
        print new Lab::Exception::VISAError( error =>
                "Error while setting Visa Attribute Timeout. $result \n" );

    }
    return $result;
}

sub set_visa_attribute {

    my $self              = shift;
    my $connection_handle = shift;
    my $attribute         = shift;
    my $value             = shift;

    if ( defined $value ) {
        my $result = Lab::VISA::viSetAttribute(
            $connection_handle, $attribute,
            $value
        );
        if ( $result != $Lab::VISA::VI_SUCCESS ) {
            print new Lab::Exception::VISAError( error =>
                    "Error while setting Visa Attribute $attribute. $result \n"
            );
        }
        return $result;
    }
    return;
}

#
# calls ibclear() on the instrument - how to do on VISA?
#
#sub connection_clear {
#	my $self = shift;
#	my $connection_handle=shift;
#
#	ibclr($connection_handle->{'gpib_handle'});
#}

#
# search and return an instance of the same type in %Lab::Bus::BusList
#
sub _search_twin {
    my $self = shift;

    # Only one VISA bus for the moment, stored as "default"
    if ( !$self->ignore_twins() ) {
        if ( defined $Lab::Bus::BusList{ $self->type() }->{'default'} ) {
            return $Lab::Bus::BusList{ $self->type() }->{'default'};
        }
    }

    return undef;
}

1;


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lab::Bus::VISA - National Instruments VISA bus

=head1 VERSION

version 3.881

=head1 SYNOPSIS

This is the VISA bus class for the NI VISA library.

  my $visa = new Lab::Bus::VISA();

or implicit through instrument creation:

  my $instrument = new Lab::Instrument::HP34401A({
    BusType => 'VISA',
  }

=head1 DESCRIPTION

soon

=head1 CONSTRUCTOR

=head2 new

 my $bus = Lab::Bus::VISA({
  });

Return blessed $self, with @_ accessible through $self->config().

Options:
none

=head1 Thrown Exceptions

Lab::Bus::VISA throws

  Lab::Exception::VISAError
    fields:
    'status', the raw ibsta status byte received from linux-gpib

  Lab::Exception::VISATimeout
    fields:
    'data', this is meant to contain the data that (maybe) has been read/obtained/generated despite and up to the timeout.
    ... and all the fields of Lab::Exception::GPIBError

=head1 METHODS

=head2 connection_new

  $visa->connection_new({ resource_name => "GPIB0::14::INSTR" });

Creates a new instrument handle for this bus.

The handle is usually stored in an instrument object and given to connection_read, connection_write etc.
to identify and handle the calling instrument:

  $InstrumentHandle = $visa->connection_new({ resource_name => "GPIB0::14::INSTR" });
  $result = $visa->connection_read($self->InstrumentHandle(), { options });

See C<Lab::Instrument::Read()>.

=head2 connection_write

  $visa->connection_write( $InstrumentHandle, { command => $command, wait_status => $wait_status } );

Sends $command to the instrument specified by the handle, and waits $wait_status microseconds before evaluating the status.

=head2 connection_read

  $visa->connection_read( $InstrumentHandle, { command => $command, read_length => $read_length, brutal => 0/1 } );

Sends $Command to the instrument specified by the handle. Reads back a maximum of $readlength bytes. If a timeout or
an error occurs, Lab::Exception::VISAError or Lab::Exception::VISATimeout are thrown, respectively. The Timeout object
carries the data received up to the timeout event, accessible through $Exception->Data().

Setting C<Brutal> to a true value will result in timeouts being ignored, and the gathered data returned without error.

=head2 connection_query

  $visa->connection_query( $InstrumentHandle, { command => $command, read_length => $read_length, wait_status => $wait_status, wait_query => $wait_query, brutal => 0/1 } );

Performs an connection_write followed by an connection_read, each given the supplied parameters. Waits $wait_query microseconds
betweeen Write and Read.

=head1 CAVEATS/BUGS

Few. Not a lot to be done here.

=head1 SEE ALSO

=over 4

=item * L<Lab::Bus::LinuxGPIB>

=item * L<Lab::Bus::MODBUS_RS232>

=item * and many more...

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2010       Andreas K. Huettel
            2011       Andreas K. Huettel, Florian Olbrich
            2012       Alois Dirnaichner, Andreas K. Huettel, Florian Olbrich, Stefan Geissler
            2013       Andreas K. Huettel, Christian Butschkow
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
