use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

# including data
install_share dist => 'metabolomics-references';

my %WriteMakefileArgs = (
    NAME             => 'Metabolomics::Fragment::Annotation',
    AUTHOR           => q{Franck Giacomoni <franck.giacomoni@inrae.fr>},
    VERSION_FROM     => 'lib/Metabolomics/Fragment/Annotation.pm',
    ABSTRACT_FROM    => 'lib/Metabolomics/Fragment/Annotation.pm',
    LICENSE          => 'open_source',
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        "File::ShareDir::Install" => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
        'File::Share' => '0.25',
    },
    PREREQ_PM => {
    	'Text::CSV_XS' => '1.39', 
        'Text::CSV' => '2.0',
        'XML::Twig' => '3.48',
        'File::Share' => '0.25',
        'JSON'	=> '2.90'
    },
    
    test  => {TESTS => 't/*.t'},
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Metabolomics-Fragment-Annotation-*' },
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

WriteMakefile(%WriteMakefileArgs);

package MY;
use File::ShareDir::Install 'postamble';
