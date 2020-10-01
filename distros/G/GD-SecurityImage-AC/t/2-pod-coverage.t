#!/usr/bin/env perl -w
use strict;
BEGIN { do 't/skip.test' or die "Can't include skip.test!" }

unless ($ENV{'TEST_POD_COVERAGE'}) {
    $|++;
    print "1..0 # Skipped: To enable POD coverage test set TEST_POD_COVERAGE=1\n";
    exit;
}

eval "use Test::Pod::Coverage;1";
if($@) {
   plan skip_all => "Test::Pod::Coverage required for testing pod coverage";
} else {
   plan tests => 1;
   # by-pass Authen::Captcha methods
   pod_coverage_ok('GD::SecurityImage::AC', { trustme => [qw/
      check_code
      create_image_file
      database_data
      database_file
      generate_code
      new
      create_sound_file
      data_folder
      debug
      expire
      height
      images_folder
      keep_failures
      output_folder
      type
      version
      width
   /]});
}
