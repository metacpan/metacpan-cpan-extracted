use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME' => 'Geo::Yandex',
    'VERSION_FROM' => 'lib/Geo/Yandex.pm',
    ($] >= 5.005
        ?
        (ABSTRACT_FROM => 'lib/Geo/Yandex.pm',
        AUTHOR => 'Andrew Shitov <andy@shitov.ru>')
        :
        ()
    ),
    'PREREQ_PM' => {
        'LWP::UserAgent' => 0,
        'URI::Escape' => 0,
        'XML::LibXML' => 0,
    }
);
