use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile tempdir);
use File::Spec;

# Find the bin/eshu script
my $eshu = File::Spec->catfile('bin', 'eshu');
my $perl = $^X;

plan tests => 5;

# 1. stdin to stdout, default (C)
{
	my $input = "void foo() {\nint x;\n}\n";
	my $expected = "void foo() {\n\tint x;\n}\n";
	my $got = pipe_through("$perl $eshu --lang c", $input);
	is($got, $expected, 'stdin to stdout with --lang c');
}

# 2. file argument, stdout output
{
	my ($fh, $tmpfile) = tempfile(SUFFIX => '.c', UNLINK => 1);
	print $fh "int main() {\nreturn 0;\n}\n";
	close $fh;

	my $got = qx($perl $eshu $tmpfile);
	my $expected = "int main() {\n\treturn 0;\n}\n";
	is($got, $expected, 'file arg outputs to stdout');
}

# 3. --tabs option
{
	my $input = "void foo() {\nint x;\n}\n";
	my $expected = "void foo() {\n\tint x;\n}\n";
	my $got = pipe_through("$perl $eshu --tabs --lang c", $input);
	is($got, $expected, '--tabs produces tab indentation');
}

# 4. --spaces option
{
	my $input = "void foo() {\nint x;\n}\n";
	my $expected = "void foo() {\n    int x;\n}\n";
	my $got = pipe_through("$perl $eshu --spaces 4 --lang c", $input);
	is($got, $expected, '--spaces 4 produces 4-space indentation');
}

# 5. --fix edits file in-place
{
	my $dir = tempdir(CLEANUP => 1);
	my $tmpfile = File::Spec->catfile($dir, 'test.c');
	open my $fh, '>', $tmpfile or die "Cannot write $tmpfile: $!";
	print $fh "void foo() {\nint x;\n}\n";
	close $fh;

	system($perl, $eshu, '--fix', $tmpfile);

	open my $in, '<', $tmpfile or die "Cannot read $tmpfile: $!";
	my $got = do { local $/; <$in> };
	close $in;

	my $expected = "void foo() {\n\tint x;\n}\n";
	is($got, $expected, '--fix edits file in-place');
}

sub pipe_through {
	my ($cmd, $input) = @_;
	my ($in_fh, $in_file) = tempfile(UNLINK => 1);
	print $in_fh $input;
	close $in_fh;
	my $got = qx($cmd < $in_file);
	return $got;
}
