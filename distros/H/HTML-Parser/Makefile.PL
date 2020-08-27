use strict;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME          => 'HTML::Parser',
    VERSION_FROM  => 'Parser.pm',
    ABSTRACT_FROM => 'Parser.pm',
    AUTHOR        => 'Gisle Aas <gisle@activestate.com>',
    LICENSE       => 'perl',

    MIN_PERL_VERSION => 5.008,
    PREREQ_PM        => {'HTML::Tagset' => 3, 'XSLoader' => 0,},
    META_MERGE       => {
        build_requires => {'Test::More'    => 0},
        recommends     => {'HTTP::Headers' => 0},
        resources      => {
            repository  => 'https://github.com/libwww-perl/HTML-Parser',
            MailingList => 'mailto:libwww@perl.org',
        }
    },

    DEFINE => "-DMARKED_SECTION",
    H      => [
        "hparser.h", "hctype.h", "tokenpos.h", "pfunc.h",
        "hparser.c", "util.c",
    ],
);

WriteMakefile(%WriteMakefileArgs);
