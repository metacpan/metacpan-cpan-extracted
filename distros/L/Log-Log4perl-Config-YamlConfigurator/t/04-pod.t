use strict;
use warnings;

use Test::More import => [ qw( plan ) ];

BEGIN { plan skip_all => 'Not release testing context' unless $ENV{ RELEASE_TESTING } }

# ensure a recent version of Test::Pod; consider updating the cpanfile too
use Test::Needs { 'Test::Pod' => 1.26 };

Test::Pod::all_pod_files_ok();
