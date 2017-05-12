# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

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
	plan( tests => 4);
}

#########################

my $version=ll_version();
1 while $version=~s/\.(\d)\./.0$1./g;
$version=~s/\.(\d)$/.0$1/;
$version=~s/\.//g;
$version=~s/^0(\d+)/$1/;

SKIP:
{
	skip('Only Supported in version 3.3 or higher',4) if $version < 3030000;
	
	# Construct a reservation for 1 node, 1 hour, 1 year from now
	#40 51 11 26 8 109 6 268 1
	# Start Format: [mm/dd[/[cc]yy]] HH:MM
	my $now = time;
	my @date=localtime($now);
	my $start = ($date[4]+1) . "/" . $date[3]. "/" . ($date[5]+1901) . " $date[2]:$date[1]";

	my $resid = ll_make_reservation($start,60,RESERVATION_BY_NODE,1,RESERVATION_SHARED|RESERVATION_BIND_SOFT,undef,undef,"wibble","",undef);
	skip("Unable to create a reservation",4) if ! defined $resid;
	ok(defined $resid,"ll_make_reservation - made $resid");


	my @IDs = ( $resid );
	# Ckeck the time on the reservation using the Data Access API
	my $query = ll_query(RESERVATIONS);

	my $return = ll_set_request($query, QUERY_RESERVATION_ID, \@IDs, ALL_DATA);
	
	my $number=0;
	my $err=0;
	my $reservation = ll_get_objs($query, LL_CM, NULL, $number, $err);
	
	my $res_start    = ll_get_data($reservation,LL_ReservationStartTime);
	ok(defined $res_start,"LL_ReservationStartTime - has value");
	
	# Is the reservation start time retreieved where we expect it to be within a reasonable limit?
	my $difference = $res_start - ($now+(60*60*24*365));
	ok($difference > -120 && $difference < 120,"LL_ReservatimeStartTime - expected value \($difference\)");
	
	# Tidy Up
	ll_free_objs($reservation);
	ll_deallocate($query);

	# Delete The Reservation
	my $rc = ll_remove_reservation( \@IDs,undef,undef,undef,undef);
	ok($rc == RESERVATION_OK,"ll_remove_reservation - deleted $resid");
}
