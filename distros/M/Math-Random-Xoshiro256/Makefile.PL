use ExtUtils::MakeMaker;
use Config;

my $is_64bit  = $Config{uvsize} >= 8;

# Cannot build if we don't have 64bit UVs
if (!$is_64bit) {
	die("This module requires that Perl be built with 64bit integer support (--64int)\n");
}

WriteMakefile(
    NAME         => 'Math::Random::Xoshiro256',
    VERSION_FROM => 'lib/Math/Random/Xoshiro256.pm',
    ABSTRACT     => 'XS wrapper for xoshiro256+ PRNG',
    AUTHOR       => 'Scott Baker <bakerscot@cpan.org>',
    PL_FILES     => {},
);
