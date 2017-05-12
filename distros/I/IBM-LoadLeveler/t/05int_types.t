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
	plan( tests => 16);
}

#########################

my $c_number     = 0;
my $c_cpus       = 0;
my $c_cpulist    = "";
my $c_pools      = 0;
my $c_poollist   = "";
my $c_windows    = 0;
my $c_windowlist = "";

ok( open(CTEST,"ct/int_types |"), "C Reference case");
while ( <CTEST> )
{
 	chomp;
 	$c_number     = $1 if (/INT_TYPES:NUMBER=(.*)/);
 	$c_cpus       = $1 if (/INT_TYPES:CPUS=(.*)/);
	$c_cpulist    = $1 if (/INT_TYPES:CPU_LIST=(.*):/);
 	$c_pools      = $1 if (/INT_TYPES:POOLS=(.*)/);
	$c_poollist   = $1 if (/INT_TYPES:POOL_LIST=(.*):/);
	$c_windows    = $1 if (/INT_TYPES:WINDOWS=(.*)/);
	$c_windowlist = $1 if (/INT_TYPES:WINDOW_LIST=(.*):/);
}
close CTEST;


# Make a Query Object
$query = ll_query(MACHINES);
ok(defined $query,"ll_query on MACHINES returned");

# Make a request Object
$return=ll_set_request($query,QUERY_ALL,undef,ALL_DATA);
ok($return == 0,"ll_set_request for QUERY_ALL");

# Make the request
my $p_number=0;
my $err=0;
my $mach=ll_get_objs($query,LL_CM,NULL,$p_number,$err);
ok($p_number > 0,"Get a machine list");
ok($p_number == $c_number, "Compare C with Perl: number of objects\($p_number != $c_number\)");
	
# Extract Pool List
my $p_pools = ll_get_data($mach, LL_MachinePoolListSize);
ok(defined $p_pools,"Get MachinePoolListSize = $p_pools");
ok($p_pools == $c_pools, "Compare C with Perl: machine pool list size \($p_pools != $c_pools\)");

SKIP:
{
	skip( 'Unable to get a machine pool list size', 2) if ! defined $p_pools || $p_pools == 0;

	my @poolList = ll_get_data($mach, LL_MachinePoolList);
	ok($#poolList == $c_pools-1,"Get the machine pool list");
	my $p_poollist=join ":",@poolList;
	ok($c_poollist eq $p_poollist, "Compare C with Perl: Machine Pool list\($c_poollist ne $p_poollist\)");
}

# Find an adapter with more than one window

my $adapter = ll_get_data($mach, LL_MachineGetFirstAdapter);
ok(defined $adapter,"Get the first adapter");
SKIP:
{

	my $p_windows = 0;
	skip('Unable to get an adapter',4) if ! defined $adapter;
	while ( ! defined $adapter && ll_get_data($adapter, LL_AdapterTotalWindowCount) == 0 )
	{
		$adapter = ll_get_data($mach, LL_MachineGetNextAdapter);
		last if ! defined $adapter;
		print STDERR "ADAP = $adapter\n";
	}
	if ( defined $adapter )
	{
		$p_windows = ll_get_data($adapter, LL_AdapterTotalWindowCount);
	}	
	skip('No adapters with windows',4) if ! defined $p_windows || $p_windows == 0;
	ok(defined $p_windows,"Get adapter window count");
	ok($p_windows == $c_windows, "Compare C with Perl: adapter window count \($p_windows != $c_windows\)");

	if ( defined $p_windows )
	{
    		@list = ll_get_data($adapter, LL_AdapterWindowList);
    		ok($#list == $p_windows-1,"Get Adapter Window List");
		my $p_windowlist=join ":",@list;
		ok($c_windowlist eq $p_windowlist, "Compare C with Perl: Adapter Window list\($c_windowlist ne $p_windowlist\)");
	}
}

# Machine CPU list

my @cpus = ll_get_data($mach,LL_MachineCPUList);
ok($c_cpus-1 == $#cpus, "Compare C with Perl: number of cpus\($c_cpus-1 != $#cpus\)");
SKIP:
{
	my $p_cpulist=join ":",@cpus;
	skip( 'Not Supported on Linux',1) if ( $^O eq 'linux');
	ok($c_cpulist eq $p_cpulist, "Compare C with Perl: CPU list\($c_cpulist ne $p_cpulist\)");
}

# Tidy up at the end
ll_free_objs($query);
ll_deallocate($query);
