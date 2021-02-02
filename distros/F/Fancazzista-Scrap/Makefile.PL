use 5.018004;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Fancazzista::Scrap',
    ABSTRACT     => 'Scrap websites article, reddit posts and dev.to article',
    VERSION_FROM => 'lib/Fancazzista/Scrap.pm',
    PREREQ_PM    => {
        'LWP::UserAgent' => 0,
        'HTTP::Request' => 0,
        'Mojo::DOM' => 0,
    },
    AUTHOR       => 'Antoine MICELI, https://miceli.click',
    'LIBS'      => ['']
);
