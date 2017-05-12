#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016 -- leonerd@leonerd.org.uk

package Device::Chip::SDCard;

use strict;
use warnings;
use base qw( Device::Chip );

our $VERSION = '0.01';

use Data::Bitfield qw( bitfield boolfield );
use Future::Utils qw( repeat );

use constant PROTOCOL => "SPI";

=head1 NAME

C<Device::Chip::SDCard> - chip driver for F<SD> and F<MMC> cards

=head1 SYNOPSIS

 use Device::Chip::SDCard;

 my $card = Device::Chip::SDCard->new;

 $card->mount( Device::Chip::Adapter::...->new )->get;

 $card->initialise->get;

 my $bytes = $card->read_block( 0 )->get;

 print "Read block zero:\n";
 printf "%v02X\n", $bytes;

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communication to an F<SD> or
F<MMC> storage card attached via an SPI adapter.

At present it only supports MMC and SDSC ("standard capacity") cards, not SDHC
or SDXC.

=cut

sub SPI_options
{
   return (
      mode        => 0,
      max_bitrate => 1E6,
   );
}

=head1 METHODS

The following methods documented with a trailing call to C<< ->get >> return
L<Future> instances.

=cut

sub send_command
{
   my $self = shift;
   my ( $cmd, $arg, $readlen ) = @_;

   $arg //= 0;
   $readlen //= 0;

   my $crcstop = 0x95;

   # TODO: until we can perform dynamic transactions with D:C:A we'll have to
   #   do this by presuming the maximum amount of time for the card to respond
   #   (8 words) and look for the response in what's returned

   $self->protocol->readwrite(
      pack "C N C a*", 0x40 | $cmd, $arg, $crcstop, "\xFF" x ( 8 + $readlen ),
   )->then( sub {
      my ( $resp ) = @_;

      # Trim to the start of the expected result
      substr $resp, 0, 7, "";

      # Look for a byte with top bit clear
      while( length $resp ) {
         my $ret = unpack( "C", $resp );
         return Future->done( $ret, unpack "x a$readlen", $resp ) if !( $ret & 0x80 );

         substr $resp, 0, 1, "";
      }
      return Future->fail(
         sprintf "Timed out waiting for response to command %02X", $cmd
      );
   });
}

sub _recv_data_block
{
   my $self = shift;
   my ( $buf, $len ) = @_;

   # Wait for a token
   ( repeat {
      $buf =~ s/^\xFF+//;
      $buf =~ s/^\xFE// and
         return Future->done();

      $self->protocol->readwrite_no_ss( "\xFF" x 16 )
         ->on_done( sub { $buf .= $_[0] } );
   } until => sub { !$_[0]->get } )
   # Now want the data + CRC
   ->then( sub {
      length $buf >= $len + 2 and
         return Future->done();

      $self->protocol->readwrite_no_ss( "\xFF" x ( $len + 2 - length $buf ) )
   })->then( sub {
      $buf .= $_[0];
      # TODO: might want to verify the CRC?
      Future->done( substr $buf, 0, $len );
   });
}

# Commands
use constant {
   CMD_GO_IDLE_STATE       => 0,
   CMD_SEND_OP_COND        => 1,
   CMD_SEND_CSD            => 9,
   CMD_SET_BLOCKLEN        => 16,
   CMD_READ_SINGLE_BLOCK   => 17,
   CMD_READ_OCR            => 58,
};

# Response first byte bitflags
use constant {
   RESP_PARAM_ERROR    => 1<<6,
   RESP_ADDR_ERROR     => 1<<5,
   RESP_ERASESEQ_ERROR => 1<<4,
   RESP_CRC_ERROR      => 1<<3,
   RESP_ILLEGAL_CMD    => 1<<2,
   RESP_ERASE_RESET    => 1<<1,
   RESP_IDLE           => 1<<0,
};

=head2 initialise

   $card->initialise->get

Checks that an SD card is present, switches it into SPI mode and waits for its
initialisation process to complete.

=cut

sub initialise
{
   my $self = shift;

   # Initialise first by switching the card into SPI mode
   $self->protocol->write( "\xFF" x 10 )->then( sub {
      $self->send_command( CMD_GO_IDLE_STATE )
   })->then( sub {
      my ( $resp ) = @_;
      $resp == 1 or die "Expected 01 response; got $resp";

      repeat {
         # TODO: Consider using SEND_IF_COND and doing SDHC initialisation
         $self->send_command( CMD_SEND_OP_COND );
      } while => sub {
         my $resp = shift->get;
         $resp & RESP_IDLE;
      }, foreach => [ 1 .. 200 ];
   })->then( sub {
      my ( $resp ) = @_;
      $resp & RESP_IDLE and die "Timed out waiting for card to leave IDLE mode";

      $self->send_command( CMD_SET_BLOCKLEN, 512 );
   })->then( sub {
      my ( $resp ) = @_;
      $resp == 0 or die "Expected 00 response; got $resp";

      Future->done;
   });
}

=head2 size

   $n_bytes = $card->size->get

Returns the size of the media card in bytes.

=cut

sub size
{
   my $self = shift;

   $self->read_csd->then( sub {
      my ( $csd ) = @_;
      return Future->done( $csd->{bytes} );
   });
}

sub _spi_txn
{
   my $self = shift;
   my ( $code ) = @_;

   $self->protocol->assert_ss->then(
      $code
   )->followed_by( sub {
      my ( $f ) = @_;
      $self->protocol->release_ss->then( sub { $f } );
   });
}

=head2 read_csd

   $data = $card->read_csd->get;

Returns a C<HASH> reference containing decoded fields from the SD card's CSD
("card-specific data") register.

This hash will contain the following fields:

   TAAC
   NSAC
   TRAN_SPEED
   CCC
   READ_BL_LEN
   READ_BL_LEN_PARTIAL
   WRITE_BLK_MISALIGN
   READ_BLK_MISALIGN
   DSR_IMP
   C_SIZE
   VDD_R_CURR_MIN
   VDD_R_CURR_MAX
   VDD_W_CURR_MIN
   VDD_W_CURR_MAX
   C_SIZE_MULT
   ERASE_BLK_EN
   SECTOR_SIZE
   WP_GRP_SIZE
   WP_GRP_ENABLE
   R2W_FACTOR
   WRITE_BL_LEN
   WRITE_BL_PARTIAL
   FILE_FORMAT_GRP
   COPY
   PERM_WRITE_PROTECT
   TEMP_WRITE_PROTECT
   FILE_FORMAT

The hash will also contain the following calculated fields, derived from the
decoded fields above for convenience of calling code.

   blocks          # number of blocks implied by C_SIZE / C_SIZE_MULT
   bytes           # number of bytes of storage, implied by blocks and READ_BL_LEN

=cut

# This code is most annoying to write as it involves lots of bitwise unpacking
# at non-byte boundaries. It's easier (though inefficient) to perform this on
# an array of 128 1-bit values
sub _bits_to_uint {
   my $n = 0;
   ( $n <<= 1 ) |= $_ for reverse @_;
   return $n;
}

my %_DECSCALE = (
   1 => 1.0, 2 => 1.2, 3 => 1.3, 4 => 1.5, 5 => 2.0, 6 => 2.5,
   7 => 3.0, 8 => 3.5, 9 => 4.0, 0xA => 4.5, 0xB => 5.0,
   0xC => 5.5, 0xD => 6.0, 0xE => 7.0, 0xF => 8.0
);

sub _convert_decimal
{
   my ( $unit, $val ) = @_;

   my $mult = $unit % 3;
   $unit -= $mult;
   $unit /= 3;

   $val = $_DECSCALE{$val} * ( 10 ** $mult );

   return $val . substr( "num kMG", $unit + 3, 1 );
}

my %_CURRMIN = (
   0 => 0.5, 1 => 1, 2 => 5, 3 => 10,
   4 => 25, 5 => 35, 6 => 60, 7 => 100,
);
my %_CURRMAX = (
   0 => 1, 1 => 5, 2 => 10, 3 => 25,
   4 => 35, 5 => 45, 6 => 80, 7 => 200,
);

sub _unpack_csd_v0
{
   my ( $bytes ) = @_;
   my @bits = reverse split //, unpack "B128", $bytes;

   my %csd = (
      TAAC                => _convert_decimal( _bits_to_uint( @bits[112 .. 114] ) - 9, _bits_to_uint( @bits[115 .. 118] ) ) . "s",
      NSAC                => 100*_bits_to_uint( @bits[104 .. 111] ) . "ck",
      TRAN_SPEED          => _convert_decimal( _bits_to_uint( @bits[ 96 ..  98] ) + 5, _bits_to_uint( @bits[ 99 .. 102] ) ) . "bit/s",
      CCC                 => [ grep { $bits[84+$_] } 0 .. 11 ],
      READ_BL_LEN         => 2**_bits_to_uint( @bits[ 80 ..  83] ),
      READ_BL_LEN_PARTIAL => $bits[79],
      WRITE_BLK_MISALIGN  => $bits[78],
      READ_BLK_MISALIGN   => $bits[77],
      DSR_IMP             => $bits[76],
      C_SIZE              => _bits_to_uint( @bits[ 62 ..  73] ),
      VDD_R_CURR_MIN      => $_CURRMIN{ _bits_to_uint( @bits[ 59 ..  61] ) } . "mA",
      VDD_R_CURR_MAX      => $_CURRMAX{ _bits_to_uint( @bits[ 56 ..  58] ) } . "mA",
      VDD_W_CURR_MIN      => $_CURRMIN{ _bits_to_uint( @bits[ 53 ..  55] ) } . "mA",
      VDD_W_CURR_MAX      => $_CURRMAX{ _bits_to_uint( @bits[ 50 ..  52] ) } . "mA",
      C_SIZE_MULT         => _bits_to_uint( @bits[ 47 ..  49] ),
      ERASE_BLK_EN        => $bits[46],
      SECTOR_SIZE         => 1+_bits_to_uint( @bits[ 39 ..  45] ),
      WP_GRP_SIZE         => 1+_bits_to_uint( @bits[ 32 ..  38] ),
      WP_GRP_ENABLE       => $bits[31],
      R2W_FACTOR          => 2**_bits_to_uint( @bits[ 26 ..  28] ),
      WRITE_BL_LEN        => 2**_bits_to_uint( @bits[ 22 ..  25] ),
      WRITE_BL_PARTIAL    => $bits[21],
      FILE_FORMAT_GRP     => $bits[15],
      COPY                => $bits[14],
      PERM_WRITE_PROTECT  => $bits[13],
      TEMP_WRITE_PROTECT  => $bits[12],
      FILE_FORMAT         => _bits_to_uint( @bits[ 10 ..  11] ),
      # Final bits are the CRC, which we ignore
   );

   $csd{blocks} = ( 1 + $csd{C_SIZE} ) * ( 2 ** ( $csd{C_SIZE_MULT} + 2 ) );
   $csd{bytes}  = $csd{blocks} * $csd{READ_BL_LEN};

   return \%csd;
}

sub read_csd
{
   my $self = shift;

   my $protocol = $self->protocol;

   my $buf;

   $self->_spi_txn( sub {
      $protocol->write_no_ss(
         pack "C N C a*", 0x40 | CMD_SEND_CSD, 0, 0xFF, "\xFF"
      )->then( sub {
         $protocol->readwrite_no_ss( "\xFF" x 8 )
      })->then( sub {
         ( $buf ) = @_;
         $buf =~ s/^\xFF*//;
         $buf =~ s/^\0// or
            return Future->fail( "Expected response 00; got " . ord( $buf ) );

         $self->_recv_data_block( $buf, 16 );
      });
   })->then( sub {
      my ( $csd ) = @_;
      # Top two bits give the structure version
      my $ver = vec( $csd, 0, 2 );
      if( $ver == 0 ) {
         return Future->done( _unpack_csd_v0( $csd ) );
      }
      elsif( $ver == 1 ) {
         return Future->done( _unpack_csd_v1( $csd ) );
      }
      else {
         return Future->fail( "Bad CSD structure version $ver" );
      }
   });
}

=head2 read_ocr

   $fields = $card->read_ocr->get

Returns a C<HASH> reference containing decoded fields from the card's OCR
("operating conditions register").

This hash will contain the following fields:

   BUSY
   CCS
   UHS_II
   1V8_ACCEPTED
   3V5, 3V4, 3V3, ..., 2V7

=cut

bitfield OCR =>
   BUSY   => boolfield( 31 ),
   CCS    => boolfield( 30 ),
   UHS_II => boolfield( 29 ),
   '1V8_ACCEPTED' => boolfield( 24 ),
   '3V5'          => boolfield( 23 ),
   '3V4'          => boolfield( 22 ),
   '3V3'          => boolfield( 21 ),
   '3V2'          => boolfield( 20 ),
   '3V1'          => boolfield( 19 ),
   '3V0'          => boolfield( 18 ),
   '2V9'          => boolfield( 17 ),
   '2V8'          => boolfield( 16 ),
   '2V7'          => boolfield( 15 );

sub read_ocr
{
   my $self = shift;

   $self->send_command( CMD_READ_OCR, undef, 4 )->then( sub {
      my ( $resp, $ocr ) = @_;
      Future->done( { unpack_OCR( unpack "N", $ocr ) } );
   });
}

=head2 read_block

   $bytes = $card->read_block( $lba )->get

Returns a 512-byte bytestring containing data read from the given sector of
the card.

=cut

sub read_block
{
   my $self = shift;
   my ( $lba ) = @_;

   my $byteaddr = $lba * 512;

   my $protocol = $self->protocol;

   my $buf;

   $self->_spi_txn( sub {
      $protocol->write_no_ss(
         pack "C N C a*", 0x40 | CMD_READ_SINGLE_BLOCK, $byteaddr, 0xFF, "\xFF"
      )->then( sub {
         $protocol->readwrite_no_ss( "\xFF" x 8 );
      })->then( sub {
         ( $buf ) = @_;
         $buf =~ s/^\xFF*//;
         $buf =~ s/^\0// or
            return Future->fail( "Expected response 00; got " . ord( $buf ) );

         $self->_recv_data_block( $buf, 512 );
      });
   });
}

=head1 TODO

=over 4

=item *

Support block writing.

=item *

Support the different initialisation sequence (and block size requirements) of
SDHC cards.

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
