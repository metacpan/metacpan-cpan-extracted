# $Id: Makefile.PL,v 1.3 2004/05/02 12:01:09 florian Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Finance::Bank::PSK',
    'VERSION_FROM'  => 'lib/Finance/Bank/PSK.pm',
    'PREREQ_PM'     => {
        'WWW::Mechanize'      => 0.57,
        'HTML::TokeParser'    => 2.24,
        'Class::MethodMaker'  => 1.06,
        },
    'dist'          => {
        'COMPRESS'            => 'gzip --force --best'
        },
);
