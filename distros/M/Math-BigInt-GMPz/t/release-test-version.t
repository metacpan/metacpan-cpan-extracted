#!perl

BEGIN {
    unless ($ENV{RELEASE_TESTING}) {
        print "1..0 # SKIP these tests are for release candidate testing";
        exit;
    }
}

use strict;
use warnings;

use Test::More;
use Test::Version;

my @imports = qw( version_all_ok );

my $params = {
  is_strict   => 1,
  has_version => 1,
  consistent  => 1,
  multiple    => 1,
};

push @imports, $params
  if version->parse($Test::Version::VERSION) >= version->parse('1.002');

Test::Version -> import(@imports);

version_all_ok();

done_testing;
