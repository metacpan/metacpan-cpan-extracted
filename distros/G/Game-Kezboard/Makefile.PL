#!perl
# The perl version probably can go lower but function signatures are
# used a lot, and there are a few instances of 42 < $x < 640 which was
# added in something like perl 5.32.
use 5.36.0;
use ExtUtils::MakeMaker;
use File::ShareDir::Install qw(install_share);

install_share 'data';

my %WriteMakefileArgs = (
    NAME               => 'Game::Kezboard',
    AUTHOR             => q{Jeremy Mates <jmates@thrig.me>},
    VERSION_FROM       => 'lib/Game/Kezboard.pm',
    ABSTRACT_FROM      => 'lib/Game/Kezboard.pm',
    LICENSE            => 'bsd',
    MIN_PERL_VERSION   => '5.36.0',
    EXE_FILES          => [qw(kezboard)],
    PL_FILES           => {},
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'     => '0',
        'File::ShareDir::Install' => '0',
    },
    TEST_REQUIRES => {
        'Test2::V0' => '0.000060',
        'perl'      => '5.36.0',
    },
    PREREQ_PM => {
        'Algorithm::QuadTree' => '0',      # only tested with 0.5
        'File::ShareDir'      => '0',
        'File::Spec'          => '0',
        'Game::Deckar'        => '0.02',
        'SDL'         => '0',        # only tested with 2.2.0 on OpenBSD 7.4
        'Time::HiRes' => '0',
        'perl'        => '5.36.0',
    },
    dist       => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean      => { FILES    => 'Game-Kezboard-*' },
    META_MERGE => {
        'resources' =>
          { repository => 'https://thrig.me/src/Game-Kezboard.git', },
    },
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless ( eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 } ) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{ $WriteMakefileArgs{PREREQ_PM} }{ keys %$test_requires } =
      values %$test_requires;
}

unless ( eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 } ) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{ $WriteMakefileArgs{PREREQ_PM} }{ keys %$build_requires } =
      values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
  unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile( ( MM->can('signature_target') ? ( SIGN => 1 ) : () ),
    %WriteMakefileArgs );

package MY;
use File::ShareDir::Install qw(postamble);
