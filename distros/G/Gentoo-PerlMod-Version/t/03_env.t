use strict;
use warnings;

use Test::More 0.96;
use Test::Fatal;
use Gentoo::PerlMod::Version::Env;

$ENV{GENTOO_PERLMOD_VERSION_OPTS} = q[ foo=1 bar=2 quux quoz=5 -quoz ];

ok( Gentoo::PerlMod::Version::Env::hasopt('foo'),   'foo defined' );
ok( Gentoo::PerlMod::Version::Env::hasopt('bar'),   'bar defined' );
ok( Gentoo::PerlMod::Version::Env::hasopt('quux'),  'quux defined' );
ok( !Gentoo::PerlMod::Version::Env::hasopt('quoz'), 'quoz not defined' );

is( Gentoo::PerlMod::Version::Env::getopt('foo'),  1, 'foo  == 1' );
is( Gentoo::PerlMod::Version::Env::getopt('bar'),  2, 'bar  == 2' );
is( Gentoo::PerlMod::Version::Env::getopt('quux'), 1, 'quux == 1' );

done_testing;
