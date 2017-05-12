use 5.008;
use ExtUtils::MakeMaker;
use Config;

#exit(0) if($ENV{AUTOMATED_TESTING});

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

unless (-t STDIN) {
  warn(
    "\n",
    "====================================================================\n",
    "\n",
    "Assuming --default because standard input is not a terminal.\n",
    "\n",
    "====================================================================\n",
    "\n",
  );
  push @ARGV, "--default";
}

# Ask if the device is attached

my $prompt1 = qq|
We need to use a test harness during testing to simulate the card if it is not currently installd or if Fuse and K8055fs are not installed. 
Use a test hadness during testing?  [y/n]|;

my $ret1 = "y";

if (grep /^--default$/, @ARGV) {
  print $prompt1, "n\n\n";
} else {
  $ret1 = prompt($prompt1, "y");
}

my $pathFileName1 = 't/testHarness.txt';
open(TOUCH,"+>$pathFileName1"); print TOUCH $ret1; close TOUCH;
print "Wrote configuration file $pathFileName1\n";


# Get the mount point for k8055fs  for the user.

my $prompt2 = qq|
We need to know where k8055fs has the device mounted, or where you wish to have it mounted if it is not already started.

Refer to the k8055 readme for more information.

Please give the k8055fs mount path name for testing.

If the path does not exist it will be created|;

my $ret2 = "/tmp/8055";

if (grep /^--default$/, @ARGV) {
  print $prompt2, " [/tmp/8055] \n\n";
} else {
  $ret2 = prompt($prompt2, "/tmp/8055");
}

my $pathFileName2 = 't/pathToDevice.txt';

unless(-d $ret2) {
    mkdir($ret2);
}
open(TOUCH,"+>$pathFileName2"); print TOUCH $ret2; close TOUCH;
print "Wrote configuration file $pathFileName2\n";

print "\n";

WriteMakefile(
    NAME              => 'Device::Velleman::K8055::Fuse',
    VERSION_FROM      => 'lib/Device/Velleman/K8055/Fuse.pm', # finds $VERSION
    PREREQ_PM         => {IO::File=>1.0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Device/Velleman/K8055/Fuse.pm',
	LICENSE => 'perl',
       AUTHOR         => 'Ronan Oger<ronan@cpan.org>') : ()),
);

