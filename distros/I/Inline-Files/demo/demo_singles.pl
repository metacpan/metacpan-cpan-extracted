use Inline::Files;

foreach $filename (@FILE) {
	open HANDLE, $filename;
	print "<<$filename>>\n";
	while (<HANDLE>) {
		print;
	}
}

__FILE__
File 1
here

__FILE__
File 2
here

__OTHER_FILE__
other file 1

__FILE__
File 3
here

