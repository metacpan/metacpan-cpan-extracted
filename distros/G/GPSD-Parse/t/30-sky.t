use strict;
use warnings;

use GPSD::Parse;
use Test::More;

my $mod = 'GPSD::Parse';

my $gps;

eval {
    $gps = $mod->new;
};

plan skip_all => "no socket available" if $@;

$gps->on;


my @stats = qw(
    satellites
    xdop
    ydop
    pdop
    tdop
    vdop
    gdop
    hdop
    class
    tag
    device
);
$gps->poll;

{
    my $s = $gps->sky;

    is ref $s, 'HASH', "sky() returns a hash ref ok";

    is keys %$s, @stats, "keys match SKY entry count";

    for (@stats){
        is exists $s->{$_}, 1, "SKY stat $_ exists";
    }

    is ref $s->{satellites}, 'ARRAY', "SKY->satellites is an aref";
    is ref $s->{satellites}[0], 'HASH', "SKY satellite entries are hrefs";
    is exists $s->{satellites}[0]{ss}, 1, "each SKY sat entry has individual stats";
}

$gps->off;

done_testing;
