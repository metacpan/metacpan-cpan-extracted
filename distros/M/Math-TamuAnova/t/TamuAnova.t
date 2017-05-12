# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl TamuAnova.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use Test::More tests => 8;
BEGIN { use_ok('Math::TamuAnova') };


my $fail = 0;
foreach my $constname (qw(
	anova_fixed anova_mixed anova_random)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined Math::TamuAnova macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }

}

ok( $fail == 0 , 'Constants' );
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Test::Deep;

$res=Math::TamuAnova::anova( [88.60,73.20,91.40,68.00,75.20,63.00,53.90,
69.20,50.10,71.50,44.90,59.50,40.20,56.30,
38.70,31.00,39.60,45.30,25.20,22.70],
[1,1,1,1,1,2,2,2,2,2,3,3,3,3,3,4,4,4,4,4],
4);


cmp_deeply($res , {
"dfTr" => num(3,0.000001),
"SSTr" => num(5882.3575,0.000001),
"MSTr" => num(1960.785833,0.000001),
 "dfE" => num(16,0.000001),
 "SSE" => num(1487.4,0.000001),
 "MSE" => num(92.9625,0.000001),
 "dfT" => num(19,0.000001),
 "SST" => num(7369.7575,0.000001),
   "F" => num(21.09222356326,0.000001),
   "p" => num(.000008324882,0.000001),
}, 'Balanced oneway ANOVA test with data from Devore');

$res=Math::TamuAnova::anova( 
[45.50,45.30,45.40,44.40,44.60,43.90,44.60,44.00,44.20,43.90,44.70,
44.20,44.00,43.80,44.60,43.10,46.00,45.90,44.80,46.20,45.10,45.50],
[1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,3,3,3,3,3,3],
3);

cmp_deeply($res , {
"dfTr" => num(2,0.000001),
"SSTr" => num(7.93007576,0.000001),
"MSTr" => num(3.96503788,0.000001),
 "dfE" => num(19,0.000001),
 "SSE" => num(5.99583333,0.000001),
 "MSE" => num(0.31557018,0.000001),
 "dfT" => num(21,0.000001),
 "SST" => num(13.92590909,0.000001),
   "F" => num(12.564678576,0.000001),
   "p" => num(0.0003336161,0.000001),
 }, 'Unbalanced oneway ANOVA test with data from Devore');

Math::TamuAnova::printtable( $res ); 
pass('printtable');

$res=Math::TamuAnova::anova_twoway(
[6,10,11,13,15,14,22,12,15,19,18,31,18,9,12],
[1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2],
[1, 1, 1, 2, 2, 3, 3, 1, 1, 1, 1, 2, 3, 3, 3],
2,3,
&Math::TamuAnova::anova_fixed);

cmp_deeply($res , {
 "SSA" => num(123.0+27.0/35.0,0.000001),
 "dfA" => num(1,0.000001),
 "MSA" => num(123.0+27.0/35.0,0.000001),
  "FA" => num(9.282857,0.000001),
  "pA" => num(0.01386499,0.000001),
 "SSB" => num(192.1276596,0.000001),
 "dfB" => num(2,0.000001),
 "MSB" => num(96.0638298,0.000001),
  "FB" => num(7.204787,0.000001),
  "pB" => num(0.01354629,0.000001),
"SSAB" => num(222.7659574,0.000001),
"dfAB" => num(2,0.000001),
"MSAB" => num(111.3829787,0.000001),
 "FAB" => num(8.353723,0.000001),
 "pAB" => num(0.00888845,0.000001),
 "SSE" => num(120.0,0.000001),
 "dfE" => num(9,0.000001),
 "MSE" => num(120.0/9.0,0.000001),
 "SST" => num(520.0,0.000001),
 "dfT" => num(14,0.000001),
}, 'Unbalanced twoway fixed ANOVA test with data from Searle');

$res=Math::TamuAnova::anova_twoway(
[10.5, 9.2,  7.9,  8.1,  8.6,  10.1, 16.1, 15.3, 17.5,
12.8, 11.2, 13.3, 12.7, 13.7, 11.5, 16.6, 19.2, 18.5,
12.1, 12.6, 14.0, 14.4, 15.4, 13.7, 20.8, 18.0, 21.0,
10.8, 9.1 , 12.5, 11.3, 12.5, 14.5, 18.4, 18.9, 17.2],
[
1,1,1,2,2,2,3,3,3,
1,1,1,2,2,2,3,3,3,
1,1,1,2,2,2,3,3,3,
1,1,1,2,2,2,3,3,3],
[
1,1,1,1,1,1,1,1,1,
2,2,2,2,2,2,2,2,2,
3,3,3,3,3,3,3,3,3,
4,4,4,4,4,4,4,4,4,
],
3, 4,
&Math::TamuAnova::anova_fixed);

cmp_deeply($res, {
 "SSA" => num(327.5972222,0.000001),
 "dfA" => num(2,0.000001),
 "MSA" => num(163.798611,0.000001),
  "FA" => num(103.3430,0.0001),
  "pA" => num(0 ,0.000001),
 "SSB" => num(86.6866667,0.000001),
 "dfB" => num(3,0.000001),
 "MSB" => num(28.8955556,0.000001),
  "FB" => num(18.23063,0.00001),
  "pB" => num(0.000002212 ,0.000001),
"SSAB" => num(8.031667,0.000001),
"dfAB" => num(6,0.000001),
"MSAB" => num(1.3386111,0.000001),
 "FAB" => num(0.8445496 ,0.000001),
 "pAB" => num(0.5483607 ,0.000001),
 "SSE" => num(38.04,0.000001),
 "dfE" => num(24,0.000001),
 "MSE" => num(1.585,0.000001),
 "SST" => num(460.3555556,0.000001),
 "dfT" => num(35,0.000001),
}, 'Balanced twoway fixed ANOVA test with data from Devore');


Math::TamuAnova::printtable_twoway( $res ); 
pass('printtable_twoway');

