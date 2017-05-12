print "1..4\n";

use Image::Density::TIFF;

my $tolerance = 0.000001;

my @expected = (0.223278, 0.130488, 0.082122);

my $original = tiff_density("t/original.tif");
printf "1 (original): %8.6f (expecting %8.6f)\n", $original, $expected[0];
print "not " unless abs($original - $expected[0]) <= $tolerance;
print "ok 1\n";

my $diffuse = tiff_density("t/diffuse.tif");
printf "2 (diffuse): %8.6f (expecting %8.6f)\n", $diffuse, $expected[1];
print "not " unless abs($diffuse - $expected[1]) <= $tolerance;
print "ok 2\n";

my $noisy = tiff_density("t/noisy.tif");
printf "3 (noisy): %8.6f (expecting %8.6f)\n", $noisy, $expected[2];
print "not " unless abs($noisy - $expected[2]) <= $tolerance;
print "ok 3\n";

my @multi = tiff_densities("t/multi.tif");
print "4 (multi): ", join(", ", map { $_ = sprintf("%8.6f", $_) } @multi), " (expecting ", join(", ", map { $_ = sprintf("%8.6f", $_) } @expected), ")\n";
print "not " unless (scalar(@multi) == 3)
  && (abs($multi[0] - $expected[0]) <= $tolerance)
  && (abs($multi[1] - $expected[1]) <= $tolerance)
  && (abs($multi[2] - $expected[2]) <= $tolerance);
print "ok 4\n";

exit 0;
