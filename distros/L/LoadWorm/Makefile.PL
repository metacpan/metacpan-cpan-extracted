
# $Name:  $

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'LoadWorm',
    'VERSION_FROM' => 'README', # finds $VERSION
    'PREREQ_PM' => { LWP => 5.20, 
                     Tk => 4.02,
                     LWP::Parallel => 2.30,
                     LWP::Parallel::RobotUA => 0,
                   },
    'PM' => {'LoadWorm.pm' => '$(INST_LIBDIR)/LoadWorm.pm',
            },
    ($] ge '5.005') ? (
                     'AUTHOR' => 'Glenn Wood <glenwood@alumni.caltech.edu>',
                     'ABSTRACT' => 'Scraper data from web search engines',
                    ) : (),
    'dist'	=> { 'TAR' => 'tar', 'TARFLAGS' => 'cvfz', 'SUFFIX' => '.gz', 'COMPRESS' => 'renameTAR'}

);
# {'name_of_file.pm' => '$(INST_LIBDIR)/install_as.pm'}

