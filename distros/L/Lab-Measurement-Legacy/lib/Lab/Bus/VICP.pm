package Lab::Bus::VICP;
#ABSTRACT: VICP bus
$Lab::Bus::VICP::VERSION = '3.899';
use v5.20;

use strict;
use Scalar::Util qw(weaken);
use Time::HiRes qw (usleep sleep);
use Lab::Bus;
use Data::Dumper;
use Carp;
use IO::Socket::INET;
use IO::Select;
use Socket qw( SOCK_STREAM SHUT_RDWR MSG_OOB TCP_NODELAY );
use Clone qw(clone);

$Data::Dumper::Useqq = 1;

our @ISA = ("Lab::Bus");

# GPIB status bit vector :
#       global variable ibsta and wait mask
use constant {
    ERR   => ( 1 << 15 ),    # Error detected                  0x8000
    TIMO  => ( 1 << 14 ),    # Timeout                         0x4000
    EOI   => ( 1 << 13 ),    # EOI or EOS detected             0x2000
    SRQI  => ( 1 << 12 ),    # SRQ detected by CIC             0x1000
    RQS   => ( 1 << 11 ),    # Device needs service            0x0800
    SPOLL => ( 1 << 10 ),    # Board has been serially polled  0x0400
    CMPL  => ( 1 << 8 ),     # I/O completed                   0x0100
    REM   => ( 1 << 6 ),     # Remote state                    0x0040
    CIC   => ( 1 << 5 ),     # Controller-in-Charge            0x0020
    ATN   => ( 1 << 4 ),     # Attention asserted              0x0010
    TACS  => ( 1 << 3 ),     # Talker active                   0x0008
    LACS  => ( 1 << 2 ),     # Listener active                 0x0004
    DTAS  => ( 1 << 1 ),     # Device trigger state            0x0002
    DCAS  => ( 1 << 0 ),     # Device clear state              0x0001
};

# GPIB error codes :
#              iberr
use constant {
    EDVR => 0,     # System error
    ECIC => 1,     # Function requires GPIB board to be CIC
    ENOL => 2,     # Write function detected no Listeners
    EADR => 3,     # Interface board not addressed correctly
    EARG => 4,     # Invalid argument to function call
    ESAC => 5,     # Function requires GPIB board to be SAC
    EABO => 6,     # I/O operation aborted
    ENEB => 7,     # Non-existent interface board
    EDMA => 8,     # Error performing DMA
    EOIP => 10,    # I/O operation started before previous operation completed
    ECAP => 11,    # No capability for intended operation
    EFSO => 12,    # File system operation error
    EBUS => 14,    # Command error during device call
    ESTB => 15,    # Serial poll status byte lost
    ESRQ => 16,    # SRQ remains asserted
    ETAB => 20,    # The return buffer is full.
    ELCK => 21,    # Address or board is locked.
};

#  VICP header 'Operation' bits
use constant {
    OPERATION_DATA          => 0x80,
    OPERATION_REMOTE        => 0x40,
    OPERATION_LOCKOUT       => 0x20,
    OPERATION_CLEAR         => 0x10,
    OPERATION_SRQ           => 0x08,
    OPERATION_REQSERIALPOLL => 0x04,
    OPERATION_EOI           => 0x01,
};

use constant {
    HEADER_VERSION1    => 0x01,    # header version
    SERVER_PORT_NUM    => 1861,    # port # for lecroy-vicp
    IO_NET_HEADER_SIZE => 8,       # size of network header
    SMALL_DATA_BUFSIZE => 8192,    # small buffer, combined header+data
};

our %fields = (
    type              => 'VICP',
    brutal            => 0,        # brutal as default?
    wait_query        => 5,        # sec;
    read_length       => 1000,     # bytes
    query_length      => 300,      # bytes
    query_long_length => 10240,    #bytes

    remote_port => SERVER_PORT_NUM,
    remote_addr => undef,
    proto       => 'tcp',
    timeout     => 10,

    _state         => 'NetWaitHeader',
    _remote        => 0,
    _lockout       => 0,
    _iberr         => 0,
    _ibsta         => 0,
    _ibcntl        => 0,
    _errflag       => 0,
    _nextseq       => 1,
    _lastseq       => 1,
    _flushunread   => 1,
    _version1a     => 0,
    _maxblocksize  => 512,
    _maxcommandbuf => 256,
);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_)
        ;    # getting fields and _permitted from parent class
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    $self->remote_addr( $self->config('remote_addr') )
        if defined $self->config('remote_addr');
    $self->remote_port( $self->config('remote_port') )
        if defined $self->config('remote_port');
    $self->proto( $self->config('proto') )
        if defined $self->config('proto');
    $self->timeout( $self->config('timeout') )
        if defined $self->config('timeout');

    # only one VICP connection/device, so don't do 'twins' stuff

    return $self;
}

sub connection_new {    # {
    my $self = shift;
    my $args = undef;
    if ( ref $_[0] eq 'HASH' ) {
        $args = shift;
    }                   # try to be flexible about options as hash/hashref
    else { $args = {@_} }

    croak("remote_addr not specified") unless defined $args->{'remote_addr'};

    my $client = IO::Socket::INET->new(
        PeerAddr => $args->{'remote_addr'} || $self->remote_addr(),
        PeerPort => $args->{'remote_port'} || $self->remote_port(),
        Proto    => $args->{'proto'}       || $self->proto(),
        Timeout  => $args->{'timeout'}     || $self->timeout(),
        Type     => SOCK_STREAM,
    );
    croak("Could not create socket client: $!") unless $client;

    #$client->autoflush(1);
    $client->sockopt(TCP_NODELAY);

    sleep(5);
    croak("did not connect") unless $client->connected();

    my $connection_handle = { valid => 1, type => "VICP", socket => $client };
    return $connection_handle;
}

sub connect {
    my $self              = shift;
    my $connection_handle = shift;
    my $nch = $self->connection_new( remote_addr => $self->remote_addr() );
    $connection_handle->{socket} = $nch->{socket};
    $connection_handle->{valid}  = $nch->{valid};
    $connection_handle->{type}   = $nch->{type};
}

sub disconnect {
    my $self              = shift;
    my $connection_handle = shift;

    return unless defined($connection_handle);
    $connection_handle->{socket}->shutdown(2);
}

# VICP v1a uses an 8 bit 'sequence number' to keep in sync

sub _nextSeq {
    my $self = shift;
    my $eoi = shift || 0;

    $self->{_lastseq} = $self->{_nextseq};
    if ($eoi) {
        $self->{_nextseq}++;
        $self->{_nextseq} = 1 if $self->{_nextseq} > 0xFF;
    }
    return $self->{_lastseq};
}

sub _lastSeq {
    my $self = shift;
    return $self->{_lastseq};
}

# Lecroy VICP has a really weird bug, where commands need to be
# an even number of bytes. Pad with spaces.

sub connection_write
{    # @_ = ( $connection_handle, $args = { command, wait_status }
    my $self              = shift;
    my $connection_handle = shift;
    my $args              = undef;
    if ( ref $_[0] eq 'HASH' ) {
        $args = shift;
    }    # try to be flexible about options as hash/hashref
    else { $args = {@_} }

    my $command = $args->{'command'} || undef;
    my $brutal  = $args->{'brutal'}  || 0;
    my $eoi     = $args->{'eoi'}     || 1;
    my $clr     = $args->{'clr'}     || 0;
    my $poll    = $args->{'poll'}    || 0;

    croak("no command") unless defined $command;
    croak("not connected") unless $connection_handle->{socket}->connected();

    my $nb = $args->{'length'} || length($command);
    croak("zero length command") unless $nb > 0;

    my $cmdlen = $nb;

    if ($eoi) {    # make sure proper termination char, EVEN length
        $command = substr( $command, 0, $nb );
        $command =~ s/(\r\n|\n\r|\r|\n)$//;
        $command .= ' ' if ( length($command) & 1 ) == 0;
        $command .= "\n";
        $nb = length($command);
    }

    if ( $self->{_flushunread} && $self->{_state} ne 'NetWaitHeader' ) {
        $self->connection_read( $connection_handle, flush => 1 );
    }

    $self->{_ibsta} &= (RQS);
    $self->{_ibcntl} = 0;
    $self->{_iberr}  = 0;

    # prepare and send header
    my $hdr = OPERATION_DATA;
    $hdr |= OPERATION_EOI           if $eoi;
    $hdr |= OPERATION_REMOTE        if $self->{_remote};
    $hdr |= OPERATION_CLEAR         if $clr;
    $hdr |= OPERATION_REQSERIALPOLL if $poll;

    my $hbuf = pack(
        'CCCCN', $hdr, HEADER_VERSION1, $self->_nextSeq($eoi), 0,
        $nb
    );

    my $sent;
    if ( $nb >= SMALL_DATA_BUFSIZE ) {
        $sent = $connection_handle->{socket}
            ->send( $hbuf, IO_NET_HEADER_SIZE, 0 );
        if ( !defined($sent) || $sent != IO_NET_HEADER_SIZE ) {
            carp("error sending header packet: $!");
            $self->{_errflag} = 1;
            $self->{_ibsta} |= ERR;
            return 0;
        }
    }
    else {    # if the packet is small combine header with data
        $command = $hbuf . $command;
        $nb += IO_NET_HEADER_SIZE;
    }

    $sent = $connection_handle->{socket}->send( $command, $nb, 0 );
    if ( !defined($sent) || $sent != $nb ) {
        carp("error sending header packet: $!  sent $sent != $nb ?");
        $self->{_errflag} = 1;
        $self->{_ibsta} |= ERR;
        return 0;
    }
    $self->{_ibsta}  = CMPL | CIC | TACS;
    $self->{_ibcntl} = $cmdlen;

    return 1;
}

#
# read the header portion of response

sub _readHeader {
    my $self              = shift;
    my $connection_handle = shift;
    my $args              = undef;
    if ( ref $_[0] eq 'HASH' ) {
        $args = shift;
    }    # try to be flexible about options as hash/hashref
    else { $args = {@_} }

    my $brutal  = $args->{'brutal'}  || 0;
    my $timeout = $args->{'timeout'} || $self->timeout();

    my $hdr = {
        SIZE => 0,
        SEQ  => undef,
        EOI  => 0,
        SRQ  => 0,
        BUF  => '',
    };

    my $sel = IO::Select->new( $connection_handle->{socket} );

    my (@ready) = $sel->can_read($timeout);
    return undef if ( $#ready < 0 );

    my $nb     = 0;
    my $header = '';
    while ( $nb < 8 ) {
        (@ready) = $sel->can_read($timeout);
        last if $#ready < 0;
        my $buf;
        $connection_handle->{socket}
            ->recv( $buf, IO_NET_HEADER_SIZE- $nb, 0 );

        #	print STDERR "hdr buf=",Dumper($buf),"\n";
        if ( length($buf) > 0 ) {
            $nb += length($buf);
            $header .= $buf;
        }
        last if $nb == 0;
    }
    $sel->remove( $connection_handle->{socket} );

    if ( $nb > IO_NET_HEADER_SIZE ) {
        $hdr->{BUF} = substr( $header, IO_NET_HEADER_SIZE );
        $nb = IO_NET_HEADER_SIZE;
    }

    if ( $nb == IO_NET_HEADER_SIZE ) {
        my ( $op, $ver, $seq, $zero, $len ) = unpack( 'CCCCN', $header );
        $hdr->{SIZE} = $len;
        if ( !( ( $op & OPERATION_DATA ) && ( $ver == HEADER_VERSION1 ) ) ) {
            carp("Invalid header");
            $self->{_errflag} = 1;
            $self->disconnect($connection_handle);
            $self->connect($connection_handle);
            return undef;
        }
        $hdr->{EOI} = ( $op & OPERATION_EOI ) == 0 ? 0 : 1;
        $hdr->{SRQ} = ( $op & OPERATION_SRQ ) == 0 ? 0 : 1;
        $hdr->{SEQ} = $seq;
    }
    else {
        # error state out of sync
        $self->disconnect($connection_handle);
        $self->connect($connection_handle);
        return undef;
    }
    return $hdr;
}

# dump data until next header is found
sub _dumpdata {
    my $self              = shift;
    my $connection_handle = shift;
    my $nb                = shift;

    carp("Unread response, dumping $nb bytes");
    while ( $nb > 0 ) {
        my $nr = $self->{_maxblocksize};
        $nr = $nb if $nr > $nb;
        my $buf;
        last
            unless
            defined( $connection_handle->{socket}->recv( $buf, $nr, 0 ) );
        $nb -= length($buf);
    }
}

sub _first {
    my $s = shift;
    my $n = length($s);
    $n = 20 if $n > 20;
    return substr( $s, 0, $n );
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
    my $flush       = $args->{'flush'}       || 0;
    my $timeout     = $args->{'timeout'}     || $self->timeout();
    $read_length = undef;

    if ( !$connection_handle->{socket}->connected() ) {
        carp("socket not connected");
        return undef;
    }

    my $result = '';
    my $eoi    = 0;
    my $srq    = 0;

    $self->{_ibsta} &= (RQS);
    $self->{_ibcntl} = 0;
    $self->{_iberr}  = 0;

    my $nb;
    my $hdr;
    my $size;
    my $read = 0;

    while (1) {
        if ( $self->{_state} eq 'NetWaitHeader' ) {

            $hdr = $self->_readHeader( $connection_handle, $args );
            if ( defined($hdr) ) {
                $self->{_state} = 'NetWaitData';
                $nb             = 0;
                $eoi            = $hdr->{EOI};
                $size           = $hdr->{SIZE};

                #$read += length($hdr->{BUF});
                #$result .= $hdr->{BUF};   # in case appended to header

                my $seq = $hdr->{SEQ};

                #		print STDERR "hdr tot read=$read ",Dumper($hdr,$result),"\n";

                # flush old stuff?
                if (   $self->{_flushread}
                    && $seq != 0
                    && $self->_lastseq() > $seq ) {
                    $self->_dumpdata( $connection_handle, $hdr->{SIZE} );
                    $self->{_state} = 'NetWaitHeader';
                }

                # vicp version 1a has nonzero seq #
                if ( $seq != 0 ) {
                    $self->{_version1a} = 1;
                }
                else {
                    $self->{_version1a} = 0;
                }
            }
            else {
                $self->{_ibsta} |= ERR;
                $self->{_iberr} = TIMO;
                last;
            }
        }

        if ( $self->{_state} eq 'NetWaitData' ) {

            if ($flush) {
                $self->_dumpdata( $connection_handle, $size - $read );
                $self->{_state} = 'NetWaitHeader';
                last;
            }

            my $sel = IO::Select->new( $connection_handle->{socket} );

            my (@ready) = $sel->can_read($timeout);
            if ( $#ready < 0 ) {
                carp("timeout on socket read:$!");
                $self->{_ibsta} |= ERR;
                $self->{_iberr} = TIMO;
                $sel->remove( $connection_handle->{socket} );
                return undef;
            }
            my $got = 0;
            while (1) {
                last if $got >= $size;
                my $buf = '';
                $nb = $size - $got;
                $nb = $self->{_maxblocksize} if $nb > $self->{_maxblocksize};

                (@ready) = $sel->can_read($timeout);
                if ( $#ready < 0 ) {
                    carp("timeout on socket read:$!");
                    $self->{_ibsta} |= ERR;
                    $self->{_iberr} = TIMO;
                    $sel->remove( $connection_handle->{socket} );
                    return undef;
                }

                $connection_handle->{socket}->recv( $buf, $nb, 0 );

                #		print STDERR "try read $nb, got:",Dumper(_first($buf)),"\n";
                if ( length($buf) < 1 ) {
                    carp("socket error on recv $!");
                    $self->{_errflag} = 1;
                    $self->{_state}   = 'NetError';
                    $self->{_ibsta} |= ERR;
                    last;
                }
                $result .= $buf;
                $read += length($buf);
                $got  += length($buf);
            }
            $sel->remove( $connection_handle->{socket} );

            $self->{_state} = 'NetWaitHeader';
            if ( $hdr->{SRQ} ) {    # update srq status, discard packet
                print "SRQ!\n";
                if ( substr( $result, 0, 1 ) eq '1' ) {
                    $self->{_ibsta} |= (RQS);
                }
                else {
                    $self->{_ibsta} &= ~(RQS);
                }
                $result = '';
                next;
            }
            if ($eoi) {
                $self->{_ibsta} |= EOI;
                last;
            }
        }
        if ( $self->{_state} eq 'NetError' ) {
            $self->{_state} = 'NetWaitHeader';
            last;
        }

        #	print STDERR "look for more packets? eoi=$eoi\n";
        last if $eoi;
    }
    $self->{_ibcntl} = length($result);

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

    $self->connection_write( $connection_handle, $args );

    $args->{'timeout'} = $wait_query;
    $result = $self->connection_read( $connection_handle, $args );
    return $result;
}

sub connection_settermchar {    # @_ = ( $connection_handle, $termchar
                                # do nothing
    return 1;
}

sub connection_enabletermchar {    # @_ = ( $connection_handle, 0/1 off/on
                                   # do nothing
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

}

sub timeout {
    my $self              = shift;
    my $connection_handle = shift;
    return $self->{timeout} unless defined $connection_handle;
    my $timo = shift;
    return $self->{timeout} unless defined $timo;

    if ( !defined($timo)
        || $timo !~ /^\s*\+?(\d+|\d+\.\d*|\.\d+)(e[\+\-]?\d+)?\s*/i ) {
        carp("bad value for timeout");
        return;
    }
    $timo += 0;
    $self->{timeout} = $timo;
    $connection_handle->{socket}->timeout($timo);
}

sub ParseIbstatus
{    # Ibstatus http://linux-gpib.sourceforge.net/doc_html/r634.html
    my $self     = shift;
    my $ibstatus = shift;    # 16 Bit int
    my @ibbits   = ();

    if ( $ibstatus !~ /[0-9]*/ || $ibstatus < 0 || $ibstatus > 0xFFFF )
    {                        # should be a 16 bit integer
        carp("Got an invalid Ibstatus");
        return undef;
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
        carp("invalid ibstatus parameter");
        return undef;
    }

    while ( my ( $k, $v ) = each %$ibstatus ) {
        $ibstatus_verbose .= "$k: $v\n";
    }

    return $ibstatus_verbose;
}

1;


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lab::Bus::VICP - VICP bus (deprecated)

=head1 VERSION

version 3.899

=head1 SYNOPSIS

This is the bus class for the VICP connection used for GPIB communication

  my $GPIB = new Lab::Bus::VICP(remote_host=>'myhost' );

or implicit through instrument and connection creation:

  my $instrument = new Lab::Instrument::LeCroy640({
    connection_type => 'VICP',
    remote_addr => 'myhost',
  }

=head1 DESCRIPTION

This module belongs to a deprecated legacy module stack, frozen and not under development anymore. Please port your code to the new API; its documentation can be found on the Lab::Measurement homepage, L<https://www.labmeasurement.de/>.

Note: you don't need to explicitly handle bus objects. The Instruments will create them themselves, and existing bus will
be automagically reused.

=head1 CONSTRUCTOR

=head2 new

 my $bus = new Lab::Bus::VICP(
    remote_addr => $ipaddr
  );

Return blessed $self, with @_ accessible through $self->config().

           ===== TBD below ===

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

  Copyright 2016       Charles Lane
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
