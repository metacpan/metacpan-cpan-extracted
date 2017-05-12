use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR		=> 'Autrijus Tang <autrijus@autrijus.org>',
    ABSTRACT		=> 'Utilities for country-specific information',
    NAME		=> 'Geography::Country::Utils',
    VERSION_FROM	=> 'lib/Geography/Country/Utils.pm',
    DISTNAME		=> 'Geography-Country-Utils',
    PREREQ_PM		=> {
	'Time::Local'	=> 0,
	'Net::Country'	=> 0,
    },
);

1;
