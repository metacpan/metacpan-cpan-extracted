#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Config;
use Test::More tests => 7;
use ExtUtils::Helpers qw/make_executable/;
use Cwd qw/cwd/;

my $filename = 'test_exec';
my @files;

open my $out, '>', $filename or die "Couldn't create $filename: $!";
print $out "#! perl -w\nexit \$ARGV[0];\n";
close $out;

make_executable($filename);

foreach my $i (42, 51, 0) {
	my $cwd = cwd;
	local $ENV{PATH} = join $Config{path_sep}, $cwd, $ENV{PATH};
	my $ret = system $filename, $i;
	is $ret & 0xff, 0, 'test_exec executed successfully';
	is $ret >> 8, $i, "test_exec $i return value ok";
}

SKIP: {
	skip 'No batch file on non-windows', 1 if $^O ne 'MSWin32';
	push @files, grep { -f } map { $filename.$_ } split / $Config{path_sep} /x, $ENV{PATHEXT};
	is scalar(@files), 1, "Executable file exists";
}

unlink $filename, @files;
