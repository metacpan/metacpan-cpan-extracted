## -*- Perl -*-

use ExtUtils::MakeMaker;

WriteMakefile(NAME	   => "HTML::Template::Extension",
		      VERSION_FROM => "Extension.pm",
			  'PREREQ_PM'         => {
                                        'HTML::Template' => 2.1,
																				'HTML::Parser' => 0
                                        },
	      ($] >= 5.005 ?
	       (ABSTRACT   => "Extension plug-ins for HTML::Template module",
		AUTHOR	   => "Emiliano Bruni <info\@ebruni.it>") : ()),
	      );
