use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'      => 'Lingua::PT::Nums2Ords',
    'VERSION_FROM'  => 'lib/Lingua/PT/Nums2Ords.pm', # finds $VERSION
    'ABSTRACT_FROM'  => 'lib/Lingua/PT/Nums2Ords.pm', # retrieve abstract from module
    'PREREQ_PM'     => {'Lingua::PT::Nums2Words' => 0.01}, # e.g., Module::Name => 1.1
    'TEST_REQUIRES' => {
        # modules only required for testing
        'Test::More' => '0.98',
        'Test::Pod' => '1.0',
        'Test::Pod::Coverage' => '1.08',
    },
    'META_MERGE'    => {
        'resources' => {
            'repository' => 'https://github.com/asb-capfan/Lingua-PT-Nums2Ords',
        },
    },
    'AUTHOR'     => 'Jose Alves de Castro <cog@cpan.org>',
    'LICENSE'      => 'perl_5',
);
