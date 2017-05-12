use strict;
use warnings;
use Test::More;
use lib qw(lib ../lib);
use FindBin qw($Bin);
plan(tests => 1);
my $ok = 0;
if(open(TEST, "$^X $Bin/../script/check.pl 2>&1 |")){
	while(my $line = <TEST>){
		print $line;	#so we can see problems if any
		if($line =~ m/Usage/){
			$ok = 1;
		}
	}
	close(TEST);
}
else{
	die("Can't run ./check.pl: $!");
}
#1
ok($ok);