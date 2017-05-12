# -*- cperl -*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 03regular.t'

#########################

use Test::More tests => 17;
BEGIN { use_ok('File::Properties::Cache');
        use_ok('File::Properties::Regular') };
use Error qw(:try);
use Time::HiRes qw(gettimeofday tv_interval);
use File::Temp;

#########################

## Create a File::Properties::Cache object attached to a temporary
## database file
my $tmpdb = File::Temp->new(EXLOCK => 0, SUFFIX => '.db', UNLINK => 1);
my $opts = {};
ok(my $fpc = File::Properties::Regular->cache($tmpdb->filename, $opts));

## Create a temporary test file containing random data and determine
## its SHA-2 file digest directly (without creating a corresponding
## File::Properties::Regular object)
my $tmpdt1 = tmprndfile(1048576);
my $tdgst1 = File::Properties::Regular::_digest($tmpdt1->filename);

## Create a File::Properties::Regular object for the temporary test
## file, measuring the time taken to do so. Check that the object was
## not retrieved from the cache, and that the object file digest value
## matches the directly determined value.
my $fpr;
my $t0 = [gettimeofday];
ok($fpr = File::Properties::Regular->new($tmpdt1->filename, $fpc));
my $t1 = [gettimeofday];
ok($fpr->_fromcache eq 0);
ok($fpr->digest eq $tdgst1);

## Create another File::Properties::Regular object for the temporary test
## file, measuring the time taken to do so. Check that the object was
## retrieved from the cache, and that the object file digest value
## matches the directly determined value.
my $t2 = [gettimeofday];
ok($fpr = File::Properties::Regular->new($tmpdt1->filename, $fpc));
my $t3 = [gettimeofday];
ok($fpr->_fromcache eq 1);
ok($fpr->digest eq $tdgst1);

# Second lookup via cache should be much faster
ok(tv_interval($t2,$t3) lt 10*tv_interval($t0,$t1));


## Create another temporary test file containing random data and
## determine its SHA-2 file digest directly (without creating a
## corresponding File::Properties::Regular object)
my $tmpdt2 = tmprndfile(2097152);
my $tdgst2 = File::Properties::Regular::_digest($tmpdt2->filename);

## Create a File::Properties::Regular object for the second temporary
## test file, measuring the time taken to do so. Check that the object
## was not retrieved from the cache, and that the object file digest
## value matches the directly determined value.
$t0 = [gettimeofday];
ok($fpr = File::Properties::Regular->new($tmpdt2->filename, $fpc));
$t1 = [gettimeofday];
ok(not $fpr->_fromcache);
ok($fpr->digest eq $tdgst2);

## Create another File::Properties::Regular object for the second
## temporary test file, measuring the time taken to do so. Check that
## the object was retrieved from the cache, and that the object file
## digest value matches the directly determined value.
$t2 = [gettimeofday];
ok($fpr = File::Properties::Regular->new($tmpdt2->filename, $fpc));
$t3 = [gettimeofday];
ok($fpr->_fromcache);
ok($fpr->digest eq $tdgst2);

# Second lookup via cache should be much faster
ok(tv_interval($t2,$t3) lt 10*tv_interval($t0,$t1));

exit 0;


# Construct a temporary file with random content, of the specified
# size
sub tmprndfile {
    my $size = shift;

    my $fh = File::Temp->new;
    print $fh map { chr(rand 256) } 1..$size;
    $fh->seek(0,0);
    return $fh;
}
