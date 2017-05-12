#!perl -w -Ilib
# Test script to monitor changes in Windows registry.
# $Id: TestRegistry.pl 521 2007-06-17 21:21:39Z kindlund $

use HoneyClient::Agent::Integrity::Registry;
use Data::Dumper;
use File::Temp qw(:POSIX);

### USER DEFINED OPTIONS ###

# Set this flag to 1, if you want a complete list of all
# registry changes -- instead of just a printout of directory
# key names.
my $more_detail = 0;

############################

print "This script will help you identify registry key directories\n" .
      "to ignore within your Registry module.\n\n" .
      "Notes: Edit this script, if you would like to have the output show\n" .
      "more detail.  Also, if you CTRL-C this script, then be sure to check\n" .
      "your /tmp directory, to delete any temporary files created.\n\n".
      "Press return to start baseline process...\n";

my $input = <>;

# Create the registry object.  Upon creation, the object
# will be initialized, by collecting a baseline of the registry.
my $registry = HoneyClient::Agent::Integrity::Registry->new();

print "\n";
print "Baseline check complete.  Perform normal allowable actions\n" .
      "on the system (i.e., browse benign web pages).\n\n" .
      "Press CTRL-D, when ready to perform an integrity check...\n";

$input = <>;

# Check the registry, for any changes.
print "Checking registry hives...\n";
my $changes = $registry->check();

if (!scalar(@{$changes})) {
    print "No registry changes have occurred.\n";
} else {
    print "Registry has changed:\n";

    if ($more_detail) {
        $Data::Dumper::Terse = 1;
        $Data::Dumper::Indent = 1;
        print Dumper($changes);
    } else {
        foreach my $change (@{$changes}) {
            print $change->{'key_name'} . " (" . $change->{'status'} . ")\n";
        }
    }
    my ($fh, $file) = tmpnam();
    $Data::Dumper::Terse = 1;
    $Data::Dumper::Indent = 1;
    print $fh Dumper($changes);
    print "\n";
    print "Done!\n";
    print "Detailed registry changes were written to: " . $file . "\n";
}
