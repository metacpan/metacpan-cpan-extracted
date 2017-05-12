# Test device status call.

$| = 1;
print "1..1\n";

use Filesys::SamFS;
use Data::Dumper;
require "t/vars.pl";

if ($>) {
  # Refuse to run for ordinary user.
  print STDERR "This test must be run as root.\n";
  exit;
}

@list = Filesys::SamFS::ndevstat($eq);
if (scalar(@list)) {
  printf "Filesys::SamFS::ndevstat of $eq: (%s)\n", Dumper(\@list);
  printf "Filesys::SamFS::devstr of $eq: '%s'\n", Filesys::SamFS::devstr($list[4]);
  print "ok 1\n";
} else {
  print "Filesys::SamFS::ndevstat of $eq failed: $!\n";
  print "not ok 1\n";
}
