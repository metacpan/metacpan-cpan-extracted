use ExtUtils::MakeMaker;
use strict;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my %opts = (
            'NAME'              => 'Linux::KernelSort',
            'VERSION_FROM'      => 'lib/Linux/KernelSort.pm', # finds $VERSION
            'PREREQ_PM'         => {}, # e.g., Module::Name => 1.1
            'ABSTRACT_FROM'     => 'lib/Linux/KernelSort.pm', # retrieve abstract from module
            'AUTHOR'            => 'Leann Ogasawara <ogasawara@osdl.org>',
);

WriteMakefile( %opts );
