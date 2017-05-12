# $Id: Makefile.PL,v 1.2 2003/08/14 21:35:23 florian Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Finance::Bank::easybank',
    'VERSION_FROM'	=> 'lib/Finance/Bank/easybank.pm',
    'PREREQ_PM'		=> {
    	'WWW::Mechanize'      => 0.57,
	'HTML::TokeParser'    => 2.24,
	'Class::MethodMaker'  => 1.06,
    	},
    'dist'              => {
    	'COMPRESS'            => 'gzip --force --best'
        },
);
