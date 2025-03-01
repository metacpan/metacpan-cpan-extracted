use 5.010;
use strict;
use warnings;

use utf8;

use Test::More;
use Test::More::UTF8;

unless ( $ENV{RELEASE_TESTING} ) {
	plan skip_all => "Author tests not required for installation. Test only run when called with RELEASE_TESTING=1";
}

my $min_tcm = '1.04';
eval "use Test::Perl::Critic $min_tcm";
plan skip_all => "Test::Perl::Critic $min_tcm not installed and required" if $@;

all_critic_ok('lib');
