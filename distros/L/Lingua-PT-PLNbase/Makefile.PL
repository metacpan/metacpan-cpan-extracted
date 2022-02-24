require 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      NAME              => 'Lingua::PT::PLNbase',
	      VERSION_FROM      => 'lib/Lingua/PT/PLNbase.pm', # finds $VERSION
	      EXE_FILES         => [ "scripts/sentences" ],
              CONFIGURE_REQUIRES => {
                                     "ExtUtils::MakeMaker" => '6.55',
                                    },
              BUILD_REQUIRES    => {
				    'Test::Pod' => '1.00',
				    'Path::Tiny' => 0,
				    'Test::Pod::Coverage' => '0.08',
				    'Lingua::PT::Abbrev' => '0.05',
                                    'File::Temp' => 0
                                   },
	      PREREQ_PM         => {
				    'utf8::all' => 0,
				    'Lingua::PT::Abbrev' => '0.05',
				   },
	      ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
	       (ABSTRACT_FROM  => 'lib/Lingua/PT/PLNbase.pm', # retrieve abstract from module
		AUTHOR         => 'Alberto Simoes <ambs@di.uminho.pt>') : ()),
	     );
