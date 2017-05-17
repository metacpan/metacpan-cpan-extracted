use strict;
use warnings;

use Data::Dumper;
use GPSD::Parse;
use Test::More;

my $mod = 'GPSD::Parse';

my $fname = 't/data/gps.json';

#FIXME: add tests for using $gps->on using the socket

my $gps;

eval {
    $gps = GPSD::Parse->new;
};

plan skip_all => "no socket available" if $@;

#
# with filename
#

{ # default return with file

    my $res = $gps->poll(fname => $fname);

    is ref $res, 'HASH', "default return is an href ok";

    is exists $res->{sky}, 1, "SKY exists";
    is exists $res->{tpv}, 1, "TPV exists";
    is exists $res->{active}, 1, "active exists";
    is exists $res->{time}, 1, "time exists";
    is $res->{class}, 'POLL', "proper poll class ok";
}

{ # json return

    my $res = $gps->poll(return => 'json', fname => $fname);

    is ref \$res, 'SCALAR', "json returns a string";
    like $res, qr/^{/, "...and appears to be JSON data";
    like $res, qr/TPV/, "...and it contains TPV ok";
}

{ # invalid filename

    my $res;

    my $ok = eval {
        $res = $gps->poll(fname => 'invalid.file');
        1;
    };

    is $ok, undef, "croaks if file can't be opened with fname param";
    like $@, qr/invalid\.file/, "...and the error msg is sane";
    undef $@;
}

{ # on/off
    my $w;
    local $SIG{__WARN__} = sub {
        $w = shift;
    };

    my $res = $gps->poll;
    is $res->{tpv}[0], undef, "TPV empty if \$gps->on isn't called";
    like $w, qr/'on\(\)' method/, "...with a proper warning";

    $gps->on;
    $res = $gps->poll;
    is ref $res->{tpv}[0], 'HASH', "TPV has data if \$gps->on is called";

    $gps->off;
    $res = $gps->poll;
    is $res->{tpv}[0], undef, "TPV undef after off() called";
}

done_testing;
