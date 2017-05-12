## An example of speed considerations

use lib '../blib/lib','../blib/arch';
use Benchmark qw (:all);
use Math::FixedPrecision;
use Finance::Performance::Calc qw (:all);
my $bmv = 20_000;
my $emv = 21_567.8901;
my $bmvobj = Math::FixedPrecision->new($bmv,4);
my $emvobj = Math::FixedPrecision->new($emv,4);
my $count = 10000;

sub ROR_native {
    ROR(bmv => $bmv, emv => $emv);
}

print "Using native Perl types (ROR_native), the ROR is ", ROR_native(), "\n";

sub ROR_objects {
    ROR(bmv => $bmvobj, emv => $emvobj);
}


print "Using Math::FixedPrecision objects (ROR_objects), the ROR is ", ROR_objects(),"\n";

print "Go get a cup of coffee while we time 10000 iterations each of ROR_native and ROR_objects\n";

print "Start: @{[scalar(localtime())]}\n";
cmpthese($count,
	 {
	  ROR_native => \&ROR_native,
	  ROR_objects => \&ROR_objects,
	 }
	);
print "End: @{[scalar(localtime())]}\n";
