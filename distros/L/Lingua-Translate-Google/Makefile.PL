use ExtUtils::MakeMaker;

WriteMakefile(
    ABSTRACT  => 'Lingua::Translate::Google - a Google backend for Lingua::Translate',
    AUTHOR    => 'Dylan Doxey, <dylan.doxey@gmail.com>',
    NAME      => "Lingua::Translate::Google",
    PREREQ_PM => {
        'WWW::Google::Translate' => 0,
        'I18N::LangTags'         => 0.27,
        'Lingua::Translate'      => 0,
        'Readonly'               => 1.03,
        'Test::More'             => 0,
        'Data::Dumper'           => 0,
    },
    VERSION_FROM => "lib/Lingua/Translate/Google.pm",
)

