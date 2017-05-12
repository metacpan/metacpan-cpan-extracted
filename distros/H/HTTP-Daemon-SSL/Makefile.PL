#
# A Makemaker script to build HTTP::Daemon::SSL
#
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  'NAME'	=> 'HTTP::Daemon::SSL',
  'VERSION_FROM' => 'SSL.pm',
  'DISTNAME' => 'HTTP-Daemon-SSL',
  'PREREQ_PM' => { 'HTTP::Daemon' => 1.0, 'IO::Socket::SSL' => 0.93 },
  'dist' => { COMPRESS => 'gzip', SUFFIX => 'gz', },
);
