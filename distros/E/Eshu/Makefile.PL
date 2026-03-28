use 5.008003;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my $has_xsmulti = eval { ExtUtils::MakeMaker->VERSION('7.12'); 1 };

my %WriteMakefileArgs = (
    NAME             => 'Eshu',
    AUTHOR           => 'LNATION <email@lnation.org>',
    VERSION_FROM     => 'lib/Eshu.pm',
    ABSTRACT         => 'Indentation fixer for C, Perl, XS, XML, HTML, CSS, JavaScript and POD source files',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.008003',
    INC              => '-I. -Iinclude',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Getopt::Long' => '0',
    },
    EXE_FILES => ['bin/eshu'],
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Eshu-* lib/*.o lib/*.c lib/*.bs' },
);

if ($has_xsmulti) {
    $WriteMakefileArgs{XSMULTI} = 1;
    $WriteMakefileArgs{XS}      = { 'lib/Eshu.xs' => 'lib/Eshu.c' };
    $WriteMakefileArgs{OBJECT}  = 'lib/Eshu$(OBJ_EXT)';
} else {
    $WriteMakefileArgs{XS}     = { 'lib/Eshu.xs' => 'lib/Eshu.c' };
    $WriteMakefileArgs{OBJECT} = 'lib/Eshu$(OBJ_EXT)';
}

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

WriteMakefile(%WriteMakefileArgs);

sub MY::postamble {
    return '' if $has_xsmulti;
    return <<'MAKE';
lib/Eshu$(OBJ_EXT): lib/Eshu.c
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) $< -o $@
MAKE
}
