use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Geo::Address::Mail::Standardizer::USPS::AMS',
    VERSION_FROM      => 'lib/Geo/Address/Mail/Standardizer/USPS/AMS.pm', # finds $VERSION
    PREREQ_PM         => {'Geo::Address::Mail::Standardizer::USPS::AMS::Results' => 0.02 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Geo/Address/Mail/Standardizer/USPS/AMS.pm', # retrieve abstract from module
       AUTHOR         => 'Mike Eldridge <diz@cpan.org>') : ()),
    LIBS              => ['-lz4'], # e.g., '-lm'
    #LIBS              => ['-lz4lnx64'], # e.g., '-lm'
    DEFINE            => '-DCASS_CYCLE_M', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
