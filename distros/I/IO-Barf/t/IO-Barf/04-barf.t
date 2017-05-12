# Pragmas.
use strict;
use warnings;

# Modules.
use Digest;
use English qw(-no_match_vars);
use Error::Pure qw(err);
use File::Object;
use File::Slurp qw(slurp);
use File::Temp qw(tempfile);
use IO::File;
use IO::Barf qw(barf);
use Test::More 'tests' => 12;
use Test::NoWarnings;

# Test data directory.
my $test_dir = File::Object->new->up->dir('data');

# Test subroutine for file.
sub test1 {
	my ($file, $message) = @_;
	my $ex = $test_dir->file($file)->s;
	my ($data, $data_sha256) = _data_digest($ex);
	my (undef, $new_ex) = tempfile();
	barf($new_ex, $data);
	my $barf_sha256 = _digest_file($new_ex);
	is($data_sha256, $barf_sha256, $message);
	unlink $new_ex;
	return;
}

# Test subroutine for handler.
sub test2 {
	my ($file, $message) = @_;
	my $ex = $test_dir->file($file)->s;
	my ($data, $data_sha256) = _data_digest($ex);
	my ($new_ex_fh, $new_ex) = tempfile();
	barf($new_ex_fh, $data);
	close $new_ex_fh;
	my $barf_sha256 = _digest_file($new_ex);
	is($data_sha256, $barf_sha256, $message);
	unlink $new_ex;
	return;
}

# Test subroutine for IO::Handler.
sub test3 {
	my ($file, $message) = @_;
	my $ex = $test_dir->file($file)->s;
	my ($data, $data_sha256) = _data_digest($ex);
	my (undef, $new_ex) = tempfile();
	my $new_ex_io = IO::File->new($new_ex, 'w');
	barf($new_ex_io, $data);
	$new_ex_io->close;
	my $barf_sha256 = _digest_file($new_ex);
	is($data_sha256, $barf_sha256, $message);
	unlink $new_ex;
	return;
}

# Get data and SHA256 digest.
sub _data_digest {
	my $file = shift;
	my $data = slurp($file);
	my $data_sha256 = _digest_file($file);
	return ($data, $data_sha256);
}

# Get digest of file.
sub _digest_file {
	my $file = shift;
	open my $file_fh, '<', $file or err "Cannot open file '$file'.";
	my $digest = Digest->new('SHA-256');
	$digest->addfile($file_fh);
	return $digest->hexdigest;
}

# Test.
test1('ex1.txt', 'Test file #1.');

# Test.
test1('ex2.txt', 'Test file #2.');

# Test.
test1('ex3.txt', 'Test file #3.');

# Test.
test2('ex1.txt', 'Test handler #1.');

# Test.
test2('ex2.txt', 'Test handler #2.');

# Test.
test2('ex3.txt', 'Test handler #3.');

# Test.
test3('ex1.txt', 'Test IO::Handler #1.');

# Test.
test3('ex2.txt', 'Test IO::Handler #2.');

# Test.
test3('ex3.txt', 'Test IO::Handler #3.');

# Test.
eval {
	barf((bless {}, 'Foo::Bar'), 'FOOBAR');
};
is($EVAL_ERROR, "Unsupported reference 'Foo::Bar'.\n",
	'Unsupported reference to \'Foo::Bar\'.');

# Test.
eval {
	barf([], 'FOOBAR');
};
is($EVAL_ERROR, "Unsupported reference 'ARRAY'.\n",
	'Unsupported reference to array.');
