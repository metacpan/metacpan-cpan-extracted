# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MassSpec-ViewSpectrum.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('MassSpec::ViewSpectrum') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my @masses = (1036.4,1133,1437,1480,1502);
my @intensities = (0.1,0.15,-0.05,0.10,0.2);
my @annotations = ('b','w','internal w', '','internal y');
my $formatokcount = 0;
my $format;
my %reasons;
my $vs;
$reasons{'gif'} = "Old GD library or bad GD installation";
$reasons{'png'} = "libpng missing during GD installation";
$reasons{'jpeg'} = "libjpeg missing during GD installation";

foreach $format ('png','jpeg','gif') {
	$vs = MassSpec::ViewSpectrum->new(\@masses,\@intensities, \@annotations);
	$vs->set(yaxismultiplier => 1.8); # a sample tweak to adjust the output
	$vs->set(outputformat => $format);
	my $output = $vs->plot();
	if ($output && length($output) > 0) {
		diag("Apparent success with output format " . $format);
		$formatokcount++;
	} else {
		diag("Failed to produce non-null output with format " . $format . "; possible reasons include: " . $reasons{$format});
	}
#	undef $vs;
}
cmp_ok($formatokcount, '>', 0, "Unable to produce any non-null graphics output");
