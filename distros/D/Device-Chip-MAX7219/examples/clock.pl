use v5.26;
use warnings;

use Device::Chip::MAX7219;
use Device::Chip::Adapter;

use Time::HiRes qw( sleep time );
use POSIX qw( strftime );

use Future::AsyncAwait;

use Getopt::Long;

GetOptions(
   'adapter|A=s' => \my $ADAPTER,
) or exit 1;

my $max = Device::Chip::MAX7219->new;
await $max->mount(
   Device::Chip::Adapter->new_from_description( $ADAPTER )
);

await $max->protocol->power(1) if $max->protocol->can( "power" );
END {
   $max and $max->adapter->shutdown;
}

$SIG{TERM} = $SIG{INT} = sub { exit };

await Future->needs_all(
   $max->limit( 8 ),
   $max->set_decode( 0xff ),
   $max->displaytest( 0 ),
);

await Future->needs_all(
   ( map {
      $max->write_bcd( $_, " " );
   } 0 .. 7 ),

   $max->shutdown( 0 ),
);

while(1) {
   my $now = time;
   my $str = strftime "%H %M %S", localtime int $now;

   await Future->needs_all( map {
      my $d = $_;
      my $val = substr $str, 7 - $d, 1;
      $max->write_bcd( $d, $val )
   } 0 .. 7 );

   sleep( int( $now + 1 ) - $now );
}
