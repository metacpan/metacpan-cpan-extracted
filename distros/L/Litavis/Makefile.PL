use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

# Resolve Colouring::In::XS include directory (for colour headers)
my $colour_inc;
# Load Colouring::In::XS without triggering XSLoader, then call include_dir().
# XSLoader::load is intercepted so the .pm's pure-Perl methods are available
# without needing the compiled .bundle (which may not match the .pm version).
eval {
    no warnings 'redefine';
    local *XSLoader::load = sub {};  # no-op the XS bootstrap
    require Colouring::In::XS;
    $colour_inc = Colouring::In::XS->include_dir();
    $colour_inc = undef unless $colour_inc && -d $colour_inc;
};
if (!$colour_inc && -d '../Colouring-In-XS/include') {
    $colour_inc = '../Colouring-In-XS/include';
}
if (!$colour_inc && -d '../Colouring-In-XS-0.07/include') {
    $colour_inc = '../Colouring-In-XS-0.07/include';
}
die "Cannot find Colouring::In::XS include directory. Install Colouring::In::XS first.\n"
    unless $colour_inc;

my %WriteMakefileArgs = (
    NAME             => 'Litavis',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Litavis.pm',
    ABSTRACT_FROM    => 'lib/Litavis.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010',

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'Colouring::In::XS'   => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
    },
    PREREQ_PM => {},

    INC    => "-I. -Iinclude -I$colour_inc",
    OBJECT => '$(O_FILES)',

    # Install headers so downstream XS modules can #include them
    PM => {
        'lib/Litavis.pm'                 => '$(INST_LIB)/Litavis.pm',
        'include/litavis.h'              => '$(INST_LIB)/Litavis/include/litavis.h',
        'include/litavis_ast.h'          => '$(INST_LIB)/Litavis/include/litavis_ast.h',
        'include/litavis_tokeniser.h'    => '$(INST_LIB)/Litavis/include/litavis_tokeniser.h',
        'include/litavis_parser.h'       => '$(INST_LIB)/Litavis/include/litavis_parser.h',
        'include/litavis_cascade.h'      => '$(INST_LIB)/Litavis/include/litavis_cascade.h',
        'include/litavis_vars.h'         => '$(INST_LIB)/Litavis/include/litavis_vars.h',
        'include/litavis_emitter.h'      => '$(INST_LIB)/Litavis/include/litavis_emitter.h',
        'include/litavis_colour.h'       => '$(INST_LIB)/Litavis/include/litavis_colour.h',
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES => 'Litavis-*' },
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
