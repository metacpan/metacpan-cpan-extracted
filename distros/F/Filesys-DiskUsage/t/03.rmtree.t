use strict;
use warnings;
use Test::More tests => 2;

use File::Temp qw(tempdir);
use Filesys::DiskUsage ();
use File::Path qw(mkpath rmtree);

# this might have failed on cygwin.
# https://rt.cpan.org/Public/Bug/Display.html?id=48227


subtest baseline => sub {
	plan tests => 2;

	my $dir = tempdir( CLEANUP => 1);

	mkpath("$dir/x/y/z");
	ok -e "$dir/x/y/z", 'directory created';

	rmtree("$dir/x");
	ok not(-e "$dir/x"), 'directory removed';
};

subtest du => sub {
	plan tests => 3;

	my $dir = tempdir( CLEANUP => 1);

	mkpath("$dir/a/b/c");
	ok -e "$dir/a/b/c", 'directory created';

	my $du = Filesys::DiskUsage::du("$dir/a/b");
	#diag explain $du;
	is $du, 0, 'du is 0';

	rmtree("$dir/a");
	ok not(-e "$dir/a"), 'directory removed';
};

