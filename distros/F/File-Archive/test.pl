# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "Trying to load module.\n"; }
END {print "not ok 1\n" unless $loaded;}
use File::Archive;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Test 2
my $arch;
print "Creating a File::Archive object.\n";
if ($arch = File::Archive->new('targz.file.tar.gz'))	{
	print "New file $arch->{filename}\n";
	print "ok 2\n";
} else {
	print "not ok 2\n";
}

# Test 3
print "What is the file's name?\n";
$name = $arch->filename;
if ($name eq 'targz.file.tar.gz')	{
	print "Filename is $name.\nok 3\n";
} else {
	print "not ok 3\n";
}

# Test 4
print "What type of file is it?\n";
$type = $arch->type;
if ($type eq "tarred compressed")	{
	print "File is a $type file.\nok 4\n";
} else {
	print "not ok 4\n";
}

# Test 5
print "What's in the file?\n";
@list = $arch->catalog;
if (@list)	{
	print "Contents: " . join ', ', @list;
	print "\nok 5\n";
} else {
	print "not ok 5\n";
}

# Test 5.5
print "What's in the file 'testfile2'?\n";
$contents = $arch->member('testfile2');
if ($contents =~ 'This is testfile 2')	{
	print $contents;
	print "ok 5.5\n";
} else {
	print "not ok 5.5\n";
}

# Test 6
print "Trying with a plain file.\n";
$arch = File::Archive->new('test.pl');
@list = $arch->catalog;
if (@list)	{
	print "Contents: " . join ', ', @list;
	print "\nok 6\n";
} else {
	print "not ok 6\n";
}

# Test 7
print "Trying with a gzipped file.\n";
$arch = File::Archive->new('gzipped.gz');
@list = $arch->catalog;
if (@list)	{
	print "Contents: " . join ', ', @list;
	print "\nok 7\n";
} else {
	print "not ok 7\n";
}

# Test 7.5
print "What's in the file 'gzipped'?\n";
$contents = $arch->member('gzipped');
if ($contents =~ 'This is the compressed file')	{
	print "ok 7.5\n";
} else {
	print "not ok 7.5\n";
}

# Test 8
print "Trying with a tar file.\n";
$arch = File::Archive->new('tarfile.tar');
@list = $arch->catalog;
if (@list)	{
	print "Contents: " . join ', ', @list;
	print "\nok 8\n";
} else {
	print "not ok 8\n";
}

# Test 9
print "What's in the file 'testfile2'?\n";
$contents = $arch->member('testfile2');
if ($contents =~ 'This is testfile 2')	{
	print $contents;
	print "ok 9\n";
} else {
	print "not ok 9\n";
}


# Test 10
print "Trying with a compressed file.\n";
$arch = File::Archive->new('compressed.Z');
@list = $arch->catalog;
if (@list)	{
	print "Contents: " . join ', ', @list;
	print "\nok 10\n";
} else {
	print "not ok 10\n";
}

# Test 11
# print "What's in the file 'compressed'?\n";
# $contents = $arch->member('compressed');
# print $contents;
# if ($contents =~ 'This is the compressed file')	{
#	print "ok 11\n";
# } else {
#	print "not ok 11\n";
# }
