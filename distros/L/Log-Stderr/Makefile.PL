use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
  (
   NAME             => 'Log::Stderr',
   VERSION_FROM     => 'lib/Log/Stderr.pm',
   PREREQ_PM        => { Carp => 0 },
   ($] >= 5.005 ?
    (ABSTRACT_FROM  => 'lib/Log/Stderr.pm',
     AUTHOR         => 'Marco Marongiu <bronto@cpan.org>') : ()),
);
