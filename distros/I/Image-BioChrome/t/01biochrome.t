#
# t/01biochrome.t
#
# set of tests to check the basic functionality of the Image::BioChrome
# module
#
# 
BEGIN { $| = 1; print "1..26\n"; }

use lib qw(. ./t ./lib ../lib ./blib/lib ../blib/lib);


my $dir = -d 't' ? 't/gif' : 'gif';
use Image::BioChrome;

eval {
	my $nf = Image::BioChrome->new();
};

print "ok 1\n" if $@;
print "not ok 1\n" unless $@;

eval {
	my $nf = Image::BioChrome->new($dir . '/nofilehere.gif');
};

print "ok 2\n" if $@;
print "not ok 2\n" unless $@;

my $bio = Image::BioChrome->new($dir . '/simple.gif');
print "ok 3\n" if $bio;
print "not ok 3\n" unless $bio;

# test file creation
$bio->write_file($dir . '/output.gif');
check_and_delete_file("$dir/output.gif",4);

# try creating a BioChrome for an unsupported file type
my $bi2 = Image::BioChrome->new($dir . '/simple.jpg');
print $bi2 ? "ok 5\n" : "not ok 5\n";

# pass some alpha data
$bi2->alphas(['ff0000','0000ff']);

# check the file gets written unmodified
$bi2->write_file($dir . '/output.jpg');
check_and_delete_file("$dir/output.jpg",6,14895);

# set alphas
$bio->alphas(['ff0000','00ff00']);
# write the file
$bio->write_file($dir . '/output.gif');
check_and_delete_file("$dir/output.gif",7,16855);



#
# Test all the color calling options
#

$bio->colors('ff0000','00ff00','0000ff');
check_colors($bio,8);
$bio->colors('ff0000_00ff00_0000ff');
check_colors($bio,9);
$bio->colors(['ff0000','00ff00','0000ff']);
check_colors($bio,10);
$bio->colors('_ff0000__00ff00__0000ff');
check_colors($bio,11);
$bio->colors('ff0000X00ff00X0000ff');
check_colors($bio,12);
$bio->colors('ff0000	00ff00	0000ff');
check_colors($bio,13);
$bio->colors('ff0000    00ff00  0000ff');
check_colors($bio,14);
$bio->colors('#ff0000_#00ff00_#0000ff');
check_colors($bio,15);


$bio->colors(['ff0000','ffffff']);
$bio->write_file($dir . '/output.gif');
check_and_delete_file("$dir/output.gif",16,19843);


$bio->alphas(['ff0000','ffffff']);
$bio->write_file($dir . '/output2.gif');
check_and_delete_file("$dir/output2.gif",17,20919);

eval {
	$bio->write_file($dir . '/test/output2.gif');
};

check_and_delete_file("$dir/test/output2.gif",18,20919);

# captials in colors
$bio->colors('FF0000_00FF00_0000ff');
check_colors($bio,19);

# invalid colors?
$bio->alphas('ffffff');
$bio->write_file($dir . '/output2.gif');
check_and_delete_file("$dir/output2.gif",20,25015);

# invalid colors?
$bio->alphas('000000');
$bio->write_file($dir . '/output2.gif');
check_and_delete_file("$dir/output2.gif",21,12775);


$bio->alphas('000000_abcdf');
$bio->write_file($dir . '/output2.gif');
check_and_delete_file("$dir/output2.gif",22,12775);

$bio->alphas('000000_abcdfg');
$bio->write_file($dir . '/output2.gif');
check_and_delete_file("$dir/output2.gif",23,12775);

$bio->alphas('ffffff_abcdfg_000000');
$bio->write_file($dir . '/output2.gif');
check_and_delete_file("$dir/output2.gif",24,18919);

$bio->alphas('ffffff','25abcdefg','25axxx','000000');
$bio->write_file($dir . '/output2.gif');
check_and_delete_file("$dir/output2.gif",25,18919);

$bio->alphas(['ffffff','26abcdefg','26axxx','000000']);
$bio->write_file($dir . '/output2.gif');
check_and_delete_file("$dir/output2.gif",26,18919);

#
# check the internal state of the colors
#

sub check_colors {
	my $bio = shift;
	my $test = shift;

	my $colors = $bio->{ colors };

	if ($$colors[0] eq 'ff0000' && 
		$$colors[1] eq '00ff00' && 
		$$colors[2] eq '0000ff') {

		print "ok $test\n";
	} else {
		print "not ok $test\n";
	}
}

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
