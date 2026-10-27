#!perl

use strict;
use warnings;

use Config;
use File::Spec;
use Test::Most;
use Test::Warnings;
use Test::TempDir::Tiny;

use_ok('File::pfopen', ('pfopen'));

my $sep = $Config{path_sep};

# Two directories, each with its own copy of the same file, to check search order
my $dir1 = File::Spec->rel2abs(tempdir('first'));
my $dir2 = File::Spec->rel2abs(tempdir('second'));
my $missing = File::Spec->catdir($dir1, 'not_there_tulip');

foreach my $dir ($dir1, $dir2) {
	open(my $fout, '>', File::Spec->catfile($dir, 'sep.txt')) or die "Can't create test file in $dir: $!";
	print $fout "$dir\n";
	close $fout;
}
open(my $fout, '>', File::Spec->catfile($dir2, 'only2.txt')) or die "Can't create test file in $dir2: $!";
print $fout "only2\n";
close $fout;

subtest 'string path uses the platform separator' => sub {
	my ($fh, $file) = pfopen("$missing$sep$dir2", 'only2', 'txt', '<');
	ok(defined($fh), 'found file in second directory');
	is(<$fh>, "only2\n", 'read the right file');
	is($file, File::Spec->catfile($dir2, 'only2.txt'), 'full filename including any drive letter');

	($fh, $file) = pfopen("$dir2$sep$dir1", 'sep', 'txt', '<');
	is(<$fh>, "$dir2\n", 'first directory in the list wins');
};

subtest 'array reference of directories' => sub {
	my ($fh, $file) = pfopen([$missing, $dir2], 'only2', 'txt', '<');
	ok(defined($fh), 'found file in second directory');
	is(<$fh>, "only2\n", 'read the right file');
	is($file, File::Spec->catfile($dir2, 'only2.txt'), 'filename is as expected');

	($fh, $file) = pfopen([$dir1, $dir2], 'sep', 'txt', '<');
	is(<$fh>, "$dir1\n", 'first directory in the list wins');

	($fh, $file) = pfopen([$dir2, $dir1], 'sep', 'txt', '<');
	is(<$fh>, "$dir2\n", 'order is honoured, and not confused by the cache');

	ok(!defined(pfopen([], 'sep', 'txt', '<')), 'empty list finds nothing');
	ok(!defined(pfopen([$missing], 'sep', 'txt', '<')), 'non-existent directory finds nothing');
};

subtest 'scalar context with an array reference' => sub {
	my $fh = pfopen([$dir1], 'sep', 'txt', '<');
	ok(defined($fh), 'returns a file handle');
	is(<$fh>, "$dir1\n", 'read the right file');
};

subtest 'cache keys do not collide' => sub {
	# Prime the cache
	ok(defined(pfopen($dir1, 'sep', 'txt', '<')), 'found sep.txt');

	# With the old "prefix;path;suffixes" key this was the same key as above,
	# so the cached sep.txt was wrongly returned
	ok(!defined(pfopen("$dir1;txt", 'sep', undef, '<')), "'sep' with no suffix isn't found from the cache");

	# Different suffixes must not share a cache entry
	ok(defined(pfopen($dir2, 'only2', 'txt', '<')), 'found only2.txt');
	ok(!defined(pfopen($dir2, 'only2', 'bin', '<')), "only2.bin isn't found from the cache");
};

subtest 'suffixes are colon separated on every platform' => sub {
	my ($fh, $file) = pfopen([$dir2], 'only2', 'bin:txt', '<');
	ok(defined($fh), 'second suffix found');
	like($file, qr/only2\.txt$/, 'with the right suffix');
};

SKIP: {
	skip('Drive letter tests are for Windows only', 1) unless($^O eq 'MSWin32');

	subtest 'drive letters on Windows' => sub {
		like($dir1, qr/^[A-Za-z]:/, 'temporary directory has a drive letter');

		my ($fh, $file) = pfopen("$missing;$dir2", 'only2', 'txt', '<');
		ok(defined($fh), 'found file after a directory with a drive letter');
		is($file, File::Spec->catfile($dir2, 'only2.txt'), 'drive letter is kept in the filename');

		my $drive = substr($dir1, 0, 2);
		($fh, $file) = pfopen("${drive}\\not_there_tulip;$dir1", 'sep', 'txt', '<');
		ok(defined($fh), 'bare drive letter path is skipped, and the next directory searched');
		is(<$fh>, "$dir1\n", 'read the right file');
	};
}

done_testing();
