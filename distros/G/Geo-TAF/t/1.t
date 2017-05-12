# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 16 };

use Geo::TAF;
ok(1); # If we made it this far, we're ok.


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


my $m;

ok ($m = new Geo::TAF);
ok (! $m->metar("EGSH 311420Z 29010KT 1600 SHSN SCT004 BKN006 01/M02 Q1021"));
ok (length $m->as_string > 30);
ok ($m->icao eq 'EGSH');
ok ($m->day == 31);
ok ($m->pressure == 1021);
ok ($m->temp == 1);
ok ($m->dewpoint == -2);
ok ($m->wind_dir == 290);
ok ($m->wind_speed == 10);
ok ($m->viz_dist == 1600);
ok ($m = new Geo::TAF);
ok (! $m->taf("EGSH 311205Z 311322 04010KT 9999 SCT020
     TEMPO 1319 3000 SHSN BKN008 PROB30
     TEMPO 1318 0700 +SHSN VV///
     BECMG 1619 22005KT"));
ok ($m->chunks);
ok ($m->as_chunk_string);
