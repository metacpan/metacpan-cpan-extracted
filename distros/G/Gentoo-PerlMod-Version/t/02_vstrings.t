
use strict;
use warnings;

use Test::More 0.96;
use Test::Fatal;
use Gentoo::PerlMod::Version qw( :all );

is( exception { gentooize_version('v1.2') }, undef, 'V-Strings don\'t need laxitives' );

is( gentooize_version('v1.2'), '1.2.0', 'Vstrings emit similar numbers' );

done_testing;
