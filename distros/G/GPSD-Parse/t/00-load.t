use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok( 'GPSD::Parse' ) || print "Bail out!\n";
}

my $fname = 't/data/gps.json';

my $gps;

my $sock = eval {
    $gps = GPSD::Parse->new;
    1;
};

if (! $sock){
    warn "In file mode; socket not available...\n";
    $gps = GPSD::Parse->new(file => $fname);
}
else {
    warn "In socket mode...\n";
}

isa_ok $gps, 'GPSD::Parse', "obj is of appropriate class";

done_testing;
