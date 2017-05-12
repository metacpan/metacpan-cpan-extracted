use 5.008001;
use ExtUtils::MakeMaker;

eval { my $q = unpack("Q", 1234123412341234) };

print STDERR <<_SORRY_ if $@;
Your architecture does not support quads (64-bit ints). This module
will NOT work on this machine. Building Makefile anyway...

_SORRY_

WriteMakefile(
              NAME              => 'Linux::Taskstats::Read',
              VERSION_FROM      => 'lib/Linux/Taskstats/Read.pm', # finds $VERSION
              PREREQ_PM         => {}, # e.g., Module::Name => 1.1
              ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
               (ABSTRACT_FROM  => 'lib/Linux/Taskstats/Read.pm', # retrieve abstract from module
                AUTHOR         => 'Scott Wiersdorf <scott@perlcode.org>') : ()),
             );
