# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Image::Caption;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

open(F, "<image.rgb") or die "$!";
my $fr = join('', <F>);
close(F);

my $time = time();
my $count = 0;

add_caption($fr, 320, 240,
	-font  => "builtin",
	-scale => 0.34,
        -pos   => sprintf("%d %d", rand(320), rand(240)),
	-right,
	-text  => '%a, %d-%b-%Y %l:%M:%S %p %Z',
);

while (1) {
	add_caption($fr, 320, 240,
	        -pos   => sprintf("%d %d", rand(320), rand(240)),
		-right,
		-text  => '%a, %d-%b-%Y %l:%M:%S %p %Z',
	);

	$count++;

	if ($time != time()) {
		printf "%s: %d frames\n", scalar localtime, $count;
		$count = 0;
		$time = time();

		last;
}	}

open(OUT, ">out.ppm");
print OUT "P6\n";
print OUT "320 240\n";
print OUT "255\n";
print OUT $fr;
close(OUT);

print "ok 2\n";
