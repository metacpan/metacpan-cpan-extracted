#
#  Example of making a .DS_Store from scratch
#
#  Creates $ARGV[1] files in a temporary directory and
#  arranges their icons in a circle.
#

use File::Temp qw(tempdir);
use Mac::Finder::DSStore::BuddyAllocator;
use Mac::Finder::DSStore;
use IO::File;

die "Usage: $0 num\n"
    if (@ARGV != 1 || ($num = 0+$ARGV[0]) < 2);

$dir = tempdir();

print "Making files in $dir\n";

@ents = ( );

foreach $i (1 .. $num) {
    open(F, ">", "$dir/file$i");
    print F "Hi!\n";
    close(F);

    $x = 200 * sin($i * 2 * 3.14159 / $num);
    $y = 200 * cos($i * 2 * 3.14159 / $num);
    $x += 300;
    $y += 300;

    my($e);
    $e = Mac::Finder::DSStore::Entry->new("file$i", 'Iloc');
    $e->value(pack('NNnnnn', $x, $y, 65536, 65536, 65536, 65536, 0));
    push(@ents, $e);
}

@ents = sort { $a->cmp($b) } @ents;

# We could also use &writeDSDBEntries here.
$store = Mac::Finder::DSStore::BuddyAllocator->new(new IO::File "$dir/.DS_Store", '>');
&Mac::Finder::DSStore::putDSDBEntries($store, \@ents);
$store->{toc}->{'Giggity giggity'} = 9909;
$store->writeMetaData;
# $store->listBlocks(1) or die;
$store->close;

