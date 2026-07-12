use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile tempdir);
use File::Spec;

my $eshu = File::Spec->catfile('bin', 'eshu');
my $perl = $^X;

plan tests => 3;

# 1. --diff shows unified diff output
{
	my $dir = tempdir(CLEANUP => 1);
	my $tmpfile = File::Spec->catfile($dir, 'test.c');
	open my $fh, '>', $tmpfile or die "Cannot write $tmpfile: $!";
	print $fh "void foo() {\nint x;\n}\n";
	close $fh;

	my $got = qx($perl $eshu --diff $tmpfile);
	like($got, qr/^---\s/m, '--diff output contains --- header');
	like($got, qr/^\+\+\+\s/m, '--diff output contains +++ header');
}

# 2. --diff produces no output when file is already correct
{
	my $dir = tempdir(CLEANUP => 1);
	my $tmpfile = File::Spec->catfile($dir, 'clean.c');
	open my $fh, '>', $tmpfile or die "Cannot write $tmpfile: $!";
	print $fh "void foo() {\n\tint x;\n}\n";
	close $fh;

	my $got = qx($perl $eshu --diff $tmpfile);
	is($got, '', '--diff produces no output for clean file');
}
