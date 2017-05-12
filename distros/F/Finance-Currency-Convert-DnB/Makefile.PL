use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Finance::Currency::Convert::DnB',
    AUTHOR              => 'Thomas Martinsen <tech@tnet.no>',
    VERSION_FROM        => 'lib/Finance/Currency/Convert/DnB.pm',
    ABSTRACT_FROM       => 'lib/Finance/Currency/Convert/DnB.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'File::Spec' => 0,
	'XML::Simple' => 0,
	'LWP::Simple' => 0,
	'Slurp' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Finance-Currency-Convert-DnB-*' },
);
