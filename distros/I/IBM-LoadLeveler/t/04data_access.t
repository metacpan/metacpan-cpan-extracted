# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/02data_access.t'


use Test::More;
use IBM::LoadLeveler;

# Skip all tests if 02query.t failed, no point running tests if you
# cant get a basic query setup.

if ( -f "SKIP_TEST_LOADLEVELER_NOT_RUNNING" )
{
	plan( skip_all => 'failed basic query, check LoadLeveler running ?');
}
else
{
	plan( tests => 18);
}
#########################

my $c_number  = 0;
my $c_cpus    = 0;
my $c_name    = "";
my $c_classes = "";
my $c_time    = 0;
my $c_adapter = "";

ok( open(CTEST,"ct/data_access |"), "C Reference case");
while ( <CTEST> )
{
 	chomp;
 	$c_number  = $1 if (/DATA_ACCESS:NUMBER=(.*)/);
 	$c_cpus    = $1 if (/DATA_ACCESS:CPUS=(.*)/);
	$c_speed   = $1 if (/DATA_ACCESS:SPEED=(.*)/);
	$c_name    = $1 if (/DATA_ACCESS:NAME=(.*)/);
	$c_classes = $1 if (/DATA_ACCESS:CLASSES=(.*):/);
	$c_time    = $1 if (/DATA_ACCESS:TIME=(.*)/);
	$c_adapter = $1 if (/DATA_ACCESS:ADAPTER=(.*)/);
}
 close CTEST;

# Make a Query Object
$query = ll_query(MACHINES);
ok(defined $query,"ll_query returned a query object");

# Make a request Object
$return=ll_set_request($query,QUERY_ALL,undef,ALL_DATA);
ok($return == 0,"ll_set_request defined a query");

# Make the request
$p_number=0;
$err=0;
$machines=ll_get_objs($query,LL_CM,NULL,$p_number,$err);
ok( $p_number > 0, "ll_get_objs should return some objects");
ok( $p_number == $c_number, "Compare C with Perl: number of objects\($p_number != $c_number\)");

SKIP:
{

  skip( 'Query returned no objects, unable to continue this test',7) if ( $p_number == 0);


  # Test Data Types

  my $p_cpus=ll_get_data($machines,LL_MachineCPUs);
  ok(defined $p_cpus,"ll_get_data - LL_INT_STAR data");
  ok($c_cpus == $p_cpus,"ll_get_data - Compare C with Perl LL_INT_STAR \($p_cpus != $c_cpus\)");
  
  $p_speed=ll_get_data($machines,LL_MachineSpeed);
  ok(defined $p_speed,"ll_get_data - LL_DOUBLE_STAR data");
  ok($c_speed == $p_speed,"ll_get_data - LL_DOUBLE_STAR data \($p_speed != $c_speed\)");	

  $p_name=ll_get_data($machines,LL_MachineName);
  ok(defined $p_name,"ll_get_data - LL_CHAR_STAR_STAR data");
  ok($c_name eq $p_name,"ll_get_data - LL_CHAR_STAR_STAR data \( $p_name ne $c_name\)");

  @classes=ll_get_data($machines,LL_MachineConfiguredClassList);
  ok(defined @classes,"ll_get_data - LL_CHAR_STAR_STAR_STAR data");
  my $p_classes = join ":",@classes;
  ok($c_classes eq $p_classes,"ll_get_data - LL_CHAR_STAR_STAR_STAR data \( $p_classes ne $c_classes\)");

  $p_time=ll_get_data($machines,LL_MachineTimeStamp);
  ok($p_time > 0,"ll_get_data - LL_TIME_T_STAR data");
  ok($c_time >= $p_time - 100 || $c_time <= $p_time - 100,"ll_get_data - LL_TIME_T_STAR data \( $p_time != $c_time\)");

  $adap=ll_get_data($machines,LL_MachineGetFirstAdapter);
  ok(defined $adap,"ll_get_data - LL_ELEMENT_STAR data");

#  print STDERR "\n";
#  print STDERR "LL_MachineCPUs                -> $p_cpus\n";
#  print STDERR "LL_MachineSpeed               -> $p_speed\n";
#  print STDERR "LL_MachineName                -> $p_name\n";
#  print STDERR "LL_MachineConfiguredClassList -> ",join(":",@classes),"\n";
#  print STDERR "LL_MachineTimeStamp           -> ", scalar localtime $p_time, "\n";
#  print STDERR "LL_MachineGetFirstAdapter     -> $adap\n";

  skip( 'No Adapters returned',2) if ( ! defined $adap || $adap == 0);

   # This looks like another string data type test, in fact the point is
   # to test that we have correctly picked up the Adapter
   
  $p_adapter=ll_get_data($adap,LL_AdapterName);
  ok(defined $p_adapter,"ll_get_data - LL_CHAR_STAR_STAR (2) data");
  ok($c_adapter eq $p_adapter,"ll_get_data - LL_CHAR_STAR_STAR_STAR data \( $p_adapter ne $c_adapter\)");

#  print STDERR "LL_AdapterName               -> $p_adapter\n";

}


# Tidy up at the end
ll_free_objs($query);
ll_deallocate($query);
