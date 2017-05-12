# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

BEGIN { $| = 1; }
END {
    unless ( $loaded ) {
        print "not ok 1\n";
        exit;
    }
}

use Math::NumberCruncher;
use Math::BigFloat;
$tests = 99;
print ("Testing Math::NumberCruncher v$Math::NumberCruncher::VERSION\n\n");

print <<END;
##########################################
#               IMPORTANT                #
##########################################
Significant improvements have been made to 
Math::NumberCruncher starting with v5.00.
Every attempt was made to maintain backward
compatibility, but in some cases, this wasn't
possible. Be certain to test scripts written
using versions < 5.00 very thoroughly.

(sleeping 3 seconds)
END
sleep(3);

$loaded = 1;
$count  = 1;
Testing();

sub Testing {
    if ( length ( $count ) < 2 ) { $count = " " . $count }
    my $mess = "Testing......$count/$tests";
    print "\r$mess" . ( " " x ( 75 - length $mess ) );
    $count++;
}

@array1 = ( 1 .. 300 );
@array2 = ( 50 .. 350 );

$ref = Math::NumberCruncher->new();
for ( 1 .. 300 ) {
    push ( @array3, $ref->RandInt( 1, 100 ) );
}

# Range()
( $high, $low ) = $ref->Range( \@array1 );
if ( $high != 300 || $low != 1 ) {
    $Failed{2} = "Range()";
}
Testing();

# Mean()
if ( $ref->Mean( \@array1 ) != 150.5 ) {
    $Failed{3} = "Mean()";
}
Testing();

# Median()
if ( $ref->Median( \@array2 ) != 200 ) {
    $Failed{4} = "Median()";
}
Testing();

# OddMedian()
if ( $ref->OddMedian( \@array2 ) != 200 ) {
    $Failed{5} = "OddMedian()";
}
Testing();

# Mode()
if ( $ref->Mode( \@array1 ) != 151 ) {
    $Failed{6} = "Mode()";
}
Testing();

# Covariance()
if ( $ref->Covariance( \@array1, \@array2 ) !~ /^7424.66666666666/ ) {
    $Failed{7} = "Covariance()";
}
Testing();

# Correlation()
if ( abs( $ref->Correlation( \@array1, \@array3 ) ) > 0.2 ) {
    $Failed{8} = "Correlation()";
}
Testing();

# BestFit()
( $slope, $y_intercept ) = $ref->BestFit( \@array1, \@array2 );
if ( $slope !~ /^0.976588628762541/ || $y_intercept !~ /^53.6900780379041/ ) {
    $Failed{9} = "BestFit()";
}
Testing();

# Distance()
$dist = $ref->Distance( 1, 2, 3, 8, 9, 10 );
if ( $dist !~ /^12.12435565298214105469/ ) {
    $Failed{10} = "Distance()";
}
Testing();

# ManhattanDistance()
if ( $ref->ManhattanDistance( 1, 3, 11, 24 ) != 31 ) {
    $Failed{11} = "ManhattanDistance()";
}
Testing();

# AllOf()
if ( $ref->AllOf( 0.3, 0.25, 0.91, 0.002 ) != 0.0001365 ) {
    $Failed{12} = "AllOf()";
}
Testing();

# NoneOf()
if ( $ref->NoneOf( 0.64, 0.52, 0.5 ) ne "0.0864" ) {
    $Failed{13} = "NoneOf()";
}
Testing();

# SomeOf()
if ( $ref->SomeOf( 0.64, 0.52, 0.5 ) != 0.9136 ) {
    $Failed{14} = "SomeOf()";
}
Testing();

# Factorial()
if ( $ref->Factorial( 10 ) != 3628800 ) {
    $Failed{15} = "Factorial()";
}
Testing();

# Permutation()
if ( $ref->Permutation( 9 ) != 362880 ) {
    $Failed{16} = "Permutation()";
}
Testing();

# Dice()
$num = $ref->Dice( 4, 12, 5 );
unless ( $num >= 9 && $num <= 53 ) {
    $Failed{17} = "Dice()";
}
Testing();

# RandInt()
$num = $ref->RandInt( 10, 50 );
unless ( $num >= 10 && $num <= 50 ) {
    $Failed{18} = "RandInt()";
}
Testing();

# RandomElement()
$item = $ref->RandomElement( \@array2 );
$found = 0;
foreach $num ( @array2 ) {
    if ( $num == $item ) {
        $found = 1;
        last;
    }
}
unless ( $found ) {
    $Failed{19} = "RandomElement()";
}
Testing();

# ShuffleArray()
@temp = @array1;
$ref->ShuffleArray( \@temp );
@temp2 = sort { $a <=> $b } @temp;
$ok1 = 1;
$ok2 = 0;
for ( $i = 0; $i <= $#array1; $i++ ) {
    if ( $temp2[$i] != $array1[$i] ) {
        $ok1--;
    }
    if ( $temp[$i] != $array1[$i] ) {
        $ok2++;
    }
}
unless ( $ok1 && $ok2 ) {
    $Failed{20} = "ShuffleArray()";
}
Testing();

# Unique
@temp = ( 1, 1, 1, 3, 5, 7, 7, 9 );
@unique = $ref->Unique( \@temp );
unless ( $unique[0] == 1 && $unique[1] == 3 && $unique[2] == 5 && $unique[3] == 7 && $unique[4] == 9 ) {
    $Failed{21} = "Unique()";
}
Testing();

# Compare
@a = ( 1, 2, 3, 4, 5 );
@b = ( 3, 5, 7, 9, 11 );
@aonly = $ref->Compare( \@a, \@b );
unless ( $aonly[0] == 1 && $aonly[1] == 2 && $aonly[2] == 4 ) {
    $Failed{22} = "Compare()";
}
Testing();

# Union
@a = ( 1, 1, 1, 2, 3 );
@b = ( 2, 3, 4 );
@union = $ref->Union( \@a, \@b );
unless ( $union[0] == 1 && $union[1] == 2 && $union[2] == 3 && $union[3] == 4 ) {
    $Failed{23} = "Union()";
}
Testing();

# Inersection()
@temp = $ref->Intersection( \@a, \@b );
unless ( $temp[0] == 2 && $temp[1] == 3 ) {
    $Failed{24} = "Intersection()";
}
Testing();

# Difference()
@a = ( 1, 2, 3, 4 );
@b = ( 3, 4, 5, 6 );
@diff = $ref->Difference( \@a, \@b );
unless ( $diff[0] == 1 && $diff[1] == 2 && $diff[2] == 5 && $diff[3] == 6 ) {
    $Failed{25} = "Difference()";
}
Testing();

# GaussianRand()
$num = $ref->GaussianRand();
unless ( defined $num ) {
    $Failed{26} = "GaussianRand()";
}
Testing();

# Choose()
if ( $ref->Choose( 5, 2 ) != 10 ) {
    $Failed{27} = "Choose()";
}
Testing();

# Binomial()
if ( $ref->Binomial( '100','45','0.5' ) !~ /^0.0484742966264307/ ) {
    $Failed{28} = "Binomial()";
}
Testing();

# GaussianDist()
if ( $ref->GaussianDist( 5, 3.5, 0.5 ) !~ /^0.05946514461181475289/ ) {
    $Failed{29} = "GaussianDist()";
}
Testing();

# StandardDeviation()
$sd = $ref->StandardDeviation( \@array2 );
if ( $sd !~ /^86.89073598491383477159/ ) {
    $Failed{30} = "StandardDeviation()";
}
Testing();

# Variance()
$error = Math::BigFloat->new( 0.000000001 );
@a = ( 5, 5, 7, 8, 8, 8, 8, 8, 9, 10 );
$variance = $ref->Variance( \@a );
$diff = Math::BigFloat->new( $variance - 2.2400000000000099999999999999999999 );
$diff->babs();
if ( $diff->bcmp( $error ) > 0 ) {
    $Failed{31} = "Variance()";
}
Testing();

# StandardScores()
@a = ( 3, 4, 4, 5 );
@temp = $ref->StandardScores( \@a );
if ( $temp[0] !~ /^-1.41421356237309504880/ ||
     $temp[1] ne "0" ||
     $temp[2] ne "0" ||
     $temp[3] !~ /^1.41421356237309504880/ ) {
         $Failed{32} = "StandardScores()";
}
Testing();

# SignSignificance()
if ( $ref->SignSignificance( 100, 33, 0.3333 ) !~ /^5.73830638060931/ ) {
    $Failed{33} = "SignSignificance()";
}
Testing();

# EMC2()
$emc = $ref->EMC2( "m0.01", "m" );
if ( $emc !~ /^347010043.87587136/ ) {
    print ("\nEMC2(): $emc\n");
    $Failed{34} = "EMC2()";
}
Testing();

# FMA()
if ( $ref->FMA( "m97", "a53" ) != 5141 ) {
    $Failed{35} = "FMA()";
}
Testing();

# Predict()
if ( $ref->Predict( 1, 3, 5 ) != 8 ) {
    $Failed{36} = "Predict()";
}
Testing();

# TriangleHeron
if ( $ref->TriangleHeron( 5, 5, 5 ) !~ /^10.82531754730548308455/ ) {
    $Failed{37} = "TriangleHeron()";
}
Testing();

# PolygonPerimeter()
$pp = $ref->PolygonPerimeter( 1, 1, 5, 5, 7, 3, 8, 0 );
if ( $pp !~ /^18.71862684627242486882/ ) {
    $Failed{38} = "PolygonPerimeter()";
}
Testing();

# Clockwise()
if ( $ref->Clockwise( 1, 1, 3, 3, 5, 3, ) < 1 ) {
    $Failed{39} = "Clockwise()";
}
Testing();

# InPolygon()
@xy = ( 1, 1, 1, 10, 10, 10, 10, 1 );
if ( $ref->InPolygon( 3, 3, @xy ) != 1 ) {
    $Failed{40} = "InPolygon()";
}
Testing();

# BoundingBox()
@points = $ref->BoundingBox( 2, @xy );
if ( $points[0] != 1 || $points[1] != 1 || $points[2] != 10 || $points[3] != 10 ) {
    $Failed{41} = "BoundingBox()";
}
Testing();

# InTriangle()
if ( $ref->InTriangle( 1, 1, 5, 1, 10, 10, 11, 5 ) ) {
    $Failed{42} = "InTriangle()";
}
Testing();

# PolygonArea()
if ( $ref->PolygonArea( 0, 1, 1, 0, 3, 2, 2, 3, 0, 2 ) != 5 ) {
    $Failed{43} = "PolygonArea()";
}
Testing();

# CircleArea()
$area = $ref->CircleArea( 5 );
if ( $area !~ /^78.53981633974483096157/ ) {
    print ("\nArea: $area\n");
    $Failed{44} = "CircleArea()";
}
Testing();

# Circumference()
$circ = $ref->Circumference( 5 );
if ( $circ !~ /^15.70796326794896619231/ ) {
    print ("\nCircumference: $circ\n");
    $Failed{45} = "Circumference()";
}
Testing();

# SphereVolume()
$vol = $ref->SphereVolume( 3 );
if ( $vol !~ /^113.09733552923227384132/ ) {
    print ("\nSphereVolume: $vol\n");
    $Failed{46} = "SphereVolume()";
}
Testing();

# SphereSurface()
$surf = $ref->SphereSurface( 3 );
if ( $surf !~ /^113.09733552923255658466/ ) {
    print ("\nSphereSurface: $surf\n");
    $Failed{47} = "SphereSurface()";
}
Testing();

# RuleOf72()
my $rule = $ref->RuleOf72( 7 );
if ( $rule !~ /^10.28571428571428571429/ ) {
    print ("\nRuleOf72: $rule\n");
    $Failed{48} = "RuleOf72()";
}
Testing();

# CylinderVolume()
$vol = $ref->CylinderVolume( 3, 5 );
if ( $vol !~ /^141.37166941154069573082/ ) {
    print ("\nCylinderVolume: $vol\n");
    $Failed{49} = "CylinderVolume()";
}
Testing();

# ConeVolume()
$vol = $ref->ConeVolume( 4, 11 );
if ( $vol !~ /^14.6666666666/ ) {
    print ("\nConeVolume: $vol\n");
    $Failed{50} = "ConeVolume()";
}
Testing();

# deg2rad()
my $conv = $ref->deg2rad( 5 );
if ( $conv !~ /^0.0872664625997/ ) {
    print ("\ndeg2rad: $conv\n");
    $Failed{51} = "deg2rad()";
}
Testing();

# rad2deg()
$conv = $ref->rad2deg( 5 );
if ( $conv !~ /^286.47889756541160438399/ ) {
    print ("\nrad2deg: $conv\n");
    $Failed{52} = "rad2deg()";
}
Testing();

# C2F()
if ( $ref->C2F( 55 ) != 131 ) {
    $Failed{53} = "C2F()";
}
Testing();

# F2C()
if ( $ref->F2C( 88 ) !~ /^31.11111111/ ) {
    $Failed{54} = "F2C()";
}
Testing();

# in2cm()
if ( $ref->in2cm( 15 ) != 38.1 ) {
    $Failed{55} = "in2cm()";
}
Testing();

# cm2in()
if ( $ref->cm2in( 30 ) !~ /^11.811023622/ ) {
    $Failed{56} = "cm2in()";
}
Testing();

# m2ft()
if ( $ref->m2ft( 30 ) != 98.42519685 ) {
    $Failed{57} = "m2ft()";
}
Testing();

# ft2m()
if ( $ref->ft2m( 15 ) != 4.572 ) {
    $Failed{58} = "ft2m()";
}
Testing();

# lb2kg()
if ( $ref->lb2kg( 55 ) != 24.94758035 ) {
    $Failed{59} = "lb2kg()";
}
Testing();

# kg2lb()
if ( $ref->kg2lb( 30 ) != 66.13867866 ) {
    $Failed{60} = "kg2lb()";
}
Testing();

# RelativeStride()
if ( $ref->RelativeStride( 7, 4 ) != 1.75 ) {
    $Failed{61} = "RelativeStride()";
}
Testing();

# RelativeStride_2()
if ( $ref->RelativeStride_2( 0.681818181818181 ) !~ /^1.749999999999/ ) {
    $Failed{62} = "RelativeStride_2()";
}
Testing();

# DimensionlessSpeed()
if ( $ref->DimensionlessSpeed( 1.75 ) !~ /^0.681818181818181/ ) {
    $Failed{63} = "DimensionlessSpeed()";
}
Testing();

# DimensionlessSpeed_2()
if ( $ref->DimensionlessSpeed_2( 0.1, 4 ) !~ /^0.015966497839052/ ) {
    $Failed{64} = "DimensionlessSpeed_2()";
}
Testing();

# ActualSpeed()
if ( $ref->ActualSpeed( 4, 0.681818181818181 ) !~ /^4.2703051645458622507/ ) {
    $Failed{65} = "ActualSpeed()";
}
Testing();

# Eccentricity()
$ecc = $ref->Eccentricity( 4, 6 );
if ( $ecc !~ /^1.11803398874989484/ ) {
    print ("\nEccentricity: $ecc\n");
    $Failed{66} = "Eccentricity()";
}
Testing();

# LatusRectum()
if ( $ref->LatusRectum( 4, 5 ) != 12.5 ) {
    $Failed{67} = "LatusRectum()";
}
Testing();

# EllipseArea()
my $area = $ref->EllipseArea( 4, 5 );
if ( $area !~ /^62.83185307179586476925/ ) {
    print ("\nEllipseArea: $area\n");
    $Failed{68} = "EllipseArea()";
}
Testing();

# OrbitalVelocity()
$ov = $ref->OrbitalVelocity( 37000, 978990, 129999999999999 );
if ( $ov !~ /^0.00000067809533454393/ ) {
    print ("\nOrvitalVelocity(): $ov\n");
    $Failed{69} = "OrbitalVelocity()";
}
Testing();

# SqrRoot()
if ( $ref->SqrRoot( 111 ) !~ /^10.53565375285273884840/ ) {
    $Failed{70} = "SqrRoot()";
}
Testing();

# asin()
if ( $ref->asin( 0.15 ) !~ /^0.150568272776686/ ) {
    $Failed{71} = "asin()";
}
Testing();

# acos()
if ( $ref->acos( 0.15 ) !~ /^1.42022805401821/ ) {
    $Failed{72} = "acos()";
}
Testing();

# atan()
my $atan = $ref->atan( 0.15 );
if ( $atan !~ /^0.14888994760949725059/ ) {
    print ("\natan: $atan\n");
    $Failed{73} = "atan()";
}
Testing();

# acot()
if ( $ref->acot( 0.15 ) !~ /^1.42190637918539936864/ ) {
    $Failed{74} = "acot()";
}
Testing();

# asec()
my $asec = $ref->asec( 2.1 );
if ( $asec !~ /^1.07447896466943/ ) {
    print ("\nasec: $asec\n");
    $Failed{75} = "asec()";
}
Testing();

# sec()
if ( $ref->sec( 0.15 ) !~ /^1.01135644267366/ ) {
    $Failed{76} = "sec()";
}
Testing();

# csc()
my $csc = $ref->csc( 0.15 );
if ( $csc !~ /^6.6917324477182/ ) {
    print ("\ncsc(): $csc\n");
    $Failed{77} = "csc()";
}
Testing();

# exsec()
my $exsec = $ref->exsec( 0.15 );
if ( $exsec !~ /^0.011356442673664/ ) {
    print ("\nexsec(): $exsec\n");
    $Failed{78} = "exsec()";
}
Testing();

# tan()
my $tan = $ref->tan( 30 );
if ( $tan !~ /^-6.40533119664627/ ) {
    print ("\ntan(): $tan\n");
    $Failed{79} = "tan()";
}
Testing();

# cot()
if ( $ref->cot( 30 ) !~ /^-0.156119952161659/ ) {
    $Failed{80} = "cot()";
}
Testing();

# vers()
$vers = $ref->vers( 30 );
if ( $vers !~ /^0.845748550112415/ ) {
    print ("\nvers(): $vers\n");
    $Failed{81} = "vers()";
}
Testing();

# covers()
$covers = $ref->covers( 30 );
if ( $covers !~ /^1.98803162409286/ ) {
    print ("\ncovers: $covers\n");
    $Failed{82} = "covers()";
}
Testing();

# hav()
$hav = $ref->hav( 5 );
if ( $hav !~ /^0.358168907268386867/ ) {
    print ("\nhav(): $hav\n");
    $Failed{83} = "hav()";
}
Testing();

# Commas()
if ( $ref->Commas( 1000000 ) ne "1,000,000" ) {
    $Failed{84} = "Commas()";
}
Testing();

# Root()
if ( $ref->Root( 55, 3 ) !~ /^3.80295246076139161855/ ) {
    $Failed{85} = "Root()";
}
Testing();

# Root2()
if ( $ref->Root2( 10000, 20, 25 ) !~ /^1.58489319246111/ ) {
    $Failed{86} = "Root2()";
}
Testing();

# Ln()
my $ln = $ref->Ln( 100 );
if ( $ln ne "4.60517018598809136804" ) {
    $Failed{87} = "Ln()";
}
Testing();

# Exp()
my $exp = $ref->Exp( 1.11111, 25 );
if ( $exp ne "3.0377284022618271502307371" ) {
    $Failed{88} = "Exp()";
}
Testing();

# PythagTriples()
( $a, $b, $c ) = $ref->PythagTriples( 5, 7 );
unless ( $a == 24 && $b == 70 && $c == 74 ) {
    $Failed{89} = "PythagTriples()";
}
Testing();

# PythagTriplesSeq()
if ( $ref->PythagTriplesSeq( 25, 53 ) !~ /^58.60034129593444611886/ ) {
    $Failed{90} = "PythagTriplesSeq()";
}
Testing();

# acsc ()
my $acsc = $ref->acsc( 5 );
if ( $acsc !~ /^0.20135792079033/ ) {
    print ("\nacsc: $acsc\n");
    $Failed{91} = "acsc()";
}
Testing();

# SIS()
@nums = $ref->SIS( 1, 5 );
unless ( $nums[0] == 1 && $nums[1] == 3 && $nums[2] == 5 && $nums[3] == 10
         && $nums[4] == 20 ) {
    $Failed{92} = "SIS()";
}
Testing();

# sin()
$sin = $ref->sin( 15 );
if ( $sin !~ /^0.65028784015711686580/ ) {
    print ("\nsin(): $sin\n");
    $Failed{93} = "sin()";
}
Testing();

# cos()
$cos = $ref->cos( 15 );
if ( $cos !~ /^-0.75968791285882127378/ ) {
    print ("\ncos: $cos\n");
    $Failed{94} = "cos()";
}
Testing();

# Inverse()
$inv = $ref->Inverse( 25 );
if ( $inv !~ /^0.04000000000000000000/ ) {
    print ("\nInverse(): $inv\n");
    $Failed{95} = "Inverse()";
}
Testing();

# km2miles()
$conv = $ref->km2miles( 10 );
if ( $conv !~ /^6.21371192200000000000/ ) {
    print ("\nkm2miles(): $conv\n");
    $Failed{96} = "km2miles()";
}
Testing();

# miles2km()
$conv = $ref->miles2km( 10 );
if ( $conv !~ /^16.09344000096690000000/ ) {
    print ("\nmiles2km(): $conv\n");
    $Failed{97} = "miles2km()";
}
Testing();

# CONSTANT()
$apery = $ref->CONSTANT( '_apery_', 15 );
if ( $apery !~ /^1.20205690315/ ) {
    print ("\nCONSTANT( '_apery_' ): $apery\n");
    $Failed{98} = "CONSTANT()";
}
Testing();

# Bernoulli()
( $x, $y ) = $ref->Bernoulli( 2 );
unless ( $x == 1 and $y == 6 ) {
    print ("\nBernoulli( 2 ): $x, $y\n");
    $Failed{99} = "Bernoulli()";
}
Testing();

print ("\n");

@failed = sort { $a <=> $b } keys %Failed;
$failed = @failed;
$per = sprintf( "%.2f", $failed / $tests * 100 );
$per = 100 - $per;
print <<END;
Total Tests:  $tests
Failed Tests: $failed
Success Rate: $per\%
END
if ( $failed ) {
    print ("The following tests encountered errors:\n");
    foreach $fail ( @failed ) {
        $num = $fail;
        if ( length ( $fail ) < 2 ) { $fail = " " . $fail }
        print ("\tTest $fail:\t$Failed{$num}\n");
    }
}
