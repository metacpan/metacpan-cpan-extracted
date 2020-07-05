#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

package Device::BusPirate::Mode::UART;

use strict;
use warnings;
use base qw( Device::BusPirate::Mode );

our $VERSION = '0.20';

use Carp;

use Future::AsyncAwait;
use List::Util 1.33 qw( any );

use constant MODE => "UART";

use constant PIRATE_DEBUG => $ENV{PIRATE_DEBUG} // 0;

=head1 NAME

C<Device::BusPirate::Mode::UART> - use C<Device::BusPirate> in UART mode

=head1 SYNOPSIS

   use Device::BusPirate;

   my $pirate = Device::BusPirate->new;
   my $uart = $pirate->enter_mode( "UART" )->get;

   $uart->configure( baud => 19200 )->get;

   $uart->write( "Hello, world!" )->get;

=head1 DESCRIPTION

This object is returned by a L<Device::BusPirate> instance when switching it
into C<UART> mode. It provides methods to configure the hardware and to
transmit bytes.

=cut

=head1 METHODS

The following methods documented with a trailing call to C<< ->get >> return
L<Future> instances.

=cut

async sub start
{
   my $self = shift;

   # Bus Pirate defaults
   $self->{open_drain} = 1;
   $self->{bits}       = 8;
   $self->{parity}     = "n";
   $self->{stop}       = 1; # 1 stop bit, not 2

   $self->{baud} = 0;

   await $self->_start_mode_and_await( "\x03", "ART" );
   ( $self->{version} ) = await $self->pirate->read( 1, "UART start" );

   print STDERR "PIRATE UART STARTED\n" if PIRATE_DEBUG;
   return $self;
}

=head2 configure

   $uart->configure( %args )->get

Change configuration options. The following options exist:

=over 4

=item open_drain

If enabled (default), a "high" output pin will be set as an input; i.e. hi-Z.
When disabled, a "high" output pin will be driven by 3.3V. A "low" output will
be driven to GND in either case.

=item bits

Number of data bits of transfer. Must be either 8 or 9.

=item parity

A single character string indicating whether to send a parity bit of
even ("E") or odd ("O"), or not ("N").

=item stop

An integer giving the number of bit-times for stop, either 1 or 2.

=item baud

An integer giving the baud rate. Must be one of the values:

   300 1200 2400 4800 9600 19200 31250 38400 57600 115200

The default speed is 300.

=back

=cut

my %DATACONF = (
   '8N' => 0,
   '8E' => 1,
   '8O' => 2,
   '9N' => 3,
);

my %BAUDS = (
   300    => 0,
   1200   => 1,
   2400   => 2,
   4800   => 3,
   9600   => 4,
   19200  => 5,
   31250  => 6,
   38400  => 7,
   57600  => 8,
   115200 => 10, # sic - there is no rate 9
);

sub configure
{
   my $self = shift;
   my %args = @_;

   my @f;

   if( any { defined $args{$_} and $args{$_}//0 ne $self->{$_} } qw( open_drain bits parity stop ) ) {
      my $bits   = $args{bits}   // $self->{bits};
      my $parity = $args{parity} // $self->{parity};
      my $stop   = $args{stop}   // $self->{stop};

      defined( my $dataconf = $DATACONF{$bits . uc $parity} ) or
         croak "Unrecognised bitsize/parity $bits$parity";
      $stop == 1 or $stop == 2 or
         croak "Unrecognised stop length $stop";

      defined $args{$_} and $self->{$_} = $args{$_}//0 for qw( open_drain bits parity stop );

      push @f, $self->pirate->write_expect_ack(
         chr( 0x80 |
              ( $self->{open_drain} ? 0 : 0x10 ) | # sense is reversed
              ( $dataconf << 2 ) |
              ( $stop == 2 ? 0x02 : 0 ) |
              0 ), "UART configure" );
   }

   if( defined $args{baud} ) {{
      my $baud = $BAUDS{$args{baud}} //
         croak "Unrecognised baud '$args{baud}'";

      last if $baud == $self->{baud};

      $self->{baud} = $baud;
      push @f, $self->pirate->write_expect_ack(
         chr( 0x60 | $self->{baud} ), "UART set baud" );
   }}

   return Future->needs_all( @f );
}

=head2 write

   $uart->write( $bytes )->get

Sends the given bytes over the TX wire.

=cut

async sub write
{
   my $self = shift;
   my ( $bytes ) = @_;

   printf STDERR "PIRATE UART WRITE %v02X\n", $bytes if PIRATE_DEBUG;

   # "Bulk Transfer" command can only send up to 16 bytes at once.

   my @chunks = $bytes =~ m/(.{1,16})/gs;

   foreach my $bytes ( @chunks ) {
      my $len_1 = length( $bytes ) - 1;

      await $self->pirate->write_expect_acked_data(
         chr( 0x10 | $len_1 ) . $bytes, length $bytes, "UART bulk write"
      );
   }

   return;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
