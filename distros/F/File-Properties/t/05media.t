# -*- cperl -*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 05media.t'

#########################

use Test::More tests => 10;
BEGIN { use_ok('File::Properties::Cache');
        use_ok('File::Properties::Media') };
use Error qw(:try);
use Time::HiRes qw(gettimeofday tv_interval);
use File::Temp;
use Image::Magick;

#########################

## Create a File::Properties::Cache object attached to a temporary
## database file
my $tmpdb = File::Temp->new(EXLOCK => 0, SUFFIX => '.db');
my $opts = {};
ok(my $fpc = File::Properties::Media->cache($tmpdb->filename, $opts));

# Create a temporary test image file
my $tmpdt = tmpimgfile(1024,768);

## Create a File::Properties::Media object for the temporary test
## file, measuring the time taken to do so. Check that the object was
## not retrieved from the cache.
my $fpr;
my $t0 = [gettimeofday];
ok($fpr = File::Properties::Media->new($tmpdt->filename, $fpc));
my $t1 = [gettimeofday];
ok(not $fpr->_fromcache);

## Create another File::Properties::Media object for the temporary
## test file, measuring the time taken to do so. Check that the object
## was retrieved from the cache.
my $t2 = [gettimeofday];
ok($fpr = File::Properties::Media->new($tmpdt->filename, $fpc));
my $t3 = [gettimeofday];
ok($fpr->_fromcache);

# Second lookup via cache should be much faster
ok(tv_interval($t2,$t3) lt 10*tv_interval($t0,$t1));

## Check whether the image dimensions from the File::Properties::Media
## EXIF data are correct
my $exf = $fpr->exifhash;
ok($exf->{'PNG:ImageWidth'} == 1024);
ok($exf->{'PNG:ImageHeight'} == 768);

exit 0;


# Create a temporary image file of the specified dimensions
sub tmpimgfile {
    my $hdim = shift;
    my $vdim = shift;

    my $fh = File::Temp->new;
    my $im = Image::Magick->new(size=>$hdim."x".$vdim,depth=>8);
    $im->ReadImage("xc:gray");
    $im->AddNoise(noise=>'Gaussian', channel=>'All');
    $im->Write(file=>$fh, filename=>"png:");
    $fh->seek(0,0);
    return $fh;
}
