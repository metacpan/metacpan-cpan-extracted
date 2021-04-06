use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'Lingua::PT::Inflect',
    'VERSION_FROM'  => 'lib/Lingua/PT/Inflect.pm', # finds $VERSION
    'ABSTRACT_FROM'  => 'lib/Lingua/PT/Inflect.pm', # retrieve abstract from module
    'PREREQ_PM'     => {
        'Lingua::PT::Hyphenate' => '1.01',
        'ExtUtils::MakeMaker' => '6.98',
    },
    'TEST_REQUIRES' => {
        # modules only required for testing
        'Test::More' => '0.98',
        'Test::Pod' => '1.0',
        'Test::Pod::Coverage' => '1.08',
    },
    'META_MERGE'    => {
        'resources' => {
            'repository' => 'https://github.com/asb-capfan/Lingua-PT-Inflect',
        },
    },
    'AUTHOR'        => 'Jose Castro <cog@cpan.org>',
    'LICENSE'      => 'perl_5',
);
