# Test stat calls.

$| = 1;
print "1..2\n";

use Filesys::SamFS;
use Data::Dumper;

eval {require "t/vars.pl";};
if (length $@) {
  print  STDERR "Problem reading variables file t/vars.pl:\n";
  $@ =~ s/\n/\n\t/g;
  printf STDERR "\t%s", $@;
  exit 1;
}

unless (defined $dir) {
  print STDERR "Variable \$dir not set in file \"t/vars.pl\". Aborting!\n";
  exit 1;
}

$filename = "$dir/archived";

# Check if stat() works at all.
@list = Filesys::SamFS::stat($filename);
if (scalar(@list)) {
#  printf "Filesys::SamFS::stat of $filename: (%s)\n", Dumper(\@list);
#  printf "Filesys::SamFS::attrtoa of $filename: '%s'\n",
#         Filesys::SamFS::attrtoa($list[13]);
  print "ok 1\n";
} else {
  print "Filesys::SamFS::stat of $filename failed: $!\n";
  print "not ok 1\n";
}

# Check if the fields we have in common with stat() are indeed the same.
@list2 = stat($filename);
# Remove the unsupported entries from the end of the stat() result.
pop @list2;
pop @list2;
# Now compare
$ok = 1;
for (my $i=0; $i<=$#list2; $i++) {
  if ($list[$i] != $list2[$i]) {
    $ok = 0;
    print "Elements $i differ: $list[$i] != $list2[$i]\n";
  }
}
printf "%sok 2\n", $ok ? '' : 'not ';

# sam_vsn_stat does not seem to return any nonempty values ?!?
