#!/usr/bin/perl

use File::Copy 'copy';
use FindBin;
my @ALGOS = @ARGV;

my $dir = "$FindBin::Bin/mb_test_templates";
opendir(my $dh, $dir) || die "Can't opendir $dir: $!";
my @test_files = grep /\A[^.]/, readdir $dh;
for my $t_file (@test_files) {
	for my $alg (@ALGOS) {
		copy("$dir/$t_file", "$dir/../t/$alg/$t_file")
			or die "Failed to copy file: $t_file: $!";
	}
}
closedir($dh) or warn "Can't closedir $dir: $!"
