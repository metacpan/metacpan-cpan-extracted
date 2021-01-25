#!perl
# Test Geo::Ellipsoid scale

use strict;
use warnings;

use Test::More tests => 180;
use Test::Number::Delta relative => 1e-6;
use Geo::Ellipsoid;

my $e = Geo::Ellipsoid->new( angle_unit => 'degrees' );
my( $xs, $ys );
( $ys, $xs ) = $e->scales(0);
delta_ok( $xs, 111319.490793274, 'x scale is within tolerance' );
delta_ok( $ys, 110574.275821594, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(1);
delta_ok( $xs, 111302.649769732, 'x scale is within tolerance' );
delta_ok( $ys, 110574.614016816, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(2);
delta_ok( $xs, 111252.131520103, 'x scale is within tolerance' );
delta_ok( $ys, 110575.628200778, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(3);
delta_ok( $xs, 111167.950506731, 'x scale is within tolerance' );
delta_ok( $ys, 110577.317168814, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(4);
delta_ok( $xs, 111050.130831399, 'x scale is within tolerance' );
delta_ok( $ys, 110579.678914611, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(5);
delta_ok( $xs, 110898.706232127, 'x scale is within tolerance' );
delta_ok( $ys, 110582.710632409, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(6);
delta_ok( $xs, 110713.720078689, 'x scale is within tolerance' );
delta_ok( $ys, 110586.408720072, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(7);
delta_ok( $xs, 110495.225366811, 'x scale is within tolerance' );
delta_ok( $ys, 110590.768783042, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(8);
delta_ok( $xs, 110243.284711052, 'x scale is within tolerance' );
delta_ok( $ys, 110595.785639154, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(9);
delta_ok( $xs, 109957.970336344, 'x scale is within tolerance' );
delta_ok( $ys, 110601.453324332, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(10);
delta_ok( $xs, 109639.364068153, 'x scale is within tolerance' );
delta_ok( $ys, 110607.765099137, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(11);
delta_ok( $xs, 109287.557321245, 'x scale is within tolerance' );
delta_ok( $ys, 110614.713456187, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(12);
delta_ok( $xs, 108902.651087025, 'x scale is within tolerance' );
delta_ok( $ys, 110622.290128422, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(13);
delta_ok( $xs, 108484.755919402, 'x scale is within tolerance' );
delta_ok( $ys, 110630.486098225, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(14);
delta_ok( $xs, 108033.991919153, 'x scale is within tolerance' );
delta_ok( $ys, 110639.291607378, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(15);
delta_ok( $xs, 107550.488716736, 'x scale is within tolerance' );
delta_ok( $ys, 110648.696167862, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(16);
delta_ok( $xs, 107034.385453513, 'x scale is within tolerance' );
delta_ok( $ys, 110658.688573475, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(17);
delta_ok( $xs, 106485.830761325, 'x scale is within tolerance' );
delta_ok( $ys, 110669.256912276, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(18);
delta_ok( $xs, 105904.982740377, 'x scale is within tolerance' );
delta_ok( $ys, 110680.388579831, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(19);
delta_ok( $xs, 105292.008935377, 'x scale is within tolerance' );
delta_ok( $ys, 110692.070293263, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(20);
delta_ok( $xs, 104647.086309862, 'x scale is within tolerance' );
delta_ok( $ys, 110704.288106085, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(21);
delta_ok( $xs, 103970.401218673, 'x scale is within tolerance' );
delta_ok( $ys, 110717.027423818, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(22);
delta_ok( $xs, 103262.149378494, 'x scale is within tolerance' );
delta_ok( $ys, 110730.273020361, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(23);
delta_ok( $xs, 102522.535836412, 'x scale is within tolerance' );
delta_ok( $ys, 110744.00905512, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(24);
delta_ok( $xs, 101751.774936417, 'x scale is within tolerance' );
delta_ok( $ys, 110758.21909087, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(25);
delta_ok( $xs, 100950.090283789, 'x scale is within tolerance' );
delta_ok( $ys, 110772.88611234, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(26);
delta_ok( $xs, 100117.714707292, 'x scale is within tolerance' );
delta_ok( $ys, 110787.992545504, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(27);
delta_ok( $xs, 99254.890219118, 'x scale is within tolerance' );
delta_ok( $ys, 110803.520277558, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(28);
delta_ok( $xs, 98361.8679724994, 'x scale is within tolerance' );
delta_ok( $ys, 110819.450677574, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(29);
delta_ok( $xs, 97438.9082169266, 'x scale is within tolerance' );
delta_ok( $ys, 110835.764617804, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(30);
delta_ok( $xs, 96486.2802508965, 'x scale is within tolerance' );
delta_ok( $ys, 110852.442495617, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(31);
delta_ok( $xs, 95504.2623721221, 'x scale is within tolerance' );
delta_ok( $ys, 110869.464256056, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(32);
delta_ok( $xs, 94493.1418251297, 'x scale is within tolerance' );
delta_ok( $ys, 110886.809414981, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(33);
delta_ok( $xs, 93453.2147461739, 'x scale is within tolerance' );
delta_ok( $ys, 110904.457082788, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(34);
delta_ok( $xs, 92384.7861053995, 'x scale is within tolerance' );
delta_ok( $ys, 110922.385988675, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(35);
delta_ok( $xs, 91288.1696461796, 'x scale is within tolerance' );
delta_ok( $ys, 110940.574505431, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(36);
delta_ok( $xs, 90163.6878215616, 'x scale is within tolerance' );
delta_ok( $ys, 110959.000674728, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(37);
delta_ok( $xs, 89011.6717277532, 'x scale is within tolerance' );
delta_ok( $ys, 110977.642232884, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(38);
delta_ok( $xs, 87832.461034582, 'x scale is within tolerance' );
delta_ok( $ys, 110996.476637075, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(39);
delta_ok( $xs, 86626.4039128637, 'x scale is within tolerance' );
delta_ok( $ys, 111015.481091969, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(40);
delta_ok( $xs, 85393.8569586184, 'x scale is within tolerance' );
delta_ok( $ys, 111034.632576751, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(41);
delta_ok( $xs, 84135.1851140718, 'x scale is within tolerance' );
delta_ok( $ys, 111053.907872507, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(42);
delta_ok( $xs, 82850.7615853864, 'x scale is within tolerance' );
delta_ok( $ys, 111073.283589948, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(43);
delta_ok( $xs, 81540.9677570662, 'x scale is within tolerance' );
delta_ok( $ys, 111092.736197432, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(44);
delta_ok( $xs, 80206.1931029833, 'x scale is within tolerance' );
delta_ok( $ys, 111112.242049253, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(45);
delta_ok( $xs, 78846.8350939781, 'x scale is within tolerance' );
delta_ok( $ys, 111131.777414176, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(46);
delta_ok( $xs, 77463.2991019873, 'x scale is within tolerance' );
delta_ok( $ys, 111151.318504168, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(47);
delta_ok( $xs, 76055.9983006586, 'x scale is within tolerance' );
delta_ok( $ys, 111170.841503309, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(48);
delta_ok( $xs, 74625.3535624143, 'x scale is within tolerance' );
delta_ok( $ys, 111190.322596824, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(49);
delta_ok( $xs, 73171.7933519306, 'x scale is within tolerance' );
delta_ok( $ys, 111209.738000236, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(50);
delta_ok( $xs, 71695.753616003, 'x scale is within tolerance' );
delta_ok( $ys, 111229.063988562, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(51);
delta_ok( $xs, 70197.6776697733, 'x scale is within tolerance' );
delta_ok( $ys, 111248.276925556, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(52);
delta_ok( $xs, 68678.0160792985, 'x scale is within tolerance' );
delta_ok( $ys, 111267.353292927, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(53);
delta_ok( $xs, 67137.2265404469, 'x scale is within tolerance' );
delta_ok( $ys, 111286.269719523, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(54);
delta_ok( $xs, 65575.7737541096, 'x scale is within tolerance' );
delta_ok( $ys, 111305.003010423, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(55);
delta_ok( $xs, 63994.1292977257, 'x scale is within tolerance' );
delta_ok( $ys, 111323.530175906, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(56);
delta_ok( $xs, 62392.7714931183, 'x scale is within tolerance' );
delta_ok( $ys, 111341.828460265, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(57);
delta_ok( $xs, 60772.1852706498, 'x scale is within tolerance' );
delta_ok( $ys, 111359.875370412, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(58);
delta_ok( $xs, 59132.8620297074, 'x scale is within tolerance' );
delta_ok( $ys, 111377.64870425, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(59);
delta_ok( $xs, 57475.2994955351, 'x scale is within tolerance' );
delta_ok( $ys, 111395.12657876, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(60);
delta_ok( $xs, 55800.0015724362, 'x scale is within tolerance' );
delta_ok( $ys, 111412.287457779, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(61);
delta_ok( $xs, 54107.4781933752, 'x scale is within tolerance' );
delta_ok( $ys, 111429.110179413, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(62);
delta_ok( $xs, 52398.2451660134, 'x scale is within tolerance' );
delta_ok( $ys, 111445.573983052, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(63);
delta_ok( $xs, 50672.8240152185, 'x scale is within tolerance' );
delta_ok( $ys, 111461.65853596, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(64);
delta_ok( $xs, 48931.7418220956, 'x scale is within tolerance' );
delta_ok( $ys, 111477.343959384, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(65);
delta_ok( $xs, 47175.5310595919, 'x scale is within tolerance' );
delta_ok( $ys, 111492.610854148, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(66);
delta_ok( $xs, 45404.7294247327, 'x scale is within tolerance' );
delta_ok( $ys, 111507.440325702, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(67);
delta_ok( $xs, 43619.8796675553, 'x scale is within tolerance' );
delta_ok( $ys, 111521.814008585, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(68);
delta_ok( $xs, 41821.5294168082, 'x scale is within tolerance' );
delta_ok( $ys, 111535.714090256, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(69);
delta_ok( $xs, 40010.2310024944, 'x scale is within tolerance' );
delta_ok( $ys, 111549.12333427, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(70);
delta_ok( $xs, 38186.5412753387, 'x scale is within tolerance' );
delta_ok( $ys, 111562.025102756, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(71);
delta_ok( $xs, 36351.0214232683, 'x scale is within tolerance' );
delta_ok( $ys, 111574.403378166, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(72);
delta_ok( $xs, 34504.2367849983, 'x scale is within tolerance' );
delta_ok( $ys, 111586.242784253, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(73);
delta_ok( $xs, 32646.7566608212, 'x scale is within tolerance' );
delta_ok( $ys, 111597.52860626, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(74);
delta_ok( $xs, 30779.1541207048, 'x scale is within tolerance' );
delta_ok( $ys, 111608.246810274, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(75);
delta_ok( $xs, 28902.0058098066, 'x scale is within tolerance' );
delta_ok( $ys, 111618.38406172, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(76);
delta_ok( $xs, 27015.8917515192, 'x scale is within tolerance' );
delta_ok( $ys, 111627.927742966, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(77);
delta_ok( $xs, 25121.3951481649, 'x scale is within tolerance' );
delta_ok( $ys, 111636.865970013, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(78);
delta_ok( $xs, 23219.1021794639, 'x scale is within tolerance' );
delta_ok( $ys, 111645.187608236, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(79);
delta_ok( $xs, 21309.6017989022, 'x scale is within tolerance' );
delta_ok( $ys, 111652.882287157, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(80);
delta_ok( $xs, 19393.4855281322, 'x scale is within tolerance' );
delta_ok( $ys, 111659.940414223, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(81);
delta_ok( $xs, 17471.3472495414, 'x scale is within tolerance' );
delta_ok( $ys, 111666.35318757, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(82);
delta_ok( $xs, 15543.7829971289, 'x scale is within tolerance' );
delta_ok( $ys, 111672.112607742, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(83);
delta_ok( $xs, 13611.3907458309, 'x scale is within tolerance' );
delta_ok( $ys, 111677.211488361, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(84);
delta_ok( $xs, 11674.7701994437, 'x scale is within tolerance' );
delta_ok( $ys, 111681.64346572, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(85);
delta_ok( $xs, 9734.52257729095, 'x scale is within tolerance' );
delta_ok( $ys, 111685.403007281, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(86);
delta_ok( $xs, 7791.25039978636, 'x scale is within tolerance' );
delta_ok( $ys, 111688.485419075, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(87);
delta_ok( $xs, 5845.55727304685, 'x scale is within tolerance' );
delta_ok( $ys, 111690.886851982, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(88);
delta_ok( $xs, 3898.04767271025, 'x scale is within tolerance' );
delta_ok( $ys, 111692.604306881, 'y scale is within tolerance' );

( $ys, $xs ) = $e->scales(89);
delta_ok( $xs, 1949.32672711493, 'x scale is within tolerance' );
delta_ok( $ys, 111693.635638667, 'y scale is within tolerance' );
