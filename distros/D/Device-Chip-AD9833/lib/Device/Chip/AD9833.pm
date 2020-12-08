#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.19;

package Device::Chip::AD9833 0.02;
class Device::Chip::AD9833
   extends Device::Chip;

use Carp;
use Data::Bitfield 0.02 qw( bitfield boolfield );

use Future::AsyncAwait 0.38; # aync method

use constant PROTOCOL => "SPI";

use constant {
   REG_CONFIG => 0x0000,
   REG_FREQ0  => 0x4000,
   REG_FREQ1  => 0x8000,
   REG_PHASE0 => 0xC000,
   REG_PHASE1 => 0xE000,
};

=head1 NAME

C<Device::Chip::AD9833> - chip driver for F<AD9833>

=head1 SYNOPSIS

   use Device::Chip::AD9833;
   use Future::AsyncAwait;

   my $chip = Device::Chip::AD9833->new;
   await $chip->mount( Device::Chip::Adapter::...->new );

   await $chip->init;

   my $freq = 440; # in Hz
   await $chip->write_FREQ0( ( $freq << 28 ) / 25E6 ); # presuming 25MHz reference

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communication to an
F<Analog Devices> F<AD9833> attached to a computer via an SPI adapter.

The reader is presumed to be familiar with the general operation of this chip;
the documentation here will not attempt to explain or define chip-specific
concepts or features, only the use of this module to access them.

=cut

sub SPI_options
{
   return ( mode => 2 );
}

has $_config = 0;

async method _write ( $word )
{
   await $self->protocol->write( pack "S>", $word )
}

=head1 METHODS

The following methods documented in an C<await> expression return L<Future>
instances.

=cut

=head2 init

   await $chip->init;

Resets the chip to a working configuration, including setting the C<B28> bit
appropriately for the way this module writes the frequency registers.

This method must be called before setting the frequency using L</write_FREQ0>
or L</write_FREQ1>.

=cut

async method init ()
{
   await $self->_write( REG_CONFIG | 0x2100 ); # RESET, B28=1
   await $self->_write( REG_CONFIG | 0x2000 ); # unreset, B28=1
}

bitfield { format => "integer" }, CONFIG =>
   B28     => boolfield( 13 ),
   HLB     => boolfield( 12 ),
   FSELECT => boolfield( 11 ),
   PSELECT => boolfield( 10 ),
   SLEEP1  => boolfield(  7 ),
   SLEEP12 => boolfield(  6 ),
   OPBITEN => boolfield(  5 ),
   DIV2    => boolfield(  3 ),
   MODE    => boolfield(  1 );

=head2 read_config

   $config = await $chip->read_config;

Returns a C<HASH> reference containing the current chip configuration. Note
that since the chip does not support querying the configuration, this is just
an in-memory copy maintained by the object instance, updated by calls to
L</change_config>.

The hash will contain the following named fields, all booleans.

   B28
   HLB
   FSELECT
   PSELECT
   SLEEP1
   SLEEP12
   OPBITEN
   DIV2
   MODE

In addition, a new value C<wave> will be created combining the current
settings of C<MODE>, C<OPBITEN> and C<DIV2> to explain the waveform generated

   wave => "sine" | "triangle" | "square" | "square/2"

=cut

async method read_config ()
{
   my %config = unpack_CONFIG( $_config );

   my $wave;
   if( $config{OPBITEN} ) {
      $wave = $config{DIV2} ? "square" : "square/2";
   }
   elsif( $config{MODE} ) {
      $wave = "triangle";
   }
   else {
      $wave = "sine";
   }
   $config{wave} = $wave;

   return \%config;
}

=head2 change_config

   await $chip->change_config( %changes );

Writes updates to the chip configuration. Takes named arguments of the same
form as returned by L</read_config>, including the synthesized C<wave>
setting.

=cut

async method change_config ( %changes )
{
   if( defined( my $wave = delete $changes{wave} ) ) {{
      $changes{OPBITEN} = 1, $changes{MODE} = 0, $changes{DIV2} = 1, last if $wave eq "square";
      $changes{OPBITEN} = 1, $changes{MODE} = 0, $changes{DIV2} = 0, last if $wave eq "square/2";
      $changes{OPBITEN} = 0, $changes{MODE} = 1, last if $wave eq "triangle";
      $changes{OPBITEN} = 0, $changes{MODE} = 0, last if $wave eq "sine";
      croak "Unrecognised value for 'wave' configuration - $wave";
   }}

   my %config = ( unpack_CONFIG( $_config ), %changes );

   $config{B28} = 1;

   await $self->_write( REG_CONFIG | ( $_config = pack_CONFIG( %config ) ) );
}

=head2 write_FREQ0

=head2 write_FREQ1

   await $chip->write_FREQ0( $freq );
   await $chip->write_FREQ1( $freq );

Writes the C<FREQ0> or C<FREQ1> frequency control register. C<$freq> should
be a 28bit integer value.

=cut

async method write_FREQ0 ( $freq )
{
   await $self->_write( REG_FREQ0 | ( $freq & 0x3FFF ) );
   await $self->_write( REG_FREQ0 | ( $freq >> 14 ) );
}

async method write_FREQ1 ( $freq )
{
   await $self->_write( REG_FREQ1 | ( $freq & 0x3FFF ) );
   await $self->_write( REG_FREQ1 | ( $freq >> 14 ) );
}

=head2 write_PHASE0

=head2 write_PHASE1

   await $chip->write_PHASE0( $phase );
   await $chip->write_PHASE1( $phase );

Writes the C<PHASE0> or C<PHASE1> phase control register. C<$phase> should
be a 12bit integer value.

=cut

async method write_PHASE0 ( $phase )
{
   await $self->_write( REG_PHASE0 | $phase );
}

async method write_PHASE1 ( $phase )
{
   await $self->_write( REG_PHASE1 | $phase );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
