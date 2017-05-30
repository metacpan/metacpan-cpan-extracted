use strict;
use warnings;

use Data::Dumper;
use GPSD::Parse;
use Test::More;

my $mod = 'GPSD::Parse';

my $fname = 't/data/gps.json';

my $gps;

my $sock = eval {
    $gps = GPSD::Parse->new;
    1;
};

$gps = GPSD::Parse->new(file => $fname) if ! $sock;

{ # default return with file

    my $res = $gps->poll;

    is ref $res, 'HASH', "default return is an href ok";

    is exists $res->{sky}, 1, "SKY exists";
    is exists $res->{tpv}, 1, "TPV exists";
    is exists $res->{active}, 1, "active exists";
    is exists $res->{time}, 1, "time exists";
    is $res->{class}, 'POLL', "proper poll class ok";
}

{ # json return

    my $res = $gps->poll(return => 'json');

    is ref \$res, 'SCALAR', "json returns a string";
    like $res, qr/^{/, "...and appears to be JSON data";
    like $res, qr/TPV/, "...and it contains TPV ok";
}

{ # invalid filename

    my $gps = GPSD::Parse->new(file => 'invalid.file');

    my $res;

    my $ok = eval {
        $res = $gps->poll(file => 'invalid.file');
        1;
    };

    is $ok, undef, "croaks if file can't be opened with file param";
    like $@, qr/invalid\.file/, "...and the error msg is sane";
    undef $@;
}

done_testing;
