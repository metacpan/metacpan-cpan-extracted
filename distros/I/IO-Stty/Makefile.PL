
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'IO::Stty',
    AUTHOR        => 'Austin Schutz <auschutz@cpan.org>',
    VERSION_FROM  => 'lib/IO/Stty.pm',
    ABSTRACT_FROM => 'lib/IO/Stty.pm',
    PL_FILES      => {},
    ( $ExtUtils::MakeMaker::VERSION >= 6.48 ? ( 'MIN_PERL_VERSION' => '5.008', ) : () ),
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002 ? ( 'LICENSE' => 'perl', ) : () ),
    ( $ExtUtils::MakeMaker::VERSION >= 6.64 ? (
        TEST_REQUIRES => {
            'Test::More' => 0,
        },
    ) : (
        PREREQ_PM => {
            'Test::More' => 0,
        },
    )),
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'IO-Stty-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        provides => {
            'IO::Stty' => {
                file    => 'lib/IO/Stty.pm',
                version => MM->parse_version('lib/IO/Stty.pm'),
            },
        },
        resources => {
            license    => ['https://dev.perl.org/licenses/'],
            homepage   => 'https://github.com/cpan-authors/IO-Stty',
            bugtracker => {
                web => 'https://github.com/cpan-authors/IO-Stty/issues',
            },
            repository => {
                type => 'git',
                url  => 'https://github.com/cpan-authors/IO-Stty.git',
                web  => 'https://github.com/cpan-authors/IO-Stty',
            },
        },
    },
);

sub MY::postamble {
    return "readme: lib/IO/Stty.pm\n"
         . "\t\@perl -MPod::Markdown -e1 2>/dev/null || (echo 'Pod::Markdown is required: cpanm Pod::Markdown' >&2; exit 1)\n"
         . "\tpod2markdown lib/IO/Stty.pm README.md\n";
}
