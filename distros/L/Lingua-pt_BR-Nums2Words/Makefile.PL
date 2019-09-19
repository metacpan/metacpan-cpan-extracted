use ExtUtils::MakeMaker;
use utf8;

WriteMakefile(
    NAME              => 'Lingua::pt_BR::Nums2Words',
    VERSION_FROM      => 'lib/Lingua/pt_BR/Nums2Words.pm',
    PREREQ_PM         => {},
    ABSTRACT_FROM     => 'lib/Lingua/pt_BR/Nums2Words.pm',
    AUTHOR            => 'Gil Magno <gils@cpan.org>',
    LICENSE           => 'perl',
    META_MERGE        => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://gitlab.com/gilmagno/lingua-pt-br-nums2words.git',
                web  => 'https://gitlab.com/gilmagno/lingua-pt-br-nums2words',
            },
        },
        x_contributors => [
            'Italo Gonçales <italo.goncales@gmail.com>',
        ],
    },
);
