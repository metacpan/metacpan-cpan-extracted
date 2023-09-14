#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2022-2023 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800;

package Device::Chip::Si5351 0.02;
class Device::Chip::Si5351
   :isa(Device::Chip::Base::RegisteredI2C);
use Device::Chip::Base::RegisteredI2C 0.21;

use Carp;
use Future::AsyncAwait 0.38;

use Data::Bitfield qw( bitfield enumfield boolfield intfield );

use POSIX qw( floor );  # TODO: grab this from builtin::

# See also
#   https://github.com/adafruit/Adafruit_Si5351_Library/blob/master/Adafruit_SI5351.cpp
#   AN619 = https://www.silabs.com/documents/public/application-notes/AN619.pdf

=encoding UTF-8

=head1 NAME

C<Device::Chip::Si5351> - chip driver for F<Si5351>

=head1 SYNOPSIS

   use Device::Chip::Si5351;
   use Future::AsyncAwait;

   my $chip = Device::Chip::Si5351->new;
   await $chip->mount( Device::Chip::Adapter::...->new );

   await $chip->init;

   await $chip->change_pll_config( "A",
      SRC   => "XTAL",
      ratio => 24,
   );

   await $chip->change_multisynth_config( 0,
      SRC   => "PLLA",
      ratio => 50,
   );

   await $chip->change_clk_config( 0,
      SRC => "MSn",
      PDN => 0,
      OE  => 1,
   );

   await $chip->reset_plls;

   # CLK0 output will now be set to the crystal reference frequency
   # multiplied by 24, divided by 50. Assuming a 25.000MHz reference
   # crystal, the output will therefore be 12.000MHz.

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communication to a F<Silabs>
F<Si5351> chip attached to a computer via an I²C adapter.

The reader is presumed to be familiar with the general operation of this chip;
the documentation here will not attempt to explain or define chip-specific
concepts or features, only the use of this module to access them.

=cut

method I2C_options
{
   return (
      addr        => 0x60,
      max_bitrate => 400E3,
   );
}

=head1 METHODS

=cut

# Silabs' AN619 gives names for the register fields but not actually the
# registers themselves. We've made up these names here

# Many of these registers aren't used in our code (yet).
use constant {
   # Register numbers are documented in decimal in the AN619 datasheet
   REG_STATUS    => 0, # (RO)
   REG_INTFLAGS  => 1,
   REG_INTMASK   => 2,
   REG_OEMASK    => 3,
   REG_OEBMASK   => 9,
   REG_PLLSOURCE => 15,

   # The 8 clock control registers
   REG_CLKCTRL_BASE => 16,

   REG_CLK03DIS  => 24,
   REG_CLK47DIS  => 25,

   # Multisynth NA+NB have a common structure
   REG_MSNA_BASE => 26,
   REG_MSNB_BASE => 34,

   # Multisynth0 to 5 have a common structure
   REG_MSx_BASE  => 42,

   # Multisynth 6 to 7 are special
   REG_MS6_P1L   => 90,
   REG_MS7_P1L   => 91,
   REG_MS67_DIV  => 92,

   # TODO: spread spectrum, VCXO

   # Phase offset - despite its silly name it is a property of the Multisynth
   #   unit, not the clock output
   REG_CLKx_PHOFF => 165,

   REG_PLLRST     => 177,

   REG_XTAL_CL    => 183,

   REG_FANOUT     => 187,
};

=head2 init

   await $chip->init;

Performs initialisation setup on the chip as recommended by the datasheet:
disables all outputs and powers down all output drivers. After this,
individual outputs can be powered up and enabled again by
L</change_clk_config>.

=cut

# A copy of the initialise code from the Adafruit driver
async method init ()
{
   # All outputs disabled (bits high)
   await $self->cached_write_reg( REG_OEMASK, "\xFF" );

   # All output drivers powered down
   await Future->needs_all(
      map { $self->cached_write_reg( REG_CLKCTRL_BASE + $_, "\x80" ) } 0 .. 7
   );
}

=head2 read_status

   $status = await $chip->read_status;

Reads and returns the chip status register, as a C<HASH> reference with the
following keys:

   SYS_INIT  => BOOL
   LOL_A     => BOOL
   LOL_B     => BOOL
   LOS_CLKIN => BOOL
   LOS_XTAL  => BOOL
   REVID     => INT

=cut

bitfield { format => "bytes-LE" }, STATUS =>
   SYS_INIT  => boolfield( 7 ),
   LOL_A     => boolfield( 6 ),
   LOL_B     => boolfield( 5 ),
   LOS_CLKIN => boolfield( 4 ),
   LOS_XTAL  => boolfield( 3 ),
   REVID     => intfield(  0, 2 ),
;

async method read_status ()
{
   my $bytes = await $self->read_reg( REG_STATUS, 1 );

   return { unpack_STATUS( $bytes ) };
}

=head2 read_config

   $config = await $chip->read_config;

Reads and returns the overall chip configuration, as a C<HASH> reference with
the following keys:

   XTAL_CL      => "6pF" | "8pF" | "10pF"
   CLKIN_FANOUT => BOOL
   XO_FANOUT    => BOOL
   MS_FANOUT    => BOOL

=cut

# Rather than one giant monster "config" structure, we'll split up
#   chip overall
#   PLLA, PLLB
#   Multisynth0 to Multisynth7
#   CLK0 to CLK7 outputs

bitfield { format => "bytes-LE" }, CONFIG =>
   # REG_XTAL_CL
   XTAL_CL => enumfield( 6, qw( . 6pF 8pF 10pF ) ),
   # REG_FANOUT
   CLKIN_FANOUT => boolfield( 15 ),
   XO_FANOUT    => boolfield( 14 ),
   MS_FANOUT    => boolfield( 12 ),
;

async method read_config ()
{
   my $bytes = join "",
      await $self->cached_read_reg( REG_XTAL_CL, 1 ),
      await $self->cached_read_reg( REG_FANOUT, 1 );

   return { unpack_CONFIG( $bytes ) };
}

=head2 change_config

   await $chip->change_config( %changes );

Writes changes to the overall chip configuration registers. Any fields not
specified will retain their current values.

=cut

async method change_config ( %changes )
{
   my $config = await $self->read_config();

   $config->{$_} = $changes{$_} for keys %changes;

   my ( $xtal_cl, $fanout ) = unpack "(a1)*", pack_CONFIG( %$config );

   await $self->cached_write_reg( REG_XTAL_CL, $xtal_cl );
   await $self->cached_write_reg( REG_FANOUT,  $fanout );
}

=head2 read_pll_config

   $config = await $chip->read_pll_config( $pll )

Reads and returns the PLL synthesizer configuration registers for the given
PLL unit (which should be C<"A"> or C<"B">), as a C<HASH> reference with the
following keys:

   P1  => INT
   P2  => INT
   P3  => INT
   SRC => "XTAL" | "CLKIN"

Additionally, the following extra fields will be inferred from the basic
parameters, as a convenience:

   ratio_a => INT  # integral part of ratio
   ratio_b => INT  # numerator of fractional part of ratio
   ratio_c => INT  # denominator of fractional part of ratio

   ratio => NUM    # ratio expressed as a float

=cut

sub unpack_PARAMS ( $bytes )
{
   my ( $p3m, $p3l, $p1h, $p1m, $p1l, $p23h, $p2m, $p2l ) = unpack "(C)8", $bytes;
   $p1h &= 0x03;
   my $p2h = ($p23h)&0x0F;
   my $p3h = ($p23h>>4);

   return (
      P1 => $p1l | ($p1m << 8) | ($p1h << 16),
      P2 => $p2l | ($p2m << 8) | ($p2h << 16),
      P3 => $p3l | ($p3m << 8) | ($p3h << 16),
   );
}

sub pack_PARAMS ( %params )
{
   my ( $p1, $p2, $p3 ) = @params{qw( P1 P2 P3 )};
   $p1 == ($p1 & 0x3FFFF) or croak "P1 out of range";
   $p2 == ($p2 & 0xFFFFF) or croak "P2 out of range";
   $p3 == ($p3 & 0xFFFFF) or croak "P3 out of range";

   return pack "C C C C C C C C",
      ($p3>>8)&0xFF, ($p3)&0xFF,             ($p1>>16),     ($p1>>8)&0xFF,
      ($p1)&0xFF,    ($p3>>16)<<4|($p2>>16), ($p2>>8)&0xFF, ($p2)&0xFF;
}

sub _infer_ratio ( $config )
{
   if( $config->{P2} == 0 ) {
      $config->{ratio_a} = ( $config->{P1} + 512 ) / 128;
      $config->{ratio_b} = 0;
      $config->{ratio_c} = 1;
   }
   else {
      my $ratio_c = $config->{ratio_c} = $config->{P3};
      my $P1_ = $config->{P1} + 512;
      $config->{ratio_a} = floor( $P1_ / 128 );
      my $floor = $P1_ - 128 * $config->{ratio_a};
      $config->{ratio_b} = floor( ( $config->{P2} + $floor * $ratio_c ) / 128 );
   }

   $config->{ratio} = $config->{ratio_a} + $config->{ratio_b} / $config->{ratio_c};
}

sub _calc_param ( $config )
{
   # These equations taken straight from AN691
   my ( $ratio_a, $ratio_b, $ratio_c ) = @{$config}{qw( ratio_a ratio_b ratio_c )};

   my $floor = floor( 128 * $ratio_b / $ratio_c );
   $config->{P1} = 128 * $ratio_a + $floor - 512;
   $config->{P2} = 128 * $ratio_b - $ratio_c * $floor;
   $config->{P3} = $ratio_c;
}

async method read_pll_config ( $pll )
{
   my $regbase = ( $pll eq "A" ) ? REG_MSNA_BASE :
                 ( $pll eq "B" ) ? REG_MSNB_BASE : croak "Invalid PLL choice '$pll'";

   my $bytes = await $self->cached_read_reg( $regbase, 8 );

   my %config = unpack_PARAMS( $bytes );

   my $pllsrc = unpack "C", await $self->cached_read_reg( REG_PLLSOURCE, 1 );
   $pllsrc &= ( $pll eq "A" ) ? (1<<2) : (1<<3);

   $config{SRC} = (qw( XTAL CLKIN ))[ !!$pllsrc ];

   _infer_ratio \%config;

   return \%config;
}

=head2 change_pll_config

   await $chip->change_pll_config( $pll, %changes )

Writes changes to the PLL synthesizer configuration registers for the given
PLL unit. Any fields not specified will retain their current values.

As a convenience, the feedback division ratio can be supplied using the three
C<ratio_...> parameters, rather than the raw C<Pn> values.

To set an integer ratio, this can alternatively be supplied directly by the
C<ratio> parameter. This must be an integer, however. To avoid floating-point
inaccuracies in fractional ratios, the three C<ratio_...> parameters must be
used if the ratio is not a simple integer.

=cut

async method change_pll_config ( $pll, %changes )
{
   my $regbase = ( $pll eq "A" ) ? REG_MSNA_BASE :
                 ( $pll eq "B" ) ? REG_MSNB_BASE : croak "Invalid PLL choice '$pll'";

   my $config = await $self->read_pll_config( $pll );

   if( exists $changes{ratio} ) {
      my $ratio = delete $changes{ratio};

      15 <= $ratio and $ratio < 91 or
         croak "Cannot set PLL multiplier ratio to $ratio";
      $ratio == int $ratio or
         croak "Cannot use 'ratio' to set a non-integer ratio; please supply ratio_a, ratio_b, ratio_c individually";

      $changes{ratio_a} = $ratio;
      $changes{ratio_b} = 0;
      $changes{ratio_c} = 1;
   }

   if( exists $changes{ratio_a} or exists $changes{ratio_b} or exists $changes{ratio_c} ) {
      _calc_param( \%changes );
   }

   exists $changes{$_} and $config->{$_} = $changes{$_} for qw( P1 P2 P3 );

   my $bytes = pack_PARAMS( %$config );

   await $self->cached_write_reg( $regbase, $bytes );

   await $self->reset_plls;
}

=head2 reset_plls

   await $chip->reset_plls;

Resets the PLLs. This method should be called at the end of configuration to
reset the PLL and divider units to begin outputting the configured
frequencies.

=cut

async method reset_plls ()
{
   # This magic value 0xAC doesn't appear in the data sheet itself, but most
   # of the other drivers use it anyway and it seems to work.
   await $self->write_reg( REG_PLLRST, pack "C", 0xAC );
}

=head2 read_multisynth_config

   $config = await $chip->read_multisynth_config( $idx )

Reads and returns the Multisynth frequency divider configuration registers for
the given unit (which should be an integer C<0> to C<5>), as a C<HASH>
reference with the following keys:

   P1     => INT
   P2     => INT
   P3     => INT
   DIVBY4 => BOOL
   INT    => BOOL
   SRC    => "PLLA" | "PLLB"
   PHOFF  => INT

Note that this method returns the setting of the appropriate phase-offset
register. Even though the datasheet names this as if it were related to the
clock output unit, it in fact relates to the Multisynth divider.

Additionally, the following extra fields will be inferred from the basic
parameters, as a convenience:

   ratio_a => INT  # integral part of ratio
   ratio_b => INT  # numerator of fractional part of ratio
   ratio_c => INT  # denominator of fractional part of ratio

   ratio => NUM    # ratio expressed as a float

Note that the integer-only Multisynth units 6 and 7 are not currently
supported.

=cut

bitfield { format => "bytes-LE" }, MS_CLKCTRL =>
   # REG_CLKnCTRL
   INT => boolfield( 6 ),
   SRC => enumfield( 5, qw( PLLA PLLB ) ),
;

async method read_multisynth_config ( $idx )
{
   # TODO: multisynths 6 and 7 are integer-only and different layout

   $idx >= 0 and $idx <= 5 or croak "Invalid Multisynth choice '$idx'";
   my $regbase = REG_MSx_BASE + 8*$idx;

   my $parambytes  = await $self->cached_read_reg( $regbase, 8 );
   my $clkctrlbyte = await $self->cached_read_reg( REG_CLKCTRL_BASE + $idx, 1 );

   my %config = (
      unpack_PARAMS( $parambytes ),
      unpack_MS_CLKCTRL( $clkctrlbyte ),
   );

   my $divby4 = ( ( unpack "x x C", $parambytes ) >> 2 ) & 0x03;
   $config{DIVBY4} = !!$divby4;

   $config{PHOFF} = unpack "C", await $self->cached_read_reg( REG_CLKx_PHOFF, 1 );

   _infer_ratio \%config;

   return \%config;
}

=head2 change_multisynth_config

   await $chip->change_multisynth_config( $pll, %changes )

Writes changes to the Multisynth frequency divider configuration registers
for the given unit. Any fields not specified will retain their current values.

As a convenience, the division ratio can be supplied using the three
C<ratio_...> parameters, rather than the raw C<Pn> values.

To set an integer ratio, this can alternatively be supplied directly by the
C<ratio> parameter. This must be an integer, however. To avoid floating-point
inaccuracies in fractional ratios, the three C<ratio_...> parameters must be
used if the ratio is not a simple integer.

=cut

async method change_multisynth_config ( $idx, %changes )
{
   # TODO: multisynths 6 and 7 are integer-only and different layout

   $idx >= 0 and $idx <= 5 or croak "Invalid Multisynth choice '$idx'";
   my $regbase = REG_MSx_BASE + 8*$idx;

   my $config = await $self->read_multisynth_config( $idx );

   if( exists $changes{ratio} ) {
      my $ratio = delete $changes{ratio};

      8 <= $ratio and $ratio <= 2048 or
         croak "Cannot set Multisynth divider ratio to $ratio";
      $ratio == int $ratio or
         croak "Cannot use 'ratio' to set a non-integer ratio; please supply ratio_a, ratio_b, ratio_c individually";

      $changes{ratio_a} = $ratio;
      $changes{ratio_b} = 0;
      $changes{ratio_c} = 1;
   }

   if( exists $changes{ratio_a} or exists $changes{ratio_b} or exists $changes{ratio_c} ) {
      _calc_param( \%changes );
   }

   exists $changes{$_} and $config->{$_} = $changes{$_} for qw( P1 P2 P3 INT SRC );

   my $paramsbytes = pack_PARAMS( %{$config}{qw( P1 P2 P3 )} );
   my $clkctrlbyte = pack_MS_CLKCTRL( %{$config}{qw( INT SRC )} );
   my $phoff       = delete $config->{PHOFF};
   $phoff >= 0 and $phoff < 128 or
      croak "Invalid PHOFF setting";

   await $self->cached_write_reg_masked( $regbase, $paramsbytes, "\xFF\xFF\x03\xFF\xFF\xFF\xFF\xFF" );
   await $self->cached_write_reg_masked( REG_CLKCTRL_BASE + $idx, $clkctrlbyte, "\x60" );
   await $self->cached_write_reg       ( REG_CLKx_PHOFF, pack "C", $phoff );
}

=head2 read_clk_config

   $config = $chip->read_clk_config( $idx )

Reads and returns the clock output pin configuration registers for the given
pin index (in the range 0 to 5), as a C<HASH> reference with the following
keys:

   IDRV => "2mA" | "4mA" | "6mA" | "8mA"
   SRC  => "XTAL" | "CLKIN" | "MS04" | "MSn"
   INV  => BOOL
   PDN  => BOOL
   DIV  => 1 | 2 | 4 | 8 | 16 | 32 | 64 | 128
   OE   => BOOL

Note that the C<OE> field has positive logic; it is true when the output is
enabled (by the C<OEMASK> register having a 0 bit in the corresponding
position).

=cut

bitfield { format => "bytes-LE" }, CLKCTRL =>
   # REG_CLKnCTRL
   IDRV => enumfield(  0, qw( 2mA 4mA 6mA 8mA ) ),
   SRC  => enumfield(  2, qw( XTAL CLKIN MS04 MSn ) ),
   INV  => boolfield(  4 ),
   PDN  => boolfield(  7 ),
   # REG_MSnBASE+2
   DIV  => enumfield( 12, qw( 1 2 4 8 16 32 64 128 ) ),
;

async method read_clk_config ( $idx )
{
   $idx >= 0 and $idx <= 7 or croak "Invalid Clk choice '$idx'";

   my $bytes = join "",
      await $self->cached_read_reg( REG_CLKCTRL_BASE + $idx, 1 ),
      await $self->cached_read_reg( REG_MSx_BASE + 8*$idx + 2, 1 );

   my %config = unpack_CLKCTRL( $bytes );

   my $oemask = unpack "C", await $self->cached_read_reg( REG_OEMASK, 1 );
   $config{OE} = !( $oemask & (1<<$idx) );

   return \%config;
}

=head2 change_clk_config

   await $chip->change_clk_config( $idx, %changes );

Writes changes to the clock output pin configuration registers for the given
pin index. Any fields not specified will retain their current values.

=cut

async method change_clk_config ( $idx, %changes )
{
   $idx >= 0 and $idx <= 7 or croak "Invalid Clk choice '$idx'";

   my $config = await $self->read_clk_config( $idx );

   $config->{$_} = $changes{$_} for keys %changes;

   # OE is inverted sense
   my $oemask = delete $config->{OE} ? "\x00" : "\xFF";
   my ( $clkctrl, $ms ) = unpack "(a1)*", pack_CLKCTRL( %$config );

   await $self->cached_write_reg_masked( REG_CLKCTRL_BASE + $idx,   $clkctrl, "\x9F" );
   await $self->cached_write_reg_masked( REG_MSx_BASE + 8*$idx + 2, $ms,      "\xFC" );

   await $self->cached_write_reg_masked( REG_OEMASK, $oemask, pack "C", (1<<$idx) );
}

=head1 TODO

This module is missing support for several chip features, mostly because I
only have the MSOP-10 version of the F<Si5351A> chip, so I cannot actually
test:

=over 4

=item *

Integer-only multisynth units 6 and 7 and their associated clock output pins.

=item *

The VCXO of F<Si5351B>.

=item *

The CLKIN of F<Si5351C>.

=back

Additionally, lacking a spectrum analyser I cannot confirm operation of:

=over 4

=item *

Spread-spectrum parameters of PLLA.

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
