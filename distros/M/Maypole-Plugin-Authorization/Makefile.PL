use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Maypole::Plugin::Authorization',
    VERSION_FROM      => 'lib/Maypole/Plugin/Authorization.pm', # find $VERSION
    PREREQ_PM         => {
	Maypole		=> 2.09,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
	# retrieve abstract from module
      (ABSTRACT_FROM  => 'lib/Maypole/Plugin/Authorization.pm',
       AUTHOR         => 'Dave Howorth <djh@cpan.org>') : ()),
);
