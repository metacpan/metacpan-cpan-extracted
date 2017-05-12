use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Finance::Currency::Convert::BChile',
    AUTHOR              => 'Hugo Salgado <hsalgado@vulcano.cl>',
    VERSION_FROM        => 'lib/Finance/Currency/Convert/BChile.pm',
    ABSTRACT_FROM       => 'lib/Finance/Currency/Convert/BChile.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'       => 0,
        'LWP::UserAgent'   => 0,
        'HTML::TokeParser' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Finance-Currency-Convert-BChile-*' },
);

