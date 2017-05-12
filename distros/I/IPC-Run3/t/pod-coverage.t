#!perl -w

use Test::More;
BEGIN {
  plan skip_all => "not run unless RELEASE_TESTING"
    unless $ENV{RELEASE_TESTING};
}
use Test::Pod::Coverage 1.04;
all_pod_coverage_ok(
	{ trustme => [ qr/_for_(?:created|modified)_(?:on|after|before)\Z/ ] }
);
