use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'HTML::Template::Convert::TT',
    VERSION_FROM      => 'lib/HTML/Template/Convert/TT.pm', # finds $VERSION
    PREREQ_PM         => {'HTML::Template' => 2.9, 'Template' => 2.20}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (
	   ABSTRACT		  => 'perl extension for converting HTML::Template templates into Template Toolkit',
       AUTHOR         => 'A. D. Solovets <asolovets@gmail.com>') : ()),
);
