use 5.010;
use strict;
use warnings;

use utf8;
binmode STDOUT,':utf8';
binmode STDERR,':utf8';

use Test::More;
use Test::More::UTF8;

# unless ( $ENV{RELEASE_TESTING} ) {
#	plan skip_all => "Author tests not required for installation. Test only run when called with RELEASE_TESTING=1";
# }

# Ensure a recent version of Test::Pod
my $min_tp = 1.22;
eval "use Test::Pod $min_tp";
plan skip_all => "Test::Pod $min_tp required for testing POD" if $@;

all_pod_files_ok();
