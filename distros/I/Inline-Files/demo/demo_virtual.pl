use Inline::Files::Virtual;

my @files = vf_load($0, "^__(?:FOO|BAR)__\n");

foreach $file (@files) {
	local *FILE;
	print "<<$file>>\n";
	vf_open FILE, $file or die "huh?";
	while (<FILE>) {
		print "> $_";
	}
}
print "<<<@files>>>\n";
print "<<<$files[0]>>>\n";

vf_open(FILE, "+> $files[0]");
print FILE "test";
vf_seek(FILE, 0, 0);
print <FILE>;




__END__
__FOO__
This is a
virtual


file
__BAR__
This is another
virtual

file
__FOO__
THIS IS YET ANOTHER SUCH
 FILE
