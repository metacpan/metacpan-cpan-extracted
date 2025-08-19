use 5.010;
use strict;
use warnings;

use utf8;

use Test::More;
use Test::More::UTF8;

unless ( $ENV{RELEASE_TESTING} ) {
	plan skip_all => "Author tests not required for installation. Test only run when called with RELEASE_TESTING=1";
}

my $min_tcm = '0.52';
eval "use Test::Strict $min_tcm";
plan skip_all => "Test::Strict $min_tcm not installed and required" if $@;

all_perl_files_ok(); # Syntax ok and use strict;

all_cover_ok( 80, 't/' );	# at least 80% coverage
