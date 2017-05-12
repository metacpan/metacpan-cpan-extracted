use Inline::Files;
use Data::Dumper;

eval join "", <CACHE>;

print "\$var was '$var'\n";
while (<>) {
	chomp;
	$var = $_;
	print "\$var now '$var'\n";
}

seek CACHE, 0, 0;
print CACHE Data::Dumper->Dump([$var],['var']);

__CACHE__
$var = 'Original value';

