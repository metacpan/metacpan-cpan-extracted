use ExtUtils::MakeMaker;
use FindBin qw($Bin);

# $Id: Makefile.PL 8365 2006-04-10 23:08:42Z vfelix $

# This script is used to build and install the HTC modules.
# For example, if you wish to install to /usr/local/scratch/perl_htc
# you would issue the following commmands:

#  perl Makefile.PL
#  make
#  make test
#  make install

BEGIN {
    require 5.6.0;
}

# See `perldoc ExtUtiles::MakeMaker` 
WriteMakefile(
    NAME          => 'Grid::Request',
    ABSTRACT      => 'Easily formulate, submit, and monitor grid jobs.',
    EXE_FILES     => [ 
                       "src/grid_request_worker",
                     ],
    VERSION_FROM  => 'VERSION', # finds $VERSION
    PREREQ_PM     => { Carp             => 0,
                       Config::IniFiles => 2.19,
                       Exception::Class => 1.23,
                       File::Path       => 1.0403,
                       File::Temp       => 0.12,
                       File::Which      => 0,
                       FindBin          => 0,
                       IO::Scalar       => 2.104,
                       Log::Log4perl    => 1.08,
                       Sys::Hostname    => 1.1,
                       Schedule::DRMAAc => 0,
                       Test::MockObject => 0,
                       Test::More       => 0.46,
                       XML::Writer      => 0.4,
                     },                        # e.g., Module::Name => 1.1
    # Make sure that the Makefile contains the correct VERSION
    # macro after any change to the file. See ExtUtiles::MakeMaker for details.
    depend => { Makefile => '$(VERSION_FROM)' }
);
