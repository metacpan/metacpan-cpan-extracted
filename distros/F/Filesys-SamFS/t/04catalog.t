# Test catalog calls.

$| = 1;
print "1..2\n";

use Filesys::SamFS;
use Data::Dumper;
require "t/vars.pl";

@list = Filesys::SamFS::opencat($catalog);
if (scalar(@list)) {
  printf "Filesys::SamFS::opencat of $catalog: (%s)\n", Dumper(\@list);
  $cat_handle = $list[0];
  print "ok 1\n";
} else {
  print "Filesys::SamFS::opencat of $catalog failed: $!\n";
  print "not ok 1\n";
}

if (defined $cat_handle) {
  @list = Filesys::SamFS::getcatalog($cat_handle, 0);
  if (scalar(@list)) {
    printf "Filesys::SamFS::getcatalog of $catalog Slot 0: (%s)\n", Dumper(\@list);
    print "ok 2\n";
  } else {
    print "Filesys::SamFS::getcatalog of $catalog Slot 0 failed: $!\n";
    print "not ok 2\n";
  }
  Filesys::SamFS::closecat($cat_handle);
}
