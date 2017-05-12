#
# t/04percent.t
#
# set of tests to check the functionality of the percent method of the module
#
# 
BEGIN { $| = 1; print "1..10\n"; }

use lib qw(. ./t ./lib ../lib ./blib/lib ../blib/lib);


my $dir = -d 't' ? 't/gif' : 'gif';
use Image::BioChrome;

eval {
	my $nf = Image::BioChrome->new();
};

print "ok 1\n" if $@;
print "not ok 1\n" unless $@;


my $bio = Image::BioChrome->new($dir . '/grey.gif');
print "ok 2\n" if $bio;
print "not ok 2\n" unless $bio;

# call the percent method
$bio->percents(100,100,0);

print "ok 3\n";

# test file creation
$bio->write_file($dir . '/output.gif');
check_and_delete_file("$dir/output.gif",4,188877);

# call the percent method
$bio->percents(50,100,100);

print "ok 5\n";

# test file creation
$bio->write_file($dir . '/output.gif');
check_and_delete_file("$dir/output.gif",6,197274);

# call the percent method
$bio->percents(100,10,10);

print "ok 7\n";

# test file creation
$bio->write_file($dir . '/output.gif');
check_and_delete_file("$dir/output.gif",8,175300);

# call the percent method
$bio->percents(150);

print "ok 9\n";

# test file creation
$bio->write_file($dir . '/output.gif');
check_and_delete_file("$dir/output.gif",10,211025);

#
# check that the file exists and delete it
# optionally check that the file has been created correctly
#

sub check_and_delete_file {
	my $file = shift || return;
	my $test = shift || return;
	my $byte = shift || 0;

	my $sum = 0;

	if (-f $file) {

		if ($byte) {

			open(IN, $file) || do {
				print "not ok $test: failed to open $file: $!\n";
				return;
			};

			# stop problems with binary data
			binmode(IN);
			
			while (read IN, my $data, 1024) {
				foreach (split(//,$data)) {
					$sum += ord $_;
				}
			}

			close(IN);

			if ($byte != $sum) {
				print "not ok $test: no byte match $byte != $sum\n";
				return;
			}

		}

		print "ok $test\n";
		unlink($file);
	} else {
		print "not ok $test: no file\n";
	}
}
