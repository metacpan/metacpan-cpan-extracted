package Lab::Bus::LinuxGPIB;
#ABSTRACT: LinuxGPIB bus
$Lab::Bus::LinuxGPIB::VERSION = '3.881';
use v5.20;

use strict;
use Scalar::Util qw(weaken);
use Time::HiRes qw (usleep sleep);
use Lab::Bus;
use LinuxGpib ':all';
use Data::Dumper;
use Carp;

our @ISA = ("Lab::Bus");

our %fields = (
    gpib_board        => 0,
    type              => 'GPIB',
    brutal            => 0,        # brutal as default?
    wait_query        => 10e-6,    # sec;
    read_length       => 1000,     # bytes
    query_length      => 300,      # bytes
    query_long_length => 10240,    #bytes
);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $twin  = undef;
    my $self  = $class->SUPER::new(@_)
        ;    # getting fields and _permitted from parent class
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    $self->gpib_board( $self->config()->{'gpib_board'} )
        if ( exists $self->config()->{'gpib_board'} );

    # search for twin in %Lab::Bus::BusList. If there's none, place $self there and weaken it.
    if ( $class eq __PACKAGE__ )
    {        # careful - do only if this is not a parent class constructor
        if ( $twin = $self->_search_twin() ) {
            undef $self;
            return $twin;    # ...and that's it.
        }
        else {
            $Lab::Bus::BusList{ $self->type() }->{ $self->gpib_board() }
                = $self;
            weaken(
                $Lab::Bus::BusList{ $self->type() }->{ $self->gpib_board() }
            );
        }
    }

    return $self;
}

sub connection_new {    # { gpib_address => primary address }
    my $self = shift;
    my $args = undef;
    if ( ref $_[0] eq 'HASH' ) {
        $args = shift;
    }                   # try to be flexible about options as hash/hashref
    else { $args = {@_} }

    if ( !defined $args->{'gpib_address'}
        || $args->{'gpib_address'} !~ /^[0-9]*$/ ) {
        Lab::Exception::CorruptParameter->throw(
                  error => "No valid gpib address given to "
                . __PACKAGE__
                . "::connection_new()\n", );
    }

    my $gpib_address      = $args->{'gpib_address'};
    my $connection_handle = undef;
    my $gpib_handle       = undef;

    # open device
    # see: http://linux-gpib.sourceforge.net/doc_html/r1297.html
    # for timeout constant table: http://linux-gpib.sourceforge.net/doc_html/r2137.html
    # ibdev arguments: board index, primary address, secondary address, timeout (constants, see link), send_eoi, eos (end-of-string character)
    # print "Opening device: " . $gpib_address . "\n";
    $gpib_handle = ibdev( 0, $gpib_address, 0, 12, 1, 0 );

    #ibconfig($gpib_handle, 'IbcEOSrd', 1);

    $connection_handle
        = { valid => 1, type => "GPIB", gpib_handle => $gpib_handle };
    return $connection_handle;
}

#
# Todo: Evaluate $ibstatus: http://linux-gpib.sourceforge.net/doc_html/r634.html
#
sub connection_read
{    # @_ = ( $connection_handle, $args = { read_length, brutal }
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

    my $result        = undef;
    my $fragment      = undef;
    my $raw           = "";
    my $ib_bits       = undef;    # hash ref
    my $ibstatus      = undef;
    my $ibsta_verbose = "";
    my $decimal       = 0;

    $ibstatus
        = ibrd( $connection_handle->{'gpib_handle'}, $result, $read_length );
    $ib_bits = $self->ParseIbstatus($ibstatus);

    while ( !$ib_bits->{'ERR'} && !$ib_bits->{'TIMO'} && !$ib_bits->{'END'} )
    {    # read on until the END status is set (and the whole string received)
        $ibstatus = ibrd(
            $connection_handle->{'gpib_handle'}, $fragment,
            $read_length
        );
        $ib_bits = $self->ParseIbstatus($ibstatus);
        $result .= $fragment;
    }

    if ( $ib_bits->{'ERR'} && !$ib_bits->{'TIMO'} )
    { # if the error is a timeout, we still evaluate the result and see what to do with the error later
        Lab::Exception::GPIBError->throw(
            error => sprintf( "ibrd failed with ibstatus %x\n", $ibstatus ),
            ibsta => $ibstatus,
            ibsta_hash => $ib_bits,
        );
    }

    # strip spaces and null byte
    # note to self: find a way to access the ibcnt variable through the perl binding to use
    # $result = substr($result, 0, $ibcnt)
    $raw = $result;

    #$result =~ /^\s*([+-][0-9]*\.[0-9]*)([eE]([+-]?[0-9]*))?\s*\x00*$/;
    #$result = $1;
    $result =~ s/[\n\r\x00]*$//;

    #
    # timeout occured - throw exception, but include the received data
    # if the "Brutal" option is present, ignore the timeout and just return the data
    #
    if ( $ib_bits->{'ERR'} && $ib_bits->{'TIMO'} && !$brutal ) {
        Lab::Exception::GPIBTimeout->throw(
            error => sprintf(
                "ibrd failed with a timeout, ibstatus %x\n", $ibstatus
            ),
            ibsta      => $ibstatus,
            ibsta_hash => $ib_bits,
            data       => $result
        );
    }

    # no timeout, regular return
    return $result;
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
    my $wait_query  = $args->{'wait_query'}  || $self->wait_query();
    my $result      = undef;

    $self->connection_write($args);

    sleep($wait_query); #<---ensures that asked data presented from the device

    $result = $self->connection_read($args);
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

    my $result        = undef;
    my $raw           = "";
    my $ib_bits       = undef;    # hash ref
    my $ibstatus      = undef;
    my $ibsta_verbose = "";
    my $decimal       = 0;

    if ( !defined $command ) {
        Lab::Exception::CorruptParameter->throw(
                  error => "No command given to "
                . __PACKAGE__
                . "::connection_write().\n", );
    }
    else {
        $ibstatus = ibwrt(
            $connection_handle->{'gpib_handle'},
            $command, length($command)
        );
    }

    $ib_bits = $self->ParseIbstatus($ibstatus);

    # 	foreach my $key ( keys %IbBits ) {
    # 		print "$key: $ib_bits{$key}\n";
    # 	}

    # Todo: better Error checking
    if ( $ib_bits->{'ERR'} == 1 ) {
        if ( $ib_bits->{'TIMO'} == 1 ) {
            Lab::Exception::GPIBTimeout->throw(
                error => sprintf(
                          "Timeout in "
                        . __PACKAGE__
                        . "::connection_write() while executing $command: ibwrite failed with status %x\n",
                    $ibstatus
                    )
                    . Dumper($ib_bits),
                ibsta      => $ibstatus,
                ibsta_hash => $ib_bits,
            );
        }
        else {
            Lab::Exception::GPIBError->throw(
                error => sprintf(
                          "Error in "
                        . __PACKAGE__
                        . "::connection_write() while executing $command: ibwrite failed with status %x\n",
                    $ibstatus
                    )
                    . Dumper($ib_bits),
                ibsta      => $ibstatus,
                ibsta_hash => $ib_bits,
            );
        }
    }

    return 1;
}

sub connection_settermchar {    # @_ = ( $connection_handle, $termchar
    my $self              = shift;
    my $connection_handle = shift;
    my $termchar          = shift;    # string termination character as string

    my $ib_bits  = undef;             # hash ref
    my $ibstatus = undef;

    my $h = $connection_handle->{'gpib_handle'};

    my $arg = ord($termchar);

    $ibstatus = ibconfig( $connection_handle->{'gpib_handle'}, 15, $arg );

    $ib_bits = $self->ParseIbstatus($ibstatus);

    if ( $ib_bits->{'ERR'} == 1 ) {
        Lab::Exception::GPIBError->throw(
            error => sprintf(
                      "Error in "
                    . __PACKAGE__
                    . "::connection_settermchar(): ibeos failed with status %x\n",
                $ibstatus
                )
                . Dumper($ib_bits),
            ibsta      => $ibstatus,
            ibsta_hash => $ib_bits,
        );
    }

    return 1;
}

sub connection_enabletermchar {    # @_ = ( $connection_handle, 0/1 off/on
    my $self              = shift;
    my $connection_handle = shift;
    my $arg               = shift;

    my $ib_bits  = undef;          # hash ref
    my $ibstatus = undef;

    my $h = $connection_handle->{'gpib_handle'};

    $ibstatus = ibconfig( $connection_handle->{'gpib_handle'}, 12, $arg );

    $ib_bits = $self->ParseIbstatus($ibstatus);

    if ( $ib_bits->{'ERR'} == 1 ) {
        Lab::Exception::GPIBError->throw(
            error => sprintf(
                      "Error in "
                    . __PACKAGE__
                    . "::connection_enabletermchar(): ibeos failed with status %x\n",
                $ibstatus
                )
                . Dumper($ib_bits),
            ibsta      => $ibstatus,
            ibsta_hash => $ib_bits,
        );
    }

    return 1;
}

sub serial_poll {
    my $self              = shift;
    my $connection_handle = shift;
    my $sbyte             = undef;

    my $ibstatus = ibrsp( $connection_handle->{'gpib_handle'}, $sbyte );

    my $ib_bits = $self->ParseIbstatus($ibstatus);

    if ( $ib_bits->{'ERR'} == 1 ) {
        Lab::Exception::GPIBError->throw(
            error => sprintf(
                "ibrsp (serial poll) failed with status %x\n",
                $ibstatus
                )
                . Dumper($ib_bits),
            ibsta      => $ibstatus,
            ibsta_hash => $ib_bits,
        );
    }

    return $sbyte;
}

sub connection_clear {
    my $self              = shift;
    my $connection_handle = shift;

    ibclr( $connection_handle->{'gpib_handle'} );
    ibloc( $connection_handle->{'gpib_handle'} );
}

sub timeout {
    my $self              = shift;
    my $connection_handle = shift;
    my $timo              = shift;
    my $timoval           = undef;

    Lab::Exception::CorruptParameter->throw( error =>
            "The timeout value has to be a positive decimal number of seconds, ranging 0-1000.\n"
        )
        if ( $timo !~ /^([+]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/
        || $timo < 0
        || $timo > 1000 );

    if    ( $timo == 0 )    { $timoval = 0 }    # never time out
    if    ( $timo <= 1e-5 ) { $timoval = 1 }
    elsif ( $timo <= 3e-5 ) { $timoval = 2 }
    elsif ( $timo <= 1e-4 ) { $timoval = 3 }
    elsif ( $timo <= 3e-4 ) { $timoval = 4 }
    elsif ( $timo <= 1e-3 ) { $timoval = 5 }
    elsif ( $timo <= 3e-3 ) { $timoval = 6 }
    elsif ( $timo <= 1e-2 ) { $timoval = 7 }
    elsif ( $timo <= 3e-2 ) { $timoval = 8 }
    elsif ( $timo <= 1e-1 ) { $timoval = 9 }
    elsif ( $timo <= 3e-1 ) { $timoval = 10 }
    elsif ( $timo <= 1 )    { $timoval = 11 }
    elsif ( $timo <= 3 )    { $timoval = 12 }
    elsif ( $timo <= 10 )   { $timoval = 13 }
    elsif ( $timo <= 30 )   { $timoval = 14 }
    elsif ( $timo <= 100 )  { $timoval = 15 }
    elsif ( $timo <= 300 )  { $timoval = 16 }
    elsif ( $timo <= 1000 ) { $timoval = 17 }

    my $ibstatus = ibtmo( $connection_handle->{'gpib_handle'}, $timoval );

    my $ib_bits = $self->ParseIbstatus($ibstatus);

    if ( $ib_bits->{'ERR'} == 1 ) {
        Lab::Exception::GPIBError->throw(
            error => sprintf(
                      "Error in "
                    . __PACKAGE__
                    . "::timeout(): ibtmo failed with status %x\n",
                $ibstatus
                )
                . Dumper($ib_bits),
            ibsta      => $ibstatus,
            ibsta_hash => $ib_bits,
        );
    }
}

sub ParseIbstatus
{    # Ibstatus http://linux-gpib.sourceforge.net/doc_html/r634.html
    my $self     = shift;
    my $ibstatus = shift;    # 16 Bit int
    my @ibbits   = ();

    if ( $ibstatus !~ /[0-9]*/ || $ibstatus < 0 || $ibstatus > 0xFFFF )
    {                        # should be a 16 bit integer
        Lab::Exception::CorruptParameter->throw(
            error =>
                'Lab::Bus::GPIB::VerboseIbstatus() got an invalid ibstatus.',
            InvalidParameter => $ibstatus
        );
    }

    for ( my $i = 0; $i < 16; $i++ ) {
        $ibbits[$i] = 0x0001 & ( $ibstatus >> $i );
    }

    my %Ib = ();
    (
        $Ib{'DCAS'}, $Ib{'DTAS'},  $Ib{'LACS'},  $Ib{'TACS'},
        $Ib{'ATN'},  $Ib{'CIC'},   $Ib{'REM'},   $Ib{'LOK'},
        $Ib{'CMPL'}, $Ib{'EVENT'}, $Ib{'SPOLL'}, $Ib{'RQS'},
        $Ib{'SRQI'}, $Ib{'END'},   $Ib{'TIMO'},  $Ib{'ERR'}
    ) = @ibbits;

    return \%Ib;

} # return: ($ERR, $TIMO, $END, $SRQI, $RQS, $SPOLL, $EVENT, $CMPL, $LOK, $REM, $CIC, $ATN, $TACS, $LACS, $DTAS, $DCAS)

sub VerboseIbstatus {
    my $self             = shift;
    my $ibstatus         = shift;
    my $ibstatus_verbose = "";

    if ( ref( \$ibstatus ) =~ /SCALAR/ ) {
        $ibstatus = $self->ParseIbstatus($ibstatus);
    }
    elsif ( ref($ibstatus) !~ /HASH/ ) {
        Lab::Exception::CorruptParameter->throw(
            error =>
                'Lab::Bus::GPIB::VerboseIbstatus() got an invalid ibstatus.',
            InvalidParameter => $ibstatus
        );
    }

    while ( my ( $k, $v ) = each %$ibstatus ) {
        $ibstatus_verbose .= "$k: $v\n";
    }

    return $ibstatus_verbose;
}

#
# search and return an instance of the same type in %Lab::Bus::BusList
#
sub _search_twin {
    my $self = shift;

    if ( !$self->ignore_twins() ) {
        for my $conn ( values %{ $Lab::Bus::BusList{ $self->type() } } ) {
            return $conn if $conn->gpib_board() == $self->gpib_board();
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

Lab::Bus::LinuxGPIB - LinuxGPIB bus

=head1 VERSION

version 3.881

=head1 SYNOPSIS

This is the GPIB bus class for the GPIB library C<linux-gpib> (aka C<libgpib0> in the debian world).

  my $GPIB = new Lab::Bus::LinuxGPIB({ gpib_board => 0 });

or implicit through instrument and connection creation:

  my $instrument = new Lab::Instrument::HP34401A({
    connection_type => 'LinuxGPIB',
    gpib_board => 0,
    gpib_address=>14,
  }

=head1 DESCRIPTION

See L<http://linux-gpib.sourceforge.net/> for details on the LinuxGPIB package. The
package provides both kernel drivers and Perl bindings. Obviously, this will work for Linux systems only. 
On Windows, please use L<Lab::Bus::VISA>. The interfaces are (errr, will be) identical.

Note: you don't need to explicitly handle bus objects. The Instruments will create them themselves, and existing bus will
be automagically reused.

In GPIB, instantiating two bus with identical parameter "gpib_board" will logically lead to the reuse of the first one.
To override this, use the parameter "ignore_twins" at your own risk.

=head1 CONSTRUCTOR

=head2 new

 my $bus = Lab::Bus::GPIB({
    gpib_board => $board_num
  });

Return blessed $self, with @_ accessible through $self->config().

C<gpib_board>: Index of board to use. Can be omitted, 0 is the default.

=head1 Thrown Exceptions

Lab::Bus::GPIB throws

  Lab::Exception::GPIBError
    fields:
    'ibsta', the raw ibsta status byte received from linux-gpib
    'ibsta_hash', the ibsta bit values in a named hash ( 'DCAS' => $val, 'DTAS' => $val, ... ). 
                  Use Lab::Bus::GPIB::VerboseIbstatus() to get a nice string representation

  Lab::Exception::GPIBTimeout
    fields:
    'Data', this is meant to contain the data that (maybe) has been read/obtained/generated despite and up to the timeout.
    ... and all the fields of Lab::Exception::GPIBError

=head1 METHODS

=head2 connection_new

  $GPIB->connection_new({ gpib_address => $paddr });

Creates a new connection ("instrument handle") for this bus. The argument is a hash, whose contents depend on the bus type.
For GPIB at least 'gpib_address' is needed.

The handle is usually stored in an instrument object and given to connection_read, connection_write etc.
to identify and handle the calling instrument:

  $InstrumentHandle = $GPIB->connection_new({ gpib_address => 13 });
  $result = $GPIB->connection_read($self->InstrumentHandle(), { options });

See C<Lab::Instrument::Read()>.

TODO: this is probably not correct anymore

=head2 connection_write

  $GPIB->connection_write( $InstrumentHandle, { Cmd => $Command } );

Sends $Command to the instrument specified by the handle.

=head2 connection_read

  $GPIB->connection_read( $InstrumentHandle, { Cmd => $Command, ReadLength => $readlength, Brutal => 0/1 } );

Sends $Command to the instrument specified by the handle. Reads back a maximum of $readlength bytes. If a timeout or
an error occurs, Lab::Exception::GPIBError or Lab::Exception::GPIBTimeout are thrown, respectively. The Timeout object
carries the data received up to the timeout event, accessible through $Exception->Data().

Setting C<Brutal> to a true value will result in timeouts being ignored, and the gathered data returned without error.

=head2 timeout

  $GPIB->timeout( $connection_handle, $timeout );

Sets the timeout in seconds for GPIB operations on the device/connection specified by $connection_handle.

=head2 config

Provides unified access to the fields in initial @_ to all the child classes.
E.g.

 $GPIB_Address=$instrument->config(gpib_address);

Without arguments, returns a reference to the complete $self->config aka @_ of the constructor.

 $config = $bus->config();
 $GPIB_PAddress = $bus->config()->{'gpib_address'};

=head1 CAVEATS/BUGS

Few. Also, not a lot to be done here.

=head1 SEE ALSO

=over 4

=item

L<Lab::Bus>

=item

L<Lab::Bus::MODBUS>

=item

and many more...

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2011       Andreas K. Huettel, Florian Olbrich
            2012       Florian Olbrich, Hermann Kraus, Stefan Geissler
            2016       Charles Lane, Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
