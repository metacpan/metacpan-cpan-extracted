#use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Jamila',
    VERSION_FROM      => 'lib/Jamila.pm', # finds $VERSION
    PREREQ_PM         => {
       utf8 => undef,
       CGI => undef,
       JSON => undef,
       LWP => undef,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Jamila.pm', # retrieve abstract from module
       AUTHOR         => 'Kawai,Takanori <kwitknr@cpan.org>') : ()),
);
