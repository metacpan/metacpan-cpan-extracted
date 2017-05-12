use Inline::Files;

while (<FILE>) {
	print "$FILE: $_";
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

