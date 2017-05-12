# Device::Modem::Protocol::Xmodem - Xmodem file transfer protocol for Device::Modem class
#
# Initial revision: 1 Oct 2003
#
# Copyright (C) 2003-2005 Cosimo Streppone, cosimo@cpan.org
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Additionally, this is ALPHA software, still needs extensive
# testing and support for generic AT commads, so use it at your own risk,
# and without ANY warranty! Have fun.
#
# This Xmodem protocol version is indeed very alpha code,
# probably does not work at all, so stay tuned...
#
# $Id$

package Xmodem::Constants;

# Define constants used in xmodem blocks
sub nul        () { 0x00 } # ^@
sub soh        () { 0x01 } # ^A
sub stx        () { 0x02 } # ^B
sub eot        () { 0x04 } # ^D
sub ack        () { 0x06 } # ^E
sub nak        () { 0x15 } # ^U
sub can        () { 0x18 } # ^X
sub C          () { 0x43 }
sub ctrl_z     () { 0x1A } # ^Z

sub CHECKSUM   () { 1 }
sub CRC16      () { 2 }
sub CRC32      () { 3 }

sub XMODEM     () { 0x01 }
sub XMODEM_1K  () { 0x02 }
sub XMODEM_CRC () { 0x03 }

#sub YMODEM     () { 0x04 }
#sub ZMODEM     () { 0x05 }

package Xmodem::Block;

use overload q[""] => \&to_string;

# Create a new block object
sub new {
    my($proto, $num, $data, $length) = @_;
    my $class = ref $proto || $proto;

    # Define block type (128 or 1k chars) if not specified
    $length ||= ( length $data > 128 ? 1024 : 128 );

    # Define structure of a Xmodem transfer block object
    my $self = {
        number  => defined $num ? $num : 0,
        'length'=> $length,
        data    => defined $data ? substr($data, 0, $length) : "",      # Blocks are limited to 128 or 1024 chars
      };

    bless $self, $class;
}

# Calculate checksum of current block data
sub checksum {
    my $self = $_[0];
    my $sum  = 0;
    foreach my $c ( $self->data() ) {
        $sum += ord $c;
        $sum %= 256;
    }
    return $sum % 256;
}

# Calculate CRC 16 bit on block data
sub crc16 {
    my $self = $_[0];
    return unpack('%C16*' => $self->data()) % 65536;
}

# Calculate CRC 32 bit on block data
sub crc32 {
    my $self = $_[0];
    return unpack('%C32' => $self->data());
}

# Return data one char at a time
sub data {
    my $self = $_[0];
    return wantarray
      ? split(//, $self->{data})
      : substr($self->{data}, 0, $self->{'length'})
}

sub number {
    my $self = $_[0];
    return $self->{number};
}

# Calculate checksum/crc for the current block and stringify block for transfer
sub to_string {
    my $self = $_[0];
    my $block_num = $self->number();

    # Assemble block to be transferred
    my $xfer = pack(

        'cccA'.$self->{'length'}.'c',

        $self->{'length'} == 128
        ? Xmodem::Constants::soh   # Start Of Header (block size = 128)
        : Xmodem::Constants::stx,  # Start Of Text   (block size = 1024)

        $block_num,                    # Block number

        $block_num ^ 0xFF,             # 2's complement of block number

        scalar $self->data,            # Data chars

        $self->checksum()              # Final checksum (or crc16 or crc32)
          # TODO crc16, crc32 ?
      );

    return $xfer;
}

#
# verify( type, value )
# ex.: verify( 'checksum', 0x7F )
# ex.: verify( 'crc16', 0x8328 )
#
sub verify {
    my($self, $type, $value) = @_;

    # Detect type of value to be checked

    # TODO use new constants

    $type = 'checksum' unless defined $type;

    if( $type eq 'checksum' ) {
        $good_value = $self->checksum();
    } elsif( $type eq 'crc16' ) {
        $good_value = $self->crc16();
    } elsif( $type eq 'crc32' ) {
        $good_value = $self->crc32();
    } else {
        $good_value = $self->checksum();
    }
    print 'value:', $value, 'goodvalue:', $good_value;
    return $good_value == $value;
}

# ----------------------------------------------------------------

package Xmodem::Buffer;

sub new {
    my($proto, $num, $data) = @_;
    my $class = ref $proto || $proto;

    # Define structure of a Xmodem transfer buffer
    my $self = [];
    bless($self);
    return $self;
}

# Push, pop, operations on buffer
sub push {
    my $self  = $_[0];
    my $block = $_[1];
    push @$self, $block;
}

sub pop {
    my $self = $_[0];
    pop @$self
}

# Get last block on buffer (to retransmit / re-receive)
sub last {
    my $self = $_[0];
    return $self->[ $#$self ];
}

sub blocks {
    return @{$_[0]};
}

#
# Replace n-block with given block object
#
sub replace {
    my $self  = $_[0];
    my $num   = $_[1];
    my $block = $_[2];

    $self->[$num] = $block;
}

sub dump {
    my $self = $_[0];
    my $output;

    # Join all blocks into string
    for (my $pos = 0; $pos < scalar($self->blocks()); $pos++) {
        $output .= $self->[$pos]->data();
    }

    # Clean out any end of file markers (^Z) in data
    $output =~ s/\x1A*$//;

    return $output;
}

# ----------------------------------------------------------------

package Xmodem::Receiver;

# Define default timeouts for CRC handshaking stage and checksum normal procedure
sub TIMEOUT_CRC      () {  3 };
sub TIMEOUT_CHECKSUM () { 10 };

our $TIMEOUT = TIMEOUT_CRC;
our $DEBUG   = 1;

sub abort_transfer {
    my $self = $_[0];

    # Send a cancel char to abort transfer
    _log('aborting transfer');
    $self->modem->atsend( chr(Xmodem::Constants::can) );
    $self->modem->port->write_drain() unless $self->modem->ostype() eq 'windoze';
    $self->{aborted} = 1;
    return 1;
}

#
# TODO protocol management
#
sub new {
    my $proto = shift;
    my %opt   = @_;
    my $class = ref $proto || $proto;

    # Create `modem' object if does not exist
    _log('opt{modem} = ', $opt{modem});
    if( ! exists $opt{modem} ) {
        require Device::Modem;
        $opt{modem} = Device::Modem->new();
    }

    my $self = {
        _modem    => $opt{modem},
        _filename => $opt{filename} || 'received.dat',
        current_block => 0,
        timeouts  => 0,
      };

    bless $self, $class;
}

# Get `modem' Device::SerialPort member
sub modem {
    $_[0]->{_modem};
}

#
# Try to receive a block. If receive is correct, push a new block on buffer
#
sub receive_message {
    my $self = $_[0];
    my $message_type;
    my $message_number = 0;
    my $message_complement = 0;
    my $message_data;
    my $message_checksum;

    # Receive answer
    #my $received = $self->modem->answer( undef, 1000 );
    #my $received = $self->modem->answer( "/.{132}/", 1000 );
    # Had problems dropping bytes from block messages  that caused the checksum
    # to be missing on rare occasions.
    ($count_in, $received) = $self->modem->port->read(132);

    _log('[receive_message][', $count_in, '] received [', unpack('H*',$received), '] data');

    # Get Message Type
    $message_type = ord(substr($received, 0, 1));

    # If this is a block extract data from message
    if( $message_type eq Xmodem::Constants::soh ) {

        # Check block number and its 2's complement
        ($message_number, $message_complement) = ( ord(substr($received,1,1)), ord(substr($received,2,1)) );

        # Extract data string from message
        $message_data = substr($received,3,128);

        # Extract checksum from message
        $message_checksum = ord(substr($received, 131, 1));
    }

    my %message = (
        type       => $message_type,        # Message Type
        number     => $message_number,      # Message Sequence Number
        complement => $message_complement,  # Message Number's Complement
        data       => $message_data,        # Message Data String
        checksum   => $message_checksum,    # Message Data Checksum
      );

    return %message;
}

sub run {
    my $self  = $_[0];
    my $modem = $self->{_modem};
    my $file  = $_[1] || $self->{_filename};
    my $protocol = $_[2] || Xmodem::Constants::XMODEM;

    _log('[run] checking modem[', $modem, '] or file[', $file, '] members');
    return 0 unless $modem and $file;

    # Initialize transfer
    $self->{current_block} = 0;
    $self->{timeouts}      = 0;

    # Initialize a receiving buffer
    _log('[run] creating new receive buffer');

    my $buffer = Xmodem::Buffer->new();

    # Stage 1: handshaking for xmodem standard version
    _log('[run] sending first timeout');
    $self->send_timeout();

    my $file_complete = 0;

    $self->{current_block} = Xmodem::Block->new(0);

    # Open output file
    return undef unless open OUTFILE, '>'.$file;

    # Main receive cycle (subsequent timeout cycles)
    do {

        # Try to receive a message
        my %message = $self->receive_message();

        if ( $message{type} eq Xmodem::Constants::nul ) {

            # Nothing received yet, do nothing
            _log('[run] <NUL>', $message{type});
        } elsif ( $message{type} eq Xmodem::Constants::eot ) {

            # If last block transmitted mark complete and close file
            _log('[run] <EOT>', $message{type});

            # Acknoledge we received <EOT>
            $self->send_ack();
            $file_complete = 1;

            # Write buffer data to file
            print(OUTFILE $buffer->dump());

            close OUTFILE;
        } elsif ( $message{type} eq Xmodem::Constants::soh ) {

            # If message header, check integrity and build block
            _log('[run] <SOH>', $message{type});
            my $message_status = 1;

            # Check block number
            if ( (255 - $message{complement}) != $message{number} ) {
                _log('[run] bad block number: ', $message{number}, ' != (255 - ', $message{complement}, ')' );
                $message_status = 0;
            }

            # Check block numbers for out of sequence blocks
            if ( $message{number} < $self->{current_block}->number() || $message{number} > ($self->{current_block}->number() + 1) ) {
                _log('[run] bad block sequence');
                $self->abort_transfer();
            }

            # Instance a new "block" object from message data received
            my $new_block = Xmodem::Block->new( $message{number}, $message{data} );

            # Check block against checksum
            if (!( defined $new_block && $new_block->verify( 'checksum', $message{checksum}) )) {
                _log('[run] bad block checksum');
                $message_status = 0;
            }

        # This message block was good, update current_block and push onto buffer
            if ($message_status) {
                _log('[run] received block ', $new_block->number());

                # Update current block to the one received
                $self->{current_block} = $new_block;

                # Push block onto buffer
                $buffer->push($self->{current_block});

                # Acknoledge we successfully received block
                $self->send_ack();

            } else {

                # Send nak since did not receive block successfully
                _log('[run] message_status = 0, sending <NAK>');
                $self->send_nak();
            }
        } else {
            _log('[run] neither types found, sending timingout');
            $self->send_timeout();
        }

      } until $file_complete or $self->timeouts() >= 10;
}

sub send_ack {
    my $self = $_[0];
    _log('sending ack');
    $self->modem->atsend( chr(Xmodem::Constants::ack) );
    $self->modem->port->write_drain();
    $self->{timeouts} = 0;
    return 1;
}

sub send_nak {
    my $self = $_[0];
    _log('sending timeout (', $self->{timeouts}, ')');
    $self->modem->atsend( chr(Xmodem::Constants::nak) );

    my $received = $self->modem->answer( undef, TIMEOUT_CHECKSUM );

    _log('[nak_dump] received [', unpack('H*',$received), '] data');

    $self->modem->port->write_drain();
    $self->{timeouts}++;
    return 1;
}

sub send_timeout {
    my $self = $_[0];
    _log('sending timeout (', $self->{timeouts}, ')');
    $self->modem->atsend( chr(Xmodem::Constants::nak) );
    $self->modem->port->write_drain();
    $self->{timeouts}++;
    return 1;
}

sub timeouts {
    my $self = $_[0];
    $self->{timeouts};
}

sub _log {
    print STDERR @_, "\n" if $DEBUG
}

1;

=head1 NAME

Device::Modem::Protocol::Xmodem

=head1 Xmodem::Block

Class that represents a single Xmodem data block.

=head2 Synopsis

	my $b = Xmodem::Block->new( 1, 'My Data...<until-128-chars>...' );
	if( defined $b ) {
		# Ok, block instanced, verify its checksum
		if( $b->verify( 'checksum', <my_chksum> ) ) {
			...
		} else {
			...
		}
	} else {
		# No block
	}

	# Calculate checksum, crc16, 32, ...
	$crc16 = $b->crc16();
	$crc32 = $b->crc32();
	$chksm = $b->checksum();

=head1 Xmodem::Buffer

Class that implements an Xmodem receive buffer of data blocks. Every block of data
is represented by a C<Xmodem::Block> object.

Blocks can be B<push>ed and B<pop>ped from the buffer. You can retrieve the B<last>
block, or the list of B<blocks> from buffer.

=head2 Synopsis

	my $buf = Xmodem::Buffer->new();
	my $b1  = Xmodem::Block->new(1, 'Data...');

	$buf->push($b1);

	my $b2  = Xmodem::Block->new(2, 'More data...');
	$buf->push($b2);

	my $last_block = $buf->last();

	print 'now I have ', scalar($buf->blocks()), ' in the buffer';

	# TODO document replace() function ???

=head1 Xmodem::Constants

Package that contains all useful Xmodem protocol constants used in handshaking and
data blocks encoding procedures

=head2 Synopsis

	Xmodem::Constants::soh ........... 'start of header'
	Xmodem::Constants::eot ........... 'end of trasmission'
	Xmodem::Constants::ack ........... 'acknowlegded'
	Xmodem::Constants::nak ........... 'not acknowledged'
	Xmodem::Constants::can ........... 'cancel'
	Xmodem::Constants::C   ........... `C' ASCII char

	Xmodem::Constants::XMODEM ........ basic xmodem protocol
	Xmodem::Constants::XMODEM_1K ..... xmodem protocol with 1k blocks
	Xmodem::Constants::XMODEM_CRC .... xmodem protocol with CRC checks

	Xmodem::Constants::CHECKSUM ...... type of block checksum
	Xmodem::Constants::CRC16 ......... type of block crc16
	Xmodem::Constants::CRC32 ......... type of block crc32
	
=head1 Xmodem::Receiver

Control class to initiate and complete a C<X-modem> file transfer in receive mode

=head2 Synopsis

	my $recv = Xmodem::Receiver->new(
 		modem    => {Device::Modem object},
		filename => 'name of file',
		XXX protocol => 'xmodem' | 'xmodem-crc', | 'xmodem-1k'
	);

	$recv->run();

=head2 Object methods

=over 4

=item abort_transfer()

Sends a B<cancel> char (C<can>), that signals to sender that transfer is aborted. This is
issued if we receive a bad block number, which usually means we got a bad line.

=item modem()

Returns the underlying L<Device::Modem> object.

=item receive_message()

Retreives message from modem and if a block is detected it breaks it into appropriate
parts.

=item run()

Starts a new transfer until file receive is complete. The only parameter accepted
is the (optional) local filename to be written.

=item send_ack()

Sends an acknowledge (C<ack>) char, to signal that we received and stored a correct block
Resets count of timeouts and returns the C<Xmodem::Block> object of the data block
received.

=item send_timeout()

Sends a B<timeout> (C<nak>) char, to signal that we received a bad block header (either
a bad start char or a bad block number), or a bad data checksum. Increments count
of timeouts and at ten timeouts, aborts transfer.

=back

=head2 See also

=over 4

=item - L<Device::Modem>

=back
