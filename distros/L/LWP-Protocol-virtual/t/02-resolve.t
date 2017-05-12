# vim: ft=perl

use Test::More tests => 1, import => ['!fail'];
use URI;
use URI::virtual;

my $name = "resolve";
my $tstdir = "file://$ENV{PWD}/t";
my $relurl = "02-$name.cfg";
my $tstcfg = "$name $tstdir";

{
	open(my $CFG,">t/02-$name.cfg");
	print { $CFG } $tstcfg, "\n";
	close($CFG);
}
#    print STDERR join("\n", keys %URI::virtual::), "\n";
&URI::virtual::lists("./t/02-$name.cfg");
#    
my $res;
eval {
	$res = new URI("virtual://$name/test")->resolve();
};
ok($res eq "$tstdir/test","resolve");
