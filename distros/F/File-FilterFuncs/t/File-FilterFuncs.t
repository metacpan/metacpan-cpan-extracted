use strict;
use warnings;
use Test::More tests => 14;
use File::FilterFuncs qw(:all);
use File::Spec::Functions;
use Fatal qw(open close);
use Fcntl qw(:seek);
use t::FF_Common;

t::FF_Common::init();

my ($infh, $outfh);
my $source = catfile($Common{tempdir}, 't.s');

# Create a local copy of the source file that uses the
# system's end-of-line format:
open ($infh, '<', catfile(t => 'source.txt'));
open ($outfh, '>', $source);
while (my $line = <$infh>) {
	print $outfh $line;
}
close $outfh;
close $infh;
undef $infh;
undef $outfh;

# Perform a simple copy.
filters ($source, testfile(1));
ok(diff($source,testfile(1)), 'simple copy');

# Perform a simple copy with a function.
filters ($source, sub { 1 }, testfile(2));
ok(diff($source,testfile(2)), 'simple copy with function');

# Uppercase the test file.
open ($infh, '<', $source);
open ($outfh, '>', testfile(3));
while (<$infh>) {
	print $outfh uc $_;
}
close $outfh;
close $infh;

filters ($source, sub { $_ = uc $_; 1 }, testfile('3b'));
ok(diff(testfile(3),testfile('3b')), 'convert to uppercase');

# Uppercase the test file and add a prefix.
open ($infh, '<', $source);
open ($outfh, '>', testfile(4));
while (<$infh>) {
	print $outfh "Line:" . uc $_;
}
close $outfh;
close $infh;

filters ($source, sub { $_ = uc $_; 1 },
	sub { $_ = "Line:" . $_; 1 }, testfile('4b'));
ok(diff(testfile(4),testfile('4b')), 'uppercase and add a prefix');

# Change the file's encoding to utf-8:
open ($infh, '<', $source);
open ($outfh, '>:utf8', testfile(5));
while (<$infh>) {
	print $outfh $_;
}
close $outfh;
close $infh;

filters ( $source, boutmode => ':utf8', testfile('5b'));
ok(diff(testfile(5),testfile('5b')), 'boutmode => :utf8');

# Change the file's encoding from utf-8 to iso-8859-1.
open ($infh, '<:utf8', testfile(5));
open ($outfh, '>', testfile(6));
while (<$infh>) {
	print $outfh $_;
}
close $outfh;
close $infh;

filters (testfile(5), binmode => ':utf8', testfile('6b'));
ok(diff(testfile(6),testfile('6b')), 'binmode => :utf8');

# Test using a fixed line length.
unslurp_file(testfile(7), 'ABCDEFGHIJKLM');
open ($infh, '<', testfile(7));
open ($outfh, '>', testfile('7b'));
{
	local $/ = \3;
	print $outfh "$_\n" while (<$infh>)
}
close $outfh;
close $infh;

filters (testfile(7), '$/' => \3,
	sub { $_ = "$_\n"; 1 }, testfile('7c'));
ok(diff(testfile('7b'), testfile('7c')),
	'setting $/ to an integer reference');


# Test reading paragraphs.
open ($infh, '<', $source);
open ($outfh, '>', testfile(8));
{
	local $/ = '';
	print $outfh "GROUP:$_" while (<$infh>);
}
close $outfh;
close $infh;

filters ($source, '$/' => '',
	sub { $_ = "GROUP:$_"; 1 }, testfile('8b'));
ok(diff(testfile(8),testfile('8b')), 'paragraph reading mode ($/ = "")');

# Test the "filter_funcs" function:
filter_funcs($source, testfile(9));
ok(diff($source,testfile(9)), 'use "filter_funcs" (alternate name)');

# Filter out lines with only whitespace.
open ($infh, '<', $source);
open ($outfh, '>', testfile(10));
print $outfh grep /\S/, <$infh>;
close $outfh;
close $infh;

filters ($source, sub { /\S/ }, testfile('10b'));
ok(diff(testfile(10),testfile('10b')), 'filter out lines with only whitespace');

# Use the $KEEP_LINE value.
filters ($source, sub { $KEEP_LINE }, testfile(11));
ok(diff($source,testfile(11)),'$KEEP_LINE value');

# Use the $IGNORE_LINE value.
filters ($source, 
	sub { return $IGNORE_LINE unless /\S/ },
	testfile(12));
ok(diff(testfile(10),testfile(12)),'$IGNORE_LINE value');

# $Common{tempdir} should be a directory.
ok(-d $Common{tempdir}, "$Common{tempdir} is a directory.");

# Testfiles should be in the tempdir.
ok(catfile($Common{tempdir},'t.1') eq testfile(1),
	'basic testfile name constrution');

t::FF_Common::cleanup;

##############################################

sub diff {
	my ($name1, $name2) = @_;
	my $file1 = slurp_file($name1);
	my $file2 = slurp_file($name2);
	$file1 eq $file2;
}

sub testfile {
	catfile($Common{tempdir},'t.' . shift());
}


