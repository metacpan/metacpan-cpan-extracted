use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Email::Received',
    VERSION_FROM      => 'lib/Email/Received.pm', # finds $VERSION
    PREREQ_PM         => {
        Regexp::Common => 0,
        Text::Balanced => 0, # Cor, it's a bit DCONWAY heavy.
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Email/Received.pm', # retrieve abstract from module
       AUTHOR         => 'simon <simon@>') : ()),
);
