# ABSTRACT: Open a file, read a number value, increment it, save the file

# For the sake of simplicity, this code assumes:
#   * the counter file already exist and is writeable
#   * the counter file has one line, which contains only numbers

use strict; # always
use warnings;

use File::Util;

my $ftl = File::Util->new();
my $counterfile = 'counter.txt'; # the counter file needs to already exist

my $count = $ftl->load_file( $counterfile );

# convert textual number to in-memory int type, -this will default
# to a zero if it encounters non-numerical or empty content
chomp $count;
$count = int $count;

print "Count value from file: $count.";

$count++; # increment the counter value by 1

# save the incremented count back to the counter file
$ftl->write_file( filename => $counterfile, content => $count );

# verify that it worked
print ' Count is now: ' . $ftl->load_file( $counterfile );

exit;
