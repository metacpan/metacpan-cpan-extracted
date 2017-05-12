use Inline::Files;

my $here;

# etc.
# etc.
# etc.

while (<FOO>) {
	print "FOO> $_";
}

my $rememBAR = $BAR;

while (<BAR>) {
	print "BAR> $_";
}


open BAR, "+<$rememBAR" or die $!;
print BAR "Ta-da!\n";

seek BAR, 0, 0;
while (<BAR>) {
	print "BAR> $_";
}

print "done\n";

__FOO__
This is a virtual file at the end
of the data

__BAZ__
This is BAZ

__BAR__
This 
is BAR

__FOO__
This is yet another 
such file
