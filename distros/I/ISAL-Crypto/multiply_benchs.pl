#!/usr/bin/perl

use File::Copy 'copy';
use File::Path 'make_path';
use FindBin;
my @ALGOS = @ARGV;

my $dir = "$FindBin::Bin/mb_bench_templates";
opendir(my $dh, $dir) || die "Can't opendir $dir: $!";
my @test_files = grep /\A[^.]/, readdir $dh;
for my $t_file (@test_files) {
	for my $alg (@ALGOS) {
		make_path "$dir/../bench/$alg" || $!{EEXIST}
			|| die "Can't create $dir/../bench/$alg: $!";
		copy("$dir/$t_file", "$dir/../bench/$alg/$t_file")
			or die "Failed to copy file: $dir/$t_file to".
				"$dir/../bench/$alg/$t_file: $!";
	}
}
closedir($dh) or warn "Can't closedir $dir: $!"
