use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME => 'Finance::RawMaterialPrice',
    ( eval { ExtUtils::MakeMaker->VERSION(6.21) } ? ( LICENSE => 'perl' ) : () ),
    VERSION_FROM => 'lib/Finance/RawMaterialPrice.pm', # finds $VERSION
    PREREQ_PM    => { 'LWP::Simple' => 0 },            # e.g., Module::Name => 1.1
    (
        $] >= 5.005
        ?                                              ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM => 'lib/Finance/RawMaterialPrice.pm', # retrieve abstract from module
            AUTHOR        => 'sdrfnord <sdrfnord@gmx.de>'
          )
        : ()
    ),
    META_MERGE => {
        resources => {
            repository => 'https://github.com/sdrfnord/Finance-RawMaterialPrice',
            bugtracker => 'https://github.com/sdrfnord/Finance-RawMaterialPrice/issues'
        }
      }

);
