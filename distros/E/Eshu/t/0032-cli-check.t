use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile tempdir);
use File::Spec;

my $eshu = File::Spec->catfile('bin', 'eshu');
my $perl = $^X;

plan tests => 3;

# 1. --check exits 0 when file is already correct
{
	my $dir = tempdir(CLEANUP => 1);
	my $tmpfile = File::Spec->catfile($dir, 'clean.c');
	open my $fh, '>', $tmpfile or die "Cannot write $tmpfile: $!";
	print $fh "void foo() {\n\tint x;\n}\n";
	close $fh;

	system($perl, $eshu, '--check', $tmpfile);
	is($? >> 8, 0, '--check exits 0 for correctly indented file');
}

# 2. --check exits 1 when file needs fixing
{
	my $dir = tempdir(CLEANUP => 1);
	my $tmpfile = File::Spec->catfile($dir, 'messy.c');
	open my $fh, '>', $tmpfile or die "Cannot write $tmpfile: $!";
	print $fh "void foo() {\nint x;\n}\n";
	close $fh;

	system($perl, $eshu, '--check', $tmpfile);
	is($? >> 8, 1, '--check exits 1 for incorrectly indented file');
}

# 3. --check prints filename to stderr for changed files
{
	my $dir = tempdir(CLEANUP => 1);
	my $tmpfile = File::Spec->catfile($dir, 'messy.c');
	open my $fh, '>', $tmpfile or die "Cannot write $tmpfile: $!";
	print $fh "void foo() {\nint x;\n}\n";
	close $fh;

	my $stderr = qx($perl $eshu --check $tmpfile 2>&1 1>/dev/null);
	like($stderr, qr/messy\.c/, '--check prints filename to stderr');
}
