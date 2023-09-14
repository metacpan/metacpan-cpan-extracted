#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2023 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800;

package Device::Chip::nRF24L01P 0.08;
class Device::Chip::nRF24L01P
   :isa(Device::Chip);

use Carp;
use Data::Bitfield qw( bitfield boolfield enumfield intfield );

use Future::AsyncAwait;

use constant PROTOCOL => "SPI";

=head1 NAME

C<Device::Chip::nRF24L01P> - chip driver for a F<nRF24L01+>

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communication to a
F<Nordic Semiconductor> F<nRF24L01+> chip attached to a computer via an SPI
adapter.

The reader is presumed to be familiar with the general operation of this chip;
the documentation here will not attempt to explain or define chip-specific
concepts or features, only the use of this module to access them.

=cut

=head1 MOUNT PARAMETERS

=head2 ce

The name of the GPIO line on the adapter that is connected to the Chip Enable
(CE) pin. This module defaults to using the C<AUX> line on a F<Bus Pirate>, or
C<D4> on an F<FTDI FT232H>; for other adapter types the parameter will have to
be supplied.

=cut

my %DEFAULT_CE = (
   'Device::Chip::Adapter::BusPirate' => "AUX",
   'Device::Chip::Adapter::FTDI'      => "D4",
);

field $_gpio_ce;

async method mount ( $adapter, %params )
{
   my $ce_pin = $params{ce} // $DEFAULT_CE{ref $adapter} // "CE";

   $_gpio_ce = $ce_pin;

   await $self->SUPER::mount( $adapter, %params );

   await $self->protocol->write_gpios( { $ce_pin => 0 } );

   return $self;
}

method SPI_options
{
   return (
      mode        => 0,
      max_bitrate => 1E6,
   );
}

=head1 METHODS

The following methods documented in an C<await> expression return L<Future>
instances.

=cut

async method power ( $on ) { await $self->protocol->power( $on ) }

# Commands
use constant {
   CMD_R_REGISTER          => 0x00,
   CMD_W_REGISTER          => 0x20,
   CMD_R_RX_PAYLOAD        => 0x61,
   CMD_W_TX_PAYLOAD        => 0xA0,
   CMD_FLUSH_TX            => 0xE1,
   CMD_FLUSH_RX            => 0xE2,
   CMD_REUSE_TX_PL         => 0xE3,
   CMD_R_RX_PL_WID         => 0x60,
   CMD_W_ACK_PAYLOAD       => 0xA8,
   CMD_W_TX_PAYLOAD_NO_ACK => 0xB0,
   CMD_NOP                 => 0xFF,
};

# Register numbers and lengths, and bitfields
use constant {
   REG_CONFIG      => [ 0x00, 1 ], # bitfield
   REG_EN_AA       => [ 0x01, 1 ], # per-pipe bitmask
   REG_EN_RXADDR   => [ 0x02, 1 ], # per-pipe bitmask
   REG_SETUP_AW    => [ 0x03, 1 ], # bitfield
   REG_SETUP_RETR  => [ 0x04, 1 ], # bitfield
   REG_RF_CH       => [ 0x05, 1 ], # int
   REG_RF_SETUP    => [ 0x06, 1 ], # bitfield
   REG_STATUS      => [ 0x07, 1 ], # bitfield
   REG_OBSERVE_TX  => [ 0x08, 1 ], # bitfield
   REG_RPD         => [ 0x09, 1 ], # bool
   REG_RX_ADDR_P0  => [ 0x0A, 5 ], # addresses
   REG_RX_ADDR_P1  => [ 0x0B, 5 ],
   REG_RX_ADDR_P2  => [ 0x0C, 1 ],
   REG_RX_ADDR_P3  => [ 0x0D, 1 ],
   REG_RX_ADDR_P4  => [ 0x0E, 1 ],
   REG_RX_ADDR_P5  => [ 0x0F, 1 ],
   REG_TX_ADDR     => [ 0x10, 5 ],
   REG_RX_PW_P0    => [ 0x11, 1 ], # ints
   REG_RX_PW_P1    => [ 0x12, 1 ],
   REG_RX_PW_P2    => [ 0x13, 1 ],
   REG_RX_PW_P3    => [ 0x14, 1 ],
   REG_RX_PW_P4    => [ 0x15, 1 ],
   REG_RX_PW_P5    => [ 0x16, 1 ],
   REG_FIFO_STATUS => [ 0x17, 1 ], # bitfield
   REG_DYNPD       => [ 0x1C, 1 ], # per-pipe bitmask
   REG_FEATURE     => [ 0x1D, 1 ], # bitfield
};

bitfield { unrecognised_ok => 1 }, CONFIG =>
   MASK_RX_DR  => boolfield(6),
   MASK_TX_DS  => boolfield(5),
   MASK_MAX_RT => boolfield(4),
   EN_CRC      => boolfield(3),
   CRCO        => enumfield(2, 1, 2 ),
   PWR_UP      => boolfield(1),
   PRIM_RX     => boolfield(0);

bitfield { unrecognised_ok => 1 }, SETUP_AW =>
   AW          => enumfield(0, undef, 3, 4, 5 );

bitfield { unrecognised_ok => 1 }, SETUP_RETR =>
   ARD         => enumfield(4, map { ( $_ + 1 ) * 250 } 0 .. 15),
   ARC         => intfield(0, 4);

bitfield { unrecognised_ok => 1 }, RF_SETUP =>
   CONT_WAVE   => boolfield(7),
   RF_DR_LOW   => boolfield(5),
   PLL_LOCK    => boolfield(4),
   RF_DR_HIGH  => boolfield(3),
   RF_PWR      => enumfield(1, -18, -12, -6, 0 );

bitfield STATUS =>
   RX_DR       => boolfield(6),
   TX_DS       => boolfield(5),
   MAX_RT      => boolfield(4),
   RX_P_NO     => enumfield(1, 0,1,2,3,4,5 ),
   TX_FULL     => boolfield(0);

bitfield OBSERVE_TX =>
   PLOS_CNT    => intfield(4, 4),
   ARC_CNT     => intfield(0, 4);

bitfield FIFO_STATUS =>
   TX_REUSE    => boolfield(6),
   TX_FULL     => boolfield(5),
   TX_EMPTY    => boolfield(4),
   RX_FULL     => boolfield(1),
   RX_EMPTY    => boolfield(0);

bitfield { unrecognised_ok => 1 }, FEATURE =>
   EN_DPL      => boolfield(2),
   EN_ACK_PAY  => boolfield(1),
   EN_DYN_ACK  => boolfield(0);

=head2 clear_caches

   $nrf->clear_caches

The chip object stores a cache of the register values it last read or wrote,
so it can optimise updates of configuration. This method clears these caches,
ensuring a fresh SPI transfer next time the register needs to be read.

This should not normally be necessary, other than for debugging.

=cut

field @_registers;

method clear_caches ()
{
   undef @_registers;
}

=head2 latest_status

   $status = $nrf->latest_status

Returns the latest cached copy of the status register from the most recent SPI
interaction. As this method does not perform any IO, it returns its result
immediately rather than via a Future.

Returns a HASH reference containing the following boolean fields

 RX_DR TX_DS MAX_RT TX_FULL

Also returned is a field called C<RX_P_NO>, which is either a pipe number (0
to 5) or undef.

=cut

field $_latest_status;

method latest_status ()
{
   return { unpack_STATUS( $_latest_status ) };
}

=head2 reset_interrupt

   await $nrf->reset_interrupt;

Clears the interrupt flags in the C<STATUS> register.

=cut

async method reset_interrupt ()
{
   await $self->_write_register_volatile( REG_STATUS, chr pack_STATUS(
         RX_DR  => 1,
         TX_DS  => 1,
         MAX_RT => 1
   ) );
}

async method _do_command ( $cmd, $data = "" )
{
   my $buf = await $self->protocol->readwrite( chr( $cmd ) . $data );

   $_latest_status = ord substr $buf, 0, 1, "";

   return $buf;
}

=head2 read_status

   $status = await $nrf->read_status;

Reads and returns the current content of the status register as a HASH
reference as per C<latest_status>.

=cut

async method read_status ()
{
   await $self->_do_command( CMD_NOP );

   return $self->latest_status;
}

# Always performs an SPI operation
async method _read_register_volatile ( $reg )
{
   my ( $regnum, $len ) = @$reg;

   my $val = await $self->_do_command( CMD_R_REGISTER | $regnum, ( "\0" x $len ) );

   $_registers[$regnum] = $val;
   return $val;
}

# Returns the cached value if present
async method _read_register ( $reg )
{
   my ( $regnum ) = @$reg;

   defined $_registers[$regnum] ?
      return $_registers[$regnum] :
      return await $self->_read_register_volatile( $reg );
}

# Always performs an SPI operation
async method _write_register_volatile ( $reg, $data )
{
   my ( $regnum, $len ) = @$reg;
   $len == length $data or croak "Attempted to write the wrong length";

   await $self->_do_command( CMD_W_REGISTER | $regnum, $data );

   $_registers[$regnum] = $data;
   return;
}

# Doesn't bother if no change
async method _write_register ( $reg, $data )
{
   my ( $regnum ) = @$reg;

   return if
      defined $_registers[$regnum] and $_registers[$regnum] eq $data;

   await $self->_write_register_volatile( $reg, $data );
}

=head2 read_config

   $config = await $nrf->read_config;

=head2 change_config

   await $nrf->change_config( %config );

Reads or writes the chip-wide configuration. This is an amalgamation of all
the non-pipe-specific configuration registers; C<CONFIG>, C<SETUP_AW>,
C<SETUP_RETR>, C<RF_CH>, C<RF_SETUP>, C<TX_ADDR> and C<FEATURE>.

When reading, the fields are returned in a HASH reference whose names are the
original bitfield names found in the F<Nordic Semiconductor> data sheet. When
writing, these fields are accepted as named parameters to the C<change_config>
method directly.

Some of the fields have special processing for convenience. They are:

=over 4

=item * CRCO

Gives the CRC length in bytes, as either 1 or 2.

=item * AW

Gives the full address width in bytes, between 3 and 5.

=item * ARD

Gives the auto retransmit delay in microseconds directly; a multiple of 250
between 250 and 4000.

=item * RF_DR

Gives the RF data rate in bytes/sec; omits the C<RF_DR_LOW> and C<RF_DR_HIGH>
fields; as 250000, 1000000 or 2000000

=item * RF_PWR

Gives the RF output power in dBm directly, as -18, -12, -6 or 0.

=item * TX_ADDR

Gives the PTX address as a string of 5 capital hexadecimal encoded octets,
separated by colons.

=back

Whenever the config is read it is cached within the C<$chip> instance.
Whenever it is written, any missing fields in the passed configuration are
pre-filled by the cached config, and only those registers that need writing
will be written.

=cut

sub _unpack_addr ( $addr )
{
   return join ":", map { sprintf "%02X", ord } split //, $addr;
}

sub _pack_addr ( $addr )
{
   return join "", map { chr hex } split m/:/, $addr;
}

sub _unpack_config ( %regs )
{
   my %config = (
      unpack_CONFIG    ( $regs{config} ),
      unpack_SETUP_AW  ( $regs{setup_aw} ),
      unpack_SETUP_RETR( $regs{setup_retr} ),
      RF_CH           => $regs{rf_ch},
      unpack_RF_SETUP  ( $regs{rf_setup} ),
      TX_ADDR         => _unpack_addr( $regs{tx_addr} ),
      unpack_FEATURE   ( $regs{feature} ),
   );

   # RF_DR is split across two discontiguous bits - currently Data::Bitmask
   # can't support this
   $config{RF_DR} = ( 1E6, 2E6, 250E6, undef )[ delete($config{RF_DR_HIGH}) + 2 * delete($config{RF_DR_LOW}) ];

   return %config;
}

sub _pack_config ( %config )
{
   # RF_DR is split across two discontiguous bits - currently Data::Bitmask
   # can't support this
   for( delete $config{RF_DR} ) {
      $config{RF_DR_LOW} = 1, $config{RF_DR_HIGH} = 0, last if $_ == 250E3;
      $config{RF_DR_LOW} = 0, $config{RF_DR_HIGH} = 0, last if $_ == 1E6;
      $config{RF_DR_LOW} = 0, $config{RF_DR_HIGH} = 1, last if $_ == 2E6;
      croak "Unsupported 'RF_DR'";
   }

   return
      config     => pack_CONFIG    ( %config ),
      setup_aw   => pack_SETUP_AW  ( %config ),
      setup_retr => pack_SETUP_RETR( %config ),
      rf_ch      => $config{RF_CH},
      rf_setup   => pack_RF_SETUP  ( %config ),
      tx_addr    => _pack_addr( $config{TX_ADDR} ),
      feature    => pack_FEATURE   ( %config ),
}

async method read_config ()
{
   my @vals = await Future->needs_all(
      map { $self->_read_register( $_ ) }
         REG_CONFIG, REG_SETUP_AW, REG_SETUP_RETR, REG_RF_CH, REG_RF_SETUP, REG_TX_ADDR, REG_FEATURE,
   );

   $_ = ord $_ for @vals[0,1,2,3,4,6]; # [5] is TX_ADDR
   my %regs;
   @regs{qw( config setup_aw setup_retr rf_ch rf_setup tx_addr feature )} = @vals;

   return { _unpack_config %regs };
}

async method change_config ( %changes )
{
   my $config = await $self->read_config;

   my %new_registers = _pack_config %$config, %changes;

   my @f;
   foreach (qw( config setup_aw setup_retr rf_ch rf_setup feature )) {
      push @f, $self->_write_register( $self->${\"REG_\U$_"}, chr $new_registers{$_} );
   }
   push @f, $self->_write_register( REG_TX_ADDR, $new_registers{tx_addr} );

   await Future->needs_all( @f );
   return;
}

=head2 read_rx_config

   $config = await $nrf->read_rx_config( $pipeno );

=head2 change_rx_config

   await $nrf->change_rx_config( $pipeno, %config );

Reads or writes the per-pipe RX configuration. This is composed of the
per-pipe bits of the C<EN_AA> and C<EN_RXADDR> registers and its
C<RX_ADDR_Pn> register.

Addresses are given as a string of 5 octets in capitalised hexadecimal
notation, separated by colons.

When reading an address from pipes 2 to 5, the address of pipe 1 is used to
build a complete address string to return. When writing and address to these
pipes, all but the final byte is ignored.

=cut

async method read_rx_config ( $pipeno )
{
   $pipeno >= 0 and $pipeno < 6 or croak "Invalid pipe number $pipeno";
   my $mask = 1 << $pipeno;

   my ( $en_aa, $en_rxaddr, $dynpd, $width, $addr, $p1addr ) =
      await Future->needs_all(
         map { $self->_read_register( $_ ) }
            REG_EN_AA, REG_EN_RXADDR, REG_DYNPD, # bitwise
            $self->${\"REG_RX_PW_P$pipeno"}, $self->${\"REG_RX_ADDR_P$pipeno"},
            # Pipes 2 to 5 share the first 4 octects of PIPE1's address
            ( $pipeno >= 2 ? REG_RX_ADDR_P1 : () ),
      );

   $_ = ord $_ for $en_aa, $en_rxaddr, $dynpd, $width;

   $addr = substr( $p1addr, 0, 4 ) . $addr if $pipeno >= 2;

   return {
      EN_AA     => !!( $en_aa     & $mask ),
      EN_RXADDR => !!( $en_rxaddr & $mask ),
      DYNPD     => !!( $dynpd     & $mask ),
      RX_PW     => $width,
      RX_ADDR   => _unpack_addr $addr,
   };
}

async method change_rx_config ( $pipeno, %changes )
{
   $pipeno >= 0 and $pipeno < 6 or croak "Invalid pipe number $pipeno";
   my $mask = 1 << $pipeno;

   my $REG_RX_PW_Pn   = $self->${\"REG_RX_PW_P$pipeno"};
   my $REG_RX_ADDR_Pn = $self->${\"REG_RX_ADDR_P$pipeno"};

   my ( $en_aa, $en_rxaddr, $dynpd, $width, $addr ) =
      await Future->needs_all(
         map { $self->_read_register( $_ ) }
            REG_EN_AA, REG_EN_RXADDR, REG_DYNPD, $REG_RX_PW_Pn, $REG_RX_ADDR_Pn
      );

   $_ = ord $_ for $en_aa, $en_rxaddr, $dynpd, $width;

   if( exists $changes{EN_AA} ) {
      $en_aa &= ~$mask;
      $en_aa |=  $mask if $changes{EN_AA};
   }
   if( exists $changes{EN_RXADDR} ) {
      $en_rxaddr &= ~$mask;
      $en_rxaddr |=  $mask if $changes{EN_RXADDR};
   }
   if( exists $changes{DYNPD} ) {
      $dynpd &= ~$mask;
      $dynpd |=  $mask if $changes{DYNPD};
   }
   if( exists $changes{RX_PW} ) {
      $width = $changes{RX_PW};
   }
   if( exists $changes{RX_ADDR} ) {
      $addr = _pack_addr $changes{RX_ADDR};
      $addr = substr( $addr, -1 ) if $pipeno >= 2;
   }

  await Future->needs_all(
      $self->_write_register( REG_EN_AA,     chr $en_aa ),
      $self->_write_register( REG_EN_RXADDR, chr $en_rxaddr ),
      $self->_write_register( REG_DYNPD,     chr $dynpd ),
      $self->_write_register( $REG_RX_PW_Pn, chr $width ),
      $self->_write_register( $REG_RX_ADDR_Pn, $addr ),
   );

   return;
}

=head2 observe_tx_counts

   $counts = await $nrf->observe_tx_counts;

Reads the C<OBSERVE_TX> register and returns the two counts from it.

=cut

async method observe_tx_counts ()
{
   my $buf = await $self->_read_register_volatile( REG_OBSERVE_TX );

   return { unpack_OBSERVE_TX( ord $buf ) };
}

=head2 rpd

   $rpd = await $nrf->rpd;

Reads the C<RPD> register

=cut

async method rpd ()
{
   my $buf = await $self->_read_register_volatile( REG_RPD );

   return ( ord $buf ) & 1;
}

=head2 fifo_status

   $status = await $nrf->fifo_status;

Reads the C<FIFO_STATUS> register and returns the five bit fields from it.

=cut

async method fifo_status ()
{
   my $buf = await $self->_read_register_volatile( REG_FIFO_STATUS );

   return { unpack_FIFO_STATUS( ord $buf ) };
}

=head2 pwr_up

   await $nrf->pwr_up( $pwr );

A convenient shortcut to setting the C<PWR_UP> configuration bit.

=cut

async method pwr_up ( $pwr )
{
   await $self->change_config( PWR_UP => $pwr );
}

=head2 chip_enable

   await $nrf->chip_enable( $ce );

Controls the Chip Enable (CE) pin of the chip.

=cut

async method chip_enable ( $ce )
{
   await $self->protocol->write_gpios( { $_gpio_ce => $ce } );
}

=head2 read_rx_payload_width

   $len = await $nrf->read_rx_payload_width;

Returns the width of the most recently received payload, when in C<DPL> mode.
Remember that C<DPL> needs to be enabled (using C<EN_DPL>) on both the
transmitter and receiver before this will work.

=cut

async method read_rx_payload_width ()
{
   return ord await $self->_do_command( CMD_R_RX_PL_WID, "\0" );
}

=head2 read_rx_payload

   $data = await $nrf->read_rx_payload( $len );

Reads the most recently received RX FIFO payload buffer.

=cut

async method read_rx_payload ( $len )
{
   $len > 0 and $len <= 32 or croak "Invalid RX payload length $len";

   return await $self->_do_command( CMD_R_RX_PAYLOAD, "\0" x $len )
}

=head2 write_tx_payload

   await $nrf->write_tx_payload( $data, %opts );

Writes the next TX FIFO payload buffer. Takes the following options:

=over 4

=item no_ack => BOOL

If true, uses the C<W_TX_PAYLOAD_NO_ACK> command, requesting that this payload
does not requre auto-ACK.

=back

=cut

async method write_tx_payload ( $data, %opts )
{
   my $len = length $data;
   $len > 0 and $len <= 32 or croak "Invalid TX payload length $len";

   my $cmd = $opts{no_ack} ? CMD_W_TX_PAYLOAD_NO_ACK : CMD_W_TX_PAYLOAD;

   await $self->_do_command( $cmd, $data );
   return;
}

=head2 flush_rx_fifo

   await $nrf->flush_rx_fifo;

=head2 flush_tx_fifo

   await $nrf->flush_tx_fifo;

Flush the RX or TX FIFOs, discarding all their contents.

=cut

async method flush_rx_fifo ()
{
   await $self->_do_command( CMD_FLUSH_RX );
   return;
}

async method flush_tx_fifo ()
{
   await $self->_do_command( CMD_FLUSH_TX );
   return;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
