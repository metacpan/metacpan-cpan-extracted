
BEGIN {print "1..5\n";}
END {print "not ok 1\n" unless $loaded;}
use Logfile::Radius;
$loaded = 1;
print "ok 1\n";

$l = new Logfile::Radius(File  => 't/radius.log', 
		                 Group => ["Acct-Session-Id", "User-Name", "Date"]);
print "\nok 2\n";
$l->report(Group => "User-Name", List => [ "Ascend-Data-Rate", 
		                                   "Framed-Protocol",
										   "Acct-Session-Time" ] );
print "\nok 3\n";
$l->report(Group => "User-Name", 
		   Sort => "Date",       List => [ "Ascend-Data-Rate", 
		                                   "Framed-Protocol",
										   "Acct-Session-Time" ] );
print "\nok 4\n";

$l->report(Group => "Acct-Session-Id",     List => [ "User-Name",
													 "NAS-Identifier",
										             "Acct-Session-Time" ] );
print "\nok 5\n";

1;
