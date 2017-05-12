use 5.006001;
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME' => 'MIME::Lite::HT::HTML',
    'VERSION_FROM' => 'lib/MIME/Lite/HT/HTML.pm',   # finds $VERSION
    'ABSTRACT_FROM'  => 'lib/MIME/Lite/HT/HTML.pm', # retrieve abstract from module
    'PL_FILES' => {},
    'INSTALLDIRS' => 'site',
    'EXE_FILES' => [],
    'PREREQ_PM' => {
        'MIME::Lite' => '3.027',
        'MIME::Words' => 0,
        'HTML::Template' => '2.9',
        'HTML::FormatText' => '2.04',
        'HTML::FormatText::WithLinks' => '0.11',
        'DateTime::Format::Mail' => '0.3001',
        'Encode' => 0,
        'ExtUtils::MakeMaker' => '6.98',
    },
    TEST_REQUIRES => {
        # modules only required for testing
        'Test::More' => '0.98',
        'Test::Pod' => '1.0',
        'Test::Pod::Coverage' => '1.08',
    },
    AUTHOR         => 'Alexander Becker <c a p f a n ^at^ g m x -dot- d e>',
    LICENSE        => 'perl_5',
    dist           => { COMPRESS => "gzip", SUFFIX => "gz" },
    META_MERGE     => {
        resources => {
            repository => 'https://github.com/asb-capfan/MIME-Lite-HT-HTML',
        },
    },
    MIN_PERL_VERSION => 5.006001,
);
