BEGIN {print "1..9\n";}
END {print "not ok 1\n" unless $loaded;}
use Logfile::NCSA;
$loaded = 1;
print "ok 1\n";

$l = new Logfile::NCSA  File  => 't/apache-ncsa.log', 
                        Group => [qw(Host Domain File Hour Date)];
print "\nok 2\n";

$l->report(Group => File, Sort => Records, Top => 10);
print "\nok 3\n";
$l->report(Group => Domain, Sort => Bytes);
print "\nok 4\n";
$l->report(Group => Hour);
print "\nok 5\n";
$l->report(Group => Date);
print "\nok 6\n";
$l->report(Group => Domain, List => [Hour, Records]);
print "\nok 7\n";
$l->report(Group => Hour, List => [Bytes, Records], Sort => Hour, Top => 2);
print "\nok 8\n";
$l->report(Group => Hour, List => [Bytes, Records], Sort => Hour, Top => 2, Reverse => 1);
print "\nok 9\n";

1;
