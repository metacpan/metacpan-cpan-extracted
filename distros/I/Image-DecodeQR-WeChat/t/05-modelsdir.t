#!/usr/bin/env perl

use strict;
use warnings;

our $VERSION = '2.2';

use Test::More;
use Test2::Plugin::UTF8;

use File::Spec;
use File::ShareDir qw/dist_dir/;
use Time::HiRes;

use Image::DecodeQR::WeChat qw/
	modelsdir
	opencv_has_highgui_xs
	detect_and_decode_qr_xs
	detect_and_decode_qr
/;

# modelsdir is installed during 'perl Makefile.PL/make install' stage
# to a share-dir relative to INSTALL_BASE and will be read-only
# if one does not supply modelsdir to detect_and_decode_qr_xs() or detect_and_decode_qr()
# this default will be used

my ($t, $d);
diag("starting ...");
$t = Time::HiRes::time;
my $modelsdir = Image::DecodeQR::WeChat::modelsdir;
$d = Time::HiRes::time-$t;
ok(-d $modelsdir, "modelsdir exists in '$modelsdir' (found in $d seconds)");

#$t = Time::HiRes::time;
#my $moduledir = File::ShareDir::module_dir('Image::DecodeQR::WeChat');
#$d = Time::HiRes::time-$t;
#ok(-d $moduledir, "module dir exists in '$moduledir' (found in $d seconds)");

my @modelfiles = qw/detect.caffemodel detect.prototxt sr.caffemodel sr.prototxt/;
for my $f (@modelfiles){
	my $fp = File::Spec->catdir($modelsdir, $f);
	ok(-f $fp, "model file '$fp' exists.")
}

done_testing;
