
use GPS::Magellan;
use GPS::Magellan::Coord;
use GPS::Magellan::File;
use Data::Dumper;

my $RUN_OFFLINE = 0;

GPS::Magellan::OpenPort('/dev/ttyS0') unless $RUN_OFFLINE;

my $gps = GPS::Magellan->new( 
    port => '/dev/ttyS0',
    RUN_OFFLINE => $RUN_OFFLINE,
);

$gps->connect();

my @wlist = $gps->getPoints("WAYPOINT");

foreach my $wpt (@wlist){

    printf "%s\n", '-' x 50;
    $wpt->_dump;

}


my $f = GPS::Magellan::File::Way_Txt->new(
    coords => \@wlist,
);

print '*'x40 . "\n";
printf "Writing %s format\n", $f->name;
print '*'x40 . "\n";

$f->write();


exit;

