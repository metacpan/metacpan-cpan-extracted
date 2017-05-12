use strict;
use warnings;
use ExtUtils::MakeMaker;
use Imager::ExtUtils;

WriteMakefile(
    NAME                => 'Imager::Filter::Sepia',
    AUTHOR              => 'Yoshiki KURIHARA <kurihara@cpan.org>',
    VERSION_FROM        => 'lib/Imager/Filter/Sepia.pm',
    ABSTRACT_FROM       => 'lib/Imager/Filter/Sepia.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Imager'     => 0.54,
    },
    INC                 => Imager::ExtUtils->includes,
    TYPEMAPS            => [ Imager::ExtUtils->typemap ],
    OBJECT              => 'Sepia.o',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Imager-Filter-Sepia-*' },
);
