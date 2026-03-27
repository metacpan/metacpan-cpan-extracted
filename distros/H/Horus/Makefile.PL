use 5.008003;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'Horus',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Horus.pm',
    ABSTRACT_FROM    => 'lib/Horus.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.008003',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {},
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Horus-*' },

    # XS configuration
    INC    => '-I. -Iinclude',
    OBJECT => '$(O_FILES)',

    # Install headers so dependent XS modules can find them
    PM => {
        'lib/Horus.pm'              => '$(INST_LIB)/Horus.pm',
        'include/horus.h'           => '$(INST_LIB)/Horus/include/horus.h',
        'include/horus_core.h'      => '$(INST_LIB)/Horus/include/horus_core.h',
        'include/horus_encode.h'    => '$(INST_LIB)/Horus/include/horus_encode.h',
        'include/horus_format.h'    => '$(INST_LIB)/Horus/include/horus_format.h',
        'include/horus_md5.h'       => '$(INST_LIB)/Horus/include/horus_md5.h',
        'include/horus_parse.h'     => '$(INST_LIB)/Horus/include/horus_parse.h',
        'include/horus_random.h'    => '$(INST_LIB)/Horus/include/horus_random.h',
        'include/horus_sha1.h'      => '$(INST_LIB)/Horus/include/horus_sha1.h',
        'include/horus_time.h'      => '$(INST_LIB)/Horus/include/horus_time.h',
        'include/horus_util.h'      => '$(INST_LIB)/Horus/include/horus_util.h',
        'include/horus_uuid.h'      => '$(INST_LIB)/Horus/include/horus_uuid.h',
    },
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

# Old MakeMaker doesn't support AUTHOR as arrayref
if (ref $WriteMakefileArgs{AUTHOR} eq 'ARRAY') {
    unless (eval { ExtUtils::MakeMaker->VERSION('6.5702'); 1 }) {
        $WriteMakefileArgs{AUTHOR} = join(', ', @{$WriteMakefileArgs{AUTHOR}});
    }
}

WriteMakefile(%WriteMakefileArgs);
