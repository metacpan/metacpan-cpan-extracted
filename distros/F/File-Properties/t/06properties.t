# -*- cperl -*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 06properties.t'

#########################

use Test::More tests => 9;
BEGIN { use_ok('File::Properties') };
use Error qw(:try);
use Time::HiRes qw(gettimeofday tv_interval);
use File::Temp;
use Image::Magick;
use Compress::Bzip2;

#########################

## Create a File::Properties::Cache object attached to a temporary
## database file
my $tmpdb = File::Temp->new(EXLOCK => 0, SUFFIX => '.db');
my $opts = {};
ok(my $fpc = File::Properties->cache($tmpdb->filename, $opts));

## Create a temporary test bzip2 compressed image file and determine
## the SHA-2 digest of its pixel data directly (without creating a
## corresponding File::Properties object)
my $tmpdt = tmpbz2imgfile(1024,768);
my $idgst = File::Properties::Image::_imagedigest(
	      File::Properties::Compressed::_tmpbunzip($tmpdt->filename));

## Create a File::Properties object for the temporary test file,
## measuring the time taken to do so. Check that the object was not
## retrieved from the cache, and that the object image digest value
## matches the directly determined value.
my $fpr;
my $t0 = [gettimeofday];
ok($fpr = File::Properties->new($tmpdt->filename, $fpc));
my $t1 = [gettimeofday];
ok(not $fpr->cachestatus);
ok($fpr->idigest eq $idgst);

## Create another File::Properties object for the temporary test file,
## measuring the time taken to do so. Check that the object was
## retrieved from the cache, and that the object image digest value
## matches the directly determined value.
my $t2 = [gettimeofday];
ok($fpr = File::Properties->new($tmpdt->filename, $fpc));
my $t3 = [gettimeofday];
ok($fpr->cachestatus);
ok($fpr->idigest eq $idgst);

# Second lookup via cache should be much faster
ok(tv_interval($t2,$t3) lt 10*tv_interval($t0,$t1));

exit 0;


# Construct a temporary bzip2 compressed image file
sub tmpbz2imgfile {
    my $hdim = shift;
    my $vdim = shift;

    my $fh1 = File::Temp->new;
    my $im = Image::Magick->new(size=>$hdim."x".$vdim,depth=>8);
    $im->ReadImage("xc:gray");
    $im->AddNoise(noise=>'Gaussian', channel=>'All');
    $im->Write(file=>$fh1, filename=>"tif:");
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
