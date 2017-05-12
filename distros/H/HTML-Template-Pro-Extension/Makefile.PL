## -*- Perl -*-

use ExtUtils::MakeMaker;

WriteMakefile(
		NAME	  			=> "HTML::Template::Pro::Extension",
	  VERSION_FROM 	=> "Extension.pm",
	 	PREREQ_PM     => {
                      'HTML::Template::Pro' => 0,
											'HTML::Parser' => 0
                     },
	      ($] >= 5.005 ?
	       (
		ABSTRACT   => "Plugin extension for HTML::Template::Pro module",
		AUTHOR	   => "Emiliano Bruni <info\@ebruni.it>") : ()),
	      );

# vim: set ts=2:
