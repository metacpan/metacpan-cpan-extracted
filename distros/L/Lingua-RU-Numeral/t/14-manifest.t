use 5.010;
use strict;
use warnings;

use utf8;

use Test::More;
use Test::More::UTF8;

unless ( $ENV{RELEASE_TESTING} ) {
	plan skip_all => "Author tests not required for installation. Test only run when called with RELEASE_TESTING=1";
}

# $ENV{MANIFEST_WARN_ONLY} = 1;	# errors will be non-fatal

my $min_tcm = 1.012;
eval "use Test::DistManifest $min_tcm";
plan skip_all => "Test::DistManifest $min_tcm not installed and required to test MANIFEST" if $@;

manifest_ok();
