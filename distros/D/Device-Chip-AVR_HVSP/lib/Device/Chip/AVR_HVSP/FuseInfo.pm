#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2015 -- leonerd@leonerd.org.uk

package Device::Chip::AVR_HVSP::FuseInfo;

use v5.26;
use warnings;

our $VERSION = '0.05';

use Carp;

use Struct::Dumb qw( readonly_struct );

readonly_struct Fuse => [qw( name offset mask caption values )];
readonly_struct FuseEnumValue => [qw( name value caption )];

my %info_for;

=head1 NAME

C<Device::Chip::AVR_HVSP::FuseInfo> - information about device fuses

=head1 DESCRIPTION

Objects in this class contain information about the configuration fuses of a
single F<AVR> HVSP-programmable device. These instances may be useful for
encoding and decoding the fuse bytes, for display or other purposes in some
user-interactive manner.

=cut

=head1 CONSTRUCTOR

=head2 $fuseinfo = Device::Chip::AVR_HVSP::FuseInfo->for_part( $part )

Returns a new C<Device::Chip::AVR_HVSP::FuseInfo> instance containing
information about the fuses for the given part name.

=cut

sub for_part
{
   my $class = shift;
   my ( $part ) = @_;

   $info_for{$part} or croak "No defined fuses for $part";

   return bless { %{ $info_for{$part} } }, $class;
}

=head1 METHODS

=cut

=head2 @fuses = $fuseinfo->fuses

Returns a list of objects, each one representing a single configuration fuse.
Each has the following fields:

 $fuse->name
 $fuse->offset
 $fuse->mask
 $fuse->caption
 @values = $fuse->values

If the C<values> method gives a non-empty list of values, then the fuse is an
enumeration; otherwise it is a simple boolean true/false flag. For enumeration
fuses, each value item has the following fields:

 $value->name
 $value->value
 $value->caption

=cut

sub fuses
{
   my $self = shift;
   return @{ $self->{fuses} };
}

=head2 %fields = $fuseinfo->unpack( $bytes )

Given a byte string containing all the fuses read from the device, unpacks
them and returns a key-value list giving the current value of every fuse.

=cut

sub unpack
{
   my $self = shift;
   my ( $bytes ) = @_;

   my %ret;
   foreach my $f ( $self->fuses ) {
      my $bits = ord( substr $bytes, $f->offset, 1 ) & $f->mask;

      $ret{$f->name} = $bits;
   }

   return %ret;
}

=head2 $bytes = $fuseinfo->pack( %fields )

Given a key-value list containing fuse values, packs them into a byte string
suitable to write onto the device and returns it.

=cut

sub pack
{
   my $self = shift;
   my %fuses = @_;

   my $bytes = ~$self->{mask};
   foreach my $f ( $self->fuses ) {
      my $v = $fuses{$f->name};

      if( $f->values ) {
         # Value check enum fuse
         croak "Invalid value for ${\$f->name}: $v" if $v & ~$f->mask;
      }
      else {
         $v = $f->mask if $v;
      }

      substr( $bytes, $f->offset, 1 ) |= chr( $f->mask & $v );
   }

   return $bytes;
}

my $info;

LINE: while( my $line = <DATA> ) {
   if( $line =~ m/^DEVICE name=(\S+)$/ ) {
      $info = {} if keys %$info; # new device
      $info_for{$1} = $info;
   }
   elsif( $line =~ m/^MASK (\d+) (\d+)$/ ) {
      $info->{mask} ||= "";
      $info->{mask} .= "\0" until length $info->{mask} >= $1;
      substr( $info->{mask}, $1, 1 ) = chr $2;
   }
   elsif( $line =~ m/^BIT (\S+) (\d+) (\d+): (.*)$/ ) {
      push @{ $info->{fuses} }, Fuse( $1, $2, $3+0, $4, undef );
   }
   elsif( $line =~ m/^ENUM (\S+) (\d+) (\d+): (.*)$/ ) {
      my $values = [];
      push @{ $info->{fuses} }, Fuse( $1, $2, $3+0, $4, $values );

      while( $line = <DATA> ) {
         $line =~ m/^  VALUE (\S+) (\d+): (.*)$/ or redo LINE;
         push @$values, FuseEnumValue( $1, $2, $3 );
      }
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

__DATA__
DEVICE name=ATtiny13A
DEVICE name=ATtiny13
MASK 1 31
BIT SELFPRGEN 1 16: Self Programming enable
BIT DWEN 1 8: Debug Wire enable
ENUM BODLEVEL 1 6: Enable BOD and select level
  VALUE 4V3 0: Brown-out detection at VCC=4.3 V
  VALUE 2V7 2: Brown-out detection at VCC=2.7 V
  VALUE 1V8 4: Brown-out detection at VCC=1.8 V
  VALUE DISABLED 6: Brown-out detection disabled
BIT RSTDISBL 1 1: Reset Disabled (Enable PB5 as i/o pin)
MASK 0 255
BIT SPIEN 0 128: Serial program downloading (SPI) enabled
BIT EESAVE 0 64: Preserve EEPROM through the Chip Erase cycle
BIT WDTON 0 32: Watch-dog Timer always on
BIT CKDIV8 0 16: Divide clock by 8 internally
ENUM SUT_CKSEL 0 15: Select Clock Source
  VALUE EXTCLK_14CK_0MS 0: Ext. Clock; Start-up time: 14 CK + 0 ms
  VALUE EXTCLK_14CK_4MS 4: Ext. Clock; Start-up time: 14 CK + 4 ms
  VALUE EXTCLK_14CK_64MS 8: Ext. Clock; Start-up time: 14 CK + 64 ms
  VALUE INTRCOSC_4MHZ8_14CK_0MS 1: Int. RC Osc. 4.8 MHz; Start-up time: 14 CK + 0 ms
  VALUE INTRCOSC_4MHZ8_14CK_4MS 5: Int. RC Osc. 4.8 MHz; Start-up time: 14 CK + 4 ms
  VALUE INTRCOSC_4MHZ8_14CK_64MS 9: Int. RC Osc. 4.8 MHz; Start-up time: 14 CK + 64 ms
  VALUE INTRCOSC_9MHZ6_14CK_0MS 2: Int. RC Osc. 9.6 MHz; Start-up time: 14 CK + 0 ms
  VALUE INTRCOSC_9MHZ6_14CK_4MS 6: Int. RC Osc. 9.6 MHz; Start-up time: 14 CK + 4 ms
  VALUE INTRCOSC_9MHZ6_14CK_64MS 10: Int. RC Osc. 9.6 MHz; Start-up time: 14 CK + 64 ms
  VALUE INTRCOSC_128KHZ_14CK_0MS 3: Int. RC Osc. 128 kHz; Start-up time: 14 CK + 0 ms
  VALUE INTRCOSC_128KHZ_14CK_4MS 7: Int. RC Osc. 128 kHz; Start-up time: 14 CK + 4 ms
  VALUE INTRCOSC_128KHZ_14CK_64MS 11: Int. RC Osc. 128 kHz; Start-up time: 14 CK + 64 ms

DEVICE name=ATtiny24A
DEVICE name=ATtiny24
DEVICE name=ATtiny44A
DEVICE name=ATtiny44
DEVICE name=ATtiny84A
DEVICE name=ATtiny84
MASK 2 1
BIT SELFPRGEN 2 1: Self Programming enable
MASK 1 255
BIT RSTDISBL 1 128: Reset Disabled (Enable PB3 as i/o pin)
BIT DWEN 1 64: Debug Wire enable
BIT SPIEN 1 32: Serial program downloading (SPI) enabled
BIT WDTON 1 16: Watch-dog Timer always on
BIT EESAVE 1 8: Preserve EEPROM through the Chip Erase cycle
ENUM BODLEVEL 1 7: Brown-out Detector trigger level
  VALUE DISABLED 7: Brown-out detection disabled
  VALUE 1V8 6: Brown-out detection at VCC=1.8 V
  VALUE 2V7 5: Brown-out detection at VCC=2.7 V
  VALUE 4V3 4: Brown-out detection at VCC=4.3 V
MASK 0 255
BIT CKDIV8 0 128: Divide clock by 8 internally
BIT CKOUT 0 64: Clock output on PORTB2
ENUM SUT_CKSEL 0 63: Select Clock source
  VALUE EXTCLK_6CK_14CK_0MS 0: Ext. Clock; Start-up time PWRDWN/RESET: 6 CK/14 CK + 0 ms
  VALUE EXTCLK_6CK_14CK_4MS1 16: Ext. Clock; Start-up time PWRDWN/RESET: 6 CK/14 CK + 4.1 ms
  VALUE EXTCLK_6CK_14CK_65MS 32: Ext. Clock; Start-up time PWRDWN/RESET: 6 CK/14 CK + 65 ms
  VALUE INTRCOSC_8MHZ_6CK_14CK_0MS 2: Int. RC Osc. 8 MHz; Start-up time PWRDWN/RESET: 6 CK/14 CK + 0 ms
  VALUE INTRCOSC_8MHZ_6CK_14CK_4MS 18: Int. RC Osc. 8 MHz; Start-up time PWRDWN/RESET: 6 CK/14 CK + 4 ms
  VALUE INTRCOSC_8MHZ_6CK_14CK_64MS_DEFAULT 34: Int. RC Osc. 8 MHz; Start-up time PWRDWN/RESET: 6 CK/14 CK + 64 ms; default value
  VALUE WDOSC_128KHZ_6CK_14CK_0MS 4: WD. Osc. 128 kHz; Start-up time PWRDWN/RESET: 6 CK/14 CK + 0 ms
  VALUE WDOSC_128KHZ_6CK_14CK_4MS 20: WD. Osc. 128 kHz; Start-up time PWRDWN/RESET: 6 CK/14 CK + 4 ms
  VALUE WDOSC_128KHZ_6CK_14CK_64MS 36: WD. Osc. 128 kHz; Start-up time PWRDWN/RESET: 6 CK/14 CK + 64 ms
  VALUE EXTLOFXTAL_1KCK_14CK_0MS 6: Ext. Low-Freq. Crystal; Start-up time PWRDWN/RESET: 1K CK/14 CK + 0 ms
  VALUE EXTLOFXTAL_1KCK_14CK_4MS 22: Ext. Low-Freq. Crystal; Start-up time PWRDWN/RESET: 1K CK/14 CK + 4 ms
  VALUE EXTLOFXTAL_32KCK_14CK_64MS 38: Ext. Low-Freq. Crystal; Start-up time PWRDWN/RESET: 32K CK/14 CK + 64 ms
  VALUE EXTXOSC_0MHZ4_0MHZ9_258CK_14CK_4MS1 8: Ext. Crystal Osc. 0.4-0.9 MHz; Start-up time PWRDWN/RESET: 258 CK/14 CK + 4.1 ms
  VALUE EXTXOSC_0MHZ4_0MHZ9_258CK_14CK_65MS 24: Ext. Crystal Osc. 0.4-0.9 MHz; Start-up time PWRDWN/RESET: 258 CK/14 CK + 65 ms
  VALUE EXTXOSC_0MHZ4_0MHZ9_1KCK_14CK_0MS 40: Ext. Crystal Osc. 0.4-0.9 MHz; Start-up time PWRDWN/RESET: 1K CK /14 CK + 0 ms
  VALUE EXTXOSC_0MHZ4_0MHZ9_1KCK_14CK_4MS1 56: Ext. Crystal Osc. 0.4-0.9 MHz; Start-up time PWRDWN/RESET: 1K CK /14 CK + 4.1 ms
  VALUE EXTXOSC_0MHZ4_0MHZ9_1KCK_14CK_65MS 9: Ext. Crystal Osc. 0.4-0.9 MHz; Start-up time PWRDWN/RESET: 1K CK /14 CK + 65 ms
  VALUE EXTXOSC_0MHZ4_0MHZ9_16KCK_14CK_0MS 25: Ext. Crystal Osc. 0.4-0.9 MHz; Start-up time PWRDWN/RESET: 16K CK/14 CK + 0 ms
  VALUE EXTXOSC_0MHZ4_0MHZ9_16KCK_14CK_4MS1 41: Ext. Crystal Osc. 0.4-0.9 MHz; Start-up time PWRDWN/RESET: 16K CK/14 CK + 4.1 ms
  VALUE EXTXOSC_0MHZ4_0MHZ9_16KCK_14CK_65MS 57: Ext. Crystal Osc. 0.4-0.9 MHz; Start-up time PWRDWN/RESET: 16K CK/14 CK + 65 ms
  VALUE EXTXOSC_0MHZ9_3MHZ_258CK_14CK_4MS1 10: Ext. Crystal Osc. 0.9-3.0 MHz; Start-up time PWRDWN/RESET: 258 CK/14 CK + 4.1 ms
  VALUE EXTXOSC_0MHZ9_3MHZ_258CK_14CK_65MS 26: Ext. Crystal Osc. 0.9-3.0 MHz; Start-up time PWRDWN/RESET: 258 CK/14 CK + 65 ms
  VALUE EXTXOSC_0MHZ9_3MHZ_1KCK_14CK_0MS 42: Ext. Crystal Osc. 0.9-3.0 MHz; Start-up time PWRDWN/RESET: 1K CK /14 CK + 0 ms
  VALUE EXTXOSC_0MHZ9_3MHZ_1KCK_14CK_4MS1 58: Ext. Crystal Osc. 0.9-3.0 MHz; Start-up time PWRDWN/RESET: 1K CK /14 CK + 4.1 ms
  VALUE EXTXOSC_0MHZ9_3MHZ_1KCK_14CK_65MS 11: Ext. Crystal Osc. 0.9-3.0 MHz; Start-up time PWRDWN/RESET: 1K CK /14 CK + 65 ms
  VALUE EXTXOSC_0MHZ9_3MHZ_16KCK_14CK_0MS 27: Ext. Crystal Osc. 0.9-3.0 MHz; Start-up time PWRDWN/RESET: 16K CK/14 CK + 0 ms
  VALUE EXTXOSC_0MHZ9_3MHZ_16KCK_14CK_4MS1 43: Ext. Crystal Osc. 0.9-3.0 MHz; Start-up time PWRDWN/RESET: 16K CK/14 CK + 4.1 ms
  VALUE EXTXOSC_0MHZ9_3MHZ_16KCK_14CK_65MS 59: Ext. Crystal Osc. 0.9-3.0 MHz; Start-up time PWRDWN/RESET: 16K CK/14 CK + 65 ms
  VALUE EXTXOSC_3MHZ_8MHZ_258CK_14CK_4MS1 12: Ext. Crystal Osc. 3.0-8.0 MHz; Start-up time PWRDWN/RESET: 258 CK/14 CK + 4.1 ms
  VALUE EXTXOSC_3MHZ_8MHZ_258CK_14CK_65MS 28: Ext. Crystal Osc. 3.0-8.0 MHz; Start-up time PWRDWN/RESET: 258 CK/14 CK + 65 ms
  VALUE EXTXOSC_3MHZ_8MHZ_1KCK_14CK_0MS 44: Ext. Crystal Osc. 3.0-8.0 MHz; Start-up time PWRDWN/RESET: 1K CK /14 CK + 0 ms
  VALUE EXTXOSC_3MHZ_8MHZ_1KCK_14CK_4MS1 60: Ext. Crystal Osc. 3.0-8.0 MHz; Start-up time PWRDWN/RESET: 1K CK /14 CK + 4.1 ms
  VALUE EXTXOSC_3MHZ_8MHZ_1KCK_14CK_65MS 13: Ext. Crystal Osc. 3.0-8.0 MHz; Start-up time PWRDWN/RESET: 1K CK /14 CK + 65 ms
  VALUE EXTXOSC_3MHZ_8MHZ_16KCK_14CK_0MS 29: Ext. Crystal Osc. 3.0-8.0 MHz; Start-up time PWRDWN/RESET: 16K CK/14 CK + 0 ms
  VALUE EXTXOSC_3MHZ_8MHZ_16KCK_14CK_4MS1 45: Ext. Crystal Osc. 3.0-8.0 MHz; Start-up time PWRDWN/RESET: 16K CK/14 CK + 4.1 ms
  VALUE EXTXOSC_3MHZ_8MHZ_16KCK_14CK_65MS 61: Ext. Crystal Osc. 3.0-8.0 MHz; Start-up time PWRDWN/RESET: 16K CK/14 CK + 65 ms
  VALUE EXTXOSC_8MHZ_XX_258CK_14CK_4MS1 14: Ext. Crystal Osc. 8.0-    MHz; Start-up time PWRDWN/RESET: 258 CK/14 CK + 4.1 ms
  VALUE EXTXOSC_8MHZ_XX_258CK_14CK_65MS 30: Ext. Crystal Osc. 8.0-    MHz; Start-up time PWRDWN/RESET: 258 CK/14 CK + 65 ms
  VALUE EXTXOSC_8MHZ_XX_1KCK_14CK_0MS 46: Ext. Crystal Osc. 8.0-    MHz; Start-up time PWRDWN/RESET: 1K CK /14 CK + 0 ms
  VALUE EXTXOSC_8MHZ_XX_1KCK_14CK_4MS1 62: Ext. Crystal Osc. 8.0-    MHz; Start-up time PWRDWN/RESET: 1K CK /14 CK + 4.1 ms
  VALUE EXTXOSC_8MHZ_XX_1KCK_14CK_65MS 15: Ext. Crystal Osc. 8.0-    MHz; Start-up time PWRDWN/RESET: 1K CK /14 CK + 65 ms
  VALUE EXTXOSC_8MHZ_XX_16KCK_14CK_0MS 31: Ext. Crystal Osc. 8.0-    MHz; Start-up time PWRDWN/RESET: 16K CK/14 CK + 0 ms
  VALUE EXTXOSC_8MHZ_XX_16KCK_14CK_4MS1 47: Ext. Crystal Osc. 8.0-    MHz; Start-up time PWRDWN/RESET: 16K CK/14 CK + 4.1 ms
  VALUE EXTXOSC_8MHZ_XX_16KCK_14CK_65MS 63: Ext. Crystal Osc. 8.0-    MHz; Start-up time PWRDWN/RESET: 16K CK/14 CK + 65 ms

DEVICE name=ATtiny25
DEVICE name=ATtiny45
DEVICE name=ATtiny85
MASK 2 1
BIT SELFPRGEN 2 1: Self Programming enable
MASK 1 255
BIT RSTDISBL 1 128: Reset Disabled (Enable PB5 as i/o pin)
BIT DWEN 1 64: Debug Wire enable
BIT SPIEN 1 32: Serial program downloading (SPI) enabled
BIT WDTON 1 16: Watch-dog Timer always on
BIT EESAVE 1 8: Preserve EEPROM through the Chip Erase cycle
ENUM BODLEVEL 1 7: Brown-out Detector trigger level
  VALUE DISABLED 7: Brown-out detection disabled
  VALUE 1V8 6: Brown-out detection at VCC=1.8 V
  VALUE 2V7 5: Brown-out detection at VCC=2.7 V
  VALUE 4V3 4: Brown-out detection at VCC=4.3 V
MASK 0 255
BIT CKDIV8 0 128: Divide clock by 8 internally
BIT CKOUT 0 64: Clock output on PORTB4
ENUM SUT_CKSEL 0 63: Select Clock source
  VALUE EXTCLK_6CK_14CK_0MS 0: Ext. Clock; Start-up time PWRDWN/RESET: 6 CK/14 CK + 0 ms
  VALUE EXTCLK_6CK_14CK_4MS1 16: Ext. Clock; Start-up time PWRDWN/RESET: 6 CK/14 CK + 4.1 ms
  VALUE EXTCLK_6CK_14CK_65MS 32: Ext. Clock; Start-up time PWRDWN/RESET: 6 CK/14 CK + 65 ms
  VALUE PLLCLK_1KCK_14CK_4MS 1: PLL Clock; Start-up time PWRDWN/RESET: 1K CK/14 CK + 4 ms
  VALUE PLLCLK_16KCK_14CK_4MS 17: PLL Clock; Start-up time PWRDWN/RESET: 16K CK/14 CK + 4 ms
  VALUE PLLCLK_1KCK_14CK_64MS 33: PLL Clock; Start-up time PWRDWN/RESET: 1K CK/14 CK + 64 ms
  VALUE PLLCLK_16KCK_14CK_64MS 49: PLL Clock; Start-up time PWRDWN/RESET: 16K CK/14 CK + 64 ms
  VALUE INTRCOSC_8MHZ_6CK_14CK_0MS 2: Int. RC Osc. 8 MHz; Start-up time PWRDWN/RESET: 6 CK/14 CK + 0 ms
  VALUE INTRCOSC_8MHZ_6CK_14CK_4MS 18: Int. RC Osc. 8 MHz; Start-up time PWRDWN/RESET: 6 CK/14 CK + 4 ms
  VALUE INTRCOSC_8MHZ_6CK_14CK_64MS 34: Int. RC Osc. 8 MHz; Start-up time PWRDWN/RESET: 6 CK/14 CK + 64 ms
  VALUE INTRCOSC_4MHZ_6CK_14CK_64MS 3: ATtiny15 Comp: Int. RC Osc. 6.4 MHz; Start-up time PWRDWN/RESET: 6 CK/14 CK + 64 ms
  VALUE INTRCOSC_4MHZ_6CK_14CK_64MS 19: ATtiny15 Comp: Int. RC Osc. 6.4 MHz; Start-up time PWRDWN/RESET: 6 CK/14 CK + 64 ms
  VALUE INTRCOSC_4MHZ_6CK_14CK_4MS 35: ATtiny15 Comp: Int. RC Osc. 6.4 MHz; Start-up time PWRDWN/RESET: 6 CK/14 CK + 4 ms
  VALUE INTRCOSC_4MHZ_1CK_14CK_0MS 51: ATtiny15 Comp: Int. RC Osc. 6.4 MHz; Start-up time PWRDWN/RESET: 1 CK/14 CK + 0 ms
  VALUE WDOSC_128KHZ_6CK_14CK_0MS 4: WD. Osc. 128 kHz; Start-up time PWRDWN/RESET: 6 CK/14 CK + 0 ms
  VALUE WDOSC_128KHZ_6CK_14CK_4MS 20: WD. Osc. 128 kHz; Start-up time PWRDWN/RESET: 6 CK/14 CK + 4 ms
  VALUE WDOSC_128KHZ_6CK_14CK_64MS 36: WD. Osc. 128 kHz; Start-up time PWRDWN/RESET: 6 CK/14 CK + 64 ms
  VALUE EXTLOFXTAL_1KCK_14CK_0MS 6: Ext. Low-Freq. Crystal; Start-up time PWRDWN/RESET: 1K CK/14 CK + 0 ms
  VALUE EXTLOFXTAL_1KCK_14CK_4MS 22: Ext. Low-Freq. Crystal; Start-up time PWRDWN/RESET: 1K CK/14 CK + 4 ms
  VALUE EXTLOFXTAL_32KCK_14CK_64MS 38: Ext. Low-Freq. Crystal; Start-up time PWRDWN/RESET: 32K CK/14 CK + 64 ms
  VALUE EXTXOSC_0MHZ4_0MHZ9_258CK_14CK_4MS1 8: Ext. Crystal Osc. 0.4-0.9 MHz; Start-up time PWRDWN/RESET: 258 CK/14 CK + 4.1 ms
  VALUE EXTXOSC_0MHZ4_0MHZ9_258CK_14CK_65MS 24: Ext. Crystal Osc. 0.4-0.9 MHz; Start-up time PWRDWN/RESET: 258 CK/14 CK + 65 ms
  VALUE EXTXOSC_0MHZ4_0MHZ9_1KCK_14CK_0MS 40: Ext. Crystal Osc. 0.4-0.9 MHz; Start-up time PWRDWN/RESET: 1K CK /14 CK + 0 ms
  VALUE EXTXOSC_0MHZ4_0MHZ9_1KCK_14CK_4MS1 56: Ext. Crystal Osc. 0.4-0.9 MHz; Start-up time PWRDWN/RESET: 1K CK /14 CK + 4.1 ms
  VALUE EXTXOSC_0MHZ4_0MHZ9_1KCK_14CK_65MS 9: Ext. Crystal Osc. 0.4-0.9 MHz; Start-up time PWRDWN/RESET: 1K CK /14 CK + 65 ms
  VALUE EXTXOSC_0MHZ4_0MHZ9_16KCK_14CK_0MS 25: Ext. Crystal Osc. 0.4-0.9 MHz; Start-up time PWRDWN/RESET: 16K CK/14 CK + 0 ms
  VALUE EXTXOSC_0MHZ4_0MHZ9_16KCK_14CK_4MS1 41: Ext. Crystal Osc. 0.4-0.9 MHz; Start-up time PWRDWN/RESET: 16K CK/14 CK + 4.1 ms
  VALUE EXTXOSC_0MHZ4_0MHZ9_16KCK_14CK_65MS 57: Ext. Crystal Osc. 0.4-0.9 MHz; Start-up time PWRDWN/RESET: 16K CK/14 CK + 65 ms
  VALUE EXTXOSC_0MHZ9_3MHZ_258CK_14CK_4MS1 10: Ext. Crystal Osc. 0.9-3.0 MHz; Start-up time PWRDWN/RESET: 258 CK/14 CK + 4.1 ms
  VALUE EXTXOSC_0MHZ9_3MHZ_258CK_14CK_65MS 26: Ext. Crystal Osc. 0.9-3.0 MHz; Start-up time PWRDWN/RESET: 258 CK/14 CK + 65 ms
  VALUE EXTXOSC_0MHZ9_3MHZ_1KCK_14CK_0MS 42: Ext. Crystal Osc. 0.9-3.0 MHz; Start-up time PWRDWN/RESET: 1K CK /14 CK + 0 ms
  VALUE EXTXOSC_0MHZ9_3MHZ_1KCK_14CK_4MS1 58: Ext. Crystal Osc. 0.9-3.0 MHz; Start-up time PWRDWN/RESET: 1K CK /14 CK + 4.1 ms
  VALUE EXTXOSC_0MHZ9_3MHZ_1KCK_14CK_65MS 11: Ext. Crystal Osc. 0.9-3.0 MHz; Start-up time PWRDWN/RESET: 1K CK /14 CK + 65 ms
  VALUE EXTXOSC_0MHZ9_3MHZ_16KCK_14CK_0MS 27: Ext. Crystal Osc. 0.9-3.0 MHz; Start-up time PWRDWN/RESET: 16K CK/14 CK + 0 ms
  VALUE EXTXOSC_0MHZ9_3MHZ_16KCK_14CK_4MS1 43: Ext. Crystal Osc. 0.9-3.0 MHz; Start-up time PWRDWN/RESET: 16K CK/14 CK + 4.1 ms
  VALUE EXTXOSC_0MHZ9_3MHZ_16KCK_14CK_65MS 59: Ext. Crystal Osc. 0.9-3.0 MHz; Start-up time PWRDWN/RESET: 16K CK/14 CK + 65 ms
  VALUE EXTXOSC_3MHZ_8MHZ_258CK_14CK_4MS1 12: Ext. Crystal Osc. 3.0-8.0 MHz; Start-up time PWRDWN/RESET: 258 CK/14 CK + 4.1 ms
  VALUE EXTXOSC_3MHZ_8MHZ_258CK_14CK_65MS 28: Ext. Crystal Osc. 3.0-8.0 MHz; Start-up time PWRDWN/RESET: 258 CK/14 CK + 65 ms
  VALUE EXTXOSC_3MHZ_8MHZ_1KCK_14CK_0MS 44: Ext. Crystal Osc. 3.0-8.0 MHz; Start-up time PWRDWN/RESET: 1K CK /14 CK + 0 ms
  VALUE EXTXOSC_3MHZ_8MHZ_1KCK_14CK_4MS1 60: Ext. Crystal Osc. 3.0-8.0 MHz; Start-up time PWRDWN/RESET: 1K CK /14 CK + 4.1 ms
  VALUE EXTXOSC_3MHZ_8MHZ_1KCK_14CK_65MS 13: Ext. Crystal Osc. 3.0-8.0 MHz; Start-up time PWRDWN/RESET: 1K CK /14 CK + 65 ms
  VALUE EXTXOSC_3MHZ_8MHZ_16KCK_14CK_0MS 29: Ext. Crystal Osc. 3.0-8.0 MHz; Start-up time PWRDWN/RESET: 16K CK/14 CK + 0 ms
  VALUE EXTXOSC_3MHZ_8MHZ_16KCK_14CK_4MS1 45: Ext. Crystal Osc. 3.0-8.0 MHz; Start-up time PWRDWN/RESET: 16K CK/14 CK + 4.1 ms
  VALUE EXTXOSC_3MHZ_8MHZ_16KCK_14CK_65MS 61: Ext. Crystal Osc. 3.0-8.0 MHz; Start-up time PWRDWN/RESET: 16K CK/14 CK + 65 ms
  VALUE EXTXOSC_8MHZ_XX_258CK_14CK_4MS1 14: Ext. Crystal Osc. 8.0-    MHz; Start-up time PWRDWN/RESET: 258 CK/14 CK + 4.1 ms
  VALUE EXTXOSC_8MHZ_XX_258CK_14CK_65MS 30: Ext. Crystal Osc. 8.0-    MHz; Start-up time PWRDWN/RESET: 258 CK/14 CK + 65 ms
  VALUE EXTXOSC_8MHZ_XX_1KCK_14CK_0MS 46: Ext. Crystal Osc. 8.0-    MHz; Start-up time PWRDWN/RESET: 1K CK /14 CK + 0 ms
  VALUE EXTXOSC_8MHZ_XX_1KCK_14CK_4MS1 62: Ext. Crystal Osc. 8.0-    MHz; Start-up time PWRDWN/RESET: 1K CK /14 CK + 4.1 ms
  VALUE EXTXOSC_8MHZ_XX_1KCK_14CK_65MS 15: Ext. Crystal Osc. 8.0-    MHz; Start-up time PWRDWN/RESET: 1K CK /14 CK + 65 ms
  VALUE EXTXOSC_8MHZ_XX_16KCK_14CK_0MS 31: Ext. Crystal Osc. 8.0-    MHz; Start-up time PWRDWN/RESET: 16K CK/14 CK + 0 ms
  VALUE EXTXOSC_8MHZ_XX_16KCK_14CK_4MS1 47: Ext. Crystal Osc. 8.0-    MHz; Start-up time PWRDWN/RESET: 16K CK/14 CK + 4.1 ms
  VALUE EXTXOSC_8MHZ_XX_16KCK_14CK_65MS 63: Ext. Crystal Osc. 8.0-    MHz; Start-up time PWRDWN/RESET: 16K CK/14 CK + 65 ms

DEVICE name=ATtiny441
DEVICE name=ATtiny841
MASK 2 255
ENUM ULPOSCSEL 2 224: Frequency selection for internal ULP oscillator. The selection only affects system clock, watchdog and reset timeout always use 32 kHz clock.
  VALUE ULPOSC_32KHZ 224: 32 kHz
  VALUE ULPOSC_64KHZ 192: 64 kHz
  VALUE ULPOSC_128KHZ 160: 128 kHz
  VALUE ULPOSC_256KHZ 128: 256 kHz
  VALUE ULPOSC_512KHZ 96: 512 kHz
ENUM BODPD 2 24: BOD mode of operation when the device is in sleep mode
  VALUE BOD_SAMPLED 8: Sampled
  VALUE BOD_ENABLED 16: Enabled
  VALUE BOD_DISABLED 24: Disabled
ENUM BODACT 2 6: BOD mode of operation when the device is active or idle
  VALUE BOD_SAMPLED 2: Sampled
  VALUE BOD_ENABLED 4: Enabled
  VALUE BOD_DISABLED 6: Disabled
BIT SELFPRGEN 2 1: Self Programming enable
MASK 1 255
BIT RSTDISBL 1 128: Reset Disabled (Enable PC2 as i/o pin)
BIT DWEN 1 64: Debug Wire enable
BIT SPIEN 1 32: Serial program downloading (SPI) enabled
BIT WDTON 1 16: Watch-dog Timer always on
BIT EESAVE 1 8: Preserve EEPROM through the Chip Erase cycle
ENUM BODLEVEL 1 7: Brown-out Detector trigger level
  VALUE 4V3 4: Brown-out detection at VCC=4.3 V
  VALUE 2V7 5: Brown-out detection at VCC=2.7 V
  VALUE 1V8 6: Brown-out detection at VCC=1.8 V
MASK 0 223
BIT CKDIV8 0 128: Divide clock by 8 internally
BIT CKOUT 0 64: Clock output on PORTC2
ENUM SUT_CKSEL 0 31: Select Clock Source
  VALUE EXTCLK_6CK_16CK_16MS 0: Ext. Clock; Start-up time PWRDWN/RESET: 6 CK/16 CK + 16 ms
  VALUE INTRCOSC_8MHZ_6CK_16CK_16MS 2: Int. RC Osc. 8 MHz; Start-up time PWRDWN/RESET: 6 CK/16 CK + 16 ms
  VALUE INTULPOSC_32KHZ_6CK_16CK_16MS 4: Int. ULP Osc.; Start-up time PWRDWN/RESET: 6 CK/16 CK + 16 ms
  VALUE EXTLOFXTAL_1KCK_16CK_16MS 6: Ext. Low-Freq. Crystal; Start-up time PWRDWN/RESET: 1K CK/16 CK + 16 ms
  VALUE EXTLOFXTAL_32KCK_14CK_16MS 22: Ext. Low-Freq. Crystal; Start-up time PWRDWN/RESET: 32K CK/16 CK + 16 ms
  VALUE EXTCRES_0MHZ4_0MHZ9_258CK_16CK_16MS 8: Ext. Ceramic Res. 0.4-0.9 MHz; Start-up time PWRDWN/RESET: 258 CK/16 CK + 16 ms
  VALUE EXTCRES_0MHZ4_0MHZ9_1KCK_16CK_16MS 24: Ext. Ceramic Res. 0.4-0.9 MHz; Start-up time PWRDWN/RESET: 1K CK/16 CK + 16 ms
  VALUE EXTXOSC_0MHZ4_0MHZ9_16KCK_16CK_16MS 9: Ext. Crystal Osc. 0.4-0.9 MHz; Start-up time PWRDWN/RESET: 16 K CK/16 CK + 16 ms
  VALUE EXTCRES_0MHZ9_3MHZ_258CK_16CK_16MS 10: Ext. Ceramic Res. 0.9-3.0 MHz; Start-up time PWRDWN/RESET: 258 CK/16 CK + 16 ms
  VALUE EXTCRES_0MHZ9_3MHZ_1KCK_16CK_16MS 26: Ext. Ceramic Res. 0.9-3.0 MHz; Start-up time PWRDWN/RESET: 1K CK/16 CK + 16 ms
  VALUE EXTXOSC_0MHZ9_3MHZ_16KCK_16CK_16MS 11: Ext. Crystal Osc. 0.9-3.0 MHz; Start-up time PWRDWN/RESET: 16 K CK/16 CK + 16 ms
  VALUE EXTCRES_3MHZ_8MHZ_258CK_16CK_16MS 12: Ext. Ceramic Res. 3.0-8.0 MHz; Start-up time PWRDWN/RESET: 258 CK/16 CK + 16 ms
  VALUE EXTCRES_3MHZ_8MHZ_1KCK_16CK_16MS 28: Ext. Ceramic Res. 3.0-8.0 MHz; Start-up time PWRDWN/RESET: 1K CK/16 CK + 16 ms
  VALUE EXTXOSC_3MHZ_8MHZ_16KCK_16CK_16MS 13: Ext. Crystal Osc. 3.0-8.0 MHz; Start-up time PWRDWN/RESET: 16 K CK/16 CK + 16 ms
  VALUE EXTCRES_8MHZ_XX_258CK_16CK_16MS 14: Ext. Ceramic Res. 8.0- MHz; Start-up time PWRDWN/RESET: 258 CK/16 CK + 16 ms
  VALUE EXTCRES_8MHZ_XX_1KCK_16CK_16MS 30: Ext. Ceramic Res. 8.0- MHz; Start-up time PWRDWN/RESET: 1K CK/16 CK + 16 ms
  VALUE EXTXOSC_8MHZ_XX_16KCK_16CK_16MS 15: Ext. Crystal Osc. 8.0- MHz; Start-up time PWRDWN/RESET: 16 K CK/16 CK + 16 ms

DEVICE name=ATA5702M322
MASK 0 255
BIT CKDIV8 0 128: Divide clock by 8 internally
BIT DWEN 0 64: Debug Wire enable
BIT SPIEN 0 32: Serial program downloading (SPI) enabled
BIT WDTON 0 16: Watch-dog Timer always on
BIT EESAVE 0 8: Preserve EEPROM memory through the Chip Erase cycle
BIT BOOTRST 0 4: Select interrupt vector location
BIT EEACC 0 2: EEPROM Access Control
BIT EXTCLKEN 0 1: External Clock enable

DEVICE name=ATmega16HVA
DEVICE name=ATmega8HVA
MASK 0 255
BIT WDTON 0 128: Watch-dog Timer always on
BIT EESAVE 0 64: Preserve EEPROM through the Chip Erase cycle
BIT SPIEN 0 32: Serial program downloading (SPI) enabled
BIT DWEN 0 16: Debug Wire enable
BIT SELFPRGEN 0 8: Self Programming enable
ENUM SUT 0 7: Select start-up time
  VALUE 6CK_14CK_4MS 0: Start-up time 6 CK/14 CK + 4 ms
  VALUE 6CK_14CK_8MS 1: Start-up time 6 CK/14 CK + 8 ms
  VALUE 6CK_14CK_16MS 2: Start-up time 6 CK/14 CK + 16 ms
  VALUE 6CK_14CK_32MS 3: Start-up time 6 CK/14 CK + 32 ms
  VALUE 6CK_14CK_64MS 4: Start-up time 6 CK/14 CK + 64 ms
  VALUE 6CK_14CK_128MS 5: Start-up time 6 CK/14 CK + 128 ms
  VALUE 6CK_14CK_256MS 6: Start-up time 6 CK/14 CK + 256 ms
  VALUE 6CK_14CK_512MS 7: Start-up time 6 CK/14 CK + 512 ms

DEVICE name=ATmega64HVE2
MASK 0 255
BIT WDTON 0 128: Watch-dog Timer always on
BIT EESAVE 0 64: Preserve EEPROM through the Chip Erase cycle
BIT SPIEN 0 32: Serial program downloading (SPI) enabled
BIT BODEN 0 16: Enable BOD
BIT CKDIV8 0 8: Divide clock by 8
ENUM SUT 0 6: Select start-up time
  VALUE 14CK_0MS 0: Start-up time 14 CK + 0 ms
  VALUE 14CK_16MS 2: Start-up time 14 CK + 16 ms
  VALUE 14CK_32MS 4: Start-up time 14 CK + 32 ms
  VALUE 14CK_64MS 6: Start-up time 14 CK + 64 ms
BIT OSCSEL0 0 1: Oscillator select
MASK 1 15
BIT DWEN 1 8: Debug Wire enable
ENUM BOOTSZ 1 6: Select Boot Size
  VALUE 512W_7E00 6: Boot Flash size=512 words Boot address=$7E00
  VALUE 1024W_7C00 4: Boot Flash size=1024 words Boot address=$7C00
  VALUE 2048W_7800 2: Boot Flash size=2048 words Boot address=$7800
  VALUE 4096W_7000 0: Boot Flash size=4096 words Boot address=$7000
BIT BOOTRST 1 1: Boot Reset vector Enabled

