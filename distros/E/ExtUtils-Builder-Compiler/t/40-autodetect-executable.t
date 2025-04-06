#! perl

use strict;
use warnings;

use Test::More 0.89;

use Config;
use ExtUtils::Builder::Planner;
use IPC::Open2 qw/open2/;
use File::Basename qw/basename dirname/;
use File::Spec::Functions qw/catfile/;

sub capturex {
	local @ENV{qw/PATH IFS CDPATH ENV BASH_ENV/};
	my $pid = open2(my($in, $out), @_);
	binmode $in, ':crlf' if $^O eq 'MSWin32';
	my $ret = do { local $/; <$in> };
	waitpid $pid, 0;
	return $ret;
}

my $planner = ExtUtils::Builder::Planner->new;
$planner->load_extension('ExtUtils::Builder::AutoDetect::C', undef,
	type => 'executable',
);

my $source_file = catfile('t', 'executable.c');
{
	open my $fh, '>', $source_file or die "Can't create $source_file: $!";
	my $content = <<END;
#include <stdio.h>

int main(int argc, char **argv, char **env) {
	printf("Dubrovnik\\n");
	return 0;
}
END
	print $fh $content or die "Can't write to $source_file: $!";
	close $fh or die "Can't close $source_file: $!";
}

ok(-e $source_file, "source file '$source_file' created");

my $object_file = catfile(dirname($source_file), basename($source_file, '.c') . $Config{obj_ext});
$planner->compile($source_file, $object_file);

my $exe_file = catfile(dirname($source_file), basename($object_file, $Config{obj_ext}) . $Config{exe_ext});
$planner->link([$object_file], $exe_file);

my $plan = $planner->materialize;
ok $plan;

ok eval { $plan->run($exe_file, logger => \&note); 1 } or diag "Got exception: $@";

ok(-e $object_file, "object file $object_file has been created");
ok(-e $exe_file, "lib file $exe_file has been created");

my $output = eval { capturex($exe_file) };
is ($output, "Dubrovnik\n", 'Output is "Dubrovnik"') or diag("Error: $@");

END {
	for ($source_file, $object_file, $exe_file) {
		next if not defined;
		1 while unlink;
	}
	if ($^O eq 'VMS') {
		1 while unlink 'EXECUTABLE.LIS';
		1 while unlink 'EXECUTABLE.OPT';
	}
}

done_testing;

