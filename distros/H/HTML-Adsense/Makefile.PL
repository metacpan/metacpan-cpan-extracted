use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTML::Adsense',
    AUTHOR              => 'Nick Gerakines <nick@gerakines.net>',
    VERSION_FROM        => 'lib/HTML/Adsense.pm',
    ABSTRACT_FROM       => 'lib/HTML/Adsense.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Class::Accessor' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTML-Adsense-*' },
);
