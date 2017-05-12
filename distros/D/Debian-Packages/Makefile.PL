use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Debian::Packages',
    AUTHOR              => 'Jeremiah C. Foster <jeremiah@cpan.org>',
    VERSION_FROM        => 'lib/Debian/Packages.pm',
    ABSTRACT_FROM       => 'lib/Debian/Packages.pm',
    INSTALLDIRS         => 'vendor',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
	'Moose'      => 0,
	'Perl6::Slurp' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Debian-*' },
);
