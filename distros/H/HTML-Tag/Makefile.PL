## -*- Perl -*-

use ExtUtils::MakeMaker;

WriteMakefile(
		NAME	  			=> "HTML::Tag",
	  VERSION_FROM 	=> "Tag.pm",
	 	PREREQ_PM     => {
	 	                   'Class::AutoAccess' => 0,
	 	                   'Tie::IxHash'    => 0,
                     },
	      ($] >= 5.005 ?
	       (
		ABSTRACT   => "Another HTML Widget system",
		AUTHOR	   => "Emiliano Bruni <info\@ebruni.it>") : ()),
	      );

# vim: set ts=2:
