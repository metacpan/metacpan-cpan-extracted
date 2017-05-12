use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Formatter::HTML::HTML',
    VERSION_FROM      => 'lib/Formatter/HTML/HTML.pm', # finds $VERSION
    PREREQ_PM         => {
			  HTML::Tidy => 1.06,
			  HTML::TokeParser => 0,
			 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Formatter/HTML/HTML.pm', # retrieve abstract from module
       AUTHOR         => 'Kjetil Kjernsmo <kjetilk@cpan.org>') : ()),
);
