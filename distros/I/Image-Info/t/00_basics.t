#!/usr/bin/perl -w

use Test::More;
use strict;
use File::Spec;

# test exporting of functions plus the basics

BEGIN
   {
   plan tests => 11;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Image::Info") or die($@);
   };

use Image::Info qw(image_info dim html_dim determine_file_format image_type);

my $test = File::Spec->catfile( File::Spec->updir(), 'img', 'test.gif');

my $info = image_info($test);

#############################################################################
# dim, html_dim

my @dim = dim($info);

is (join(" ", @dim), "200 150", 'dim()');

is (dim($info), '200x150', 'dim($info)');

is (html_dim($info), 'width="200" height="150"', 'html_dim()');

is (html_dim(image_info('README')), '', 'no README in info');

#############################################################################
# image_type

my $type = image_type($test);

if (is (ref($type), 'HASH', 'got hash from image_type'))
  {
  is ($type->{file_type}, 'GIF', 'image_type is GIF');
  }
else
  {
  fail ('image_type');
  }

$type = image_type($test.'non-existant');

if (is (ref($type), 'HASH', 'got hash from image_type'))
  {
  ok (exists $type->{error}, '{error} got set');
  ok (exists $type->{Errno}, '{Errno} got set');
  }
else
  {
  fail ('image_type with error');
  fail ('image_type with error');
  }

#############################################################################
# determine_file_format

is (determine_file_format('GIF87a'), 'GIF', 'determine_file_format is GIF');
