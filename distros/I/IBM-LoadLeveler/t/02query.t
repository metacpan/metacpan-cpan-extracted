# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/02data_access.t'


use Test::More tests => 3;
use IBM::LoadLeveler;

#########################

$NotRunning="SKIP_TEST_LOADLEVELER_NOT_RUNNING";

#$ResultFile="/tmp/LoadLeveler-test.res";

unlink $NotRunning if ( -f $NotRunning );

my $Failed=0;

# Make a Query Object
$query = ll_query(MACHINES);
ok(defined $query,"ll_query returned a query object");

$Failed=1 if ( ! defined $query );

# Make a request Object
$return=ll_set_request($query,QUERY_ALL,undef,ALL_DATA);
ok($return == 0,"ll_set_request defined a query");

$Failed=1 if ($return < 0);

# Make the request
my $number=0;
my $err=0;
my $machines=ll_get_objs($query,LL_CM,NULL,$number,$err);
ok( $number > 0, "ll_get_objs should return some objects");

$Failed=1 if ($number < 1);

# If any of the previous tests failed then something is really
# wrong. Like LoadLeveler not running."

if ( $Failed )
{
	open(FILE,"> $NotRunning");
	close(FILE);
}

# Tidy up at the end
ll_free_objs($query);
ll_deallocate($query);

#unlink $ResultFile if -f $ResultFile;
