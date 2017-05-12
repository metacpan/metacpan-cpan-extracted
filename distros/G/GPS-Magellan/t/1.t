

# $Id: 1.t,v 1.2 2004/02/29 21:46:26 peter Exp $

no warnings;

eval `cat test.conf`;

$Num_Tests = 10 + 20 * scalar(@COMMANDS);

# TODO figure out why this doesn't work
# use Test::More tests => $Num_Tests;

use Test::More qw/no_plan/;

use_ok('GPS::Magellan');
use_ok('GPS::Magellan::File');
use_ok('GPS::Magellan::Coord');
use_ok('GPS::Magellan::Message');

use Data::Dumper;

SKIP: {
    skip 'in OFFLINE test', 2  unless not $RUN_OFFLINE;
    ok( ! GPS::Magellan::OpenPort('/dev/ttyS0'), 'OpenPort');
}

TODO: {
    local $TODO = 'test case for $GPS::Magellan::Serial';
    ok( $GPS::Magellan::Serial, 'port handle');
}

$gps = GPS::Magellan->new( 
    port => '/dev/ttyS0',
    RUN_OFFLINE => $RUN_OFFLINE,
);

isa_ok( $gps, 'GPS::Magellan', 'object type');

eval {
    $connect_status = $gps->connect();
};

diag($@) if $@;

ok( !$@, 'no exception in connect()');

ok( !$connect_status, 'connect() result');

foreach $cmd ( @COMMANDS ){

    @points = ();

    eval {
        @points = $gps->getPoints($cmd);
    };

    diag($@) if $@;

    ok( ! $@, 'get waypoints: no exception');
    ok( @points, 'get waypoints: result');

    $CKPOINT_FILE = "test-data/ref.$cmd.dump";

    diag($CKPOINT_FILE);

    if($GENERATE_REFDATA){
        open(TEST, ">$CKPOINT_FILE");
        print TEST Dumper(\@points);
        close TEST;
    }

    do $CKPOINT_FILE;

    is_deeply( \@points, $VAR1, 'result matches ref data');

    eval {
        $f = GPS::Magellan::File::Way_Txt->new(
            coords => \@points,
        );
    };

    diag($@) if $@;

    ok( ! $@, 'GPS::Magellan::File::Way_Txt: no exception');

    isa_ok( $f, 'GPS::Magellan::File', 'is a GPS::Magellan::File');

    can_ok( $f, qw/encode decode read write name/);

    ok( $f->name ne '', 'has name');

    ok( $f->as_string() ne '', 'as_string() returned something');

    eval {
        $write_status = $f->write('/dev/null');
    };

    diag($@) if $@;

    ok( ! $@, 'write() did not throw exception');

    ok( ! $write_status, 'write() result');

}

1;

