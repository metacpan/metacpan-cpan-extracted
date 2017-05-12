# -*- cperl -*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 04compress.t'

#########################

use Test::More tests => 8;
BEGIN { use_ok('File::Properties::Cache');
        use_ok('File::Properties::Compressed') };
use Error qw(:try);
use Time::HiRes qw(gettimeofday tv_interval);
use File::Temp;
use Compress::Bzip2;

#########################

## Create a File::Properties::Cache object attached to a temporary
## database file
my $tmpdb = File::Temp->new(EXLOCK => 0, SUFFIX => '.db');
my $opts = {};
ok(my $fpc = File::Properties::Compressed->cache($tmpdb->filename, $opts));

# Create a temporary bzip2 test file
my $tmpdt = tmprndbz2file(1048576);

## Create a File::Properties::Compressed object for the temporary test
## file, measuring the time taken to do so. Check that the object was
## not retrieved from the cache.
my $fpr;
my $t0 = [gettimeofday];
ok($fpr = File::Properties::Compressed->new($tmpdt->filename, $fpc));
my $t1 = [gettimeofday];
ok(not $fpr->_fromcache);

## Create another File::Properties::Compressed object for the
## temporary test file, measuring the time taken to do so. Check that
## the object was retrieved from the cache.
my $t2 = [gettimeofday];
ok($fpr = File::Properties::Compressed->new($tmpdt->filename, $fpc));
my $t3 = [gettimeofday];
ok($fpr->_fromcache);

# Second lookup via cache should be much faster
ok(tv_interval($t2,$t3) lt 10*tv_interval($t0,$t1));

exit 0;


# Construct a temporary bzip2 file, compressing a file with random
# content of the specified size
sub tmprndbz2file {
    my $size = shift;

    my $fh1 = File::Temp->new;
    print $fh1 map { chr(rand 256) } 1..$size;
    $fh1->seek(0,0);
    my $fh2 = File::Temp->new;
    my $bz = bzopen($fh2, "wb") or return undef;
    my $buf;
    while ($buf = <$fh1>) {
      $bz->bzwrite($buf);
    }
    $bz->bzclose;
    $fh2->seek(0,0);
    return $fh2;
}
