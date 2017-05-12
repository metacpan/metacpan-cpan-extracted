use Test::More;
use vars qw($TESTS);

BEGIN { 
	$TESTS = 13;
	eval { require Data::Dumper };
	if ($@) {
		plan skip_all => "skipping (Data::Dumper Missing)";
	}
	plan tests => $TESTS;
}

use File::Temp "tempfile";
use Devel::StealthDebug DUMPER=>1, emit_type => 'print';

close STDOUT;
my ($fh1,$fn1)= tempfile() or die $!;
my ($fh2,$fn1)= tempfile() or die $!;
open (STDOUT, "> $fn1") or die $!;

my %var;
$var{scalar}=3;
$var{array}=['','b',3];
$var{hash}={a=>'b',b=>'c',c=>'d'};

my $donothing='whatever'; #!dump(\%var)!;
close STDOUT;

open(TMP, "> $fn2");
print TMP Data::Dumper::Dumper(\%var);
close TMP;

open (TMP,"< $fn2");
open (STDIN,"< $fn1");
my ($out,$check);
for(1..$TESTS) {
	$out	=<STDIN>;
	$check	=quotemeta(<TMP>);
	like($out , qr/$check/);
}
close TMP;
close STDIN;
