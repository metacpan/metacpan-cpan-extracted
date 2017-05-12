use Inline::Files;

open CACHE or die $!;	# read access (uses $CACHE to locate file)
eval join "", <CACHE>;
close CACHE or die $!;

print "\$var was '$var'\n";

while (<>) {
	chomp;
	$var = $_;
	print "\$var now '$var'\n";
}

open CACHE, ">$CACHE" or die $!;	# write access
use Data::Dumper;
print CACHE Data::Dumper->Dump([$var],['var']);
close CACHE or die $!;

__CACHE__
$var = 'Original value';

