#!/usr/bin/perl

use v5.26;
use warnings;

use Device::Chip::CC1101;

use Future::AsyncAwait;
use Object::Pad;

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

class Device::Chip::CC1101::Virtual extends Device::Chip::CC1101 {
   use Future;

   my $config = Device::Chip::CC1101->CONFIG_DEFAULT;

   async method _read_CONFIG ()
   {
      return $config;
   }

   async method _write_CONFIG ( $addr, $bytes )
   {
      substr( $config, $addr, length $bytes ) = $bytes;
   }

   my $patable = "\x00" x 8;

   async method _read_PATABLE ()
   {
      return $patable;
   }

   async method _write_PATABLE ( $_new )
   {
      $patable = $_new;
   }
}

my $chip = Device::Chip::CC1101::Virtual->new;

await $chip->change_config(
   band => $BAND,
   mode => $MODE,

   CHAN => $CHANNEL,

   defined $PKTLEN ? (
      LENGTH_CONFIG => "fixed",
      PACKET_LENGTH => 8,
   ) : (),

   %MORECONFIG,
);

if( $PRINT_CONFIG ) {
   my %config = await $chip->read_config;
   printf STDERR "%-20s: %s\n", $_, $config{$_} for sort keys %config;
}

# TODO: Customisable language
my $config_bytes = join ", ", map { sprintf "0x%02X", ord $_ } split //, await $chip->_read_CONFIG;
$config_bytes =~ s/((0x[0-9A-F]{2}, ){8})/$1\n/g;
$config_bytes =~ s/^/  /mg;

my $patable_bytes = join ", ", map { sprintf "0x%02X", ord $_ } split //, await $chip->_read_PATABLE;

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
