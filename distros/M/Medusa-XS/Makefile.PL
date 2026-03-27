use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

# Find Horus and Loo include dirs from installed modules
my @inc_dirs;
for my $mod (qw(Horus Loo)) {
    eval "require $mod";
    if (!$@ && $mod->can('include_dir')) {
        my $dir = $mod->include_dir();
        push @inc_dirs, $dir if -d $dir;
    }
}
# Fallback to sibling dirs for dev workspace
push @inc_dirs, '../Horus/include' if !grep { /Horus/ } @inc_dirs && -d '../Horus/include';
push @inc_dirs, '../Loo/include'   if !grep { /Loo/ }   @inc_dirs && -d '../Loo/include';

my $inc = join(' ', '-I.', map { "-I$_" } @inc_dirs);
warn "Medusa::XS INC = $inc\n";

my $has_xsmulti = eval { ExtUtils::MakeMaker->VERSION('7.12'); 1 };

my %WriteMakefileArgs = (
    NAME             => 'Medusa::XS',
    AUTHOR           => 'LNATION <email@lnation.org>',
    VERSION_FROM     => 'lib/Medusa/XS.pm',
    ABSTRACT         => 'XS-accelerated subroutine auditing with custom ops',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Devel::PPPort' => '3.68',
        'Horus' => '0.01',
        'Loo'   => '0.04',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
    },
    PREREQ_PM => {
        'Time::HiRes' => '0',
    },

    # Horus UUID library headers (pure C, reusable)
    # Loo Data Dumper headers (needs -I../Loo for ppport.h, -I../Loo/include for headers)
    # Paths are relative to Medusa-XS/ build directory
    INC      => $inc,

    EXE_FILES => ['bin/medusa-strip-colour'],

    # Ensure all PM files are installed
    PM => {
        'lib/Medusa/XS.pm'         => '$(INST_LIB)/Medusa/XS.pm',
        'lib/Medusa/XS/Logger.pm'  => '$(INST_LIB)/Medusa/XS/Logger.pm',
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Medusa-XS-* lib/Medusa/*.o lib/Medusa/*.c lib/Medusa/*.bs' },
);

if ($has_xsmulti) {
    # Modern MakeMaker: XSMULTI handles subdirectory XS natively
    $WriteMakefileArgs{XSMULTI} = 1;
    $WriteMakefileArgs{XS}      = { 'lib/Medusa/XS.xs' => 'lib/Medusa/XS.c' };
    $WriteMakefileArgs{OBJECT}  = 'lib/Medusa/XS$(OBJ_EXT)';
} else {
    # Old MakeMaker: explicit XS mapping with postamble for compile rule
    $WriteMakefileArgs{XS}     = { 'lib/Medusa/XS.xs' => 'lib/Medusa/XS.c' };
    $WriteMakefileArgs{OBJECT} = 'lib/Medusa/XS$(OBJ_EXT)';
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

# For old MakeMaker without XSMULTI: add explicit compile rule for
# the XS-generated .c file in lib/Medusa/ subdirectory
sub MY::postamble {
    return '' if $has_xsmulti;
    return <<'MAKE';
lib/Medusa/XS$(OBJ_EXT): lib/Medusa/XS.c
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) $< -o $@
MAKE
}
