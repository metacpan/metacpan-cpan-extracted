#!perl
# Test Geo::Ellipsoid at

use strict;
use warnings;

use Test::More tests => 400;
use Test::Number::Delta relative => 1e-6;
use Geo::Ellipsoid;

my $e1 = Geo::Ellipsoid->new(angle_unit => 'degrees');
my $e2 = Geo::Ellipsoid->new(angle_unit => 'degrees',longitude_symmetric => 1);
my($lat1,$lon1,$lat2,$lon2,$x,$y);

($lat1,$lon1) = $e1->at(-38.369163,190.874558,663.027183,53.574472);
($lat2,$lon2) = $e2->at(-38.369163,190.874558,663.027183,53.574472);
delta_ok( $lat1, -38.3656166574816, 'latitude is within tolerance' );
delta_ok( $lon1, 190.880662670944, 'longitude is within tolerance' );
delta_ok( $lat2, -38.3656166574816, 'latitude is within tolerance' );
delta_ok( $lon2, -169.119337329056, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-14.608137,30.094655,6390.954467,5.838786);
($lat2,$lon2) = $e2->at(-14.608137,30.094655,6390.954467,5.838786);
delta_ok( $lat1, -14.5506757312212, 'latitude is within tolerance' );
delta_ok( $lon1, 30.1006878108632, 'longitude is within tolerance' );
delta_ok( $lat2, -14.5506757312212, 'latitude is within tolerance' );
delta_ok( $lon2, 30.1006878108632, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-41.623677,208.834416,1610.051073,95.264953);
($lat2,$lon2) = $e2->at(-41.623677,208.834416,1610.051073,95.264953);
delta_ok( $lat1, -41.6250052190667, 'latitude is within tolerance' );
delta_ok( $lon1, 208.853654884741, 'longitude is within tolerance' );
delta_ok( $lat2, -41.6250052190667, 'latitude is within tolerance' );
delta_ok( $lon2, -151.146345115259, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-67.726400,52.964864,873.162562,51.679717);
($lat2,$lon2) = $e2->at(-67.726400,52.964864,873.162562,51.679717);
delta_ok( $lat1, -67.72154487153, 'latitude is within tolerance' );
delta_ok( $lon1, 52.9810494838027, 'longitude is within tolerance' );
delta_ok( $lat2, -67.72154487153, 'latitude is within tolerance' );
delta_ok( $lon2, 52.9810494838027, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-5.158991,259.931626,4773.871059,200.977967);
($lat2,$lon2) = $e2->at(-5.158991,259.931626,4773.871059,200.977967);
delta_ok( $lat1, -5.19929911014964, 'latitude is within tolerance' );
delta_ok( $lon1, 259.916209822012, 'longitude is within tolerance' );
delta_ok( $lat2, -5.19929911014964, 'latitude is within tolerance' );
delta_ok( $lon2, -100.083790177988, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-0.582762,29.118576,2946.165884,106.326170);
($lat2,$lon2) = $e2->at(-0.582762,29.118576,2946.165884,106.326170);
delta_ok( $lat1, -0.590251306822751, 'latitude is within tolerance' );
delta_ok( $lon1, 29.1439759994689, 'longitude is within tolerance' );
delta_ok( $lat2, -0.590251306822751, 'latitude is within tolerance' );
delta_ok( $lon2, 29.1439759994689, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-26.934636,30.474042,991.354098,72.872537);
($lat2,$lon2) = $e2->at(-26.934636,30.474042,991.354098,72.872537);
delta_ok( $lat1, -26.9320006429191, 'latitude is within tolerance' );
delta_ok( $lon1, 30.4835810246334, 'longitude is within tolerance' );
delta_ok( $lat2, -26.9320006429191, 'latitude is within tolerance' );
delta_ok( $lon2, 30.4835810246334, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-62.773742,62.342057,8353.955232,297.642864);
($lat2,$lon2) = $e2->at(-62.773742,62.342057,8353.955232,297.642864);
delta_ok( $lat1, -62.738893257913, 'latitude is within tolerance' );
delta_ok( $lon1, 62.197305731553, 'longitude is within tolerance' );
delta_ok( $lat2, -62.738893257913, 'latitude is within tolerance' );
delta_ok( $lon2, 62.197305731553, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(68.057252,192.858027,4711.422894,252.341167);
($lat2,$lon2) = $e2->at(68.057252,192.858027,4711.422894,252.341167);
delta_ok( $lat1, 68.0444035490457, 'latitude is within tolerance' );
delta_ok( $lon1, 192.750473587802, 'longitude is within tolerance' );
delta_ok( $lat2, 68.0444035490457, 'latitude is within tolerance' );
delta_ok( $lon2, -167.249526412198, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(1.348841,276.378914,9829.506468,166.918436);
($lat2,$lon2) = $e2->at(1.348841,276.378914,9829.506468,166.918436);
delta_ok( $lat1, 1.26225340172628, 'latitude is within tolerance' );
delta_ok( $lon1, 276.398904775364, 'longitude is within tolerance' );
delta_ok( $lat2, 1.26225340172628, 'latitude is within tolerance' );
delta_ok( $lon2, -83.6010952246363, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(27.335146,320.699240,8536.611848,271.060094);
($lat2,$lon2) = $e2->at(27.335146,320.699240,8536.611848,271.060094);
delta_ok( $lat1, 27.336544790133, 'latitude is within tolerance' );
delta_ok( $lon1, 320.612989777828, 'longitude is within tolerance' );
delta_ok( $lat2, 27.336544790133, 'latitude is within tolerance' );
delta_ok( $lon2, -39.3870102221718, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(34.623205,31.357288,7988.594185,134.837127);
($lat2,$lon2) = $e2->at(34.623205,31.357288,7988.594185,134.837127);
delta_ok( $lat1, 34.5724140545376, 'latitude is within tolerance' );
delta_ok( $lon1, 31.4190231012302, 'longitude is within tolerance' );
delta_ok( $lat2, 34.5724140545376, 'latitude is within tolerance' );
delta_ok( $lon2, 31.4190231012302, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-6.856999,130.887597,7763.221087,214.956451);
($lat2,$lon2) = $e2->at(-6.856999,130.887597,7763.221087,214.956451);
delta_ok( $lat1, -6.91453101371974, 'latitude is within tolerance' );
delta_ok( $lon1, 130.847349224089, 'longitude is within tolerance' );
delta_ok( $lat2, -6.91453101371974, 'latitude is within tolerance' );
delta_ok( $lon2, 130.847349224089, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-70.754141,43.777574,5605.534780,236.246900);
($lat2,$lon2) = $e2->at(-70.754141,43.777574,5605.534780,236.246900);
delta_ok( $lat1, -70.7820124418521, 'latitude is within tolerance' );
delta_ok( $lon1, 43.6507601360177, 'longitude is within tolerance' );
delta_ok( $lat2, -70.7820124418521, 'latitude is within tolerance' );
delta_ok( $lon2, 43.6507601360177, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-69.865357,188.114494,8437.219491,56.767387);
($lat2,$lon2) = $e2->at(-69.865357,188.114494,8437.219491,56.767387);
delta_ok( $lat1, -69.8238139675753, 'latitude is within tolerance' );
delta_ok( $lon1, 188.297759634022, 'longitude is within tolerance' );
delta_ok( $lat2, -69.8238139675753, 'latitude is within tolerance' );
delta_ok( $lon2, -171.702240365978, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-79.523730,324.065787,2171.798854,67.387309);
($lat2,$lon2) = $e2->at(-79.523730,324.065787,2171.798854,67.387309);
delta_ok( $lat1, -79.5162359949416, 'latitude is within tolerance' );
delta_ok( $lon1, 324.164444728713, 'longitude is within tolerance' );
delta_ok( $lat2, -79.5162359949416, 'latitude is within tolerance' );
delta_ok( $lon2, -35.8355552712871, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(74.606774,294.646962,7101.250686,211.655252);
($lat2,$lon2) = $e2->at(74.606774,294.646962,7101.250686,211.655252);
delta_ok( $lat1, 74.552581484185, 'latitude is within tolerance' );
delta_ok( $lon1, 294.521662695934, 'longitude is within tolerance' );
delta_ok( $lat2, 74.552581484185, 'latitude is within tolerance' );
delta_ok( $lon2, -65.4783373040659, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(28.972667,278.549276,2327.886028,78.654517);
($lat2,$lon2) = $e2->at(28.972667,278.549276,2327.886028,78.654517);
delta_ok( $lat1, 28.9767972109023, 'latitude is within tolerance' );
delta_ok( $lon1, 278.572694719835, 'longitude is within tolerance' );
delta_ok( $lat2, 28.9767972109023, 'latitude is within tolerance' );
delta_ok( $lon2, -81.4273052801652, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-20.359063,296.599967,1628.799157,220.382033);
($lat2,$lon2) = $e2->at(-20.359063,296.599967,1628.799157,220.382033);
delta_ok( $lat1, -20.3702696544288, 'latitude is within tolerance' );
delta_ok( $lon1, 296.589859316515, 'longitude is within tolerance' );
delta_ok( $lat2, -20.3702696544288, 'latitude is within tolerance' );
delta_ok( $lon2, -63.4101406834851, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-60.365048,156.813021,10.808349,186.644917);
($lat2,$lon2) = $e2->at(-60.365048,156.813021,10.808349,186.644917);
delta_ok( $lat1, -60.3651441594277, 'latitude is within tolerance' );
delta_ok( $lon1, 156.812997908757, 'longitude is within tolerance' );
delta_ok( $lat2, -60.3651441594277, 'latitude is within tolerance' );
delta_ok( $lon2, 156.812997908757, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-6.203945,247.684632,324.776721,145.835257);
($lat2,$lon2) = $e2->at(-6.203945,247.684632,324.776721,145.835257);
delta_ok( $lat1, -6.20637500756399, 'latitude is within tolerance' );
delta_ok( $lon1, 247.686280489375, 'longitude is within tolerance' );
delta_ok( $lat2, -6.20637500756399, 'latitude is within tolerance' );
delta_ok( $lon2, -112.313719510625, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(0.611947,100.746342,9973.981611,131.132873);
($lat2,$lon2) = $e2->at(0.611947,100.746342,9973.981611,131.132873);
delta_ok( $lat1, 0.55261091016823, 'latitude is within tolerance' );
delta_ok( $lon1, 100.813828549171, 'longitude is within tolerance' );
delta_ok( $lat2, 0.55261091016823, 'latitude is within tolerance' );
delta_ok( $lon2, 100.813828549171, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-20.725615,342.386744,817.492741,221.236681);
($lat2,$lon2) = $e2->at(-20.725615,342.386744,817.492741,221.236681);
delta_ok( $lat1, -20.7311674916701, 'latitude is within tolerance' );
delta_ok( $lon1, 342.381570767838, 'longitude is within tolerance' );
delta_ok( $lat2, -20.7311674916701, 'latitude is within tolerance' );
delta_ok( $lon2, -17.6184292321621, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(46.911457,128.191393,9713.277037,65.802158);
($lat2,$lon2) = $e2->at(46.911457,128.191393,9713.277037,65.802158);
delta_ok( $lat1, 46.9472109419573, 'latitude is within tolerance' );
delta_ok( $lon1, 128.307769547944, 'longitude is within tolerance' );
delta_ok( $lat2, 46.9472109419573, 'latitude is within tolerance' );
delta_ok( $lon2, 128.307769547944, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-11.235004,282.756437,1175.174596,192.154112);
($lat2,$lon2) = $e2->at(-11.235004,282.756437,1175.174596,192.154112);
delta_ok( $lat1, -11.2453901777647, 'latitude is within tolerance' );
delta_ok( $lon1, 282.754171348951, 'longitude is within tolerance' );
delta_ok( $lat2, -11.2453901777647, 'latitude is within tolerance' );
delta_ok( $lon2, -77.2458286510488, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-41.167125,221.956378,7772.438867,65.964741);
($lat2,$lon2) = $e2->at(-41.167125,221.956378,7772.438867,65.964741);
delta_ok( $lat1, -41.1385887169891, 'latitude is within tolerance' );
delta_ok( $lon1, 222.040925759323, 'longitude is within tolerance' );
delta_ok( $lat2, -41.1385887169891, 'latitude is within tolerance' );
delta_ok( $lon2, -137.959074240677, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-1.549886,336.466532,3150.908018,129.475800);
($lat2,$lon2) = $e2->at(-1.549886,336.466532,3150.908018,129.475800);
delta_ok( $lat1, -1.56800166865689, 'latitude is within tolerance' );
delta_ok( $lon1, 336.48838856866, 'longitude is within tolerance' );
delta_ok( $lat2, -1.56800166865689, 'latitude is within tolerance' );
delta_ok( $lon2, -23.5116114313395, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-63.776699,134.057987,8903.026576,322.164617);
($lat2,$lon2) = $e2->at(-63.776699,134.057987,8903.026576,322.164617);
delta_ok( $lat1, -63.7135798907925, 'latitude is within tolerance' );
delta_ok( $lon1, 133.947510160671, 'longitude is within tolerance' );
delta_ok( $lat2, -63.7135798907925, 'latitude is within tolerance' );
delta_ok( $lon2, 133.947510160671, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(77.940951,38.523563,1493.070064,336.795873);
($lat2,$lon2) = $e2->at(77.940951,38.523563,1493.070064,336.795873);
delta_ok( $lat1, 77.9532419255974, 'latitude is within tolerance' );
delta_ok( $lon1, 38.4983240629321, 'longitude is within tolerance' );
delta_ok( $lat2, 77.9532419255974, 'latitude is within tolerance' );
delta_ok( $lon2, 38.4983240629321, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(45.339403,315.409130,2618.493509,45.478452);
($lat2,$lon2) = $e2->at(45.339403,315.409130,2618.493509,45.478452);
delta_ok( $lat1, 45.3559203918087, 'latitude is within tolerance' );
delta_ok( $lon1, 315.432955775137, 'longitude is within tolerance' );
delta_ok( $lat2, 45.3559203918087, 'latitude is within tolerance' );
delta_ok( $lon2, -44.5670442248635, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(6.190847,124.992089,3854.030593,133.198367);
($lat2,$lon2) = $e2->at(6.190847,124.992089,3854.030593,133.198367);
delta_ok( $lat1, 6.16698993482276, 'latitude is within tolerance' );
delta_ok( $lon1, 125.017473198902, 'longitude is within tolerance' );
delta_ok( $lat2, 6.16698993482276, 'latitude is within tolerance' );
delta_ok( $lon2, 125.017473198902, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-4.121498,262.769582,9308.966888,178.488881);
($lat2,$lon2) = $e2->at(-4.121498,262.769582,9308.966888,178.488881);
delta_ok( $lat1, -4.20565178483598, 'latitude is within tolerance' );
delta_ok( $lon1, 262.771793465594, 'longitude is within tolerance' );
delta_ok( $lat2, -4.20565178483598, 'latitude is within tolerance' );
delta_ok( $lon2, -97.2282065344056, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-4.285155,344.319438,2988.101263,161.216474);
($lat2,$lon2) = $e2->at(-4.285155,344.319438,2988.101263,161.216474);
delta_ok( $lat1, -4.31073788511535, 'latitude is within tolerance' );
delta_ok( $lon1, 344.328105973954, 'longitude is within tolerance' );
delta_ok( $lat2, -4.31073788511535, 'latitude is within tolerance' );
delta_ok( $lon2, -15.6718940260457, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(51.523602,137.628739,7272.747263,125.320332);
($lat2,$lon2) = $e2->at(51.523602,137.628739,7272.747263,125.320332);
delta_ok( $lat1, 51.4857783969849, 'latitude is within tolerance' );
delta_ok( $lon1, 137.714167388512, 'longitude is within tolerance' );
delta_ok( $lat2, 51.4857783969849, 'latitude is within tolerance' );
delta_ok( $lon2, 137.714167388512, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(25.726049,310.324628,6650.414158,289.782664);
($lat2,$lon2) = $e2->at(25.726049,310.324628,6650.414158,289.782664);
delta_ok( $lat1, 25.7463533347373, 'latitude is within tolerance' );
delta_ok( $lon1, 310.262255281203, 'longitude is within tolerance' );
delta_ok( $lat2, 25.7463533347373, 'latitude is within tolerance' );
delta_ok( $lon2, -49.7377447187972, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(68.128342,115.791221,4772.498578,204.791356);
($lat2,$lon2) = $e2->at(68.128342,115.791221,4772.498578,204.791356);
delta_ok( $lat1, 68.0894895788839, 'latitude is within tolerance' );
delta_ok( $lon1, 115.743184646015, 'longitude is within tolerance' );
delta_ok( $lat2, 68.0894895788839, 'latitude is within tolerance' );
delta_ok( $lon2, 115.743184646015, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-11.919645,340.641713,891.615326,153.274434);
($lat2,$lon2) = $e2->at(-11.919645,340.641713,891.615326,153.274434);
delta_ok( $lat1, -11.9268441615802, 'latitude is within tolerance' );
delta_ok( $lon1, 340.645393779515, 'longitude is within tolerance' );
delta_ok( $lat2, -11.9268441615802, 'latitude is within tolerance' );
delta_ok( $lon2, -19.354606220485, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-30.550903,251.787663,3538.553197,192.651457);
($lat2,$lon2) = $e2->at(-30.550903,251.787663,3538.553197,192.651457);
delta_ok( $lat1, -30.5820467190056, 'latitude is within tolerance' );
delta_ok( $lon1, 251.77958340328, 'longitude is within tolerance' );
delta_ok( $lat2, -30.5820467190056, 'latitude is within tolerance' );
delta_ok( $lon2, -108.22041659672, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-61.797586,265.384439,9288.961574,50.299469);
($lat2,$lon2) = $e2->at(-61.797586,265.384439,9288.961574,50.299469);
delta_ok( $lat1, -61.7442754682937, 'latitude is within tolerance' );
delta_ok( $lon1, 265.519702300482, 'longitude is within tolerance' );
delta_ok( $lat2, -61.7442754682937, 'latitude is within tolerance' );
delta_ok( $lon2, -94.4802976995183, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(71.112709,8.834545,4018.709300,72.034521);
($lat2,$lon2) = $e2->at(71.112709,8.834545,4018.709300,72.034521);
delta_ok( $lat1, 71.1237884898956, 'latitude is within tolerance' );
delta_ok( $lon1, 8.9403714174623, 'longitude is within tolerance' );
delta_ok( $lat2, 71.1237884898956, 'latitude is within tolerance' );
delta_ok( $lon2, 8.9403714174623, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-63.553064,13.025588,4062.612060,159.653083);
($lat2,$lon2) = $e2->at(-63.553064,13.025588,4062.612060,159.653083);
delta_ok( $lat1, -63.587232627602, 'latitude is within tolerance' );
delta_ok( $lon1, 13.0540374200214, 'longitude is within tolerance' );
delta_ok( $lat2, -63.587232627602, 'latitude is within tolerance' );
delta_ok( $lon2, 13.0540374200214, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(29.289568,92.918510,8113.351247,35.674974);
($lat2,$lon2) = $e2->at(29.289568,92.918510,8113.351247,35.674974);
delta_ok( $lat1, 29.3490208963828, 'latitude is within tolerance' );
delta_ok( $lon1, 92.9672340946057, 'longitude is within tolerance' );
delta_ok( $lat2, 29.3490208963828, 'latitude is within tolerance' );
delta_ok( $lon2, 92.9672340946057, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(23.630668,183.960989,4996.609275,55.919867);
($lat2,$lon2) = $e2->at(23.630668,183.960989,4996.609275,55.919867);
delta_ok( $lat1, 23.6559427295585, 'latitude is within tolerance' );
delta_ok( $lon1, 184.001554318971, 'longitude is within tolerance' );
delta_ok( $lat2, 23.6559427295585, 'latitude is within tolerance' );
delta_ok( $lon2, -175.998445681029, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(21.323022,38.682180,2136.676569,319.096878);
($lat2,$lon2) = $e2->at(21.323022,38.682180,2136.676569,319.096878);
delta_ok( $lat1, 21.3376068588205, 'latitude is within tolerance' );
delta_ok( $lon1, 38.6686929767104, 'longitude is within tolerance' );
delta_ok( $lat2, 21.3376068588205, 'latitude is within tolerance' );
delta_ok( $lon2, 38.6686929767104, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(77.751666,6.954744,8617.247199,43.480525);
($lat2,$lon2) = $e2->at(77.751666,6.954744,8617.247199,43.480525);
delta_ok( $lat1, 77.8075587887118, 'latitude is within tolerance' );
delta_ok( $lon1, 7.20615011733763, 'longitude is within tolerance' );
delta_ok( $lat2, 77.8075587887118, 'latitude is within tolerance' );
delta_ok( $lon2, 7.20615011733763, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-58.652658,205.140021,1309.266436,310.900238);
($lat2,$lon2) = $e2->at(-58.652658,205.140021,1309.266436,310.900238);
delta_ok( $lat1, -58.6449608105583, 'latitude is within tolerance' );
delta_ok( $lon1, 205.122978574437, 'longitude is within tolerance' );
delta_ok( $lat2, -58.6449608105583, 'latitude is within tolerance' );
delta_ok( $lon2, -154.877021425563, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(7.193705,159.638737,3177.227490,155.223944);
($lat2,$lon2) = $e2->at(7.193705,159.638737,3177.227490,155.223944);
delta_ok( $lat1, 7.16761967835449, 'latitude is within tolerance' );
delta_ok( $lon1, 159.650791084088, 'longitude is within tolerance' );
delta_ok( $lat2, 7.16761967835449, 'latitude is within tolerance' );
delta_ok( $lon2, 159.650791084088, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(74.707726,290.854396,7214.189514,304.432840);
($lat2,$lon2) = $e2->at(74.707726,290.854396,7214.189514,304.432840);
delta_ok( $lat1, 74.7441816240245, 'latitude is within tolerance' );
delta_ok( $lon1, 290.651891561222, 'longitude is within tolerance' );
delta_ok( $lat2, 74.7441816240245, 'latitude is within tolerance' );
delta_ok( $lon2, -69.3481084387778, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(68.994921,41.466113,4652.207721,141.053623);
($lat2,$lon2) = $e2->at(68.994921,41.466113,4652.207721,141.053623);
delta_ok( $lat1, 68.9624691494271, 'latitude is within tolerance' );
delta_ok( $lon1, 41.5390782800596, 'longitude is within tolerance' );
delta_ok( $lat2, 68.9624691494271, 'latitude is within tolerance' );
delta_ok( $lon2, 41.5390782800596, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-19.222949,91.053479,1338.282294,224.550018);
($lat2,$lon2) = $e2->at(-19.222949,91.053479,1338.282294,224.550018);
delta_ok( $lat1, -19.2315645979899, 'latitude is within tolerance' );
delta_ok( $lon1, 91.0445501139712, 'longitude is within tolerance' );
delta_ok( $lat2, -19.2315645979899, 'latitude is within tolerance' );
delta_ok( $lon2, 91.0445501139712, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(19.041053,175.994927,5177.048787,281.316611);
($lat2,$lon2) = $e2->at(19.041053,175.994927,5177.048787,281.316611);
delta_ok( $lat1, 19.0502245946019, 'latitude is within tolerance' );
delta_ok( $lon1, 175.946699498326, 'longitude is within tolerance' );
delta_ok( $lat2, 19.0502245946019, 'latitude is within tolerance' );
delta_ok( $lon2, 175.946699498326, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-35.454628,153.274308,1072.202082,83.828810);
($lat2,$lon2) = $e2->at(-35.454628,153.274308,1072.202082,83.828810);
delta_ok( $lat1, -35.4535887262639, 'latitude is within tolerance' );
delta_ok( $lon1, 153.286050580698, 'longitude is within tolerance' );
delta_ok( $lat2, -35.4535887262639, 'latitude is within tolerance' );
delta_ok( $lon2, 153.286050580698, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(64.324875,209.104753,8132.271740,281.572223);
($lat2,$lon2) = $e2->at(64.324875,209.104753,8132.271740,281.572223);
delta_ok( $lat1, 64.3394159635433, 'latitude is within tolerance' );
delta_ok( $lon1, 208.939932681831, 'longitude is within tolerance' );
delta_ok( $lat2, 64.3394159635433, 'latitude is within tolerance' );
delta_ok( $lon2, -151.060067318169, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(33.139375,123.465763,9357.301964,74.517011);
($lat2,$lon2) = $e2->at(33.139375,123.465763,9357.301964,74.517011);
delta_ok( $lat1, 33.1618601109721, 'latitude is within tolerance' );
delta_ok( $lon1, 123.562433957867, 'longitude is within tolerance' );
delta_ok( $lat2, 33.1618601109721, 'latitude is within tolerance' );
delta_ok( $lon2, 123.562433957867, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(35.694667,300.725605,3436.937434,117.656799);
($lat2,$lon2) = $e2->at(35.694667,300.725605,3436.937434,117.656799);
delta_ok( $lat1, 35.6802840942486, 'latitude is within tolerance' );
delta_ok( $lon1, 300.75923369164, 'longitude is within tolerance' );
delta_ok( $lat2, 35.6802840942486, 'latitude is within tolerance' );
delta_ok( $lon2, -59.2407663083597, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-25.789728,191.087862,5544.330184,5.661707);
($lat2,$lon2) = $e2->at(-25.789728,191.087862,5544.330184,5.661707);
delta_ok( $lat1, -25.7399260442896, 'latitude is within tolerance' );
delta_ok( $lon1, 191.093313592838, 'longitude is within tolerance' );
delta_ok( $lat2, -25.7399260442896, 'latitude is within tolerance' );
delta_ok( $lon2, -168.906686407162, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-7.204161,179.885067,2512.365469,183.789892);
($lat2,$lon2) = $e2->at(-7.204161,179.885067,2512.365469,183.789892);
delta_ok( $lat1, -7.22682901108564, 'latitude is within tolerance' );
delta_ok( $lon1, 179.883563144484, 'longitude is within tolerance' );
delta_ok( $lat2, -7.22682901108564, 'latitude is within tolerance' );
delta_ok( $lon2, 179.883563144484, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-41.090138,219.595320,2968.409513,329.275936);
($lat2,$lon2) = $e2->at(-41.090138,219.595320,2968.409513,329.275936);
delta_ok( $lat1, -41.0671591825447, 'latitude is within tolerance' );
delta_ok( $lon1, 219.577276687536, 'longitude is within tolerance' );
delta_ok( $lat2, -41.0671591825447, 'latitude is within tolerance' );
delta_ok( $lon2, -140.422723312464, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(11.191046,106.356107,4851.812086,51.506296);
($lat2,$lon2) = $e2->at(11.191046,106.356107,4851.812086,51.506296);
delta_ok( $lat1, 11.2183452049465, 'latitude is within tolerance' );
delta_ok( $lon1, 106.390879919224, 'longitude is within tolerance' );
delta_ok( $lat2, 11.2183452049465, 'latitude is within tolerance' );
delta_ok( $lon2, 106.390879919224, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(22.955732,47.794852,8246.705286,185.066176);
($lat2,$lon2) = $e2->at(22.955732,47.794852,8246.705286,185.066176);
delta_ok( $lat1, 22.8815557299625, 'latitude is within tolerance' );
delta_ok( $lon1, 47.7877547716615, 'longitude is within tolerance' );
delta_ok( $lat2, 22.8815557299625, 'latitude is within tolerance' );
delta_ok( $lon2, 47.7877547716615, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-15.074589,56.914619,7164.429748,173.487403);
($lat2,$lon2) = $e2->at(-15.074589,56.914619,7164.429748,173.487403);
delta_ok( $lat1, -15.1389196660838, 'latitude is within tolerance' );
delta_ok( $lon1, 56.9221791309893, 'longitude is within tolerance' );
delta_ok( $lat2, -15.1389196660838, 'latitude is within tolerance' );
delta_ok( $lon2, 56.9221791309893, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(35.067827,307.917302,8369.643934,170.157432);
($lat2,$lon2) = $e2->at(35.067827,307.917302,8369.643934,170.157432);
delta_ok( $lat1, 34.993494196776, 'latitude is within tolerance' );
delta_ok( $lon1, 307.932973187806, 'longitude is within tolerance' );
delta_ok( $lat2, 34.993494196776, 'latitude is within tolerance' );
delta_ok( $lon2, -52.0670268121944, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(66.084685,30.192264,1657.534288,243.904448);
($lat2,$lon2) = $e2->at(66.084685,30.192264,1657.534288,243.904448);
delta_ok( $lat1, 66.0781430272163, 'latitude is within tolerance' );
delta_ok( $lon1, 30.1593794067059, 'longitude is within tolerance' );
delta_ok( $lat2, 66.0781430272163, 'latitude is within tolerance' );
delta_ok( $lon2, 30.1593794067059, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(42.839865,327.847225,4283.496948,308.416746);
($lat2,$lon2) = $e2->at(42.839865,327.847225,4283.496948,308.416746);
delta_ok( $lat1, 42.8638173053354, 'latitude is within tolerance' );
delta_ok( $lon1, 327.806155932557, 'longitude is within tolerance' );
delta_ok( $lat2, 42.8638173053354, 'latitude is within tolerance' );
delta_ok( $lon2, -32.1938440674425, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-23.824528,241.336801,2179.408647,175.675228);
($lat2,$lon2) = $e2->at(-23.824528,241.336801,2179.408647,175.675228);
delta_ok( $lat1, -23.8441499994284, 'latitude is within tolerance' );
delta_ok( $lon1, 241.338413904748, 'longitude is within tolerance' );
delta_ok( $lat2, -23.8441499994284, 'latitude is within tolerance' );
delta_ok( $lon2, -118.661586095252, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-48.109675,147.804097,3851.598342,313.390029);
($lat2,$lon2) = $e2->at(-48.109675,147.804097,3851.598342,313.390029);
delta_ok( $lat1, -48.0858733128975, 'latitude is within tolerance' );
delta_ok( $lon1, 147.766528156688, 'longitude is within tolerance' );
delta_ok( $lat2, -48.0858733128975, 'latitude is within tolerance' );
delta_ok( $lon2, 147.766528156688, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-17.562152,276.168590,5665.575297,135.075003);
($lat2,$lon2) = $e2->at(-17.562152,276.168590,5665.575297,135.075003);
delta_ok( $lat1, -17.5983930208429, 'latitude is within tolerance' );
delta_ok( $lon1, 276.206284342329, 'longitude is within tolerance' );
delta_ok( $lat2, -17.5983930208429, 'latitude is within tolerance' );
delta_ok( $lon2, -83.7937156576705, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(64.918979,305.870922,2833.416804,309.531171);
($lat2,$lon2) = $e2->at(64.918979,305.870922,2833.416804,309.531171);
delta_ok( $lat1, 64.9351480714201, 'latitude is within tolerance' );
delta_ok( $lon1, 305.824710582963, 'longitude is within tolerance' );
delta_ok( $lat2, 64.9351480714201, 'latitude is within tolerance' );
delta_ok( $lon2, -54.1752894170374, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(75.481994,274.248595,1614.672640,65.431283);
($lat2,$lon2) = $e2->at(75.481994,274.248595,1614.672640,65.431283);
delta_ok( $lat1, 75.4880029055828, 'latitude is within tolerance' );
delta_ok( $lon1, 274.301072964265, 'longitude is within tolerance' );
delta_ok( $lat2, 75.4880029055828, 'latitude is within tolerance' );
delta_ok( $lon2, -85.6989270357354, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(3.076206,112.117539,9835.156864,258.316434);
($lat2,$lon2) = $e2->at(3.076206,112.117539,9835.156864,258.316434);
delta_ok( $lat1, 3.05819117659668, 'latitude is within tolerance' );
delta_ok( $lon1, 112.03089587221, 'longitude is within tolerance' );
delta_ok( $lat2, 3.05819117659668, 'latitude is within tolerance' );
delta_ok( $lon2, 112.03089587221, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(12.921677,151.249684,4165.773730,74.171323);
($lat2,$lon2) = $e2->at(12.921677,151.249684,4165.773730,74.171323);
delta_ok( $lat1, 12.9319448741798, 'latitude is within tolerance' );
delta_ok( $lon1, 151.286617723767, 'longitude is within tolerance' );
delta_ok( $lat2, 12.9319448741798, 'latitude is within tolerance' );
delta_ok( $lon2, 151.286617723767, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(72.833548,317.667505,62.516492,29.001224);
($lat2,$lon2) = $e2->at(72.833548,317.667505,62.516492,29.001224);
delta_ok( $lat1, 72.8340378772457, 'latitude is within tolerance' );
delta_ok( $lon1, 317.668425118621, 'longitude is within tolerance' );
delta_ok( $lat2, 72.8340378772457, 'latitude is within tolerance' );
delta_ok( $lon2, -42.3315748813785, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-33.041308,313.249683,9757.188845,231.280178);
($lat2,$lon2) = $e2->at(-33.041308,313.249683,9757.188845,231.280178);
delta_ok( $lat1, -33.0963123185806, 'latitude is within tolerance' );
delta_ok( $lon1, 313.168134096477, 'longitude is within tolerance' );
delta_ok( $lat2, -33.0963123185806, 'latitude is within tolerance' );
delta_ok( $lon2, -46.8318659035227, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-12.674750,312.909013,3145.681733,358.190380);
($lat2,$lon2) = $e2->at(-12.674750,312.909013,3145.681733,358.190380);
delta_ok( $lat1, -12.6463295522285, 'latitude is within tolerance' );
delta_ok( $lon1, 312.908098770026, 'longitude is within tolerance' );
delta_ok( $lat2, -12.6463295522285, 'latitude is within tolerance' );
delta_ok( $lon2, -47.0919012299736, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-67.846380,99.041109,8317.496525,12.266233);
($lat2,$lon2) = $e2->at(-67.846380,99.041109,8317.496525,12.266233);
delta_ok( $lat1, -67.7735027510774, 'latitude is within tolerance' );
delta_ok( $lon1, 99.0829538757835, 'longitude is within tolerance' );
delta_ok( $lat2, -67.7735027510774, 'latitude is within tolerance' );
delta_ok( $lon2, 99.0829538757835, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(41.911754,138.151813,2308.592027,18.057173);
($lat2,$lon2) = $e2->at(41.911754,138.151813,2308.592027,18.057173);
delta_ok( $lat1, 41.9315142758588, 'latitude is within tolerance' );
delta_ok( $lon1, 138.160440601835, 'longitude is within tolerance' );
delta_ok( $lat2, 41.9315142758588, 'latitude is within tolerance' );
delta_ok( $lon2, 138.160440601835, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-27.100512,351.279156,7472.750836,215.020221);
($lat2,$lon2) = $e2->at(-27.100512,351.279156,7472.750836,215.020221);
delta_ok( $lat1, -27.1557353506078, 'latitude is within tolerance' );
delta_ok( $lon1, 351.235890988004, 'longitude is within tolerance' );
delta_ok( $lat2, -27.1557353506078, 'latitude is within tolerance' );
delta_ok( $lon2, -8.76410901199599, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(19.497371,220.383733,5718.963068,119.960301);
($lat2,$lon2) = $e2->at(19.497371,220.383733,5718.963068,119.960301);
delta_ok( $lat1, 19.4715643857244, 'latitude is within tolerance' );
delta_ok( $lon1, 220.430924356231, 'longitude is within tolerance' );
delta_ok( $lat2, 19.4715643857244, 'latitude is within tolerance' );
delta_ok( $lon2, -139.569075643769, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(18.396198,143.265994,7349.515732,7.492742);
($lat2,$lon2) = $e2->at(18.396198,143.265994,7349.515732,7.492742);
delta_ok( $lat1, 18.4620306038802, 'latitude is within tolerance' );
delta_ok( $lon1, 143.275067859029, 'longitude is within tolerance' );
delta_ok( $lat2, 18.4620306038802, 'latitude is within tolerance' );
delta_ok( $lon2, 143.275067859029, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-18.084386,221.381908,5982.507117,338.372199);
($lat2,$lon2) = $e2->at(-18.084386,221.381908,5982.507117,338.372199);
delta_ok( $lat1, -18.0341383666819, 'latitude is within tolerance' );
delta_ok( $lon1, 221.361083689563, 'longitude is within tolerance' );
delta_ok( $lat2, -18.0341383666819, 'latitude is within tolerance' );
delta_ok( $lon2, -138.638916310437, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(46.204817,295.396070,8211.580529,221.904425);
($lat2,$lon2) = $e2->at(46.204817,295.396070,8211.580529,221.904425);
delta_ok( $lat1, 46.1498123310369, 'latitude is within tolerance' );
delta_ok( $lon1, 295.325077737085, 'longitude is within tolerance' );
delta_ok( $lat2, 46.1498123310369, 'latitude is within tolerance' );
delta_ok( $lon2, -64.6749222629154, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-30.523088,295.285416,434.243851,69.446059);
($lat2,$lon2) = $e2->at(-30.523088,295.285416,434.243851,69.446059);
delta_ok( $lat1, -30.5217130438922, 'latitude is within tolerance' );
delta_ok( $lon1, 295.289652469157, 'longitude is within tolerance' );
delta_ok( $lat2, -30.5217130438922, 'latitude is within tolerance' );
delta_ok( $lon2, -64.7103475308431, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(13.742087,63.763606,4388.913613,181.241894);
($lat2,$lon2) = $e2->at(13.742087,63.763606,4388.913613,181.241894);
delta_ok( $lat1, 13.7024269689814, 'latitude is within tolerance' );
delta_ok( $lon1, 63.7627262988153, 'longitude is within tolerance' );
delta_ok( $lat2, 13.7024269689814, 'latitude is within tolerance' );
delta_ok( $lon2, 63.7627262988153, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(1.554684,167.837560,3131.747930,59.213013);
($lat2,$lon2) = $e2->at(1.554684,167.837560,3131.747930,59.213013);
delta_ok( $lat1, 1.56918059097552, 'latitude is within tolerance' );
delta_ok( $lon1, 167.861737784577, 'longitude is within tolerance' );
delta_ok( $lat2, 1.56918059097552, 'latitude is within tolerance' );
delta_ok( $lon2, 167.861737784577, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(40.356751,153.160097,5740.614634,305.081769);
($lat2,$lon2) = $e2->at(40.356751,153.160097,5740.614634,305.081769);
delta_ok( $lat1, 40.3864504304799, 'latitude is within tolerance' );
delta_ok( $lon1, 153.104771159051, 'longitude is within tolerance' );
delta_ok( $lat2, 40.3864504304799, 'latitude is within tolerance' );
delta_ok( $lon2, 153.104771159051, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(46.867006,44.857631,9269.632604,208.315002);
($lat2,$lon2) = $e2->at(46.867006,44.857631,9269.632604,208.315002);
delta_ok( $lat1, 46.7935841133508, 'latitude is within tolerance' );
delta_ok( $lon1, 44.8000433688766, 'longitude is within tolerance' );
delta_ok( $lat2, 46.7935841133508, 'latitude is within tolerance' );
delta_ok( $lon2, 44.8000433688766, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-9.089458,237.666143,2239.328571,14.324009);
($lat2,$lon2) = $e2->at(-9.089458,237.666143,2239.328571,14.324009);
delta_ok( $lat1, -9.06984018685995, 'latitude is within tolerance' );
delta_ok( $lon1, 237.671182904242, 'longitude is within tolerance' );
delta_ok( $lat2, -9.06984018685995, 'latitude is within tolerance' );
delta_ok( $lon2, -122.328817095758, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-27.107665,34.103508,4111.521802,243.342905);
($lat2,$lon2) = $e2->at(-27.107665,34.103508,4111.521802,243.342905);
delta_ok( $lat1, -27.1243073483822, 'latitude is within tolerance' );
delta_ok( $lon1, 34.0664465612592, 'longitude is within tolerance' );
delta_ok( $lat2, -27.1243073483822, 'latitude is within tolerance' );
delta_ok( $lon2, 34.0664465612592, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(5.067958,24.268528,8172.788174,38.204963);
($lat2,$lon2) = $e2->at(5.067958,24.268528,8172.788174,38.204963);
delta_ok( $lat1, 5.12603197726362, 'latitude is within tolerance' );
delta_ok( $lon1, 24.3141162471053, 'longitude is within tolerance' );
delta_ok( $lat2, 5.12603197726362, 'latitude is within tolerance' );
delta_ok( $lon2, 24.3141162471053, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-30.360974,322.538048,1475.216259,59.263577);
($lat2,$lon2) = $e2->at(-30.360974,322.538048,1475.216259,59.263577);
delta_ok( $lat1, -30.3541720736129, 'latitude is within tolerance' );
delta_ok( $lon1, 322.551236568074, 'longitude is within tolerance' );
delta_ok( $lat2, -30.3541720736129, 'latitude is within tolerance' );
delta_ok( $lon2, -37.4487634319259, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(54.780139,8.410011,9928.854395,201.999534);
($lat2,$lon2) = $e2->at(54.780139,8.410011,9928.854395,201.999534);
delta_ok( $lat1, 54.6974261720386, 'latitude is within tolerance' );
delta_ok( $lon1, 8.3523242715081, 'longitude is within tolerance' );
delta_ok( $lat2, 54.6974261720386, 'latitude is within tolerance' );
delta_ok( $lon2, 8.3523242715081, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(13.769616,110.113762,1308.712391,343.083492);
($lat2,$lon2) = $e2->at(13.769616,110.113762,1308.712391,343.083492);
delta_ok( $lat1, 13.78093309177, 'latitude is within tolerance' );
delta_ok( $lon1, 110.110240703272, 'longitude is within tolerance' );
delta_ok( $lat2, 13.78093309177, 'latitude is within tolerance' );
delta_ok( $lon2, 110.110240703272, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-64.270514,45.105873,5363.627587,140.110968);
($lat2,$lon2) = $e2->at(-64.270514,45.105873,5363.627587,140.110968);
delta_ok( $lat1, -64.3074130400444, 'latitude is within tolerance' );
delta_ok( $lon1, 45.1769508481278, 'longitude is within tolerance' );
delta_ok( $lat2, -64.3074130400444, 'latitude is within tolerance' );
delta_ok( $lon2, 45.1769508481278, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-45.137898,141.541847,1959.185717,345.810769);
($lat2,$lon2) = $e2->at(-45.137898,141.541847,1959.185717,345.810769);
delta_ok( $lat1, -45.1208065938124, 'latitude is within tolerance' );
delta_ok( $lon1, 141.535743596221, 'longitude is within tolerance' );
delta_ok( $lat2, -45.1208065938124, 'latitude is within tolerance' );
delta_ok( $lon2, 141.535743596221, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(6.782845,255.237805,3347.905328,296.785788);
($lat2,$lon2) = $e2->at(6.782845,255.237805,3347.905328,296.785788);
delta_ok( $lat1, 6.79648733577162, 'latitude is within tolerance' );
delta_ok( $lon1, 255.21076894319, 'longitude is within tolerance' );
delta_ok( $lat2, 6.79648733577162, 'latitude is within tolerance' );
delta_ok( $lon2, -104.78923105681, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(6.371687,279.113190,364.003776,337.941402);
($lat2,$lon2) = $e2->at(6.371687,279.113190,364.003776,337.941402);
delta_ok( $lat1, 6.37473803790458, 'latitude is within tolerance' );
delta_ok( $lon1, 279.111954845525, 'longitude is within tolerance' );
delta_ok( $lat2, 6.37473803790458, 'latitude is within tolerance' );
delta_ok( $lon2, -80.8880451544753, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(44.782374,163.862303,9245.465886,45.480517);
($lat2,$lon2) = $e2->at(44.782374,163.862303,9245.465886,45.480517);
delta_ok( $lat1, 44.8406766505374, 'latitude is within tolerance' );
delta_ok( $lon1, 163.945679242349, 'longitude is within tolerance' );
delta_ok( $lat2, 44.8406766505374, 'latitude is within tolerance' );
delta_ok( $lon2, 163.945679242349, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-70.362274,322.490547,2582.286613,323.109595);
($lat2,$lon2) = $e2->at(-70.362274,322.490547,2582.286613,323.109595);
delta_ok( $lat1, -70.343757819168, 'latitude is within tolerance' );
delta_ok( $lon1, 322.449273778159, 'longitude is within tolerance' );
delta_ok( $lat2, -70.343757819168, 'latitude is within tolerance' );
delta_ok( $lon2, -37.5507262218411, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-19.715571,5.847281,5797.359451,217.945830);
($lat2,$lon2) = $e2->at(-19.715571,5.847281,5797.359451,217.945830);
delta_ok( $lat1, -19.7568659277085, 'latitude is within tolerance' );
delta_ok( $lon1, 5.81326755286751, 'longitude is within tolerance' );
delta_ok( $lat2, -19.7568659277085, 'latitude is within tolerance' );
delta_ok( $lon2, 5.81326755286751, 'longitude is within tolerance' );

($lat1,$lon1) = $e1->at(-69.938162,165.492639,7837.486006,155.206150);
($lat2,$lon2) = $e2->at(-69.938162,165.492639,7837.486006,155.206150);
delta_ok( $lat1, -70.0019179240387, 'latitude is within tolerance' );
delta_ok( $lon1, 165.578716457451, 'longitude is within tolerance' );
delta_ok( $lat2, -70.0019179240387, 'latitude is within tolerance' );
delta_ok( $lon2, 165.578716457451, 'longitude is within tolerance' );
