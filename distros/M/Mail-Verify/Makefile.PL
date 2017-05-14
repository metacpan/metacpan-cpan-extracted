# $Id: Makefile.PL,v 1.1.1.1 2001/07/26 18:33:27 petef Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
    'AUTHOR'		=> 'Pete Fritchman <petef@databits.net>',
    'NAME'		=> 'Mail::Verify',
    'VERSION_FROM'	=> 'lib/Mail/Verify.pm',
    'PREREQ_PM'		=> {
				'IO::Socket' => 0.1,
				'Net::DNS' => 0.1,
			   },
    'dist'		=> {COMPRESS => 'gzip', SUFFIX => 'gz' },
);

