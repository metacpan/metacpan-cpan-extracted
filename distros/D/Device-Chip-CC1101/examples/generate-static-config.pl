#!/usr/bin/perl

use strict;
use warnings;

use Device::Chip::CC1101;

use Getopt::Long qw( :config no_ignore_case );

my %MORECONFIG;

GetOptions(
   # script options
   'print-config|P' => \( my $PRINT_CONFIG ),

   # Radio setup
   'band|B=s'    => \( my $BAND = "868MHz" ),
   'mode|m=s'    => \( my $MODE = "GFSK-38.4kb" ),
   'channel|C=i' => \( my $CHANNEL = 1 ),
   'config=s'    => sub { $_[1] =~ m/(^.*?)=(.*)/ and $MORECONFIG{$1} = $2 },
   'pkt-length|L=i' => \( my $PKTLEN ),
) or exit 1;

package Device::Chip::CC1101::Virtual {
   use base qw( Device::Chip::CC1101 );

   use Future;

   my $config = Device::Chip::CC1101->CONFIG_DEFAULT;

   sub _read_CONFIG
   {
      return Future->done( $config );
   }

   sub _write_CONFIG
   {
      shift;
      my ( $addr, $bytes ) = @_;

      substr( $config, $addr, length $bytes ) = $bytes;
      return Future->done;
   }

   my $patable = "\x00" x 8;

   sub _read_PATABLE
   {
      return Future->done( $patable );
   }

   sub _write_PATABLE
   {
      shift;
      ( $patable ) = @_;

      return Future->done;
   }
}

my $chip = Device::Chip::CC1101::Virtual->new;

$chip->change_config(
   band => $BAND,
   mode => $MODE,

   CHAN => $CHANNEL,

   defined $PKTLEN ? (
      LENGTH_CONFIG => "fixed",
      PACKET_LENGTH => 8,
   ) : (),

   %MORECONFIG,
)->get;

if( $PRINT_CONFIG ) {
   my %config = $chip->read_config->get;
   printf STDERR "%-20s: %s\n", $_, $config{$_} for sort keys %config;
}

# TODO: Customisable language
my $config_bytes = join ", ", map { sprintf "0x%02X", ord $_ } split //, $chip->_read_CONFIG->get;
$config_bytes =~ s/((0x[0-9A-F]{2}, ){8})/$1\n/g;
$config_bytes =~ s/^/  /mg;

my $patable_bytes = join ", ", map { sprintf "0x%02X", ord $_ } split //, $chip->_read_PATABLE->get;

print <<"EOF";
/* Config generated automatically using $0 with options
 *   --band=$BAND --channel=$CHANNEL --mode=$MODE
 */
static uint8_t cc1101_config[] = {
$config_bytes
};
static uint8_t cc1101_patable[] = {
  $patable_bytes
};
EOF
