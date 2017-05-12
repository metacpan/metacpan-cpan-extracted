#!/usr/local/bin/perl
# Test Geo::Ellipsoid scale
use Test::More tests => 180;
use Test::Number::Delta relative => 1e-6;
use Geo::Ellipsoid;
use blib;
use strict;
use warnings;

my $e = Geo::Ellipsoid->new( units => 'degrees' );
my( $xs, $ys );
( $ys, $xs ) = $e->scales(0);
delta_ok( $xs, 111319.490793274 );
delta_ok( $ys, 110574.275821594 );

( $ys, $xs ) = $e->scales(1);
delta_ok( $xs, 111302.649769732 );
delta_ok( $ys, 110574.614016816 );

( $ys, $xs ) = $e->scales(2);
delta_ok( $xs, 111252.131520103 );
delta_ok( $ys, 110575.628200778 );

( $ys, $xs ) = $e->scales(3);
delta_ok( $xs, 111167.950506731 );
delta_ok( $ys, 110577.317168814 );

( $ys, $xs ) = $e->scales(4);
delta_ok( $xs, 111050.130831399 );
delta_ok( $ys, 110579.678914611 );

( $ys, $xs ) = $e->scales(5);
delta_ok( $xs, 110898.706232127 );
delta_ok( $ys, 110582.710632409 );

( $ys, $xs ) = $e->scales(6);
delta_ok( $xs, 110713.720078689 );
delta_ok( $ys, 110586.408720072 );

( $ys, $xs ) = $e->scales(7);
delta_ok( $xs, 110495.225366811 );
delta_ok( $ys, 110590.768783042 );

( $ys, $xs ) = $e->scales(8);
delta_ok( $xs, 110243.284711052 );
delta_ok( $ys, 110595.785639154 );

( $ys, $xs ) = $e->scales(9);
delta_ok( $xs, 109957.970336344 );
delta_ok( $ys, 110601.453324332 );

( $ys, $xs ) = $e->scales(10);
delta_ok( $xs, 109639.364068153 );
delta_ok( $ys, 110607.765099137 );

( $ys, $xs ) = $e->scales(11);
delta_ok( $xs, 109287.557321245 );
delta_ok( $ys, 110614.713456187 );

( $ys, $xs ) = $e->scales(12);
delta_ok( $xs, 108902.651087025 );
delta_ok( $ys, 110622.290128422 );

( $ys, $xs ) = $e->scales(13);
delta_ok( $xs, 108484.755919402 );
delta_ok( $ys, 110630.486098225 );

( $ys, $xs ) = $e->scales(14);
delta_ok( $xs, 108033.991919153 );
delta_ok( $ys, 110639.291607378 );

( $ys, $xs ) = $e->scales(15);
delta_ok( $xs, 107550.488716736 );
delta_ok( $ys, 110648.696167862 );

( $ys, $xs ) = $e->scales(16);
delta_ok( $xs, 107034.385453513 );
delta_ok( $ys, 110658.688573475 );

( $ys, $xs ) = $e->scales(17);
delta_ok( $xs, 106485.830761325 );
delta_ok( $ys, 110669.256912276 );

( $ys, $xs ) = $e->scales(18);
delta_ok( $xs, 105904.982740377 );
delta_ok( $ys, 110680.388579831 );

( $ys, $xs ) = $e->scales(19);
delta_ok( $xs, 105292.008935377 );
delta_ok( $ys, 110692.070293263 );

( $ys, $xs ) = $e->scales(20);
delta_ok( $xs, 104647.086309862 );
delta_ok( $ys, 110704.288106085 );

( $ys, $xs ) = $e->scales(21);
delta_ok( $xs, 103970.401218673 );
delta_ok( $ys, 110717.027423818 );

( $ys, $xs ) = $e->scales(22);
delta_ok( $xs, 103262.149378494 );
delta_ok( $ys, 110730.273020361 );

( $ys, $xs ) = $e->scales(23);
delta_ok( $xs, 102522.535836412 );
delta_ok( $ys, 110744.00905512 );

( $ys, $xs ) = $e->scales(24);
delta_ok( $xs, 101751.774936417 );
delta_ok( $ys, 110758.21909087 );

( $ys, $xs ) = $e->scales(25);
delta_ok( $xs, 100950.090283789 );
delta_ok( $ys, 110772.88611234 );

( $ys, $xs ) = $e->scales(26);
delta_ok( $xs, 100117.714707292 );
delta_ok( $ys, 110787.992545504 );

( $ys, $xs ) = $e->scales(27);
delta_ok( $xs, 99254.890219118 );
delta_ok( $ys, 110803.520277558 );

( $ys, $xs ) = $e->scales(28);
delta_ok( $xs, 98361.8679724994 );
delta_ok( $ys, 110819.450677574 );

( $ys, $xs ) = $e->scales(29);
delta_ok( $xs, 97438.9082169266 );
delta_ok( $ys, 110835.764617804 );

( $ys, $xs ) = $e->scales(30);
delta_ok( $xs, 96486.2802508965 );
delta_ok( $ys, 110852.442495617 );

( $ys, $xs ) = $e->scales(31);
delta_ok( $xs, 95504.2623721221 );
delta_ok( $ys, 110869.464256056 );

( $ys, $xs ) = $e->scales(32);
delta_ok( $xs, 94493.1418251297 );
delta_ok( $ys, 110886.809414981 );

( $ys, $xs ) = $e->scales(33);
delta_ok( $xs, 93453.2147461739 );
delta_ok( $ys, 110904.457082788 );

( $ys, $xs ) = $e->scales(34);
delta_ok( $xs, 92384.7861053995 );
delta_ok( $ys, 110922.385988675 );

( $ys, $xs ) = $e->scales(35);
delta_ok( $xs, 91288.1696461796 );
delta_ok( $ys, 110940.574505431 );

( $ys, $xs ) = $e->scales(36);
delta_ok( $xs, 90163.6878215616 );
delta_ok( $ys, 110959.000674728 );

( $ys, $xs ) = $e->scales(37);
delta_ok( $xs, 89011.6717277532 );
delta_ok( $ys, 110977.642232884 );

( $ys, $xs ) = $e->scales(38);
delta_ok( $xs, 87832.461034582 );
delta_ok( $ys, 110996.476637075 );

( $ys, $xs ) = $e->scales(39);
delta_ok( $xs, 86626.4039128637 );
delta_ok( $ys, 111015.481091969 );

( $ys, $xs ) = $e->scales(40);
delta_ok( $xs, 85393.8569586184 );
delta_ok( $ys, 111034.632576751 );

( $ys, $xs ) = $e->scales(41);
delta_ok( $xs, 84135.1851140718 );
delta_ok( $ys, 111053.907872507 );

( $ys, $xs ) = $e->scales(42);
delta_ok( $xs, 82850.7615853864 );
delta_ok( $ys, 111073.283589948 );

( $ys, $xs ) = $e->scales(43);
delta_ok( $xs, 81540.9677570662 );
delta_ok( $ys, 111092.736197432 );

( $ys, $xs ) = $e->scales(44);
delta_ok( $xs, 80206.1931029833 );
delta_ok( $ys, 111112.242049253 );

( $ys, $xs ) = $e->scales(45);
delta_ok( $xs, 78846.8350939781 );
delta_ok( $ys, 111131.777414176 );

( $ys, $xs ) = $e->scales(46);
delta_ok( $xs, 77463.2991019873 );
delta_ok( $ys, 111151.318504168 );

( $ys, $xs ) = $e->scales(47);
delta_ok( $xs, 76055.9983006586 );
delta_ok( $ys, 111170.841503309 );

( $ys, $xs ) = $e->scales(48);
delta_ok( $xs, 74625.3535624143 );
delta_ok( $ys, 111190.322596824 );

( $ys, $xs ) = $e->scales(49);
delta_ok( $xs, 73171.7933519306 );
delta_ok( $ys, 111209.738000236 );

( $ys, $xs ) = $e->scales(50);
delta_ok( $xs, 71695.753616003 );
delta_ok( $ys, 111229.063988562 );

( $ys, $xs ) = $e->scales(51);
delta_ok( $xs, 70197.6776697733 );
delta_ok( $ys, 111248.276925556 );

( $ys, $xs ) = $e->scales(52);
delta_ok( $xs, 68678.0160792985 );
delta_ok( $ys, 111267.353292927 );

( $ys, $xs ) = $e->scales(53);
delta_ok( $xs, 67137.2265404469 );
delta_ok( $ys, 111286.269719523 );

( $ys, $xs ) = $e->scales(54);
delta_ok( $xs, 65575.7737541096 );
delta_ok( $ys, 111305.003010423 );

( $ys, $xs ) = $e->scales(55);
delta_ok( $xs, 63994.1292977257 );
delta_ok( $ys, 111323.530175906 );

( $ys, $xs ) = $e->scales(56);
delta_ok( $xs, 62392.7714931183 );
delta_ok( $ys, 111341.828460265 );

( $ys, $xs ) = $e->scales(57);
delta_ok( $xs, 60772.1852706498 );
delta_ok( $ys, 111359.875370412 );

( $ys, $xs ) = $e->scales(58);
delta_ok( $xs, 59132.8620297075 );
delta_ok( $ys, 111377.64870425 );

( $ys, $xs ) = $e->scales(59);
delta_ok( $xs, 57475.2994955351 );
delta_ok( $ys, 111395.12657876 );

( $ys, $xs ) = $e->scales(60);
delta_ok( $xs, 55800.0015724362 );
delta_ok( $ys, 111412.287457779 );

( $ys, $xs ) = $e->scales(61);
delta_ok( $xs, 54107.4781933752 );
delta_ok( $ys, 111429.110179413 );

( $ys, $xs ) = $e->scales(62);
delta_ok( $xs, 52398.2451660134 );
delta_ok( $ys, 111445.573983052 );

( $ys, $xs ) = $e->scales(63);
delta_ok( $xs, 50672.8240152185 );
delta_ok( $ys, 111461.65853596 );

( $ys, $xs ) = $e->scales(64);
delta_ok( $xs, 48931.7418220956 );
delta_ok( $ys, 111477.343959384 );

( $ys, $xs ) = $e->scales(65);
delta_ok( $xs, 47175.5310595919 );
delta_ok( $ys, 111492.610854148 );

( $ys, $xs ) = $e->scales(66);
delta_ok( $xs, 45404.7294247327 );
delta_ok( $ys, 111507.440325702 );

( $ys, $xs ) = $e->scales(67);
delta_ok( $xs, 43619.8796675553 );
delta_ok( $ys, 111521.814008585 );

( $ys, $xs ) = $e->scales(68);
delta_ok( $xs, 41821.5294168082 );
delta_ok( $ys, 111535.714090256 );

( $ys, $xs ) = $e->scales(69);
delta_ok( $xs, 40010.2310024944 );
delta_ok( $ys, 111549.12333427 );

( $ys, $xs ) = $e->scales(70);
delta_ok( $xs, 38186.5412753387 );
delta_ok( $ys, 111562.025102756 );

( $ys, $xs ) = $e->scales(71);
delta_ok( $xs, 36351.0214232683 );
delta_ok( $ys, 111574.403378166 );

( $ys, $xs ) = $e->scales(72);
delta_ok( $xs, 34504.2367849983 );
delta_ok( $ys, 111586.242784253 );

( $ys, $xs ) = $e->scales(73);
delta_ok( $xs, 32646.7566608212 );
delta_ok( $ys, 111597.52860626 );

( $ys, $xs ) = $e->scales(74);
delta_ok( $xs, 30779.1541207048 );
delta_ok( $ys, 111608.246810274 );

( $ys, $xs ) = $e->scales(75);
delta_ok( $xs, 28902.0058098066 );
delta_ok( $ys, 111618.38406172 );

( $ys, $xs ) = $e->scales(76);
delta_ok( $xs, 27015.8917515192 );
delta_ok( $ys, 111627.927742966 );

( $ys, $xs ) = $e->scales(77);
delta_ok( $xs, 25121.3951481649 );
delta_ok( $ys, 111636.865970013 );

( $ys, $xs ) = $e->scales(78);
delta_ok( $xs, 23219.1021794639 );
delta_ok( $ys, 111645.187608236 );

( $ys, $xs ) = $e->scales(79);
delta_ok( $xs, 21309.6017989022 );
delta_ok( $ys, 111652.882287157 );

( $ys, $xs ) = $e->scales(80);
delta_ok( $xs, 19393.4855281322 );
delta_ok( $ys, 111659.940414223 );

( $ys, $xs ) = $e->scales(81);
delta_ok( $xs, 17471.3472495414 );
delta_ok( $ys, 111666.35318757 );

( $ys, $xs ) = $e->scales(82);
delta_ok( $xs, 15543.7829971289 );
delta_ok( $ys, 111672.112607742 );

( $ys, $xs ) = $e->scales(83);
delta_ok( $xs, 13611.3907458309 );
delta_ok( $ys, 111677.211488361 );

( $ys, $xs ) = $e->scales(84);
delta_ok( $xs, 11674.7701994437 );
delta_ok( $ys, 111681.64346572 );

( $ys, $xs ) = $e->scales(85);
delta_ok( $xs, 9734.52257729095 );
delta_ok( $ys, 111685.403007281 );

( $ys, $xs ) = $e->scales(86);
delta_ok( $xs, 7791.25039978636 );
delta_ok( $ys, 111688.485419075 );

( $ys, $xs ) = $e->scales(87);
delta_ok( $xs, 5845.55727304685 );
delta_ok( $ys, 111690.886851982 );

( $ys, $xs ) = $e->scales(88);
delta_ok( $xs, 3898.04767271025 );
delta_ok( $ys, 111692.604306881 );

( $ys, $xs ) = $e->scales(89);
delta_ok( $xs, 1949.32672711493 );
delta_ok( $ys, 111693.635638667 );

