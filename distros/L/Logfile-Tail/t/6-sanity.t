use Test::More tests => 1;

use File::Find ();
use Digest::SHA ();
use Cwd ();

my $status_filename = Digest::SHA::sha256_hex(Cwd::getcwd() . '/t/file');
my $status_filename_r1 = Digest::SHA::sha256_hex(Cwd::getcwd() . '/t/rotate1');
my $status_filename_r2 = Digest::SHA::sha256_hex(Cwd::getcwd() . '/t/rotate2');
my $status_filename_rf = Digest::SHA::sha256_hex(Cwd::getcwd() . '/t/rotfail');

my @files;

File::Find::find(sub { push @files, $File::Find::name }, glob(".logfile*"), glob("logfile*"));
@files = sort map { s!^./!! ; $_; } @files;

is_deeply(\@files, [
	'.logfile-tail-status',
	'.logfile-test3',
	".logfile-test3/$status_filename",
	'logfile-status-file',
	], 'check that only so many files were created');

