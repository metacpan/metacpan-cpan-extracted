use 5.008003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'FlatFile::DataStore',
    VERSION_FROM      => 'lib/FlatFile/DataStore.pm', # finds $VERSION
    PREREQ_PM         => {
        'URI'            =>  1.35,
        'URI::Escape'    =>  1.35,
        'Data::Omap'     =>  0.06,
        'Math::Int2Base' =>  0.03,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/FlatFile/DataStore.pm', # retrieve abstract from module
       AUTHOR         => 'Brad Baxter <bbaxter@cpan.org>') : ()),
);
