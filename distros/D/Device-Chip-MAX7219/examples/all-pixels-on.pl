use v5.26;
use warnings;

use Device::Chip::MAX7219Panel;
use Device::Chip::Adapter;

use Time::HiRes qw( sleep time );
use POSIX qw( strftime );

use Future::AsyncAwait;

use Getopt::Long;

my $on = "#";

GetOptions(
   'adapter|A=s'    => \my $ADAPTER,
   'brightness|B=s' => \(my $BRIGHTNESS = 5),
   'geom|g=s'       => \(my $GEOM),
   'off'            => sub { $on = " " },
) or exit 1;

my $panel = Device::Chip::MAX7219Panel->new( geom => $GEOM );
await $panel->mount(
   Device::Chip::Adapter->new_from_description( $ADAPTER )
);

await $panel->protocol->power(1) if $panel->protocol->can( "power" );
END {
   # $panel and $panel->adapter->shutdown;
}

$SIG{TERM} = $SIG{INT} = sub { exit };

await $panel->init;

await $panel->intensity( $BRIGHTNESS );
await $panel->displaytest( 0 );

my $columns = $panel->columns;

$panel->clear;
$panel->draw_blit( 0, 0, ( $on x $panel->columns ) x $panel->rows );

await $panel->refresh;
