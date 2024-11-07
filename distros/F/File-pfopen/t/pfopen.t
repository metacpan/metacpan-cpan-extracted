#!perl

use strict;
use warnings;

use Cwd;
use File::Spec;
use Test::Most tests => 33;
use Test::NoWarnings;
use Test::TempDir::Tiny;

use_ok('File::pfopen', ('pfopen'));

my $tmpdir = tempdir();
my $filename = File::Spec->catfile($tmpdir, 'pfopen.txt');
open(my $fout, '>', $filename);
print $fout "Hello, world\n";
close $fout;
ok(defined(pfopen($tmpdir, 'pfopen', 'txt')));
ok(defined(pfopen("/non-existent:$tmpdir", 'pfopen', 'txt')));
ok(defined(pfopen("/etc/group:$tmpdir", 'pfopen', 'txt')));
ok(!defined(pfopen($tmpdir, 'pfopen', 'bar')));
my $fh;
($fh, $filename) = pfopen($tmpdir, 'pfopen', 'bar:txt');
ok(<$fh> eq "Hello, world\n");
ok($filename =~ /pfopen\.txt$/);
$fh = pfopen($tmpdir, 'pfopen', 'txt:baz');
ok(<$fh> eq "Hello, world\n");
ok(!defined(pfopen('/', 'pfopen', 'txt')));
ok(defined(pfopen("/:$tmpdir", 'pfopen', 'bar:txt')));
($fh, $filename) = pfopen("/:$tmpdir", 'pfopen', 'bar:txt');
ok(<$fh> eq "Hello, world\n");
ok($filename =~ /pfopen\.txt$/);
$fh = pfopen("/:$tmpdir", 'pfopen', 'bar:txt');
ok(<$fh> eq "Hello, world\n");
ok(!defined(pfopen('/', 'pfopen', 'txt')));
ok(!defined(pfopen("/:$tmpdir", 'pfopen')));
ok(defined(pfopen($tmpdir, 'pfopen.txt')));
($fh, $filename) = pfopen("/:$tmpdir", 'pfopen.txt');
ok(<$fh> eq "Hello, world\n");
ok($filename =~ /pfopen\.txt$/);
$fh = pfopen("/:$tmpdir", 'pfopen.txt');
ok(<$fh> eq "Hello, world\n");

($fh, $filename) = pfopen("/:/not_there_tulip:$tmpdir", 'pfopen.txt');
ok(<$fh> eq "Hello, world\n");
ok($filename =~ /pfopen\.txt$/);

# Mock data
$filename = File::Spec->catfile($tmpdir, 'testfile.txt');

# Set up a test file to read
open($fh, '>', $filename) or die "Could not create test file: $!";
print $fh "Sample text\n";
close $fh;

# Open file without suffix in scalar context
{
	my $fh = pfopen($tmpdir, 'testfile', undef);
	ok(!defined $fh, "Don't open file without suffix in scalar context");
}

# Open file with suffix in scalar context
{
	my $fh = pfopen($tmpdir, 'testfile', 'txt', '<');
	ok(defined $fh, 'Opened file with suffix in scalar context');
	close $fh if $fh;
}

# Open file with suffix in scalar context, using first suffix
{
	my ($fh, $file) = pfopen($tmpdir, 'testfile', 'txt:foo');
	ok(defined $fh, 'Opened file with suffix in scalar context, first suffix');
	close $fh if $fh;
	if($^O eq 'MSWin32') {
		like($filename, qr/\Q$file\E/, 'suffixes are scanned');
	} else {
		cmp_ok($file, 'eq', $filename, 'suffixes are scanned');
	}
}

# Open file with suffix in scalar context, using second suffix
{
	my ($fh, $file) = pfopen($tmpdir, 'testfile', 'foo:txt');
	ok(defined $fh, 'Opened file with suffix in scalar context, second suffix');
	close $fh if $fh;
	if($^O eq 'MSWin32') {
		like($filename, qr/\Q$file\E/, 'suffixes are scanned');
	} else {
		cmp_ok($file, 'eq', $filename, 'suffixes are scanned');
	}
}

# Open file without suffix in list context
{
	my ($fh, $rc) = pfopen($tmpdir, 'testfile', undef);
	ok((!defined $fh) && (!defined $rc),  "Don't open file without suffix in list context");
	close $fh if $fh;
}

# Open file with suffix in list context
{
	my ($fh, $rc) = pfopen($tmpdir, 'testfile', 'txt');
	ok((defined $fh) && (defined $rc), 'Opened file with suffix in list context');
	# my $t1 = 'D:\a\File-pfopen\File-pfopen\tmp\t_pfopen_t\default_1\testfile.txt';
	# my $t2 = '\a\File-pfopen\File-pfopen\tmp\t_pfopen_t\default_1\testfile.txt';
	if($^O eq 'MSWin32') {
		like($filename, qr/\Q$rc\E/, 'Filename is as expected minus the drive letter');
	} else {
		cmp_ok($rc, 'eq', $filename, 'Filename was as expected');
	}
	close $fh if $fh;
}

# Clean up
unlink $filename;

# File not found returns undef
{
	my $fh = pfopen($tmpdir, 'nonexistentfile', undef);
	ok(!defined $fh, 'Returns undef when file is not found');
}

# File not openable returns undef
{
	my $fh = pfopen($tmpdir, '.', undef, '>');
	ok(!defined $fh, 'Returns undef when attempting to open directory for writing')
}
