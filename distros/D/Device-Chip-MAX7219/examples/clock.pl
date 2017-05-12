use strict;
use warnings;

use Device::Chip::MAX7219;
use Device::Chip::Adapter;

use Time::HiRes qw( sleep time );
use POSIX qw( strftime );

use Getopt::Long;

GetOptions(
   'adapter|A=s' => \( my $ADAPTER = "BusPirate" ),
) or exit 1;

my $max = Device::Chip::MAX7219->new;
$max->mount(
   Device::Chip::Adapter->new_from_description( $ADAPTER )
)->get;

$max->protocol->power(1)->get;
END {
   $max and $max->adapter->shutdown;
}

$SIG{TERM} = $SIG{INT} = sub { exit };

Future->needs_all(
   $max->limit( 8 ),
   $max->set_decode( 0xff ),
   $max->displaytest( 0 ),
)->get;

Future->needs_all(
   ( map {
      $max->write_bcd( $_, " " );
   } 0 .. 7 ),

   $max->shutdown( 0 ),
)->get;

while(1) {
   my $now = time;
   my $str = strftime "%H %M %S", localtime int $now;

   Future->needs_all( map {
      my $d = $_;
      my $val = substr $str, 7 - $d, 1;
      $max->write_bcd( $d, $val )
   } 0 .. 7 )->get;

   sleep( int( $now + 1 ) - $now );
}
