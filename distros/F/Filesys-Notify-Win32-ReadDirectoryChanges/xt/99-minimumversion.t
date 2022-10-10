#!perl -w
use strict;
use Test::More;

if( $^O ne 'MSWin32' ) {
    plan skip_all => "This module only works on Windows";
    exit;
};

eval {
  #require Test::MinimumVersion::Fast;
  require Test::MinimumVersion;
  Test::MinimumVersion->import;
};

my @files;

if ($@) {
  plan skip_all => "Test::MinimumVersion required for testing minimum Perl version";
}
else {
  all_minimum_version_from_metajson_ok();
}
