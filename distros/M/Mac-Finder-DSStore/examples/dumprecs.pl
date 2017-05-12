#
#  Simple dump of records to stdout
#

use Mac::Finder::DSStore::BuddyAllocator;
use Mac::Finder::DSStore;
use IO::File;
use Data::Dumper;

die "Usage: $0 /path/to/.DS_Store\n"
    unless @ARGV == 1 && -f $ARGV[0];

$Data::Dumper::Useqq = 1;

$store = Mac::Finder::DSStore::BuddyAllocator->open(new IO::File $ARGV[0], '<');
@ents = &Mac::Finder::DSStore::getDSDBEntries($store);
undef $store;

print Dumper(\@ents);
