# -*- cperl -*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 03regular.t'

#########################

use Test::More tests => 9;
BEGIN { use_ok('File::Properties::Generic') };
use Error qw(:try);
use File::Temp;
use File::Basename;

#########################

# Create a temporary test file containing random data
my $tmpdt = tmprndfile(1048576);
# Construct a File::Properties::Generic object for the test file
ok($fpg = File::Properties::Generic->new($tmpdt));
# Check whether the file size in the File::Properties::Generic object
# is correct
ok($fpg->size == 1048576);

## Create a temporary directory and populate the temporary directory
## with 5 random files of different sizes
my $tmpdr = File::Temp->newdir(CLEANUP => 1);
my $n = 262144;
my $tflst = [];
my $tmpfl;
for (my $k = 0; $k < 5; $k++) {
  $tmpfl = tmprndfile($n, $tmpdr);
  $n *= 2;
  push @$tflst, $tmpfl;
}

## Construct a File::Properties::Generic object for the test directory
## and get a hash mapping directory entries to
## File::Properties::Generic objects
ok($fpg = File::Properties::Generic->new($tmpdr));
my $fpch = $fpg->children;
## Check whether each of these File::Properties::Generic objects has
## the correct file size
$n = 262144;
for (my $k = 0; $k < 5; $k++) {
  $tmpfl = basename($tflst->[$k]->filename);
  ok($fpch->{$tmpfl}->size == $n);
  $n *= 2;
}

exit 0;


# Construct a temporary file with random content, of the specified
# size, and, if an optional second argument is provided, in the
# specified directory
sub tmprndfile {
    my $size = shift;

    my $fh;
    if (@_) {
      my $dir = shift;
      $fh = File::Temp->new(DIR => $dir);
    } else {
      $fh = File::Temp->new;
    }
    print $fh map { chr(rand 256) } 1..$size;
    $fh->seek(0,0);
    return $fh;
}
