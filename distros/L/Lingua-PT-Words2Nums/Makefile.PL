use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Lingua::PT::Words2Nums',
    'VERSION_FROM'	=> 'lib/Lingua/PT/Words2Nums.pm', # finds $VERSION
    'ABSTRACT_FROM'  => 'lib/Lingua/PT/Words2Nums.pm', # retrieve abstract from module
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'TEST_REQUIRES' => {
        # modules only required for testing
        'Test::More' => '0.98',
        'Test::Pod' => '1.0',
        'Test::Pod::Coverage' => '1.08',
    },
    'META_MERGE'    => {
        'resources' => {
            'repository' => 'https://github.com/asb-capfan/Lingua-PT-Words2Nums',
        },
    },
    'AUTHOR'     => 'Jose Alves de Castro <cog@cpan.org>',
    'LICENSE'      => 'perl_5',
);
