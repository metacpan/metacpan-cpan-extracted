use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'HTML::BBCode',
    VERSION_FROM      => 'lib/HTML/BBCode.pm', # finds $VERSION
    PREREQ_PM         => {
      HTML::StripScripts::Parser => 0,
      HTML::StripScripts => 1.04,
      URI                => 0
      },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/HTML/BBCode.pm', # retrieve abstract from module
       AUTHOR         => 'M. Blom <blom@cpan.org>') : ()),
);
