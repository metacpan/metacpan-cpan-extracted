use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Formatter::HTML::Preformatted',
    VERSION_FROM      => 'lib/Formatter/HTML/Preformatted.pm', # finds $VERSION
    PREREQ_PM         => {
			  URI::Find::Simple => 0,
			 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Formatter/HTML/Preformatted.pm', # retrieve abstract from module
       AUTHOR         => 'Kjetil Kjernsmo <kjetilk@cpan.org>') : ()),
);
