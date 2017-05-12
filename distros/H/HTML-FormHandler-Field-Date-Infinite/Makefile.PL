use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTML::FormHandler::Field::Date::Infinite',
    AUTHOR              => 'Torbjørn Lindahl <torbjorn.lindahl@gmail.com>',
    VERSION_FROM        => 'lib/HTML/FormHandler/Field/Date/Infinite.pm',
    ABSTRACT_FROM       => 'lib/HTML/FormHandler/Field/Date/Infinite.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'HTML::FormHandler::Field::Date' => '0.03',
        'DateTime'                       => '1.06',
        'Moose'                          => '2.1005',
        'Test::Warnings'                 => '0.010',
        'Test::Most'                     => '0.34',
        'namespace::autoclean'           => '0.13',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTML-FormHandler-Field-Date-Infinite-*' },
);
