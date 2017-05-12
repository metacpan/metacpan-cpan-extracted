use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'HTML::Extract',
    VERSION_FROM      => 'lib/HTML/Extract.pm', # finds $VERSION
    PREREQ_PM         => {HTML::Tree => 3.0, HTML::Element => 3.0, HTML::TreeBuilder => 3.0 , LWP::UserAgent => 2}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/HTML/Extract.pm', # retrieve abstract from module
       AUTHOR         => 'Emma Tonkin <et207@slackware.lan>') : ()),
);
