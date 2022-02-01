use v5.26;
use warnings;

use Device::Chip::MAX7219Panel;
use Device::Chip::Adapter;

use Time::HiRes qw( sleep time );
use POSIX qw( strftime );

use Future::AsyncAwait;

use Getopt::Long;

GetOptions(
   'adapter|A=s'    => \my $ADAPTER,
   'brightness|B=s' => \(my $BRIGHTNESS = 5),
   'speed|s=s'      => \(my $SPEED = 20),
   'geom|g=s'       => \(my $GEOM),
) or exit 1;

my $panel = Device::Chip::MAX7219Panel->new( geom => $GEOM );
await $panel->mount(
   Device::Chip::Adapter->new_from_description( $ADAPTER )
);

await $panel->protocol->power(1) if $panel->protocol->can( "power" );
END {
   $panel and $panel->shutdown->get;
   $panel and $panel->adapter->shutdown;
}

$SIG{TERM} = $SIG{INT} = sub { exit };

await $panel->init;

await $panel->intensity( $BRIGHTNESS );
await $panel->displaytest( 0 );

my $columns = $panel->columns;

my @message = <DATA>;
chomp for @message;

if( $panel->rows == 8 ) {
   # Keep the first 8 lines
   @message = @message[0 .. 7];
}
elsif( $panel->rows == 16 ) {
   @message = @message[8 .. 8+15];
   pop @message while !defined $message[-1];
   push @message, " " x length($message[0]) while @message < 16;
}
else {
   die "TODO: No message bitmap available for this number of rows\n";
}

# Insert some spacing
$_ = " "x$columns . $_ for @message;

my $tick = time;
my $offset = 0;
while(1) {
   $tick += 1 / $SPEED;

   $panel->clear;
   $panel->draw_blit( 0, 0, map { substr( $_, $offset, $columns ) } @message );

   await $panel->refresh;

   my $delay = $tick - time;
   sleep( $delay ) if $delay > 0;

   $offset++;
   $offset = 0 if $offset > length $message[0];
}

__DATA__
#   #       ##  ##                                     ##      # # 
#   #        #   #                                      #      # # 
#   #  ###   #   #   ###             #   #  ###  # ##   #   ## # # 
##### #   #  #   #  #   #            #   # #   # ##  #  #  #  ## # 
#   # #####  #   #  #   #            # # # #   # #      #  #   # # 
#   # #      #   #  #   #  ##        # # # #   # #      #  #  ##   
#   #  ###  ### ###  ###   #          # #   ###  #     ###  ## # # 
                          #                                        
                                                                                                             
##    ##           ####     ####                                                         ####          ## ## 
##    ##             ##       ##                                                           ##          ## ## 
##    ##             ##       ##                                                           ##          ## ## 
##    ##             ##       ##                                                           ##          ## ## 
##    ##             ##       ##                                                           ##          ## ## 
##    ##   ####      ##       ##      ####                   ##    ##   ####   ## ####     ##      ### ## ## 
########  ##  ##     ##       ##     ##  ##                  ##    ##  ##  ##   ###  ##    ##     ##  ### ## 
##    ## ##    ##    ##       ##    ##    ##                 ##    ## ##    ##  ##         ##    ##    ## ## 
##    ## ########    ##       ##    ##    ##                 ## ## ## ##    ##  ##         ##    ##    ## ## 
##    ## ##          ##       ##    ##    ##                 ## ## ## ##    ##  ##         ##    ##    ## ## 
##    ## ##          ##       ##    ##    ##                 ## ## ## ##    ##  ##         ##    ##    ##    
##    ##  ##   ##    ##       ##     ##  ##   ###            ########  ##  ##   ##         ##     ##  ### ## 
##    ##   #####  ######## ########   ####    ###             ##  ##    ####    ##      ########   ### ## ## 
                                             ###                                                             
