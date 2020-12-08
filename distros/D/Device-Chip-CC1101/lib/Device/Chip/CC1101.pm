#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2019-2020 -- leonerd@leonerd.org.uk

use v5.26; # postfix-deref, signatures
use Object::Pad 0.27;

package Device::Chip::CC1101 0.05;
class Device::Chip::CC1101
   extends Device::Chip;

use Carp;
use Data::Bitfield 0.04 qw( bitfield boolfield enumfield intfield signed_intfield );
use Future::AsyncAwait;
use Future::IO;

use constant PROTOCOL => "SPI";

my %BANDS;
my %PRESET_MODES;

my @CACHED_CONFIG = qw( APPEND_STATUS PACKET_LENGTH LENGTH_CONFIG );

=head1 NAME

C<Device::Chip::CC1101> - chip driver for a F<CC1101>

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communication to a
F<Texas Instruments> F<CC1101> radio transceiver chip attached to a computer
via an SPI adapter.

The reader is presumed to be familiar with the general operation of this chip;
the documentation here will not attempt to explain or define chip-specific
concepts or features, only the use of this module to access them.

=cut

=head1 CONSTRUCTOR

=head2 new

   $chip = Device::Chip::CC1101->new( %ops )

Constructs a new C<Device::Chip::CC1101> instance. Takes the following
optional named arguments:

=over 4

=item * fosc

Gives the XTAL oscillator frequency in Hz. This is used by the
L<carrier_frequency> to calculate the actual frequency from the chip config.
A default of 26MHz applies if not supplied.

=item * poll_interval

Interval in seconds to poll the chip status after transmitting. A default of
20msec applies if not supplied.

=back

=cut

has $_fosc;
has $_poll_interval;

BUILD ( %opts )
{
   $_fosc          = $opts{fosc} // 26E6; # presets presume 26MHz XTAL
   $_poll_interval = $opts{poll_interval} // 0.05;
}

method SPI_options
{
   return (
      mode        => 0,
      max_bitrate => 1E6,
   );
}

method power ( $on ) { $self->protocol->power( $on ) }

=head1 METHODS

The following methods documented in an C<await> expression return L<Future>
instances.

=cut

use constant {
   REG_WRITE  => 0x00,
   REG_BURST  => 0x40,
   REG_READ   => 0x80,

   REG_PKTSTATUS => 0x38,
   REG_MARCSTATE => 0x35,
   REG_RXBYTES   => 0x3B,
   REG_PATABLE   => 0x3E,
   REG_TXFIFO    => 0x3F, # write-only
   REG_RXFIFO    => 0x3F, # read-only

   CMD_SRES    => 0x30,
   CMD_SFSTXON => 0x31,
   CMD_SXOFF   => 0x32,
   CMD_SCAL    => 0x33,
   CMD_SRX     => 0x34,
   CMD_STX     => 0x35,
   CMD_SIDLE   => 0x36,
   CMD_SWOR    => 0x38,
   CMD_SPWD    => 0x39,
   CMD_SFRX    => 0x3A,
   CMD_SFTX    => 0x3B,
   CMD_SWORRST => 0x3C,
   CMD_SNOP    => 0x3D,
};

=head2 read_register

   $value = await $chip->read_register( $addr );

Reads a single byte register and returns its numerical value.

C<$addr> should be between 0 and 0x3D, giving the register address.

=cut

async method read_register ( $addr )
{
   $addr >= 0 and $addr <= 0x3D or
      croak "Invalid register address";
   $addr |= REG_BURST if $addr >= 0x30;

   return unpack "C", await $self->protocol->write_then_read(
      pack( "C", REG_READ | $addr ), 1
   );
}

my @GDO_CFGs = qw(
   rx-fifo-full rx-fifo-or-eop tx-fifo-above-threshold tx-fifo-full
   rx-fifo-overflow tx-fifo-underflow packet-in-flight packet-received
   pqi-reached cca pll-lock sync-sck
   sync-sdo async-sdo carrier-sense CRC_OK
   . . . .
   . . RX_HARD_DATA[1] RX_HARD_DATA[0]
   . . . PA_PD
   LNA_PD RX_SYMBOL_TICK . .
   . . . .
   WOR_EVNT0 WOR_EVNT1 CLK_256 CLK_32k
   . CHIP_RDYn . XOSC_STABLE
   . . hiZ low
   CLK_XOSC/1  CLK_XOSC/1.5 CLK_XOSC/2   CLK_XOSC/3
   CLK_XOSC/4  CLK_XOSC/6   CLK_XOSC/8   CLK_XOSC/12
   CLK_XOSC/16 CLK_XOSC/24  CLK_XOSC/32  CLK_XOSC/48
   CLK_XOSC/64 CLK_XOSC/96  CLK_XOSC/128 CLK_XOSC/196
);

bitfield { format => "bytes-BE" }, CONFIG =>
   # IOCFG2
   GDO2_INV              => boolfield(     6),
   GDO2_CFG              => enumfield(     0, @GDO_CFGs),
   # IOCFG1
   GDO_DS                => enumfield( 1*8+7, qw( low high )),
   GDO1_INV              => boolfield( 1*8+6),
   GDO1_CFG              => enumfield( 1*8+0, @GDO_CFGs),
   # IOCFG0
   TEMP_SENSOR_ENABLE    => boolfield( 2*8+7),
   GDO0_INV              => boolfield( 2*8+6),
   GDO0_CFG              => enumfield( 2*8+0, @GDO_CFGs),
   # FIFOTHR
   ADC_RETENTION         => boolfield( 3*8+6),
   CLOSE_IN_RX           => enumfield( 3*8+4, qw( 0dB 6dB 12dB 18dB )),
   FIFO_THR              => intfield ( 3*8+0, 4), # TODO enum
   # SYNC0..1
   SYNC                  => intfield ( 4*8+0, 16),
   # PKTLEN
   PACKET_LENGTH         => intfield ( 6*8+0, 8),
   # PKTCTRL1
   PQT                   => intfield ( 7*8+5, 3),
   CRC_AUTOFLUSH         => boolfield( 7*8+3),
   APPEND_STATUS         => boolfield( 7*8+2),
   ADR_CHK               => enumfield( 7*8+0, qw( none addr addr+bc addr+2bc )),
   # PKTCTRL0
   WHITE_DATA            => boolfield( 8*8+6),
   PKT_FORMAT            => enumfield( 8*8+4, qw( fifo sync random async )),
   CRC_EN                => boolfield( 8*8+2),
   LENGTH_CONFIG         => enumfield( 8*8+0, qw( fixed variable infinite . )),
   # ADDR
   DEVICE_ADDR           => intfield ( 9*8+0, 8),
   # CHANNR
   CHAN                  => intfield (10*8+0, 8),
   # FSCTRL1
   FREQ_IF               => intfield (11*8+0, 5),
   # FSCTRL0
   FREQOFF               => signed_intfield(12*8+0, 8),
   # FREQ0..2
   FREQ                  => intfield (13*8+0, 24),
   # MDMCFG4
   CHANBW_E              => intfield (16*8+6, 2),
   CHANBW_M              => intfield (16*8+4, 2),
   DRATE_E               => intfield (16*8+0, 4),
   # MDMCFG3
   DRATE_M               => intfield (17*8+0, 8),
   # MDMCFG2
   DEM_DCFILT_OFF        => boolfield(18*8+7),
   MOD_FORMAT            => enumfield(18*8+4, qw( 2-FSK GFSK . ASK 4-FSK . . MSK )),
   MANCHESTER_EN         => boolfield(18*8+3),
   SYNC_MODE             => enumfield(18*8+0, qw( none 15/16 16/16 30/32 cs 15/16+cs 16/16+cs 30/32+cs )),
   # MDMCFG1
   FEC_EN                => boolfield(19*8+7),
   NUM_PREAMBLE          => enumfield(19*8+4, qw( 2B 3B 4B 6B 8B 12B 16B 24B )),
   CHANSPC_E             => intfield (19*8+0, 2),
   # MDMCFG0
   CHANSPC_M             => intfield (20*8+0, 8),
   # DEVIATN
   DEVIATION_E           => intfield (21*8+4, 3),
   DEVIATION_M           => intfield (21*8+0, 3),
   # MSCM2
   RX_TIME_RSSI          => boolfield(22*8+4),
   RX_TIME_QUAL          => boolfield(22*8+3),
   RX_TIME               => intfield (22*8+0, 3),
   # MSCM1
   CCA_MODE              => enumfield(23*8+4, qw( always rssi unless-rx rssi-unless-rx )),
   RXOFF_MODE            => enumfield(23*8+2, qw( IDLE FSTXON TX RX )),
   TXOFF_MODE            => enumfield(23*8+0, qw( IDLE FSTXON TX RX )),
   # MSCM0
   FS_AUTOCAL            => enumfield(24*8+4, qw( never on-unidle on-idle on-idle/4 )),
   PO_TIMEOUT            => enumfield(24*8+2, qw( x1 x16 x64 x256 )),
   PIN_CTRL_EN           => boolfield(24*8+1),
   XOSC_FORCE_ON         => boolfield(24*8+0),
   # FOCCFG
   FOC_BS_CS_GATE        => boolfield(25*8+5),
   FOC_PRE_K             => enumfield(25*8+3, qw( K 2K 3K 4K )),
   FOC_POST_K            => enumfield(25*8+2, qw( PRE K/2 )),
   FOC_LIMIT             => enumfield(25*8+0, qw( 0 BW/8 BW/4 BW/2 )),
   # BSCFG
   BS_PRE_KI             => enumfield(26*8+6, qw( KI 2KI 3KI 4KI )),
   BS_PRE_KP             => enumfield(26*8+4, qw( KP 2KP 3KP 4KP )),
   BS_POST_KI            => enumfield(26*8+3, qw( PRE KI/2 )),
   BS_POST_KP            => enumfield(26*8+2, qw( PRE KP )),
   BS_LIMIT              => enumfield(26*8+0, qw( 0 3.125% 6.25% 12.5% )),
   # AGCCTRL2
   MAX_DVGA_GAIN         => enumfield(27*8+6, qw( max not-top not-top-2 not-top-3 )),
   MAX_LNA_GAIN          => enumfield(27*8+3, "max", map { "max-${_}dB"} qw( 2.6 6.1 7.4 9.2 11.5 14.6 17.1 )),
   MAGN_TARGET           => enumfield(27*8+0, qw( 24dB 27dB 30dB 33dB 36dB 38dB 40dB 42dB )),
   # AGCCTRL1
   AGC_LNA_PRIORITY      => enumfield(28*8+6, qw( lna-first lna2-first )),
   CARRIER_SENSE_REL_THR => enumfield(28*8+4, qw( disabled 5dB 10dB 14dB )),
   CARRIER_SENSE_ABS_THR => enumfield(28*8+0,
                              "at-magn-target", ( map { "${_}dB-above" } 1 .. 7 ),
                              "disabled",       ( map { "${_}dB-below" } -7 .. -1 ) ),
   # AGCCTRL0
   HYST_LEVEL            => enumfield(29*8+6, qw( no low medium high )),
   WAIT_TIME             => enumfield(29*8+4, qw( 8sa 16sa 24sa 32sa )),
   AGC_FREEZE            => enumfield(29*8+2, qw( never after-sync freeze-analog freeze-all )),
   FILTER_LENGTH         => enumfield(29*8+0, qw( 8sa 16sa 32sa 64sa )), # TODO: in OOK/ASK modes this is different
   # WOREVT0..1
   EVENT0                => intfield (30*8+0, 16),
   # WORCTRL
   RC_PD                 => boolfield(32*8+7),
   EVENT1                => enumfield(32*8+4, qw( 4clk 6clk 8clk 12clk 16clk 24clk 32clk 48clk )),
   RC_CAL                => boolfield(32*8+3),
   WOR_RES               => enumfield(32*8+0, qw( 1P 2^5P 2^10P 2^15P )),
   # FREND1
   LNA_CURRENT           => intfield (33*8+6, 2),
   LNA2MIX_CURRENT       => intfield (33*8+4, 2),
   LODIV_BUF_CURRENT_RX  => intfield (33*8+2, 2),
   MIX_CURRENT           => intfield (33*8+0, 2),
   # FREND0
   LODIV_BUF_CURRENT_TX  => intfield (34*8+4, 2),
   PA_POWER              => intfield (34*8+0, 3),
   # The FSCAL registers are basically opaque
   FSCAL                 => intfield (35*8+0, 32),
   # RCCTRL too
   RCCTRL                => intfield (39*8+0, 16),
   # The remaining registers are test registers not for user use
   ;

# Not used directly by this code, but helpful for unit tests, etc..
use constant CONFIG_DEFAULT =>
   "\x29\x2E\x3F\x07\xD3\x91\xFF\x04\x45\x00\x00\x0F\x00\x1E\xC4\xEC" .
   "\x8C\x22\x02\x22\xF8\x47\x07\x30\x04\x36\x6C\x03\x40\x91\x87\x6B" .
   "\xF8\x56\x10\xA9\x0A\x20\x0D\x41\x00";

=head2 read_config

   $config = await $chip->read_config;

Reads and returns the current chip configuration as a C<HASH> reference.

The returned hash will contain keys with capitalized names representing all of
the config register fields in the datasheet, from registers C<IOCFG2> to
C<RCCTRL0>. Values are returned either as integers, or converted enumeration
names. Where documented by the datasheet, the enumeration values are
capitalised. Where invented by this module from the description they are given
in lowercase.

The value of C<PATABLE> is also returned, rendered as a human-readable hex
string in the form

   PATABLE => "01.23.45.67.89.AB.CD.EF",

The following values are also returned, derived from the actual register
values as a convenience.

   carrier_frequency => "800.000MHz",
   channel_spacing   => "191.951.kHz",
   deviation         => "47.607kHz",

   data_rate         => "115.1kbps",

=cut

sub _tohex   ( $v ) { return sprintf "%v02X", $v }
sub _fromhex ( $v ) { return pack "H*", $v =~ s/\.//gr }

async method _read_CONFIG ()
{
   return await $self->protocol->write_then_read(
      pack( "C", REG_READ | REG_BURST | 0 ), 41
   );
}

async method _read_PATABLE ()
{
   return await $self->protocol->write_then_read(
      pack( "C", REG_READ | REG_BURST | REG_PATABLE ), 8
   );
}

has $_config;
has $_patable;
has %_cached_config;

async method read_config ()
{
   my %config = (
      unpack_CONFIG( $_config //= await $self->_read_CONFIG ),
      PATABLE => _tohex $_patable //= await $self->_read_PATABLE,
   );

   # Post-convert some derived fields just for user convenience
   my $fosc = $_fosc;

   my $channel_spacing = $fosc * ( 256 + $config{CHANSPC_M} ) * 2 ** $config{CHANSPC_E} / 2**18;

   $config{channel_spacing} = sprintf "%.3fkHz", $channel_spacing / 1E3;

   $config{carrier_frequency} = sprintf "%.3fMHz",
      ( $fosc * $config{FREQ} / 2**16 + $config{CHAN} * $channel_spacing ) / 1E6;

   my $mod_format = $config{MOD_FORMAT};
   if( $mod_format =~ m/-FSK$|^GFSK$/ ) {
      $config{deviation} = sprintf "%.3fkHz",
         $fosc * ( 8 + $config{DEVIATION_M} ) * 2 ** $config{DEVIATION_E} / 2**17 / 1E3;
   }

   $config{data_rate} = sprintf "%.1fkbps",
      $fosc * ( 256 + $config{DRATE_M} ) * 2 ** $config{DRATE_E} / 2**28 / 1E3;

   $_cached_config{$_} = $config{$_} for @CACHED_CONFIG;
   return %config;
}

=head2 change_config

   await $chip->change_config( %changes );

Writes the configuration registers to apply the given changes. Any fields not
specified will retain their current values. The value of C<PATABLE> can also
be set here. Values should be given using the same converted forms as the
C<read_config> returns.

The following additional lowercase-named keys are also provided as shortcuts.

=over 4

=item * band => STRING

A convenient shortcut to setting the C<FREQ> and C<PATABLE> configuration to
one of the standard ISM bands. The names of these bands are

   433MHz
   868MHz

=item * mode => STRING

A convenient shortcut to setting the configuration state to one of the presets
supplied with the module. The names of these presets are

   GFSK-1.2kb
   GFSK-38.4kb
   GFSK-100kb
   MSK-250kb
   MSG-500kb

=back

=cut

async method _write_CONFIG ( $addr, $bytes )
{
   await $self->protocol->write(
      pack "C a*", REG_WRITE | REG_BURST | $addr, $bytes
   );
}

async method _write_PATABLE ( $bytes )
{
   await $self->protocol->write(
      pack "C a*", REG_WRITE | REG_BURST | REG_PATABLE, $bytes
   );
}

async method change_config ( %changes )
{
   defined $_config or await $self->read_config;
   # Use unpack_CONFIG() directly to avoid the derived keys
   my %config = unpack_CONFIG( $_config );

   if( defined( my $mode = delete $changes{mode} ) ) {
      $PRESET_MODES{$mode} or
         croak "Unrecognised preset mode name '$mode'";

      %config = ( %config, $PRESET_MODES{common}->%*, $PRESET_MODES{$mode}->%* );
   }

   if( defined( my $band = delete $changes{band} ) ) {
      $BANDS{$band} or
         croak "Unrecognised band name '$band'";

      %config = ( %config, $BANDS{$band}->%* );
   }

   %config = ( %config, %changes );
   my $newpatable = delete $config{PATABLE};
   $newpatable = _fromhex $newpatable if defined $newpatable;

   my $oldconfig = $_config;
   my $newconfig = pack_CONFIG( %config );

   my $addr = 0;
   $addr++ while $addr < length $newconfig and
      substr( $newconfig, $addr, 1 ) eq substr( $oldconfig, $addr, 1 );

   my $until = length( $newconfig );
   $until-- while $until > $addr and
      substr( $newconfig, $until-1, 1 ) eq substr( $oldconfig, $until-1, 1 );

   if( my $len = $until - $addr ) {
      await $self->_write_CONFIG( $addr, substr( $newconfig, $addr, $len ) );
      $_config = $newconfig;
   }

   if( defined $newpatable and $newpatable ne $_patable ) {
      await $self->_write_PATABLE( $newpatable );
      $_patable = $newpatable;
   }

   defined $config{$_} and $_cached_config{$_} = $config{$_} for @CACHED_CONFIG;
}

=head2 read_marcstate

   $state = await $chip->read_marcstate;

Reads the C<MARCSTATE> register and returns the state name.

=cut

my @MARCSTATE = qw(
   SLEEP IDLE XOFF VCOON_MC REGON_MC MANCAL VCOON REGON
   STARTCAL BWBOOST FS_LOCK IFADCON ENDCAL RX RX_END RX_RST
   TXRX_SWITCH RXFIFO_OVERFLOW FSTXON TX TXEND RXTX_SWITCH TXFIFO_UNDERFLOW
);

async method read_marcstate ()
{
   my $marcstate = await $self->read_register( REG_MARCSTATE );
   return $MARCSTATE[$marcstate] // $marcstate;
}

=head2 read_chipstatus_rx

=head2 read_chipstatus_tx

   $status = await $chip->read_chipstatus_rx;

   $status = await $chip->read_chipstatus_tx;

Reads the chip status word and returns a reference to a hash containing the
following:

   STATE                => string
   FIFO_BYTES_AVAILABLE => integer

=cut

method read_chipstatus_rx () { $self->_read_chipstatus( REG_READ ) }
method read_chipstatus_tx () { $self->_read_chipstatus( REG_WRITE ) }

my @STATES = qw( IDLE RX TX FSTXON CALIBRATE SETTLINE RXFIFO_OVERFLOW TXFIFO_UNDERFLOW );

async method _read_chipstatus ( $rw )
{
   my $status = unpack "C", await $self->protocol->readwrite(
      pack "C", $rw | CMD_SNOP
   );

   return {
      STATE                => $STATES[ ( $status & 0x70 ) >> 4 ],
      FIFO_BYTES_AVAILABLE => ( $status & 0x0F ),
   };
}

=head2 read_pktstatus

   $status = await $chip->read_pktstatus;

Reads the C<PKTSTATUS> register and returns a reference to a hash containing
boolean fields of the following names:

   CRC_OK CS PQT_REACHED CCA SFD GDO0 GDO2

=cut

async method read_pktstatus ()
{
   my $pktstatus = unpack "C", await $self->protocol->write_then_read(
      pack( "C", REG_READ|REG_BURST | REG_PKTSTATUS ), 1
   );

   return {
      CRC_OK      => !!( $pktstatus & ( 1 << 7 ) ),
      CS          => !!( $pktstatus & ( 1 << 6 ) ),
      PQT_REACHED => !!( $pktstatus & ( 1 << 5 ) ),
      CCA         => !!( $pktstatus & ( 1 << 4 ) ),
      SFD         => !!( $pktstatus & ( 1 << 3 ) ),
      GDO2        => !!( $pktstatus & ( 1 << 2 ) ),
      GDO0        => !!( $pktstatus & ( 1 << 0 ) ),
   };
}

async method command ( $cmd )
{
   $cmd >= 0x30 and $cmd <= 0x3D or
      croak "Invalid command byte";

   await $self->protocol->write( pack( "C", $cmd ) );
}

=head2 reset

   await $chip->reset;

Command the chip to perform a software reset.

=cut

async method reset ()
{
   await $self->command( CMD_SRES );
}

=head2 flush_fifos

   await $chip->flush_fifos;

Command the chip to flush the RX and TX FIFOs.

=cut

async method flush_fifos ()
{
   await $self->command( CMD_SFRX );
   await $self->command( CMD_SFTX );
}

=head2 start_rx

   await $chip->start_rx;

Command the chip to enter RX mode.

=cut

async method start_rx ()
{
   await $self->command( CMD_SIDLE );
   1 until ( await $self->read_marcstate ) eq "IDLE";

   await $self->command( CMD_SRX );
   1 until ( await $self->read_marcstate ) eq "RX";
}

=head2 start_tx

   await $chip->start_tx;

Command the chip to enter TX mode.

=cut

async method start_tx ()
{
   await $self->command( CMD_SIDLE );
   1 until ( await $self->read_marcstate ) eq "IDLE";

   await $self->command( CMD_STX );
   1 until ( await $self->read_marcstate ) eq "TX";
}

=head2 idle

   await $chip->idle;

Command the chip to enter IDLE mode.

=cut

async method idle ()
{
   await $self->command( CMD_SIDLE );
}

=head2 read_rxfifo

   $bytes = await $chip->read_rxfifo( $len );

Reads the given number of bytes from the RX FIFO.

=cut

async method read_rxfifo ( $len )
{
   await( $self->read_register( REG_RXBYTES ) ) >= $len or
      croak "RX UNDERFLOW - not enough bytes available";

   return await $self->protocol->write_then_read(
      pack( "C", REG_READ | REG_BURST | REG_RXFIFO ), $len
   );
}

=head2 write_txfifo

   await $chip->write_txfifo( $bytes );

Writes the given bytes into the TX FIFO.

=cut

async method write_txfifo ( $bytes )
{
   await $self->protocol->write(
      pack "C a*", REG_WRITE | REG_BURST | REG_TXFIFO, $bytes
   );
}

=head2 receive

   $packet = await $chip->receive;

Retrieves a packet from the RX FIFO, returning a HASH reference.

   data => STRING

This method automatically strips the C<RSSI>, C<LQI> and C<CRC_OK> fields from
the data and adds them to the returned hash if the chip is configured with
C<APPEND_STATUS>.

   RSSI   => NUM (in units of dBm)
   LQI    => INT
   CRC_OK => BOOL

This method automatically handles prepending the packet length if the chip is
configured in variable-length packet mode.

B<TODO>: Note that, despite its name, this method does not currently wait for
a packet to be available - the caller is responsible for calling L</start_rx>
and waiting for a packet to be received. This may be provided in a later
version by polling chip status or using interrupts if C<Device::Chip> makes
them available.

=cut

async method receive ()
{
   # TODO: Check for RX UNDERFLOW somehow?

   my $fixedlen = $_cached_config{LENGTH_CONFIG} eq "fixed";
   my $append_status = $_cached_config{APPEND_STATUS};

   my $len = $fixedlen ?
      $_cached_config{PACKET_LENGTH} :
      unpack "C", await $self->read_rxfifo( 1 );

   $len += 2 if $append_status;

   my $bytes = await $self->read_rxfifo( $len );
   my %ret;

   if( $append_status ) {
      my ( $rssi, $lqi ) = unpack( "c C", substr( $bytes, -2, 2, "" ) );

      # RSSI is 2s complement in 0.5dBm units offset from -74dBm
      $ret{RSSI} = $rssi / 2 - 74;

      # LQI/CRC_OK
      $ret{LQI}    = $lqi & 0x7F;
      $ret{CRC_OK} = !!( $lqi & 0x80 );
   }

   $ret{data} = $bytes;

   return \%ret;
}

=head2 transmit

   await $chip->transmit( $bytes );

Enters TX mode and sends a packet containing the given bytes.

This method automatically handles prepending the packet length if the chip is
configured in variable-length packet mode.

=cut

async method transmit ( $bytes )
{
   my $fixedlen = $_cached_config{LENGTH_CONFIG} eq "fixed";

   my $pktlen = length $bytes;
   if( $fixedlen ) {
      $pktlen == $_cached_config{PACKET_LENGTH} or
         croak "Expected a packet $_cached_config{PACKET_LENGTH} bytes long";
   }
   else {
      # Ensure we can't overflow either TX or RX FIFO
      $pktlen <= 62 or
         croak "Expected no more than 62 bytes of packet data"
   }

   await $self->start_tx;

   $bytes = pack "C a*", $pktlen, $bytes if !$fixedlen;

   await $self->write_txfifo( $bytes );

   my $timeout = 20; # TODO: configuration
   while( await( $self->read_chipstatus_tx )->{STATE} eq "TX" ) {
      $timeout-- or croak "Timed out waiting for TX to complete";
      await Future::IO->sleep( $_poll_interval );
   }
}

{
   while( readline DATA ) {
      chomp;
      next if m/^#/;
      my ( $name, $fields ) = split m/\|/, $_;

      $PRESET_MODES{$name} = +{
         map { m/(.*?)=(.*)/ } split m/,/, $fields
      };
   }

   %BANDS = (
      "433MHz" => {
         FREQ    => 1091426,
         # From the datasheet presuming 433MHz on multilayer inductors
         PATABLE => "12.0E.1D.34.60.84.C8.C0",
      },

      "868MHz" => {
         FREQ    => 2188650,
         # From the datasheet presuming 868MHz on multilayer inductors
         PATABLE => "03.0F.1E.27.50.81.CB.C2",
      },
   );
}

0x55AA;

=head1 TODO

=over 4

=item *

Polling/interrupts to wait for RX packet

=item *

Support addressing modes in L</transmit> and L</receive>

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

__DATA__
# The following data is automatically generated by update-configs.pl
common|CCA_MODE=always,CHANSPC_E=0,FEC_EN=1,FOC_BS_CS_GATE=,FREQ=2188650,FS_AUTOCAL=on-unidle,PA_POWER=7,PO_TIMEOUT=x64,RXOFF_MODE=RX,SYNC_MODE=30/32
GFSK-1.2kb|CHANBW_E=3,CHANBW_M=3,DEVIATION_E=1,DEVIATION_M=5,DRATE_E=5,DRATE_M=131,FREQ_IF=8,FSCAL=2836004881,MOD_FORMAT=GFSK
GFSK-100kb|AGC_LNA_PRIORITY=lna-first,BS_PRE_KI=KI,BS_PRE_KP=2KP,CHANBW_E=1,CHANBW_M=1,DRATE_E=11,DRATE_M=248,FILTER_LENGTH=32sa,FOC_LIMIT=BW/8,FOC_PRE_K=4K,FREQ_IF=8,FSCAL=3926523921,LNA2MIX_CURRENT=3,LNA_CURRENT=2,MAGN_TARGET=42dB,MAX_DVGA_GAIN=not-top-3,MOD_FORMAT=GFSK,WAIT_TIME=32sa
GFSK-38.4kb|CHANBW_E=3,DEVIATION_E=3,DEVIATION_M=4,DRATE_E=10,DRATE_M=131,FREQ_IF=6,FSCAL=2836004881,MAX_DVGA_GAIN=not-top,MOD_FORMAT=GFSK
MSK-250kb|AGC_LNA_PRIORITY=lna-first,BS_PRE_KI=KI,BS_PRE_KP=2KP,CHANBW_E=0,CHANBW_M=2,DEVIATION_E=0,DEVIATION_M=0,DRATE_E=13,DRATE_M=59,FILTER_LENGTH=32sa,FOC_LIMIT=BW/8,FOC_PRE_K=4K,FREQ_IF=11,FSCAL=3926523921,LNA2MIX_CURRENT=3,LNA_CURRENT=2,MAGN_TARGET=42dB,MAX_DVGA_GAIN=not-top-3,MOD_FORMAT=MSK,WAIT_TIME=32sa
MSK-500kb|BS_PRE_KI=KI,BS_PRE_KP=2KP,CHANBW_E=0,DEVIATION_E=0,DEVIATION_M=0,DRATE_E=14,DRATE_M=59,FILTER_LENGTH=32sa,FOC_LIMIT=BW/8,FOC_PRE_K=4K,FREQ_IF=12,FSCAL=3926523929,LNA2MIX_CURRENT=3,LNA_CURRENT=2,MAGN_TARGET=42dB,MAX_DVGA_GAIN=not-top-3,MOD_FORMAT=MSK,WAIT_TIME=32sa
