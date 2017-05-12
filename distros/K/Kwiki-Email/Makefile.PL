use 5.008003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Kwiki::Email',
    VERSION_FROM      => 'lib/Kwiki/Email.pm', # finds $VERSION
    PREREQ_PM         => {
		Email::Valid  => 0,
		Kwiki::Plugin => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Kwiki/Email.pm', # retrieve abstract from module
       AUTHOR         => 'Alexander Goller <decay@cpan.org>') : ()),
);
