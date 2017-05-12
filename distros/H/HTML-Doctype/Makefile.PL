use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'HTML::Doctype',
    VERSION_FROM      => 'lib/HTML/Doctype.pm', # finds $VERSION
    PREREQ_PM         => {
      SGML::Parser::OpenSP => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/HTML/Doctype.pm', # retrieve abstract from module
       AUTHOR         => 'Bjoern Hoehrmann <bjoern@hoehrmann.de>') : ()),

    LICENSE           => 'perl',
    'dist'            => {
      PREOP     => 'chmod 600 Makefile.PL',
      TARFLAGS	=> '--group=cpan --owner=bjoern -cvf',
    },

);
