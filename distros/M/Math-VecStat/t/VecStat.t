
print "1..40\n";

$main::testct = 1;

use Math::VecStat qw(min max ordered allequal
	minabs maxabs
	sumbyelement diffbyelement
	convolute vecprod
	average median
);
# require 'VecStat.pm';

# function t moved here to stop complaints
# thanks to Andreas Marcel Riechert <riechert@pobox.com>

sub t()
{
	printf "%sok %d\n", ($main::ok?'':'not '), $main::testct++;
}

##################################
# min (1-5)
##################################

# basic test
$main::ok = (Math::VecStat::min( 1, 2, 3 ) == 1 );
t();

# negative values
$main::ok = (Math::VecStat::min( 1, 2, -3 ) == -3 );
t();

# empty arg list
$main::ok = not defined(Math::VecStat::min());
t();

# empty array
$main::ok = not defined(Math::VecStat::min([]));
t();

# floats
$main::ok = (abs(Math::VecStat::min( 1.1, 0.5, 3.2 ) - 0.5) < 1e-6 );
t();

##################################
# max (6-10)
##################################

# basic test
$main::ok = (Math::VecStat::max( 1, 2, 3 ) == 3 );
t();

# negative values
$main::ok = (Math::VecStat::max( 1, 2, -3 ) == 2 );
t();

# empty arg list
$main::ok = not defined(Math::VecStat::max());
t();

# empty array
$main::ok = not defined(Math::VecStat::max([]));
t();

# floats
$main::ok = (abs(Math::VecStat::max( 1.1, 0.5, 3.2 ) - 3.2) < 1e-6 );
t();

##################################
# ordered (11-15)
##################################

# basic test
$main::ok = ordered(1,2,3);
t();

$main::ok = ordered(1,1,1);
t();

$main::ok = not ordered(1,2,0);
t();

$main::ok = ordered( -3.1, -1.9, 0 );
t();

$main::ok = not ordered( -3.1, -1.9, -5.0 );
t();

##################################
# allequal (16-20)
##################################

$main::ok = allequal( [1,2,3,4,5], [1,2,3,4,5] );
t();

$main::ok = allequal( [], [] );
t();

$main::ok = not allequal( [1,2,3,4,5], [1,2,3,4,6] );
t();

$main::ok = not allequal( [7,2,3,4], [1,2,3,4] );
t();

$main::ok = not allequal( [1,2,3], [1,2,3,4] );
t();

##################################
# {sum,diff}byelement (21-25)
##################################

$main::ok = allequal( sumbyelement( [10,20,30], [1,2,3] ), [11,22,33] );
t();

$main::ok = allequal( diffbyelement( [10,20,30], [1,2,3] ), [9,18,27] );
t();

$main::ok = allequal( sumbyelement( [], [] ), [] );
t();

$main::ok = (maxabs( diffbyelement( [1.03,1.97,3.01],[1,2,3] ) ) < 0.1 );
t();

$main::ok = (minabs( diffbyelement( [1.03,1.97,3.01],[1,2,3] ) ) > 1e-3 );
t();

##################################
# convolute (26-30)
##################################

$main::ok = allequal( convolute( [1,2,3], [-1,2,1] ), [-1,4,3]);
t();

# pro domo sua
$main::ok = not allequal( [], [1] );
t();

$main::ok = not allequal( [2], [] );
t();

$main::ok = allequal( convolute( [], [] ), []);
t();

$main::ok = (maxabs( diffbyelement( convolute( [1.1,2.2,3.3], [2.0,3.0,4.0] ),
		[2.2,6.6,13.2] ) ) < 1e-6);
t();

##################################
# average (31-35)
##################################

$main::ok = ( abs( average( 10.1, 4.9, -0.1) - 5.0) < 0.1 );
t();

$main::ok = not defined( average([]) );
t();

$main::ok = ( abs( average( [10.1, 4.9, -0.1] ) - 5.0) < 0.1 );
t();

$main::ok = average( 2.78 ) == 2.78;
t();

$main::ok = average( 0.0 ) == 0.0;
t();

my $a = median( [1,1,2,3,4,3,2,3,4,5] );
$main::ok = ($a->[0] == 3) && ($a->[1] == 3);
t();

$a = median( [1,1,2,4,3,3,2,3,4,5] );
$main::ok = ($a->[0] == 3) && ($a->[1] == 4);
t();

$a = median( [1,3,3,3,5] );
$main::ok = ($a->[0] == 3) && ($a->[1] == 1);
t();

$a = median( [1,2,2,3] );
$main::ok = ($a->[0] == 2) && ($a->[1] == 1);
t();

$a = median( [4,4,4,4] );
$main::ok = ($a->[0] == 4) && ($a->[1] == 0);
t();
