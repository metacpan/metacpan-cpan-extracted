use 5.010;
use strict;
use warnings;

use utf8;

use Test::More;
use Test::More::UTF8;

unless ( $ENV{RELEASE_TESTING} ) {
	plan skip_all => "Author tests not required for installation. Test only run when called with RELEASE_TESTING=1";
}

my $min_tcm = '1.28';
eval "use Test::Kwalitee $min_tcm qw/ kwalitee_ok /";
plan skip_all => "Test::Kwalitee $min_tcm not installed and required" if $@;

kwalitee_ok();
done_testing;
