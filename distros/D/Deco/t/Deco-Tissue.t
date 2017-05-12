#
# $Revision$
#
use Test::More tests => 36;
use Test::Exception;

my $Class = 'Deco::Tissue';

use_ok($Class);

my $tissue = new $Class;
isa_ok( $tissue, $Class, "Creating tissue without parameters");

my $tis  =  new Deco::Tissue( halftime => 300, M0 => 1.52, deltaM => 1.10 );
isa_ok( $tis, $Class, "Creating tissue with halftime and max M-value parameters");

# try to set wrong depth and timestamp
throws_ok { $tis->depth( -10 ) } qr/can not be negative/ , "can't set negative depths";
throws_ok { $tis->time( -10 ) } qr/can not be negative/ , "can't set negative timestamps";

# get internal pressure at start
my $N2press = 0.741507; # bar at sealevel
is( sprintf( "%.6f", $tis->internalpressure()), $N2press, "Starting internal pressure is $N2press");

# check _depth2pressure
is( $tis->_depth2pressure(0), 0, "Sea level should be 0 bar");
is( $tis->_depth2pressure(15), 1.5, "15 meters should be 1.5 bar");

# same for ambient
$tis->depth(0);
is( $tis->ambientpressure(), 1, "Starting ambient pressure is 1 bar");
$tis->depth(22.5);
is( $tis->ambientpressure(), 3.25, "Ambient pressure at 22.5 meters is 3.25 bar");

# try the alveolar pressure (with default RQ=0.8)
$tis->depth(0);
is( sprintf("%.6f", $tis->_alveolarPressure() ), 0.741507, "Alveolar pressure for 78% N2 is 0.741507 bar at sea level");

# now with RQ=0.9 of US navy alveolar pressure
$tis->depth(0);
$tis->rq(0.9);
is( sprintf("%.6f", $tis->_alveolarPressure() ), 0.735722, "Alveolar pressure for 78% N2 is 0.735722 bar at sea level with RQ of 0.9");

# check the M value, at depth 0 it is the same as M0
is( $tis->M( depth => 0), $tis->{m0}, "M0 value set OK");

# half time
my $hlf = 3; # minutes
# set it 
is($tis->halftime($hlf), $hlf, "Half time set to $hlf");
# retrieve it
is($tis->halftime(), $hlf, "Half time $hlf returned correctly");
# get the k value (ln(2)/halftime)
is($tis->k(), ( log(2) / $hlf), "K value calculated correctly");

# find the pressure for a 30 minute dive to 30 minutes in the 4 minute tissue
$hlf = 4;
$tis->depth(30);
$tis->halftime($hlf);
my $function_ref = $tis->_haldanePressure();

is( sprintf( "%.6f", &$function_ref(30) ), 3.062827, "Haldane pressure calculated OK for $hlf minute tissue");

# get info
my $info = $tis->info();
like($info, qr/= Halftime .*: $hlf/, "Tissue info looks good");

# let's set some depth/time points, point takes time , depth
my $time  = 60;
my $depth = 1.5;
$tis->point( $time, $depth);
is ($tis->{depth}, $depth, "Depth set OK");
is ($tis->{time}->{current}, $time, "Time set OK");


$tis->point( 120, 5.6);
is ($tis->{time}->{previous}, $time, "Previous time remembered");
is ($tis->{previousdepth}, $depth, "....as well as previous depth");

$tis->point( 200, 5.6);
is ($tis->{time}->{lastdepthchange}, 120 , "...and time of last depth change");

# test the no_deco function
# start at 1 meter, 1 second which should give - as no deco time
my $tis2  =  new Deco::Tissue( halftime => 5, M0 => 3.17, deltaM => 0.180 );

$tis2->point(1, 1);
is ($tis2->nodeco_time(), '-', 'No deco time as 1 meter');
# let's go to 30 meters, the 5 minute tissue can stay here indefinitely as well
$tis2->point(2, 30);
is ($tis2->nodeco_time(), '-', 'No deco time at 30 meter');

$tis2->point(2, 50);
is ( sprintf("%.0f", $tis2->nodeco_time()) , '7', 'No deco time at 50 meter');

# let's do some time_until calculation
my $time_until = sprintf('%.0f', $tis2->time_until_pressure( gas => 'n2', pressure => 1.89 ));
is( $time_until, 3, "time_until calculation is ok");
$time_until = sprintf('%.0f', $tis2->time_until_pressure( gas => 'n2', pressure => 2.89 ));
is( $time_until, 6, " and 2nd too");

# OTU calculations with air
my $tis3  =  new Deco::Tissue( halftime => 5, M0 => 3.17, deltaM => 0.180);
is ($tis3->otu(), 0, "Starting with 0 otu's");
# under 0.5 pO2 otu's do not contribute, at 10 meters pO2 = 0.42
$tis3->point(1,10);
$tis3->point(61,10);  # 1 minute at 10 meters
is( $tis3->calculate_otu(), 0, "10 meters on air does not give otu's");

# now go to 20 meters (pO2 0.63)
$tis3->point(62,20);
$tis3->point(182,20); # stay for 2 minutes
is( sprintf("%.3f", $tis3->calculate_otu()), 0.654, "OTU's look good");
# are they stored OK
is( sprintf("%.3f", $tis3->otu()), 0.654, "....and stored as well");
# let's stay another 4 minutes, this should triple the amount of OTU's
$tis3->point(422, 20);
is( sprintf("%.3f", $tis3->calculate_otu()), 1.961, "OTU's added");


# let's set some different gases
$tis3->gas( 'O2' => 55, 'n2'=> 45);
is($tis3->{'o2'}->{fraction}, 0.55, "O2 fraction is good");
is($tis3->{'n2'}->{fraction}, 0.45, "as is the N2 fraction");
throws_ok { $tis3->gas( 'Xe' => 12)  } qr/Can't use gas xe/ , "trying to set unsupported gas";


